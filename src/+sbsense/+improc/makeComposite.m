function C = makeComposite(A,B)
    A = im2double(A);
    B = im2double(B);
    C = imlincomb(0.5, immultiply(A,B), 0.5, imlincomb(0.5, A, 0.5, B, 'double'), 'double');
end