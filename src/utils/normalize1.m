function varargout = normalize1(varargin)
narginchk(1,Inf);
if(nargout)
    [varargout{:}] = normalize(varargin{:});
else
    normalize(varargin{:});
end
end