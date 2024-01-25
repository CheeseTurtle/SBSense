function A = bitsToUint8(A0)
arguments(Input)
    A0 (:,:) logical;
end
% reshape(int2bit([1 2 3 ; 4 5 6]', 8), [], 2)'
A = uint8(bit2int(A0', 8))';
end