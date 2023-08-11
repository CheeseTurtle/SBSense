classdef LorentzFitter < matlab.mixin.SetGetExactNames
    properties(Constant)%, Hidden, Access=protected) % SetAccess=immutable)
        nvars     = 3;
        %Opts0Base = sbsense.LorentzFitter.makeBaseOpts();
        %Opts0Fast = sbsense.LorentzFitter.makeFastOpts(LorentzFitter.nvars, LorentzFitter.Opts0Base);
        %Opts0Slow = sbsense.LorentzFitter.makeSlowOpts(LorentzFitter.nvars, LorentzFitter.Opts0Base); 
        
    end

    properties(Access=public,Constant)
        OptsBase = sbsense.LorentzFitter.makeBaseOpts();%LorentzFitter.Opts0Base;
        OptsFast = sbsense.LorentzFitter.makeFastOpts(sbsense.LorentzFitter.nvars, sbsense.LorentzFitter.OptsBase);%LorentzFitter.Opts0Fast;
        OptsSlow = sbsense.LorentzFitter.makeSlowOpts(sbsense.LorentzFitter.nvars, sbsense.LorentzFitter.OptsBase); %LorentzFitter.Opts0Slow;
    end

    properties(SetAccess=public) % TODO: Make BaseWindowFactor and BaseWindowFactorScale DEPENDENT properties
        NumSamplePoints = 1280; % 3264; %{mustBeInteger, mustBePositive, mustBeFinite, mustBeReal} = 3264;
        NumFitPoints  {mustBeInteger, mustBePositive, mustBeFinite, mustBeReal} = 1280; % 3264;
        DoSecondPass {mustBeNumericOrLogical} = 0;
        DefaultParamGuess (1,3) {mustBeNumeric, mustBeReal} = [1 0 0];
        OutlierFillMethod {mustBeMember(OutlierFillMethod, {'center','clip','previous','next','nearest','linear','spline','pchip','makima'})} = 'pchip';
        OutlierFindMethod {mustBeMember(OutlierFindMethod, {'median','mean','quartiles','grubbs','movmean','movmedian'})} = 'movmedian';
        BaseOutlierThreshold {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite} = 1;
        BasicSmoothingMethod  {mustBeMember(BasicSmoothingMethod, {'movmean','movmedian','gaussian','loess','lowess','rloess','rlowess','sgolay'})} = 'sgolay';
        PeakSmoothingMethod  {mustBeMember(PeakSmoothingMethod, {'movmean','movmedian','gaussian','loess','lowess','rloess','rlowess','sgolay'})} = 'rlowess';
        %PeakSmoothingMethod1  {mustBeMember(PeakSmoothingMethod1, {'movmean','movmedian','gaussian','loess','lowess','rloess','rlowess','sgolay'})} = 'rlowess';
        %PeakSmoothingMethod2  {mustBeMember(PeakSmoothingMethod2, {'movmean','movmedian','gaussian','loess','lowess','rloess','rlowess','sgolay'})} = 'rlowess';
        BaseWindowFactorNum {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite,mustBeInteger} = 32;
        BaseWindowFactorScale {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite,mustBeInteger} = 500;
        PeakThresholdHeightMultiplier {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite} = 0.6;
        PeakThresholdMaxMultiplier {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite} = 0.75;
        SmoothingLevel {mustBeInteger,mustBeInRange(SmoothingLevel,-1,7)} = 1;
        TailOutlierThreshold {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite} = 1;
        TailSmoothWindowFactors1 (1, 2) {mustBeNumeric, mustBePositive, mustBeReal, mustBeFinite} = [0.125 1.675];
        TailSmoothWindowFactors2 (1, 2) {mustBeNumeric, mustBePositive, mustBeReal, mustBeFinite} = [0.5   1.5  ];
        % TailSmoothMedianThresholdFactor {mustBeNumeric,mustBePositive,mustBeReal,mustBeFinite} = 1.25;
        TailSmoothingMethod  {mustBeMember(TailSmoothingMethod, {'movmean','movmedian','gaussian','loess','lowess','rloess','rlowess','sgolay'})} = 'rlowess';
        OptimOptionsBase {mustBeA(OptimOptionsBase, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsBase;%Opts0Base;
        OptimOptionsFast {mustBeA(OptimOptionsFast, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsFast;%Opts0Fast;
        OptimOptionsSlow {mustBeA(OptimOptionsSlow, 'optim.options.Lsqcurvefit')} = sbsense.LorentzFitter.OptsSlow;%Opts0Slow;
        FitParamBounds (3, 2) {mustBeNumeric,mustBeReal} = [ 0 1280 ; eps Inf; eps Inf ];
    end

    properties(SetAccess=protected, SetObservable, GetAccess=public)
        % TailSmoothingFactor;
        TailSmoothWindow1;
        TailSmoothWindow2;
        BaseWindow;
        BaseWindowFactor;
        FitParamLowerBounds;
        FitParamUpperBounds;
    end

    methods
        function self = LorentzFitter(opts)
            arguments(Input)
                opts.?sbsense.LorentzFitter;
            end
            % disp(opts);
            
            %self.NumSamplePoints = opts.NumSamplePoints;
            %self.DefaultParamGuess = opts.DefaultParamGuess;
            %self.SmoothMethod = opts.SmoothMethod;
            propCell = reshape(namedargs2cell(opts), 2, []);
            %disp(propCell);
            if(~isempty(propCell))
                propNames = propCell{1,:};
                propVals  = propCell{2,:};
                % propStruct = cell2struct(propCell);
                % propCell = reshape(propCell, [], 2);
                [~] = set(self, propNames, propVals); % TODO: Unnecessary?
            end
            % fprintf('ok\n');
            %disp(self.BaseWindowFactorNum);
            %disp(size(self.BaseWindowFactorNum));
            %disp(self.BaseWindowFactorScale);
            %disp(size(self.BaseWindowFactorScale));
            %disp(self.NumSamplePoints);
            %disp(size(self.NumSamplePoints));
            self.BaseWindowFactor = ...
                self.BaseWindowFactorNum ...
                * self.BaseWindowFactorScale / self.NumSamplePoints;
            % fprintf('1\n');
            self.BaseWindow = max(1, floor(self.BaseWindowFactor));
            % fprintf('2\n');
            self.TailSmoothWindow1 = ceil(self.BaseWindowFactor * ...
                self.TailSmoothWindowFactors1);
            % fprintf('3\n');
            self.TailSmoothWindow2 = ceil(self.BaseWindowFactor * ...
                self.TailSmoothWindowFactors2);
            % fprintf('4\n');
            self.FitParamLowerBounds = (self.FitParamBounds(:,1))';
            % fprintf('5\n');
            self.FitParamUpperBounds = (self.FitParamBounds(:,2))';
            % fprintf('ok\n');
        end

        % [xCurrent,Resnorm,FVAL,EXITFLAG,OUTPUT,LAMBDA,JACOB]
        function varargout = curvefit(self,p0,XDATA,YDATA,opts)
            arguments(Input)
                self sbsense.LorentzFitter;
                p0 (1,3) {mustBeNumeric};
                XDATA {mustBeVector,mustBeNumeric};
                YDATA {mustBeVector,mustBeNumeric,sbsense.LorentzFitter.mustBeEqualSize(YDATA,XDATA)};
                opts.PeakSearchBounds double = [];
                opts.NumFitPoints  {mustBeInteger, mustBePositive, mustBeFinite, mustBeReal} = self.NumFitPoints;
                opts.DoSecondPass {mustBeNumericOrLogical} = self.DoSecondPass;
                opts.SmoothingLevel {mustBeInteger,mustBeInRange(opts.SmoothingLevel,-1,7)} = self.SmoothingLevel;
                opts.FallbackPeakMask {mustBeNumericOrLogical} = [];
                opts.PreferFallbackMask (1,1) logical = false;
                opts.LogFile = 1;
            end
                
            fitParamLowerBounds = self.FitParamLowerBounds;
            fitParamUpperBounds = self.FitParamUpperBounds;

            fprintf(opts.LogFile, '[curvefit] fitParamBounds: [%g %g %g ; %g %g %g]\n', ...
                fitParamLowerBounds(1), fitParamLowerBounds(2), fitParamLowerBounds(3), ...
                fitParamUpperBounds(1), fitParamUpperBounds(2), fitParamUpperBounds(3));

            if(isempty(p0))
                p0 = self.DefaultParamGuess;
                if ~isempty(opts.PeakSearchBounds)
                    p0(1) = 0.5*sum(opts.PeakSearchBounds);
                    fitParamLowerBounds(1) = opts.PeakSearchBounds(1);
                    fitParamUpperBounds(1) = opts.PeakSearchBounds(2);
                end
            elseif ~isempty(opts.PeakSearchBounds)
                fitParamLowerBounds(1) = opts.PeakSearchBounds(1);
                fitParamUpperBounds(1) = opts.PeakSearchBounds(2);
            end
            fprintf(opts.LogFile, '[curvefit] PSB: [%g %g] --> fitParamBounds: [%g %g %g ; %g %g %g]\n', ...
                opts.PeakSearchBounds(1), opts.PeakSearchBounds(2), ...
                fitParamLowerBounds(1), fitParamLowerBounds(2), fitParamLowerBounds(3), ...
                fitParamUpperBounds(1), fitParamUpperBounds(2), fitParamUpperBounds(3));
            numSampPoints = length(XDATA);
            fprintf(opts.LogFile, '[curvefit] NumSampPoints: %d; class of XDATA: %s, size of XDATA: [%d %d]\n', ...
                numSampPoints, class(XDATA), size(XDATA,1), size(XDATA,2));
            %narginchk(3,Inf);
            %nargoutchk(1, 7);

            %if(nargin <= 3)
            %    p0 = self.DefaultParamGuess;
            %    [XDATA, YDATA] = varargin{:};
            %else
            %    p0 = varargin{1};
            %    if (isempty(p0))
            %        p0 = self.DefaultParamGuess;
            %    end
            %    XDATA = varargin{2};
            %    YDATA = varargin{3};
            %end
            
            % YDATA0 = YDATA;

            % fprintf('self.BaseWindow: %s', formattedDisplayText(self.BaseWindow));
            if(opts.SmoothingLevel > -1)
                try
                 fprintf(opts.LogFile, '[curvefit] opts.SmoothingLevel > -1 --> filling outliers\n');
                    YDATA = filloutliers(YDATA, self.OutlierFillMethod, ...
                        self.OutlierFindMethod, self.BaseWindow, ...
                        'ThresholdFactor', self.BaseOutlierThreshold);
                catch ME
                    throw(MException(ME.identifier, ...
                        '(%s) %s', formattedDisplayText(self.BaseWindow), ME.message));
                end
            end

            if(opts.SmoothingLevel > 0)
                fprintf(opts.LogFile, '[curvefit] opts.SmoothingLevel > 0 --> smoothing data\n');
                YDATA = smoothdata(YDATA, self.BasicSmoothingMethod, ...
                    self.BaseWindow);
            end
            if(opts.SmoothingLevel > 2) % 3, 4, or 5
                fprintf(opts.LogFile, '[curvefit] opts.SmoothingLevel > 2 --> lsqcurvefit for preliminary estimate\n');
                [p01, resnorm, ~, exitflag] = lsqcurvefit(@sbsense.lorentz, ...
                    p0, ...
                    XDATA, YDATA, ...
                    fitParamLowerBounds, ...
                    fitParamUpperBounds, ...
                    self.OptsBase);
                if ~isempty(p01)
                    fprintf(opts.LogFile, '[curvefit] resnorm: %g, exitflag: %g, p01: [%g %g %g]\n', ...
                        resnorm, exitflag, p01(1), p01(2), p01(3));
                else
                    fprintf(opts.LogFile, '[curvefit] resnorm: %g, exitflag: %g, p01: []\n', ...
                        resnorm, exitflag);
                end
                if(exitflag < 1)
                    if(resnorm < 0.1)
                        fprintf(opts.LogFile, '[curvefit] exitflag<1 && resnorm<0.1 --> p0 = p01\n');
                        p0 = p01;
                    end
                end
                minPkHt = min(...
                    self.PeakThresholdHeightMultiplier * (p0(3))/(p0(1)), ...
                    self.PeakThresholdMaxMultiplier * max(YDATA, [], "all"));
                fprintf(opts.LogFile, '[curvefit] minPkHt (preliminary): %g\n', minPkHt);
                ymean = mean(YDATA, "all", 'omitnan');
                if ~isnan(ymean) && ~isempty(ymean)
                    minPkHt = min(minPkHt, ymean);
                    fprintf(opts.LogFile, '[curvefit] min(minPkHt, mean(YDATA)) = min(minPkHt, %g) = %g\n', ...
                        ymean, minPkHt);
                else
                    fprintf(opts.LogFile, '[curvefit] mean(YDATA,omitnan) = NaN.\n');
                end
                [~, loc, wd, ~] = findpeaks(YDATA, "NPeaks", 1, ...
                    "SortStr", "descend", "MinPeakHeight", minPkHt); % TODO: More constraints?
                if(~isempty(loc) && ~isempty(wd) || ~isempty(opts.FallbackPeakMask))
                    if(opts.PreferFallbackMask || ... % TODO: Rework logic to avoid unnecessary fitting when fallback preferred
                            (((isempty(loc) || isempty(wd)) && any(opts.FallbackPeakMask))))
                        % YDATA_peak = YDATA(opts.FallbackPeakMask);
                        pkLeftIdx = find(opts.FallbackPeakMask, 1, "first");
                        pkRightIdx = find(opts.FallbackPeakMask, 1, "last");
                        fprintf(opts.LogFile, '[curvefit] Based on FallbackPeakMask, pkLeftIdx=%g, pkRightIdx=%g\n', ...
                            pkLeftIdx, pkRightIdx);
                    else
                        pkwd = ceil(0.5*wd);
                        pkLeftIdx = loc - pkwd;
                        pkRightIdx = loc + pkwd;
                        fprintf(opts.LogFile, '[curvefit] loc=%g, pkwd=%g, pkLeftIdx=%g, pkRightIdx=%g\n', ...
                            loc, pkwd, pkLeftIdx, pkRightIdx);
                    end

                    YDATA_peak = YDATA(:,pkLeftIdx:pkRightIdx);
                    fprintf(opts.LogFile, '[curvefit] YDATA_peak: %s', ...
                        formattedDisplayText(YDATA_peak));
                    if(opts.SmoothingLevel > 3) % 4 or 5
                        YDATA_peak = smoothdata(YDATA_peak, self.PeakSmoothingMethod, ...
                            ceil(self.BaseWindow / 8));
                    end
                    if pkLeftIdx <= 1
                        YDATA_left = [];
                    else
                        YDATA_left = YDATA(:,1:pkLeftIdx-1);
                        % fprintf('self.TailSmoothWindow1: %s', formattedDisplayText(self.TailSmoothWindow1));
                        try
                            YDATA_left = filloutliers(YDATA_left, ...
                                self.OutlierFillMethod, self.OutlierFindMethod, ...
                                self.TailSmoothWindow1, ...
                                'ThresholdFactor', self.TailOutlierThreshold);
                        catch ME
                            throw(MException(ME.identifier, ...
                                '(%s) %s', formattedDisplayText(self.TailSmoothWindow1), ME.message));
                        end
                        if(opts.SmoothingLevel > 1)
                            YDATA_left = smoothdata(YDATA_left, ...
                                self.TailSmoothingMethod, self.TailSmoothWindow2);
                        end
                    end
                    if pkRightIdx >= numel(YDATA)
                        YDATA_right = [];
                    else
                        YDATA_right = YDATA(:, pkRightIdx+1:end);
                        % fprintf('flip(self.TailSmoothWindow1): %s', formattedDisplayText(flip(self.TailSmoothWindow1, 2)));
                        try
                            YDATA_right = filloutliers(YDATA_right, ...
                                self.OutlierFillMethod, self.OutlierFindMethod, ...
                                flip(self.TailSmoothWindow1, 2), ...
                                'ThresholdFactor', self.TailOutlierThreshold);
                        catch ME
                            throw(MException(ME.identifier, ...
                                '(%s) %s', formattedDisplayText(self.TailSmoothWindow1), ME.message));
                        end
                        if(opts.SmoothingLevel > 1)
                            YDATA_right = smoothdata(YDATA_right, ...
                                self.TailSmoothingMethod, ...
                                flip(self.TailSmoothWindow2, 2));
                        end
                    end
                    fprintf(opts.LogFile, '[curvefit] YDATA_left: %sYDATA_right: %s', ...
                        formattedDisplayText(YDATA_left), ...
                        formattedDisplayText(YDATA_right));
                    YDATA1 = horzcat(YDATA_left, YDATA_peak, YDATA_right);

                    if(length(YDATA1)>1)
                        fprintf(opts.LogFile, '[curvefit] size(YDATA1) = [%d %d] --> YDATA=YDATA1\n', ...
                            size(YDATA1,1), size(YDATA1,2));
                        YDATA = YDATA1;
                        % YDATA0 = YDATA1;
                    else % TODO: Else... use fallback mask?
                        fprintf(opts.LogFile, '[curvefit] (EMPTY) size(YDATA1) = [%d %d] --> YDATA still equals YDATA0.\n', ...
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

            if(bitget(opts.SmoothingLevel,3) ...%bitand(opts.SmoothingLevel,4) ...  % 4, 5, 6, 7
                    && (opts.NumFitPoints < numSampPoints))
                fprintf(opts.LogFile, '[curvefit] bitget(SL,3) && (#fitpoints < numSampPoints) --> datasample\n');
                % YDATA0 = YDATA; XDATA0 = XDATA;
                ds = [0 diff(YDATA)];
                wwin = 64;
                ws = movmad(ds, wwin, "Endpoints", "shrink");
                %ws(1:wwin) = 0;
                %ws(end-wwin:end) = 0;
                ws = movmean(ws, [1 1], "Endpoints", "fill");
                ws(isnan(ws)) = 0;
                ws = normalize( -1*ws, 'range');
                
                [YDATA, idxs] = datasample(YDATA, opts.NumFitPoints, ...
                    'Replace', true, 'Weights', ws);
                XDATA = XDATA(idxs);
                fprintf(opts.LogFile, '[curvefit] (post-datasample) Size of xdata,ydata: [%d %d],[%d %d]\n', ...
                    size(XDATA,1), size(XDATA,2), size(YDATA,1), size(YDATA,2));
                %disp(size(YDATA0));
                %disp(size(YDATA));
                
%                 % YDATA0 = YDATA;
%                 XDATA0 = XDATA;
%                 [YDATA, XDATA] = ksdensity(YDATA, XDATA, ...
%                     'NumPoints', opts.NumFitPoints, 'Function', 'pdf');
%                 % TODO: XDATA0 -> XDATA
%                 % XDATA = rescale(XDATA0, YDATA0(1), YDATA0(end));
%                 mnxd0 = mean(XDATA0);
%                 mnxd1 = mean(XDATA);
%                 pcxd0 = prctile(XDATA0, [25 75]).';
%                 pcxd1 = prctile(XDATA, [25 75]).';
%                 scxd0 = mean(abs(pcxd0 - mnxd0));
%                 scxd1 = mean(abs(pcxd1 - mnxd1));
%                 scxd  = scxd0 / scxd1;
%                 % XDATA = rescale(XDATA, min(XDATA0),  max(XDATA0));
%                 % XDATA = rescale(XDATA, scxd*min(XDATA), scxd*max(XDATA));
%                 % XDATA = XDATA0;
            elseif(opts.NumFitPoints ~= numSampPoints) %~= self.NumSamplePoints)
                fprintf(opts.LogFile, '[curvefit] #fitpoints ~= numSampPoints --> interp1\n');
                XDATA0 = XDATA;
                YDATA0 = YDATA;
                try 
                    st = min(XDATA0); en = max(XDATA0);
                    xstp = (en-st) / (opts.NumFitPoints-1);
                    XDATA = st:xstp:en;
                    % interp1([x,] v, xq, [method, [extrapolation]])
                    fprintf(opts.LogFile, '[curvefit] (pre-interp1) # ydata NaN / # ydata = %d/%d\n', ...
                        sum(isnan(YDATA)), numel(YDATA));
                    YDATA = interp1(XDATA0, YDATA, XDATA, 'makima', NaN); %'extrap');
                    fprintf(opts.LogFile, '[curvefit] (post-interp1) Size of xdata,ydata: [%d %d],[%d %d]\n', ...
                        size(XDATA,1), size(XDATA,2), size(YDATA,1), size(YDATA,2));
                    fprintf(opts.LogFile, '[curvefit] (post-interp1) # ydata NaN / # ydata = %d/%d\n', ...
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

%             elseif(self.NumFitPoints < self.NumSamplePoints)
%                 numExcess = self.NumSamplePoints - self.NumFitPoints;
%                 resampFactor = self.NumFitPoints / self.NumSamplePoints;
% 
%                 XDATA0 = XDATA;
%                 xstp = (max(XDATA0)-min(XDATA0)) / (self.NumFitPoints-1);
%                 XDATA = (min(XDATA0)):xstp:(max(XDATA0));
% 
%                 % decimate, downsample
%                 
%                 % filter, filtfilt, fftfilt
% 
%                 % decimate(x,r,[n,'fir'])
%                 
%             elseif(self.NumFitPoints > self.NumSamplePoints)
%                 % upsample, interp1, interp (intfilt)
%                 % griddedInterpolant
%                 resampFactor = self.NumFitPoints / self.NumSamplePoints;
%                 numAddtl = self.NumFitPoints - self.NumSamplePoints;
% 
%                 XDATA0 = XDATA;
%                 xstp = (max(XDATA0)-min(XDATA0)) / (self.NumFitPoints-1);
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
%                 %xstp = (max(XDATA0)-min(XDATA0)) / (self.NumFitPoints-1);
%                 %XDATA = (min(XDATA0)):xstp:(max(XDATA0));
% 
%                 % upfirdn(xin,h,[,p,q])
% 
%                 % [y, b]     = resample(x,p,q[,n[,beta]])
%                 % [y, ty, b] = resample(x,tx[,fs[,p,q[,method]]])
%                 % [YDATA, XDATA] = resample(YDATA, XDATA, ... ) % TODO
            end

            if(islogical(opts.DoSecondPass))
                doPass2 = opts.DoSecondPass;%true;
            else
                doPass2 = (opts.DoSecondPass >= 2);
            end

            try
                fprintf(opts.LogFile, '[curvefit] doPass2: %d; class(XDATA),class(YDATA)): %s, %s\n', ...
                    doPass2, class(XDATA), class(YDATA));
                disp(class(XDATA)); disp(class(YDATA));
                [varargout{1:nargout}] = lsqcurvefit(...
                    @sbsense.lorentz, p0, XDATA, YDATA, ...
                    fitParamLowerBounds, ...
                    fitParamUpperBounds, ...
                    self.OptsFast);
                p0 = varargout{1};
                % TODO: Exit flag handling
            catch ERR % TODO: Handle specific error
                fprintf(opts.LogFile, 'Error occurred during Lorentzian curvefit (first pass): [%s] %s\n', ERR.identifier, ERR.message);
               if(~opts.DoSecondPass || (isnumeric(opts.DoSecondPass) && (opts.DoSecondPass <= 1)))
                   if(nargout)
                       varargout{:} = {};
                       if(opts.SmoothingLevel > 2)
                           % p0 = Crude preliminary estimate for findpeaks
                           varargout{1} = p0;
                       end
                   end
                   return;
               end
               fprintf(opts.LogFile, '[curvefit] Error occurred during first pass, so setting doPass2=true.\n');
               doPass2 = true;
            end

            if (~doPass2)
                fprintf(opts.LogFile, '[curvefit] doPass2 is false, so returning without doing second pass.\n');
                return;
            end
            try
                [varargout{1:nargout}] = lsqcurvefit(...
                    @sbsense.lorentz, p0, XDATA, YDATA, ...
                    fitParamLowerBounds, ...
                    fitParamUpperBounds, ...
                    self.OptsSlow);
                % TODO: Exit flag handling
            catch ERR % TODO: Handle specific error
               fprintf(opts.LogFile, 'Error occurred during Lorentzian curvefit (second pass): %s\n', ERR.message);
               if(nargout)
                   varargout{:} = {};
               end
            end
        end
    end

    methods(Static,Access=private)
        function opts0 = makeBaseOpts()
            opts0 = optimoptions("lsqcurvefit", ...
                "Display", "none", ...
                ... % "TypicalX", [ 1 1 1 ], ... % TODO
                "MaxIterations", 400, ...
                "FunctionTolerance", 1e-6, ...
                "OptimalityTolerance", 1e-6, ...
                "StepTolerance", 1e-6, ...
                "CheckGradients", false, ... % TODO
                "SpecifyObjectiveGradient", false, ... % TODO: Jacobian
                "OutputFcn", [], ...
                "PlotFcn", [], ...
                "UseParallel", false ... % TODO
                );
            opts0.FunValCheck = 'off';
            opts0.Diagnostics = 'off';
            opts0.DiffMaxChange = Inf;
            opts0.DiffMinChange = 0;
        end

        function optsFast = makeFastOpts(nvars,opts0)
            optsFast = optimoptions(opts0, ...
                "Algorithm", "trust-region-reflective", ...
                "MaxFunctionEvaluations", 100*nvars, ...
                ... %"CheckGradients", true, ... % TODO
                ... % "SpecifyObjectiveGradient", true, ... % TODO: Jacobian
                ...% "JacobianMultiplyFcn", [],
                "FiniteDifferenceType", "forward", ...
                "FiniteDifferenceStepSize", sqrt(eps) ...
                );
            % TODO: JacobPattern
            % optsFast.JacobPattern = ...

            % Maximum number of PCG (preconditioned conjugate gradient) iterations,
            % a positive scalar.
            % optsFast.MaxPCGIter = max(1, nvars/2);

            % Upper bandwidth of preconditioner for PCG, a nonnegative integer.
            % The default PrecondBandWidth is Inf, which means a direct factorization
            % (Cholesky) is used rather than the conjugate gradients (CG).
            % The direct factorization is computationally more expensive than CG, but
            % produces a better quality step towards the solution.
            % Set PrecondBandWidth to 0 for diagonal preconditioning
            % (upper bandwidth of 0). For some problems, an intermediate bandwidth
            % reduces the number of PCG iterations.
            % optsFast.PrecondBandWidth = Inf;

            % Determines how the iteration step is calculated.
            % The default, 'factorization', takes a slower but more accurate step than 'cg'
            optsFast.SubproblemAlgorithm = 'cg';

            % Termination tolerance on the PCG iteration, a positive scalar.
            optsFast.TolPCG = 0.1;
        end

        function optsSlow = makeSlowOpts(nvars,opts0)

            % Internally, the 'levenberg-marquardt' algorithm uses an optimality tolerance
            % (stopping criterion) of 1e-4 times FunctionTolerance and does not use OptimalityTolerance.
            optsSlow = optimoptions(opts0, ...
                "Algorithm", "levenberg-marquardt", ...
                "MaxFunctionEvaluations", 300*nvars, ...
                "FiniteDifferenceType", "central", ...
                "FiniteDifferenceStepSize", eps^(1/3), ...
                "FunctionTolerance", eps, ...
                "OptimalityTolerance", eps, ...
                "StepTolerance", eps ...
                );

            % Initial value (λ0) of the Levenberg-Marquardt parameter, a positive scalar.
            % Occasionally, the 0.01 default value of this option can be unsuitable.
            % If you find that the Levenberg-Marquardt algorithm makes little initial
            % progress, try setting InitDamping to a different value from the default,
            % such as 1e2.
            optsSlow.InitDamping = 1e-2;

            % Set the option ScaleProblem to 'none' to choose Equation 12,
            % or set ScaleProblem to 'Jacobian' to choose Equation 13.
            % ScaleProblem: 'jacobian' can sometimes improve the convergence of a
            % poorly scaled problem; the default is 'none'.
            optsSlow.ScaleProblem = 'none';
        end
    end

    % methods
        % smprat = 500 / nsamps
        % floor(32*smprat)
%         function self = set.NumFitPoints(self,val)
%             self.NumFitPoints = val;
%         end
%         %function self = set.NumFitPoints(self,val)
%         %    self.BaseWindowFactor = self.BaseWindowFactorNum 
%         %end
%         function self = set.BaseWindowFactorNum(self,val)
%             self.BaseWindowFactor = self.BaseWindowFactorNum 
%         end
%         function self = set.BaseWindowFactorScale(self,val)
%             
%         end
%         function self = set.TailSmoothWindowFactors1(self,val)
%             
%         end
%         function self = set.TailSmoothWindowFactors1(self,val)
%             
%         end
%    end

methods(Static)
function printAbortedFitOutput(fitName, outinfo)
fprintf(...
    "%s fitting aborted with exitflag %d" ...
    + " (%s @ stp %0.4e -> opt %0.4e)\n", ...
    fitName, ...
    outinfo.algorithm, outinfo.stepsize, outinfo.firstorderopt);
fprintf("\t(CG)Iter,FncCount: %d, %d\n", ...
    outinfo.cgiterations, outinfo.iterations, outinfo.funcCount);
fprintf("\tMessage: %s\n", ...
    outinfo.message);
end

% Custom validator functions
function mustBeOfClass(input,className)
    % Test for specific class name
    cname = class(input);
    if ~strcmp(cname,className)
        eid = 'Class:notCorrectClass';
        msg = ['Input must be of class ',className,'.'];
        throwAsCaller(MException(eid,msg))
    end
end

function mustBeEqualSize(a,b)
    % Test for equal size
    if ~isequal(size(a),size(b))
        eid = 'Size:notEqual';
        msg = 'Inputs must have equal size.';
        throwAsCaller(MException(eid,msg))
    end
end

function mustBeDims(input,numDims)
    % Test for number of dimensions    
    if ~isequal(length(size(input)),numDims)
        eid = 'Size:wrongDimensions';
        msg = ['Input must have ',num2str(numDims),' dimension(s).'];
        throwAsCaller(MException(eid,msg))
    end
end
end

end