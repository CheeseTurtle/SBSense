function [I,W] = imfusew(I1, I2, W)
switch(class(I1))
    case 'single'
        fcn = @im2single;
    case 'uint8'
        fcn = @im2uint8;
    case 'uint16'
        fcn = @im2uint16;
    case 'uint32'
        fcn = @im2uint32;
    case 'int16'
        fcn = @im2int16;
    case 'logical'
        fcn = @im2uint8; % Or @imbinarize...?
        %otherwise
        %    % Leave as double
end
if isscalar(W)
    %W = min(size(I1, 2), W);
    if(W < size(I1,1))
        I1(:,W+1:end) = I2(:,W+1:end);
    end
    I = fcn(I1);

    %W = horzcat( ...
    %    false(size(I1,1),W, 'logical'), ...
    %    true(size(I1, 1),size(I1,2) - W, 'logical'));
    return;
elseif isvector(W)
    numRows = min(size(I1,1), size(I2,1));
    numCols = min(size(I1,2), size(I2,2));
    if(~all(fix(W)==W))
        W = numCols*W;
    end
    W = min(max(W,0),numCols);


    numLeftCols = W(1); %max(0, floor(0.35*numCols) - 1);
    numRightCols = min(W(2), numCols-numLeftCols); % max(0, ceil(0.65*numCols) - 1);
    numMidCols = max(numCols - numLeftCols - numRightCols, 0);
    WLeft = zeros(numRows, numLeftCols, 'double');
    WRight = ones(numRows, numRightCols, 'double');
    stp = double((numMidCols+1)\1);
    WMid = repelem(stp*double((1:numMidCols)), numRows, 1);
    W = horzcat(WLeft, WMid, WRight);
elseif ~isa(W,'double')
    W = rescale(im2double(W), 0, 1, "InputMin", 0, "InputMax", 255);
end


% immagbox

% difs = imlincomb(-1.0, I1, 1.0, I2, 'double', 0.5);
% [mindif,maxdif] = minmax(difs(:)');

if(isa(W,'logical'))
    I1(W) = I2(W);
else
    if(~isa(I1,'double'))
        I1 = im2double(I1);
    end
    if(~isa(I2,'double'))
        I2 = im2double(I2);
    end
    msk1 = (W <= 0.0);
    msk2 = (W >= 1.0);
    msk3 = (msk1 | msk2);
    msk0 = ~msk3;
    I1_0 = sparse(I1.*msk0);
    I2_0 = sparse(I2.*msk0);
    W_0 =  sparse(W.*msk0);
    difs = I2_0 - I1_0;
    I_0 = I1_0 + difs.*W_0;

    I1 = I1.*msk1 + I2.*msk2 + full(I_0);
end

I = fcn(I1);

% greatest positive diff. possible = max(I2) - min(I1);
% greatest negative diff. possible = min(I2) - max(I1);

end