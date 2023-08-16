function A = uint8ToBits(A0)
arguments(Input)
    A0 (:,:) uint8;
end
% reshape(int2bit([1 2 3 ; 4 5 6]', 8), [], 2)'
% A = reshape(logical(int2bit(A0', 8)), [], size(A0, 1))';
A = logical(int2bit(A0', 8))';
end