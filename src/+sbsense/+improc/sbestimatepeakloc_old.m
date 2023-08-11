function  [channelPeakData,intensityProfile, ...
    p1, successTF, cfitBounds, sampMask, sampMask0, roiMask, resnorm, wps,ws,XDATA] ...
    = sbestimatepeakloc_old(Y0c,Y1c,Ycc,...%estimatedLaserIntensity, ...
    origDims, peakSearchBounds, peakSearchZone, f, p01, sampMaskResults, preferFallbackMask)
    %numHalfIPpixels, numIPpixels, f)
arguments(Input)
    Y0c; Y1c; Ycc;
    %numFitPoints (1,1) {mustBeInteger, mustBeNonnegative};
    origDims (1,2) uint16;
    peakSearchBounds (1,2) uint16;
    %numHalfIPpixels; numIPpixels;
    peakSearchZone = []; % [1 origDims(2)];
    f = 1;
    p01 = [];
    % debug logical = false;
    sampMaskResults = {};
    preferFallbackMask = true;
end


% 0) Divide Y1/Y0 = Yr.
% 1) Determine tail pixels and their weight for averaging
% 2) Determine A ≈ A1 ≈ A2 ≈ A3 (ALT+247)
%    A ≈ average of all Aij (value of tail pixel in Yr)
% 2) Multiply scalar estimated A with BG image Y0
% 3) Subtract Y1 from the product (or subtract
%    product from Y1)
% 4) Divide result of subtraction by each Aij
%    (or scalar A? or mean of scalar A and Aij?)
%    ** Fill outliers AND PEAK PART with scalar A **

% if isempty(peakSearchZone) || isequal(peakSearchZone, [0, 0]) || all(isnan(peakSearchZone))
%     IPxs = 1:double(origDims(2));
%     intensityProfile = mean(Ycc, 1);
%     numFitPoints = size(fitProfile,2);
% else
%     if ~peakSearchZone(1)
%         peakSearchZone(1) = 1;
%     end
%     if peakSearchZone(2) <= peakSearchZone(1)
%         peakSearchZone(2) = origDims(2);
%     end
%     IPxs = double(peakSearchZone(1)):1:double(peakSearchZone(2));
%     intensityProfile = mean(Ycc(:,IPxs),1);
% end

if isempty(peakSearchZone) || isequal(peakSearchZone, [0, 0]) || all(isnan(peakSearchZone))
    peakSearchZone0 = [];
    peakSearchZone = [1 origDims(2)];
else
    if anynan(peakSearchZone)
        peakSearchZone(isnan(peakSearchZone)) = 0;
    end
    if ~peakSearchZone(1)
        peakSearchZone(1) = 1;
    end
    if peakSearchZone(2) <= peakSearchZone(1)
        peakSearchZone(2) = double(origDims(2));
    end
    peakSearchZone0 = peakSearchZone;
end

ws = double.empty();
intensityProfile = mean(double(Ycc), 1);
try
    XDATA = 1:double(origDims(2));
    peakInfo = sbsense.improc.getContourPeakInfo(double(XDATA), intensityProfile, p01);
    for pki = peakInfo
        fprintf(f, '[sbestimatepeakloc] peakInfo:\n%s\n', ...
            strip(formattedDisplayText(struct2table(pki, 'AsArray', true))));
    end
    if peakInfo.numPeaks
        [p1a,wresa, p01a, wps, hgta,wida, npksa] = sbsense.improc.lzcurvefite(XDATA, intensityProfile, ...
            peakInfo.ys1, peakInfo.hgts, peakInfo.locs, peakInfo.wids, peakInfo.scores);
        if ~isempty(p1a)
            resnorma = sum(wresa.^2);
            p1a = double(p1a);
            if (resnorma < 20e-4) && (isempty(peakSearchZone0) ...
                || ((double(peakSearchZone(1)) <= p1a(1)) && (p1a(1) <= double(peakSearchZone(2)))))
                cfitBounds = [1 origDims(2)];
                sampMask = false(origDims);
                hwd = min(ceil(wid*0.375), 100);
                sampMask(:, max(1,fix(p1a(1)-hwd)):min(double(origDims(2)),ceil(p1a(1)+hwd))) = true;
                roiMask = sampMask;
                sampMask0 = sampMask;
                p1 = p1a; resnorm = resnorma;
                successTF = true;
                channelPeakData = [p1(1) p1(3)/p1(2)];
                return;
            end
        %else
        %    p1a = [];
        end
    else
        p1a = [];
        p01a = [];
    end
catch ME
    fprintf(f, '[sbestimatepeakloc] Error "%s" occurred while calling getContourPeakInfo functions: %s\n', ...
        ME.identifier, getReport(ME));
    p1a = [];
    p01a = [];
end

