function I = gray2rgb0(img)
I(:,:,1) = img;
I(:,:,2) = zeros(size(img), 'like', img);
I(:,:,3) = I(:,:,2);
end
