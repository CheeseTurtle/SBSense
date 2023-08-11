function  [successTF, Yc,peakInfo,estimatedLaserIntensity,intensityProfile, ...
    Yr, p1, sampMask, sampMask0, roiMask] ...
    = sbanalyzecomposite(Y0,Y1,numFitPoints, analysisRescale, f)
arguments(Input)
    Y0; Y1;
    % lfit sbsense.LorentzFitter;
    numFitPoints (1,1) {mustBeInteger, mustBeNonnegative};
    analysisRescale;
    f = 1; %#ok<INUSA>
    % debug logical = false;
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

successTF = true; % TODO: Return success value from sampmask function then check
[sampMask, sampMask0, roiMask, Yr, ~, typeIsDouble, centroid] = ...
    sbsense.improc.sbsampmask(Y0, Y1, false, f);

fprintf(f, 'Made samp mask. typeIsDouble: %s', ...
    formattedDisplayText(typeIsDouble));
fprintf(f, 'Centroid: %s', formattedDisplayText(centroid));
fprintf(f, 'Class of sampMask: %s\n', class(sampMask));

Y1 = im2double(Y1); Y0 = im2double(Y0);
if(~typeIsDouble)
    Yr = Y1./Y0;
end
estimatedLaserIntensity = mean(Yr(~sampMask), "all");
Yc0 = Yr./estimatedLaserIntensity;
% disp(mean(Yc0(~sampMask), "all"));

%Yc = imlincomb(0.5, imcomplement(Yc0), ...
%    0.5, imabsdiff(Yc0, ones(size(Yc0), 'like', Yc0)));
% Yc = abs(imsubtract(Yc0, ones(size(Yc0), 'like', Yc0)));
% Yc = realsqrt(max(0,imcomplement(Yc0)).*max(0,Yc3));

%Yc_1 = imclose(Yc, strel('rectangle', [25 3]));
%Yc0_1 = imcomplement(imopen(Yc0, strel('rectangle', [25 3])));
%Yc0 = imcomplement(Yc0);
%Yc = max(imimposemin(Yc, imabsdiff(Yc,Yc0)), 0);

%Yc = max(imcomplement(Yc0), 0);
%Yc = max(0,1.0 - Yc0);
Yc = 1.0 - Yc0;

%Yc = imdilate(Yc, strel('disk', 5));
%Yc = imopen(Yc, strel('disk', 10));
%Yc = imgaussfilt(Yc, 5);
%Yc = imboxfilt(Yc, [25 3]);


intensityProfile = mean(Yc, 1);
IPxs = 1:length(intensityProfile);

colMask = any(roiMask, 1);
colLeft = find(colMask, 1, "first");
colRight = find(colMask, 1, "last");
p0_x0 = centroid(1);
if(~(colLeft <= p0_x0) || ~(p0_x0 <= colRight))
    if(colLeft == colRight)
        p0_x0 = colLeft;
    else
        p0_x0 = 0.5*(colLeft+colRight);
    end
end

p0_pkHt = prctile(Yc(roiMask), 95, "all", "Method", "approximate");
p0_A = 2*p0_pkHt; p0_B = 2;

% TODO: Check validity of p0 values
p0 = [p0_x0 p0_B p0_A];
% p0 = lfit.DefaultParamGuess;



% TODO: Initial guess based on image

% TODO: SuccessTF
% fprintf(f, 'roiMask count: %d\n', sum(roiMask,"all"));
%try
    % p1 = lfit.curvefit(p0, ...
    %     IPxs, intensityProfile, "FallbackPeakMask", roiMask, ...
    %     "PreferFallbackMask", true, "NumFitPoints", numFitPoints);
    p1 = lzcurvefit(p0, IPxs, intensityProfile, [1 length(IPxs)], ...
        numFitPoints, roiMask, true, [1 -inf inf ; length(IPxs) inf inf], f);
    if(isempty(p1))
        successTF = false;
    end
%catch ME
%    % TODO: Print error
%    fprintf(f, 'Error during curvefitting (%s): %s\n', ME.identifier, ME.message);
%end
% disp(p1);


% TODO: Skip this part? Or use interp2?
if(analysisRescale ~= 1)
    p1(1) = analysisRescale*p1(1);

    Yc = imresize(Yc, analysisRescale, "lanczos3");
    Yr = imresize(Yr, analysisRescale,  "lanczos3");
end
x0 = p1(1); pkHt = p1(3) / p1(2);
peakInfo = [x0 pkHt];
%FCmean = Yc; % TODO
%Y2 = Yc; % TODO
end