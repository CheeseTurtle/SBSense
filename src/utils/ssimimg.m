function [I, m] = ssimimg(A, ref, varargin)
[m, I] = ssim(A, ref, varargin{:});
end