wps = double.empty(3,0);
ws = double.empty(); % Moved up
XDATA = [];

try
    if isempty(sampMaskResults)
        [sampMask, sampMask0, roiMask, ~, ~, ~, centroid] = ...
            sbsense.improc.sbsampmask(Y0c, Y1c, peakSearchBounds, false, f, peakSearchZone, peakInfo);
    else
        [sampMask, sampMask0, roiMask, centroid] = sampMaskResults{:};
    end
    successTF = ~isempty(sampMask);
catch ME
    fprintf(f, '[sbestimatepeakloc] Error "%s" occurred while calling sbsampmask function: %s\n', ...
        ME.identifier, getReport(ME));
    successTF = false;
    roiMask = logical.empty(); sampMask = logical.empty(); sampMask0 = logical.empty();
end

if ~successTF
    fprintf(f, '[sbestimatepeakloc] sampmask is empty!\n');
    channelPeakData = [NaN NaN];
    intensityProfile = NaN(1, origDims(2));
    p1 = [NaN NaN NaN];
    cfitBounds = [NaN NaN];
    resnorm = NaN;
    return;
end

fprintf(f, '[sbestimatepeakloc] Made samp mask. typeIsDouble: (omitted)\n'); %, ...
    %formattedDisplayText(typeIsDouble));
fprintf(f, '[sbestimatepeakloc] Centroid: %s', formattedDisplayText(centroid));
fprintf(f, '[sbestimatepeakloc] Class of sampMask: %s\n', class(sampMask));

if isempty(peakSearchZone0) && ~isempty(peakSearchBounds) && ~anynan(peakSearchBounds)
    peakSearchZone01 = peakSearchBounds;
else
    peakSearchZone01 = peakSearchZone;
end

foundSol = false;
if ~isempty(p1a) && (resnorma<=250e-4) && (peakSearchZone01(1)<=p1a(1)) ...
    && (p1a(1)<=peakSearchZone01(2)) ...
    && (isempty(p01) || (abs(p01(1) - p1a(1)) <= 0.1*double(origDims(2)))) % Todo: check if within peak width
    p0 = p1a;
    hwd = max(8,min(p1a(2)*0.7,50));
    ipStartPixel = max(1, fix(p0(1) - hwd));
    ipStopPixel = min(double(origDims(2)), ceil(p0(1) + hwd));
% elseif (0 < centroid(1)) && (peakSearchZone01(1)<=centroid(1)) ...
%         && (centroid(1)<=peakSearchZone01(2))
elseif ~isempty(p01) && (peakSearchZone01(1)<=p01(1)) ...
    && (p01(1)<=peakSearchZone01(2)) % ...
    if isempty(p01a) % || (abs(hgta*p01(2)/p01(3)) < 0.5) %(abs(p01a(1) - p01(1)) <= 0.1*double(origDims(2))) % Todo: check if within peak width
        p0 = p01;
    else
        p0 = p01a;
    end
    hwd = max(8,min(0.375*p0(2),50)); % Or average??
    ipStartPixel = max(1, fix(p0(1) - hwd));
    ipStopPixel = min(double(origDims(2)), ceil(p0(1) + hwd));
