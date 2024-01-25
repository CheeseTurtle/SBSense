function X = colonspace(varargin)
% narginchk(2,3);
try
    X = colon(varargin{:});
catch ME
    celldisp(varargin);
    rethrow(ME);
end
try
    if X(end) < varargin{end}
        X = [X varargin{end}];
    end
catch ME
    display(X); celldisp(varargin);
    rethrow(ME);
end
end