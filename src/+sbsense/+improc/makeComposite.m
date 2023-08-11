function C = makeComposite(A,B)
    % A = im2double(A);
    % B = im2double(B);
    A = im2uint16(A);
    % B = im2uint16(B); % assume B is already uint16!
    C = imlincomb(0.5, immultiply(A,B), 0.5, imlincomb(0.5, A, 0.5, B, 'uint16'), 'uint16'); % type of C is uint16
end