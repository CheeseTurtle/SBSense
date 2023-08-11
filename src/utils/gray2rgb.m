function I = gray2rgb(BW, N)
arguments(Input)
    BW (:,:,1) {mustBeNumeric};
    N {mustBeNumeric} = islogical(BW)*2 + ~islogical(BW)*255;
end
[X, cmap] = gray2ind(BW,N);
I = ind2rgb(X, cmap);
end