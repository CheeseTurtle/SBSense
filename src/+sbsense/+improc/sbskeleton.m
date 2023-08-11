function skel = sbskeleton(I, minbranchlength)
arguments(Input)
    I;
    minbranchlength = 100;
end
imgBW = sbsense.improc.sbbinarize(I);
%skel = bwmorph(imcomplement(imgBW), 'skeleton', Inf);
skel = bwskel(imcomplement(imgBW), 'MinBranchLength', minbranchlength);
eps = bwmorph(skel, 'endpoints', Inf);
clf, montage({imdilate(skel, strel('disk', 20, 4)), ...
    imdilate(eps,strel('disk', 20, 4))});
end