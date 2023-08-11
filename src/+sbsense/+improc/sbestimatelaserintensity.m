function  [estimatedLaserIntensity, successTF, Yc, Yr, ...
    sampMask, sampMask0, roiMask, centroid] ...
    = sbestimatelaserintensity(Y0,Y1,peakSearchBounds,deadMask,f)
arguments(Input)
    Y0; Y1; peakSearchBounds;
    deadMask;
    f = 1;
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

[sampMask, sampMask0, roiMask, Yr, ~, typeIsDouble, centroid] = ...
    sbsense.improc.sbsampmask(Y0, Y1, peakSearchBounds, false, f);

successTF = ~isempty(sampMask);
if ~successTF
    estimatedLaserIntensity = NaN;
    Yc = NaN(size(Y0));
    sampMask0 = [];
    roiMask = [];
    return;
end

fprintf(f, 'Made samp mask. typeIsDouble: %s', ...
    formattedDisplayText(typeIsDouble));
fprintf(f, 'Centroid: %s', formattedDisplayText(centroid));
fprintf(f, 'Class of sampMask: %s\n', class(sampMask));

Y0 = im2double(Y0); Y1 = im2double(Y1);
if(~typeIsDouble)
    Yr = Y1./Y0;
end
estimatedLaserIntensity = mean(Yr(deadMask), 'all', 'omitnan'); %mean(Yr(~sampMask), "all");
Yc0 = Yr./estimatedLaserIntensity;
Yc = 1.0 - Yc0;

end