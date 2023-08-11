function HC = makeHalfComposite(fphh,frames)
    assert(~isempty(frames));
    if(fphh < 1)
        if size(frames,3)==1
            HC = im2double(frames);
            return;
        end
        fphh = idivide(size(frames,3), 2, 'fix');
    end

    if(fphh == 1)
        A = im2double(frames(:,:,1));
        B = im2double(frames(:,:,2));
    else
        iA2 = fphh;
        iB1 = iA2 + 1;

        A0 = im2double(frames(:,:,iA2));
        B0 = im2double(frames(:,:,iB1));
        A = A0;
        B = B0;
        iA1 = iA2 - 1;
        iB2 = iB1 + 1;

        while (iA1 >= 1)
            A = sbsense.improc.makeComposite(im2double(frames(:,:,iA1)), A);
            B = sbsense.improc.makeComposite(B, im2double(frames(:,:,iB2)));
            iA1 = iA1 - 1;
            iB2 = iB2 + 1;
        end
    end
    HC = sbsense.improc.makeComposite(A,B);
end