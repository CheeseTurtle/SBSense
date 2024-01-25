function J = imimposemax(I, BW, conn, returnComplement)
arguments(Input)
    I {mustBeNumeric};
    BW {mustBeNumericOrLogical};
    conn = 8; % Default is 8 for 2D images and 26 for 3D images
    returnComplement logical = false;
end
I = imcomplement(I); BW = imcomplement(BW);
J = imimposemin(I, BW, conn);
if(~returnComplement)
    J = imcomplement(J);
end
end