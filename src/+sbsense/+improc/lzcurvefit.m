function [p1,resnorm,wps2,ws,XDATA,YDATA,resids] = lzcurvefit(p0, XDATA, YDATA, peakSearchBounds, peakSearchZone, ...
    numFitPoints, fallbackPeakMask, preferFallbackMask, fitParamBounds, f, p001)
fprintf(f, '[lzcurvefit] nargout: %d, nargin: %d\n', nargout, nargin);
smoothingLevel = 1;
fitParamLowerBounds = fitParamBounds(1,:);
fitParamUpperBounds = fitParamBounds(2,:);

baseWindowFactorNum = 32; baseWindowFactorScale = 500;
numSampPoints = length(XDATA);
baseWindowFactor = ...
    baseWindowFactorNum ...
    * baseWindowFactorScale / numSampPoints;
% fprintf('1\n');
baseWindow = max(1, floor(baseWindowFactor));
% fprintf('2\n');
tailSmoothWindow1 = ceil(baseWindowFactor *  [0.125 1.675]);
% fprintf('3\n');
tailSmoothWindow2 = ceil(baseWindowFactor * [0.5   1.5]);

doSecondPass = 0;
defaultParamGuess = [1 1 1];
outlierFillMethod ='pchip';
outlierFindMethod = 'movmedian';
baseOutlierThreshold = 1;
basicSmoothingMethod = 'sgolay';
peakSmoothingMethod = 'rlowess';
% peakThresholdHeightMultiplier = 0.6;
% peakThresholdMaxMultiplier = 0.75;
tailOutlierThreshold = 1;
% tailSmoothWindowFactors1 (1, 2) {mustBeNumeric, mustBePositive, mustBeReal, mustBeFinite} = [0.125 1.675];
% tailSmoothWindowFactors2 (1, 2) {mustBeNumeric, mustBePositive, mustBeReal, mustBeFinite} = [0.5   1.5  ];
tailSmoothingMethod = 'rlowess';
%optimOptionsBase {mustBeA(OptimOptionsBase, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsBase;%Opts0Base;
%optimOptionsFast {mustBeA(OptimOptionsFast, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsFast;%Opts0Fast;
%optimOptionsSlow {mustBeA(OptimOptionsSlow, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsSlow;%Opts0Slow;

fprintf(f, '[curvefit] fitParamBounds: [%g %g %g ; %g %g %g]\n', ...
    fitParamLowerBounds(1), fitParamLowerBounds(2), fitParamLowerBounds(3), ...
    fitParamUpperBounds(1), fitParamUpperBounds(2), fitParamUpperBounds(3));

wps2 = double.empty(3,0);
ws = double.empty();

hasPrediction = ~isempty(p001);

if(isempty(p0))
    if ~hasPrediction
        %p0 = mean(fitParamBounds,1);
        %p0(isnan(p0) || ~isfinite(p0)) = 1;
        p0 = double(defaultParamGuess);
        if ~isempty(peakSearchBounds)
            p0(1) = 0.5*double(sum(peakSearchBounds));
            fitParamLowerBounds(1) = peakSearchBounds(1);
            fitParamUpperBounds(1) = peakSearchBounds(2);
        end
    else
        % TODO: Check that p001 is a double??
        p0 = double(p001);
        if ~isempty(peakSearchBounds)
            fitParamLowerBounds(1) = peakSearchBounds(1);
            fitParamUpperBounds(1) = peakSearchBounds(2);
        end
    end
elseif ~isempty(peakSearchBounds)
    fitParamLowerBounds(1) = peakSearchBounds(1);
    fitParamUpperBounds(1) = peakSearchBounds(2);
end
fprintf(f, '[curvefit] PSB: [%g %g] --> fitParamBounds: [%g %g %g ; %g %g %g]\n', ...
    peakSearchBounds(1), peakSearchBounds(2), ...
    fitParamLowerBounds(1), fitParamLowerBounds(2), fitParamLowerBounds(3), ...
    fitParamUpperBounds(1), fitParamUpperBounds(2), fitParamUpperBounds(3));
numSampPoints = length(XDATA);
fprintf(f, '[curvefit] NumSampPoints: %d; class of XDATA: %s, size of XDATA: [%d %d]\n', ...
    numSampPoints, class(XDATA), size(XDATA,1), size(XDATA,2));

% YDATA0 = YDATA;

% fprintf('baseWindow: %s', formattedDisplayText(baseWindow));
if(smoothingLevel > -1)
    try
        fprintf(f, '[curvefit] smoothingLevel > -1 --> filling outliers\n');
        YDATA = filloutliers(YDATA, outlierFillMethod, ...
            outlierFindMethod, baseWindow, ...
            'ThresholdFactor', baseOutlierThreshold);
    catch ME
        throw(MException(ME.identifier, ...
            '(%s) %s', formattedDisplayText(baseWindow), ME.message));
    end
end

if(smoothingLevel > 0)
    fprintf(f, '[curvefit] smoothingLevel > 0 --> smoothing data\n');
    YDATA = smoothdata(YDATA, basicSmoothingMethod, ...
        baseWindow);
end

if(smoothingLevel > 2) % 3, 4, or 5
    fprintf(f, '[curvefit] smoothingLevel > 2 --> lsqcurvefit for preliminary estimate\n');
    % if false && hasPrediction
    %     [p01,R,~,~] = nlinfit(XDATA, YDATA, @sbsense.lorentz, p0);
    %     resnorm = sum(R.^2);
    %     exitflag = -1;
    % else
        [p01, resnorm01, ~, exitflag] = lsqcurvefit(@sbsense.lorentz, ...
            double(p0), XDATA, YDATA, fitParamLowerBounds, fitParamUpperBounds, sbsense.LorentzFitter.OptsBase);
    %end
    if ~isempty(p01)
        fprintf(f, '[curvefit] resnorm: %g, exitflag: %g, p01: [%g %g %g]\n', ...
            resnorm01, exitflag, p01(1), p01(2), p01(3));
    else
        fprintf(f, '[curvefit] resnorm: %g, exitflag: %g, p01: []\n', ...
            resnorm01, exitflag);
    end
    if(exitflag < 1)
        if(resnorm01 < 0.1)
            fprintf(f, '[curvefit] exitflag<1 && resnorm<0.1 --> p0 = p01; checking prediction validity (if present).\n');
            p0 = double(p01);
            if hasPrediction
                if abs(p01(1)-p001(1)) > 0.05*size(XDATA,2)
                    fprintf(f, '[curvefit] Abs. dist %g is more than 5% of XDATA width %g --> prediction invalid.\n', ...
                        abs(p01(1)-p001(1)), 0.02*size(XDATA,2));
                    hasPrediction = false;
                elseif abs( 1 - (p01(2)/p01(3))*(p001(3)/p001(2)) ) > 0.9
                    fprintf(f, '[curvefit] Ratio %g is more than 0.9 away from 1.0 --> prediction invalid.\n', ...
                        (p01(2)/p01(3))*(p001(2)/p001(3)));
                    hasPrediction = false;
                else
                    fprintf(f, '[curvefit] Prediction is still valid.\n');
                end
            else
                fprintf(f, '[curvefit] (no prediction supplied.)\n');
            end
        end
    end
    minPkHt = min(...
        0.6 * (p0(3))/(p0(1)), ...
        0.75 * max(YDATA, [], "all"));
    fprintf(f, '[curvefit] minPkHt (preliminary): %g\n', minPkHt);
    ymean = mean(YDATA, "all", 'omitnan');
    if ~isnan(ymean) && ~isempty(ymean)
        minPkHt = min(minPkHt, ymean);
        fprintf(f, '[curvefit] min(minPkHt, mean(YDATA)) = min(minPkHt, %g) = %g\n', ...
            ymean, minPkHt);
    else
        fprintf(f, '[curvefit] mean(YDATA,omitnan) = NaN.\n');
    end
    [~, loc, wd, ~] = findpeaks(YDATA, "NPeaks", 1, ...
        "SortStr", "descend", "MinPeakHeight", minPkHt); % TODO: More constraints?
    if(~isempty(loc) && ~isempty(wd) || ~isempty(fallbackPeakMask))
        if(preferFallbackMask || ... % TODO: Rework logic to avoid unnecessary fitting when fallback preferred
                (((isempty(loc) || isempty(wd)) && any(fallbackPeakMask))))
            % YDATA_peak = YDATA(fallbackPeakMask);
            pkLeftIdx = find(fallbackPeakMask, 1, "first");
            pkRightIdx = find(fallbackPeakMask, 1, "last");
            fprintf(f, '[curvefit] Based on FallbackPeakMask, pkLeftIdx=%g, pkRightIdx=%g\n', ...
                pkLeftIdx, pkRightIdx);
        else
            pkwd = ceil(0.5*wd);
            pkLeftIdx = loc - pkwd;
            pkRightIdx = loc + pkwd;
            fprintf(f, '[curvefit] loc=%g, pkwd=%g, pkLeftIdx=%g, pkRightIdx=%g\n', ...
                loc, pkwd, pkLeftIdx, pkRightIdx);
        end

        YDATA_peak = YDATA(:,pkLeftIdx:pkRightIdx);
        fprintf(f, '[curvefit] YDATA_peak: %s', ...
            formattedDisplayText(YDATA_peak));
        if(smoothingLevel > 3) % 4 or 5
            YDATA_peak = smoothdata(YDATA_peak, peakSmoothingMethod, ...
                ceil(baseWindow / 8));
        end
        if pkLeftIdx <= 1
            YDATA_left = [];
        else
            YDATA_left = YDATA(:,1:pkLeftIdx-1);
            % fprintf('tailSmoothWindow1: %s', formattedDisplayText(tailSmoothWindow1));
            try
                YDATA_left = filloutliers(YDATA_left, ...
                    outlierFillMethod, outlierFindMethod, ...
                    tailSmoothWindow1, ...
                    'ThresholdFactor', tailOutlierThreshold);
            catch ME
                throw(MException(ME.identifier, ...
                    '(%s) %s', formattedDisplayText(tailSmoothWindow1), ME.message));
            end
            if(smoothingLevel > 1)
                YDATA_left = smoothdata(YDATA_left, ...
                    tailSmoothingMethod, tailSmoothWindow2);
            end
        end
        if pkRightIdx >= numel(YDATA)
            YDATA_right = [];
        else
            YDATA_right = YDATA(:, pkRightIdx+1:end);
            % fprintf('flip(tailSmoothWindow1): %s', formattedDisplayText(flip(tailSmoothWindow1, 2)));
            try
                YDATA_right = filloutliers(YDATA_right, ...
                    outlierFillMethod, outlierFindMethod, ...
                    flip(tailSmoothWindow1, 2), ...
                    'ThresholdFactor', tailOutlierThreshold);
            catch ME
                throw(MException(ME.identifier, ...
                    '(%s) %s', formattedDisplayText(tailSmoothWindow1), ME.message));
            end
            if(smoothingLevel > 1)
                YDATA_right = smoothdata(YDATA_right, ...
                    tailSmoothingMethod, ...
                    flip(tailSmoothWindow2, 2));
            end
        end
        fprintf(f, '[curvefit] YDATA_left: %sYDATA_right: %s', ...
            formattedDisplayText(YDATA_left), ...
            formattedDisplayText(YDATA_right));
        YDATA1 = horzcat(YDATA_left, YDATA_peak, YDATA_right);

        if(length(YDATA1)>1)
            fprintf(f, '[curvefit] size(YDATA1) = [%d %d] --> YDATA=YDATA1\n', ...
                size(YDATA1,1), size(YDATA1,2));
            YDATA = YDATA1;
            % YDATA0 = YDATA1;
        else % TODO: Else... use fallback mask?
            fprintf(f, '[curvefit] (EMPTY) size(YDATA1) = [%d %d] --> YDATA still equals YDATA0.\n', ...
                size(YDATA1,1), size(YDATA1,2));
        end
    end
    % YDATA = YDATA0;
end  % end of if ~isempty(wd)

% TODO: movmad
% resample (requires integer resamp factors)
% upfirdn (integer up/down only)

% movmad([zeros(1, 2) movmean([0 diff([1 2 8 4 9 6 7 8 9 10], 1, 2)], [2 2], "Endpoints", "discard") zeros(1, 2)], 2)
% movvar([zeros(1, 2) movmean([0 diff([1 2 8 4 9 6 7 8 9 10], 1, 2)], [2 2], "Endpoints", "discard") zeros(1, 2)], 2)
% movstd([zeros(1, 2) movmean([0 diff([1 2 8 4 9 6 7 8 9 10], 1, 2)], [2 2], "Endpoints", "discard") zeros(1, 2)], 2)

if(bitget(smoothingLevel,3) ...%bitand(smoothingLevel,4) ...  % 4, 5, 6, 7
        && (numFitPoints < numSampPoints))
    fprintf(f, '[curvefit] bitget(SL,3) && (#fitpoints < numSampPoints) --> datasample\n');
    % YDATA0 = YDATA; XDATA0 = XDATA;
    ds = [0 diff(YDATA)];
    wwin = 64;
    ws = movmad(ds, wwin, "Endpoints", "shrink");
    %ws(1:wwin) = 0;
    %ws(end-wwin:end) = 0;
    ws = movmean(ws, [1 1], "Endpoints", "fill");
    ws(isnan(ws)) = 0;
    ws = normalize( -1*ws, 'range'); % or 1 - norm?

    [YDATA, idxs] = datasample(YDATA, numFitPoints, ...
        'Replace', true, 'Weights', ws);
    XDATA = XDATA(idxs);
    fprintf(f, '[curvefit] (post-datasample) Size of xdata,ydata: [%d %d],[%d %d]\n', ...
        size(XDATA,1), size(XDATA,2), size(YDATA,1), size(YDATA,2));
elseif(numFitPoints ~= numSampPoints) %~= numSampPoints)
    fprintf(f, '[curvefit] #fitpoints ~= numSampPoints --> interp1\n');
    XDATA0 = XDATA;
    YDATA0 = YDATA;
    ws = double.empty();
    try
        st = min(XDATA0); en = max(XDATA0);
        xstp = (double(en)-double(st)) / (double(numFitPoints)-1);
        XDATA = double(st):xstp:double(en);
        % interp1([x,] v, xq, [method, [extrapolation]])
        fprintf(f, '[curvefit] (pre-interp1) # ydata NaN / # ydata = %d/%d\n', ...
            sum(isnan(YDATA)), numel(YDATA));
        YDATA = interp1(XDATA0, YDATA, XDATA, 'makima', NaN); %'extrap');
        fprintf(f, '[curvefit] (post-interp1) Size of xdata,ydata: [%d %d],[%d %d]\n', ...
            size(XDATA,1), size(XDATA,2), size(YDATA,1), size(YDATA,2));
        fprintf(f, '[curvefit] (post-interp1) # ydata NaN / # ydata = %d/%d\n', ...
            sum(isnan(YDATA)), numel(YDATA));
        % disp(size(YDATA0));
        % disp(size(YDATA));
    catch ME
        throw(MException(ME.identifier, ...
            'Interpolation error: (XDATA0 size: %s, YDATA0 size: %s, XDATA size: %s) %s', ...
            formattedDisplayText(size(XDATA0)), ...
            formattedDisplayText(size(XDATA)), ...
            formattedDisplayText(size(YDATA0)), ...
            ME.message));
        %    fprintf(2, 'Interpolation aborted due to error: %s', ME.message);
        %    fprintf(2, 'Stack: %s', formattedDisplayText(ME.stack));
        %    XDATA = XDATA0;
        %    YDATA = YDATA0;
    end

    %             elseif(numFitPoints < numSampPoints)
    %                 numExcess = numSampPoints - numFitPoints;
    %                 resampFactor = numFitPoints / numSampPoints;
    %
    %                 XDATA0 = XDATA;
    %                 xstp = (max(XDATA0)-min(XDATA0)) / (numFitPoints-1);
    %                 XDATA = (min(XDATA0)):xstp:(max(XDATA0));
    %
    %                 % decimate, downsample
    %
    %                 % filter, filtfilt, fftfilt
    %
    %                 % decimate(x,r,[n,'fir'])
    %
    %             elseif(numFitPoints > numSampPoints)
    %                 % upsample, interp1, interp (intfilt)
    %                 % griddedInterpolant
    %                 resampFactor = numFitPoints / numSampPoints;
    %                 numAddtl = numFitPoints - numSampPoints;
    %
    %                 XDATA0 = XDATA;
    %                 xstp = (max(XDATA0)-min(XDATA0)) / (numFitPoints-1);
    %                 XDATA = (min(XDATA0)):xstp:(max(XDATA0));
    %
    %                 % interp(x, r, [n, cutoff])
    %                 % YDATA = interp(x, resampFactor, 4);
    %
    %                 % interp1([x,] v, xq, [method, extrapolation])
    %                 % YDATA = interp1(XDATA0, YDATA, XDATA1, 'makima', NaN); %'extrap');
    %
    %                 % upsample(x,n,[offset])
    %                 % YDATA = upsample(YDATA, numAddtl+1);
    %             else
    %                 %XDATA0 = XDATA;
    %                 %xstp = (max(XDATA0)-min(XDATA0)) / (numFitPoints-1);
    %                 %XDATA = (min(XDATA0)):xstp:(max(XDATA0));
    %
    %                 % upfirdn(xin,h,[,p,q])
    %
    %                 % [y, b]     = resample(x,p,q[,n[,beta]])
    %                 % [y, ty, b] = resample(x,tx[,fs[,p,q[,method]]])
    %                 % [YDATA, XDATA] = resample(YDATA, XDATA, ... ) % TODO
end

if(islogical(doSecondPass))
    doPass2 = doSecondPass;%true;
else
    doPass2 = (doSecondPass >= 2);
end

try
    fprintf(f, '[curvefit] doPass2: %d; class(XDATA),class(YDATA)): %s, %s\n', ...
        doPass2, class(XDATA), class(YDATA));
    %disp(class(XDATA)); disp(class(YDATA));
    if hasPrediction
        predCurve = sbsense.lorentz(p001', XDATA);
        if length(YDATA) >= 128 %512
            [uenv, lenv] = envelope(YDATA, fix(length(YDATA)/64), 'peak');
            profCurve = 0.5 * (uenv+lenv);
        else
            profCurve = YDATA;
        end
        maxY = max(profCurve, [], 'all', 'omitnan');
        predDeriv = [0 diff(predCurve)];
        profDifs = (profCurve - predCurve);
        profDeriv = [0 diff(profCurve)];
        derivDifs = (profDeriv - predDeriv);
        wgts1 = normalize(1 - max(1,abs(maxY\profDifs), 'omitnan'), 'range');
        wgts2 = normalize(1 - max(1,abs(maxY\derivDifs), 'omitnan'), 'range');
        wgts = 0.05 .* wgts1 + 0.55 .* wgts2;
        fprintf(f, 'minY: %g, maxY: %g, min curve y: %g, max curve y: %g\n', ...
            min(profCurve, [], 'all', 'omitnan'), max(profCurve, [], 'all', 'omitnan'), ...
            min(predCurve, [], 'all'), max(predCurve, [], 'all'));
        fprintf(f, 'min Y diff: %g, max Y diff: %g, min wgts1: %g, max wgts1: %g\n', ...
            min(profDifs, [], 'all'), max(profDifs, [], 'all'), ...
            min(wgts1, [], 'all'), max(wgts1, [], 'all'));
        fprintf(f, 'min Y delta: %g, max Y delta: %g, min curve y delta: %g, max curve y delta: %g\n', ...
            min(profDeriv, [], 'all', 'omitnan'), max(profDeriv, [], 'all', 'omitnan'), ...
            min(predDeriv, [], 'all'), max(predDeriv, [], 'all'));
        fprintf(f, 'min Y delta diff: %g, max Y delta diff: %g, min wgts2: %g, max wgts2: %g\n', ...
            min(derivDifs, [], 'all'), max(derivDifs, [], 'all'), ...
            min(wgts2, [], 'all'), max(wgts2, [], 'all'));
        fprintf(f, 'min wgts: 0.35 + %g, max wgts: 0.32 + %g\n', ...
            min(wgts, [], 'all'), max(wgts, [], 'all'));
        wgts = wgts + 0.4;
        wps2 = vertcat(predCurve,profCurve,predDeriv,profDifs,profDeriv,derivDifs,wgts1,wgts2,wgts);
        try
            [p1, resids] = nlinfit(XDATA, YDATA, @sbsense.lorentz, ...
                double(p001), 'Weights', wgts);
            if isempty(p1) || any(isnan(p1), 'all') ...
                    || any(~isfinite(p1), 'all') ...
                    || any(p1 < fitParamLowerBounds, 'all') ...
                    || any(p1 > fitParamLowerBounds, 'all')
                hasPrediction = false;
                resnorm = NaN; % TODO: ??
            else
                if isempty(resids)
                    fprintf(f, 'Somehow wres is empty even though p1 is not!\n');
                    fprintf(f, 'Size of wgts: [%d %d]\n', size(wgts,1), size(wgts,2));
                    fprintf(f, 'Size of XDATA: [%d %d]\n', size(XDATA,1), size(XDATA,2));
                    fprintf(f, 'Size of YDATA: [%d %d]\n', size(YDATA,1), size(YDATA,2));
                end                  

                % Squared norm of the residual, returned as a nonnegative real. 
                % resnorm is the squared 2-norm of the residual at x: sum((fun(x,xdata)-ydata).^2).
                resnorm = sum(resids.^2, 'all'); % Note that nlinfit residuals are ydata - fun(x,xdata).
                if isempty(resnorm)
                    fprintf(f, 'Somehow resnorm is empty even though wres and p1 are not!\n');
                    fprintf(f, 'Size of wgts: [%d %d]\n', size(wgts,1), size(wgts,2));
                    fprintf(f, 'Size of wres: [%d %d]\n', size(wres,1), size(wres,2));
                    fprintf(f, 'Size of XDATA: [%d %d]\n', size(XDATA,1), size(XDATA,2));
                    fprintf(f, 'Size of YDATA: [%d %d]\n', size(YDATA,1), size(YDATA,2));
                end    
            end
        catch NLINERR
            fprintf(f,'[lzcurvefit] Error occurred while using nlinfit: %s\n', ...
                getReport(NLINERR));
            hasPrediction = false;
            % display(p1);
        end
    else
        wps2 = double.empty(9,0);
    end
    if ~hasPrediction
        [p1, resnorm,resids] = lsqcurvefit(...
            @sbsense.lorentz, p0, XDATA, YDATA, ...
            fitParamLowerBounds, ...
            fitParamUpperBounds, ...
            sbsense.LorentzFitter.OptsFast);
%     elseif nargout>1
%         % nlinfit: beta, R (residuals), J (jacobian), CovB, MSE, ErrorModelInfo
%         % lsqcurvefit: x, resnorm, residual, exitflag, output, lambda, jacobian
    end
    p0 = p1;
    % TODO: Exit flag handling

    if isempty(resnorm) && ~isempty(p1)
        resnorm = sum((sbsense.lorentz(p1, XDATA) - YDATA).^2, 'all');
        fprintf(f, 'Somehow resnorm was empty even though p1 was not. Now resnorm (recalculated) is: %s\n', ...
        strip(formattedDisplayText(resnorm)));
        fprintf(f, 'Size of XDATA: [%d %d]\n', size(XDATA,1), size(XDATA,2));
        fprintf(f, 'Size of YDATA: [%d %d]\n', size(YDATA,1), size(YDATA,2));
    end    
catch ERR % TODO: Handle specific error
    fprintf(f, 'Error occurred during Lorentzian curvefit (first pass, class of args: %s,%s,%s,%s): [%s] %s\n', class(p001), class(p0), class(XDATA), class(YDATA), ERR.identifier, ERR.message);
    % display(XDATA);
    if(~doSecondPass || (isnumeric(doSecondPass) && (doSecondPass <= 1)))
        resids = [];
        if(nargout)
            % varargout{:} = {};
            resnorm = NaN;% {};
            if(smoothingLevel > 2)
                % % p0 = Crude preliminary estimate for findpeaks
                % % varargout{1} = p0;
                % p1 = p01;
                % resnorm = resnorm01;
                p1 = p0;
            else
                p1 = []; % {};
            end
        end
        return;
    end
    fprintf(f, '[curvefit] Error occurred during first pass, so setting doPass2=true.\n');
    doPass2 = true;
end

if (~doPass2)
    fprintf(f, '[curvefit] doPass2 is false, so returning without doing second pass.\n');
    resids = [];
    return;
end
try
    [p1, resnorm] = lsqcurvefit(...
        @sbsense.lorentz, p0, XDATA, YDATA, ...
        fitParamLowerBounds, ...
        fitParamUpperBounds, ...
        sbsense.LorentzFitter.OptsSlow);
    % TODO: Exit flag handling
catch ERR % TODO: Handle specific error
    fprintf(f, 'Error occurred during Lorentzian curvefit (second pass): %s\n', ERR.message);
    if(nargout)
        % p1 = {}; resnorm = {};
        p1 = []; resnorm = NaN;
        %varargout{:} = {};
    end
end



% if ~isempty(resnorm) && ~isempty(p1)
if ~isempty(p1)
    if isempty(resnorm)
        resnorm = sum((sbsense.lorentz(p1, XDATA) - YDATA).^2, 'all');
        fprintf(f, 'Somehow resnorm was empty even though p1 was not. Now resnorm (recalculated) is: %s\n', ...
        strip(formattedDisplayText(resnorm)));
    end
    hgt = p1(3)/p1(2);
    if (resnorm > 0.5) || (hgt < 1e-4) ...
        || ((resnorm >= 0.4) && (hgt < 0.01))
        %p1 = {};
        %resnorm = {};
        p1 = [];
        resnorm = NaN;
    end
elseif isempty(resnorm) && ~isempty(p1)
    fprintf(f, 'Somehow resnorm is empty even though p1 is not! p1: %s\n', strip(formattedDisplayText(p1)));
    fprintf(f, 'Size of XDATA: [%d %d]\n', size(XDATA,1), size(XDATA,2));
    fprintf(f, 'Size of YDATA: [%d %d]\n', size(YDATA,1), size(YDATA,2));
elseif isempty(p1)
    fprintf(f, 'p1 is empty. resnorm is empty (before assigning NaN): %d\n', isempty(resnorm));
    resnorm = [];
end
    
end