function FC = makeFullComposite(A,B)
    %A = im2double(A);
    %B = im2double(B);
    % FC = im2double(imfuse(A, B, 'blend'));
    FC = imlincomb(0.5, im2double(A), 0.5, im2double(B), 'double');
end
