function [BW, gray, mask] = sbbinarize(I, diskSize1, diskSize2, ...
    minCutoff, binarizeSensitivity)
arguments(Input)
    I {mustBeNumeric};
    diskSize1 {mustBeInteger, mustBePositive} = 4;
    diskSize2 {mustBeInteger, mustBePositive} = 16;
    minCutoff {mustBeNumeric, mustBeReal} = 0.001; % 100;
    binarizeSensitivity {mustBeNumeric, mustBeNonnegative, mustBeReal} ...
        = 0.01;
end

se1 = strel('disk', diskSize1, 4); %2, 4);
se2 = strel('disk', diskSize2, 4); % 10, 4); % se1 = strel('disk', 30, 4);
mask = imfill(imcomplement(imextendedmin(I,minCutoff,8)), 4, "holes");
% mask = bwmorph(mask, "erode", 1);
% mask = bwmorph(mask, "clean", 50);
mask = bwmorph(imcomplement(mask), "fill", Inf);
mask = bwfill(mask, "holes", 4);
mask = bwmorph(mask, 'erode', 1);

gray = imimposemin(imcomplement(I), mask, 1); %imimposemin(I,mask,8);
gray = imerode(imdilate(gray,se1), se2);
BW = imbinarize(gray, "adaptive", "ForegroundPolarity", "dark", ...
    "Sensitivity", binarizeSensitivity); % TODO: Sensitivity can also be a mat?

BW = bwareafilt(imcomplement(BW), 1, "largest", 8);

ar = regionprops(BW, "Area");
% montage({mask, gray, BW});
if(isempty(ar))
    BW = imfill(imcomplement(BW), 8, "holes");
else
    BW = bwareaopen(imcomplement(BW), ceil(0.9*(ar(1).Area)));
end

end
