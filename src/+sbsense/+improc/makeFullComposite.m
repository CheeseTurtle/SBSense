function FC = makeFullComposite(A,B)
    %A = im2double(A);
    %B = im2double(B);
    % FC = im2double(imfuse(A, B, 'blend'));
    % Assume B is already uint16!
    FC = imlincomb(0.5, im2uint16(A), 0.5, B, 'uint16');
end
