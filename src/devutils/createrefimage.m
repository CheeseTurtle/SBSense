function [I, I1_reg, I1_R, I2_reg, I2_R] = createrefimage(I1, I2, I3, opts)
arguments(Input)
    I1 {mustBeA(I1, 'uint8')}; 
    I2 {mustBeA(I2, 'uint8')}; 
    I3 {mustBeA(I3, 'uint8')} = [];
    opts.FlipHorizontal {mustBeInteger,mustBeInRange(opts.FlipHorizontal, 0, 2)} = 2;
    opts.FlipVertical {mustBeInteger,mustBeInRange(opts.FlipVertical, 0, 2)} = 0;
end
if opts.FlipHorizontal
    if(opts.FlipHorizontal > 1)
        I2 = flip(I2, 2); % left of I2 used to cover right side of I1
    else
        I1 = flip(I1,2);
    end
end
if(opts.FlipVertical)
    if(opts.FlipVertical > 1)
        I1 = flip(I1,1);
    else
        I2 = flip(I2,1);
    end
end
if ~isempty(I3)
    sim = absdiff(I1, I3);
    msk1 = (sim > 0.99*max(sim(:)));
    msk2 = (sim > 0.95*max(sim(:)));
    msk3 = (sim >= 0.90*max(sim(:)));
    msk4 = imlincomb(0.5, msk1, 0.25, msk2, 0.25, msk3, 'single');
    msk  = imlincomb(0.3, msk4, 0.7, imboxfilt(msk4, [8 8]), 'single');
end

% [optimizer,metric] = imregconfig('monomodal');
optimizer = registration.optimizer.RegularStepGradientDescent();
metric = registration.metric.MeanSquares();

optimizer.MaximumIterations = 300;
optimizer.MinimumStepLength = 5e-4;

I1_R0  = imref2d(size(I1));
[I1_reg, I1_R] = imregister(I1,I1_R0, I2,'translation',optimizer,metric, ...
    "PyramidLevels", 3);

I2_R0  = imref2d(size(I2));
[I2_reg, I2_R] = imregister(I2,I2_R0, I1,'translation',optimizer,metric, ...
    "PyramidLevels", 3);
%disp(I1_reg); disp(I1_R);
%disp(I2_reg); disp(I2_R);

numRows = min(size(I1,1), size(I2,1));
numCols = min(size(I1,2), size(I2,2));




rect_onion   = [1 floor(0.35*size(I1,2)) size(I1,1) ceil(0.51*size(I1,2))];
rect_peppers = [1 floor(0.49*size(I2,2)) size(I2,1) ceil(0.65*size(I2,2))];

xc1 = normxcorr2(sub_onion, sub_peppers);
xc2 = normxcorr2(sub_peppers, sub_onion);
% offset found by correlation
[~,imax1] = max(abs(xc1(:)));
[~,imax2] = max(abs(xc2(:)));
imax = max(imax1, imax2);
[ypeak,xpeak] = ind2sub(size(xc),imax(1));
if(imax1 > imax2) % Shift image 1
    corr_offset = [(xpeak-size(sub_onion,2))
        (ypeak-size(sub_onion,1))];
    % relative offset of position of subimages
    rect_offset = [(rect_peppers(1)-rect_onion(1))
        (rect_peppers(2)-rect_onion(2))];
else % Shift image 2
    corr_offset = [(xpeak-size(sub_peppers,2))
        (ypeak-size(sub_peppers,1))];
    % relative offset of position of subimages
    rect_offset = [(rect_onion(1)-rect_peppers(1))
        (rect_onion(2)-rect_peppers(2))];
end

% total offset
offset = corr_offset + rect_offset;
xoffset = offset(1);
yoffset = offset(2);





if(imax1 > imax2) % Shift image 1
    if(offset > 0) % Shifting to the right
        %I1 = I1(:,1:ceil(0.51*size(I1,2)));
        I1(:,end-offset+1:end) = [];
        I1a = padarray(I1, [0 offset], 'symmetric' ,'pre');
        I1b = padarray(I1, [0 offset], 'replicate' ,'pre');
    elseif(offset < 0) % Shifting left
        I1(:, 1:offset) = [];
        I1a = padarray(I1, [0 offset], 'replicate', 'post');
        I1b = padarray(I1, [0 offset], 'symmetric', 'post');
    end
    I1 = imlincomb(0.5, I1a, 0.5, I1b, class(I1));
else % Shift image 2
    if(offset < 0) % Shifting to the left
        %I2 = I2(:,floor(0.49*size(I2,2)):end);
        I2(:,1:offset) = [];
        I2a = padarray(I2, [0 offset], 'symmetric' ,'post');
        I2b = padarray(I2, [0 offset], 'replicate' ,'post');
    elseif(offset > 0) % Shifting to the right
        I2(:,end-offset+1:end) = [];
        I2a = padarray(I2, [0 offset], 'replicate', 'pre');
        I2b = padarray(I2, [0 offset], 'symmetric', 'pre');
    end
    I2 = imlincomb(0.5, I2a, 0.5, I2b, class(I2));
end

numLeftCols = max(0, floor(0.35*numCols) - 1);
numRightCols = max(0, ceil(0.65*numCols) - 1);
numMidCols = numCols - numLeftCols - numRightCols;

WLeft = zeros(numRows, numLeftCols, 'double');
WRight = ones(numRows, numRightCols, 'double');
stp = double((numMidCols+1)\1);
WMid = repelem(stp*double((1:numMidCols)), numRows, 1);

W = horzcat(WLeft, WMid, WRight);
I = imfusew(I1, I2, W);

end