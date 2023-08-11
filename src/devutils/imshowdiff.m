function h = imshowdiff(fignum,img0_0, img1_0,img2_0, img1,img2)
if(fignum<1)
    h = figure;
else
    h = figure(fignum);
end

clf;
showOrig = ~(isempty(img1_0) && isempty(img2_0));

tl = tiledlayout(1,3+showOrig);
if(showOrig)
    if(isempty(img1_0))
    img1_0 = zeros(size(img1));
    end
    if(isempty(img2_0))
        img2_0 = zeros(size(img1));
    end
    nexttile(tl, 1, [1 1]);
    if(isempty(img0_0))
        imshow(imtile({img1_0,img2_0}, 'GridSize', [2 1]));
    else
        imshow(imtile({img1_0,img0_0,img2_0}, 'GridSize', [3 1]));
    end
    
end
nexttile(tl, [1 1]);
montage({img1,img2},'Size', [2 1]);

nexttile(tl, [1 2]);
montage({imfuse(img1,img2,"blend","Scaling","none"), ...
    imfuse(img1,img2,"diff", "Scaling", "none"), ...
    imfuse(img1,img2,"falsecolor","Scaling","none"), ...
    imfuse(img1,img2,"checkerboard","Scaling","none")}, ....
    'Size', [2 2]);
end