else% if ~isempty(peakSearchZone0) || ~isempty(peakSearchBounds)
    %if (0 >= centroid(1)) || (peakSearchZone01(1)>centroid(1)) ...
    %    || (centroid(1)>peakSearchZone01(2))
    if ~isempty(p01) && (peakSearchZone01(1)<=p01(1)) ...
        && (p01(1)<=peakSearchZone01(2))
        centroid(1) = p01(1);
        hwd = max(8,min(p1a(2)*0.7,50));
        colLeft = max(1, fix(p01(1) - hwd));
        colRight = min(double(origDims(2)), ceil(p01(1) + hwd));
    elseif ~isempty(p01a) && (peakSearchZone01(1)<=p01a(1)) ...
        && (p01a(1)<=peakSearchZone01(2))
        centroid(1) = p01a(1);
        hwd = max(8,min(p01a(2)*0.7, 50));
        colLeft = max(1, fix(p01a(1) - hwd));
        colRight = min(double(origDims(2)), ceil(p01a(1) + hwd));
    elseif ~isempty(p01a)
        p0 = p01a;
        hwd = max(8,min(p0(2)*0.7,50)); % Or average??
        ipStartPixel = max(1, fix(p0(1) - hwd));
        ipStopPixel = min(double(origDims(2)), ceil(p0(1) + hwd));
    else
        colMask = any(roiMask, 1);
        colLeft = find(colMask, 1, "first");
        colRight = find(colMask, 1, "last");
        if colLeft == colRight
            if (centroid(1)<=0) || ((max(1,colLeft - 20)<=centroid(1)) ...
                || (centroid(1)<=min(double(origDims(2)), colRight + 10)))
                colLeft = max(1, colLeft - 20);
                colRight = max(double(origDims(2)), colRight + 10);
            else
                colLeft = peakSearchZone01(1);
                colRight = peakSearchZone01(2);
            end
        elseif centroid(1)==0
            centroid(1) = 0.5*(colLeft+colRight);
        end
        % hwd = NaN;
    %else
    %    colLeft = peakSearchZone01(1);
    %    colRight = peakSearchZone01(2);
    %    % hwd = NaN;
    end
    if ~((centroid(1) > 0) && (colLeft<=centroid(1)) && (colRight>=centroid(1)))
        centroid(1) = 0.5*(colLeft+colRight);
        % p0_x0 = centroid(1);
    % elseif ~isempty(p01) && ~anynan(p01)
    %     p0_x0 = p01(1);
    % else
        % p0_x0 = 0.5*(colLeft+colRight);
    end
    p0_pkHt = double(prctile(Ycc(roiMask), 98, "all", "Method", "approximate"));
    p0_B = 2\(colRight - colLeft + 1);
    p0_A = p0_B*p0_pkHt;
    p0 = double([centroid(1) p0_B p0_A]);

    ipStartPixel = colLeft;
    ipStopPixel = colRight;
    % % colLeft = max(colLeft, peakSearchBounds(1));
    % % colRight = min(colRight, peakSearchBounds(2));
    % if colRight < colLeft
    %     colRight = colLeft; % TODO
    % end

    % if(~(colLeft <= p0_x0) || ~(p0_x0 <= colRight))
    %     if(colLeft == colRight)
    %         p0_x0 = colLeft;
    %     else
    %         p0_x0 = 0.5*(colLeft+colRight);
    %     end
    % end
end

% TODO: Check validity of p0 values
% TODO: Initial guess based on image
% p0 = lfit.DefaultParamGuess;

% intensityProfile = mean(Ycc, 1); % Moved to beginning of function

if isempty(peakSearchZone0) % || isequal(peakSearchZone, [0, 0]) || all(isnan(peakSearchZone))
    PSZMsk = logical.empty();
    preferFallbackMask = true; % TODO?
    % ipStartPixel = 1;
    % ipStopPixel = double(origDims(2));
    % peakSearchZone = [1 ipStopPixel];
    % peakSearchZone= [ipStartPixel ipStopPixel];
    % IPxs = double(ipStartPixel:ipStopPixel);
    IPxs = ipStartPixel:1:ipStopPixel;
    fitProfile = intensityProfile(:,IPxs);
    % fitProfile = intensityProfile;
    FBPM = roiMask(:,IPxs);
    % FBPM = roiMask;
    % numFitPoints = origDims(2); %size(fitProfile,2);
    numFitPoints = ipStopPixel - ipStartPixel + 1;
else
    % if ~peakSearchZone(1)
    %     peakSearchZone(1) = 1;
    % end
    % if peakSearchZone(2) <= peakSearchZone(1)
    %     peakSearchZone(2) = double(origDims(2));
    % end
    % peakSearchZone = double(peakSearchZone);
    % TODO: Why 250???
    fprintf(f, '[sbestimatepeakloc] [1 origDims(2)] = [1 %g]\n', origDims(2));
    fprintf(f, '[sbestimatepeakloc] peakSearchZone: [%g %g]\n', peakSearchZone(1), peakSearchZone(2));


    
    % fprintf(f, '[sbestimatepeakloc] floor(p0_x0)-250: %g\n', floor(p0_x0)-250);
    % fprintf(f, '[sbestimatepeakloc] ceil(p0_x0)+250: %g\n', ceil(p0_x0)+250);
    % ipStartPixel = max(max(1, floor(p0_x0) - 250), peakSearchZone(1));
    % ipStopPixel  = min(min(ceil(p0_x0) + 250, double(origDims(2))), peakSearchZone(2));

    % ipStartPixel = peakSearchZone(1);
    % ipStopPixel = peakSearchZone(2);

    IPxs = double(ipStartPixel:1:ipStopPixel);
    % fprintf(f, '[sbestimatepeakloc] IPxs: %s\n', strip(formattedDisplayText(IPxs)));
    % fprintf(f, '[sbestimatepeakloc] intensityProfile: %s\n', strip(formattedDisplayText(intensityProfile)));
    fitProfile = intensityProfile(:,IPxs);
    numFitPoints = ipStopPixel - ipStartPixel + 1; % size(fitProfile,2);
    FBPM = roiMask(:,IPxs);
    PSZMsk = false(1,size(Y0c,2));
    % PSZMsk(:,peakSearchZone(1):1:peakSearchZone(2)) = true;
    PSZMsk(:, IPxs) = true; % TODO
    if sum(roiMask & PSZMsk, 'all') < 0.9*(diff(peakSearchZone))
        preferFallbackMask = false; % TODO
    end
