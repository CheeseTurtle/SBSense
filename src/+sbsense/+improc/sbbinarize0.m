function [BW, gray] = sbbinarize0(I)
se1 = strel('disk', 30, 4);
se2 = strel('disk', 2, 4);
mask = imfill(imextendedmin(I,100,8), 4, "holes");
gray = imimposemin(I,mask,8);
gray = imerode(imdilate(gray,se2), se1);
BW = imcomplement(imbinarize(gray, "adaptive", ...
    "ForegroundPolarity", "dark", ...
    "Sensitivity", 0.01)); % TODO: Sensitivity can also be a mat?
% roipoly
% bwlabel
% bwlabel, label2rgb, poly2label, poly2mask
% bwconncomp => labelmatrix

% imfill, regionfill
% https://www.mathworks.com/help/images/classify-pixels-that-are-partially-enclosed-by-roi.html

% BW = bwmorph(BW, 'clean');
%BW = bwmorph(BW, 'open');
% BW = bwmorph(BW, 'bridge');
%BW = bwmorph(BW, 'fill');
%BW = bwconvhull(imcomplement(BW), "objects");

%BW = bwmorph(BW, 'thicken');
%BW = bwmorph(BW, 'thin');
%BW = bwmorph(BW, 'shrink');
%BW = bwmorph(BW, 'fatten');
end