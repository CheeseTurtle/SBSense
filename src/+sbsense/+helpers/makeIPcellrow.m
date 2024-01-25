function C = makeIPcellrow(bounds)
sz = size(bounds);
nd = ndims(bounds);
onez = ones(1, sz(end));
nd = nd - 1;
sz = num2cell(sz(1:nd)); %mat2cell(sz(1:nd), 1, ones(1,nd));
C = mat2cell(bounds, sz{:}, onez);
end