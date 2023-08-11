function [h1,h2] = calcChannelHeightFromNthDiv(divBoundsPositions,j)
h1 = double(diff(divBoundsPositions(j:j+2)));
h2 = h1(2);
h1(2) = [];
end