end




cfitBounds = [ipStartPixel ipStopPixel];

% TODO: Output image that shows fit region, num fit points, sample points, IPxs, num profile points...
% TODO: SuccessTF
try
    fprintf(f,'[sbestimatepeakloc] origDims: %s', formattedDisplayText(origDims));
    [p1, resnorm, wps,ws,XDATA] = sbsense.improc.lzcurvefit(p0, ...
        IPxs, fitProfile, peakSearchBounds, peakSearchZone, numFitPoints, FBPM, ...()
        preferFallbackMask, [1 0 eps ; double(origDims(2)) inf inf], f, p01); % NOTE: PeakSearchBounds taken into account here!
    % cfitBounds = [ipStartPixel ipStopPixel]; %IPxs([1 end]); % ????
catch ME
    % TODO: Print error
    fprintf(f, '[sbestimatepeakloc] Error during curvefitting (%s): %s\n', ME.identifier, ME.message);
    p1 = [];
end


if isempty(p1)
    fprintf(f, '[sbestimatepeakloc] Result of curvefit with p0 [%g %g %g] and PSB [%g %g]: []\n', ...
        p0(1), p0(2), p0(3), peakSearchBounds(1), peakSearchBounds(2));
    fprintf(f,formattedDisplayText({size(IPxs), size(intensityProfile), size(fitProfile), numFitPoints, size(FBPM)}));
    % channelPeakData = cfitBounds;

    if ~isempty(p1a) && (resnorma < 100e-4) && (isempty(peakSearchZone0) ...
        || ((peakSearchZone(1) <= p1a(1)) && (p1a(1) <= peakSearchZone(2))))
        fprintf(f, '[sbestimatepeakloc] Using p1a instead.\n');
        cfitBounds = [1 origDims(2)];
        sampMask = false(origDims);
        hwd = max(8,min(double(ceil(wid*0.375)), 50));
        p1a = double(p1a);
        sampMask(:, double(max(double(1),fix(p1a(1)-hwd))):double(min(double(origDims(2)),ceil(p1a(1)+hwd)))) = true;
        roiMask = sampMask;
        sampMask0 = sampMask;
        p1 = p1a; resnorm = resnorma;
        successTF = true;
        channelPeakData = [p1(1) p1(3)/p1(2)];
    else
        successTF = false;
        p1 = [NaN NaN NaN];
        resnorm = NaN;
        cfitBounds = [NaN NaN]; % Or empty?
        channelPeakData = [NaN NaN];
    end
else
    % XDATAb = (1:origDims(2));

    % TODO: Try to also restrict to area close to p1a / p01a peak if possible


    hwdb = max(8,min(ceil(0.375*p1(2)), 50));
    XDATAb = max(1,fix(p1(1)-hwdb)):1:min(double(origDims(2)),ceil(p1(1)+hwdb));
    intensityProfileb = intensityProfile(XDATAb);
    
    [p1b,wresb, p01b,wpsb, hgtb,widb, npksb] = sbsense.improc.lzcurvefite(XDATAb, intensityProfileb, ...
        peakInfo.ys1(XDATAb), peakInfo.hgts, peakInfo.locs, peakInfo.wids, peakInfo.scores);
    if ~isempty(p1b)
        resnormb = sum(wresb.^2);
        if (~successTF || (resnormb <= 1.25*resnorm)) &&  (resnormb < 20e-4) && ...
            (isempty(peakSearchZone0) ...
            || ((peakSearchZone(1) <= p1b(1)) && (p1b(1) <= peakSearchZone(2))))
            cfitBounds = [1 origDims(2)];
            sampMask = false(origDims);
            hwdb = max(8,min(ceil(0.375*widb), 50));
            sampMask(:, max(1,fix(p1b(1)-hwdb)):min(double(origDims(2)),ceil(p1b(1)+hwdb))) = true;
            roiMask = sampMask;
            sampMask0 = sampMask;
            p1 = p1b; resnorm = resnormb;
            successTF = true;
            %channelPeakData = [p1(1) p1(3)/p1(2)];
            %return;
        end
    %else
    %    p1a = [];
    end


    % x0 = p1(1); pkHt = p1(3) / p1(2);
    % channelPeakData = [x0 pkHt];
    channelPeakData = [p1(1) p1(3)/p1(2)];
    fprintf(f, '[sbestimatepeakloc] Result of curvefit with p0 [%g %g %g] and PSB [%g %g]: [%g %g %g], channelPeakData = [%g %g]\n', ...
        p0(1), p0(2), p0(3), peakSearchBounds(1), peakSearchBounds(2), p1(1), p1(2), p1(3), channelPeakData(1), channelPeakData(2));
end
end