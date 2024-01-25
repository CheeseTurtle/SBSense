function I = imadjstretch(varargin)
narginchk(1,3);
I = varargin{1};
if ~islogical(I)
    I = imadjust(I, stretchlim(varargin{:}));
end
end