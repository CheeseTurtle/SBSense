function X = colonspace1(threshFactor, varargin)
narginchk(3,4);
try
    X = colon(varargin{:});
catch ME
    celldisp(varargin);
    rethrow(ME);
end
if isempty(X)
    fprintf('####### [colonspace1([%0.4g %0.4g], varargin)] X IS EMPTY. varargin: %s', ...
        threshFactor(1), threshFactor(end), formattedDisplayText(varargin));
    X = [varargin{1},varargin{end}];
end
%try
if X(end) < varargin{end}
    absdif = varargin{end} - X(end);
    if isscalar(X) || ( ...
            (absdif >= threshFactor(1)*(varargin{end}-varargin{1})) ...
            && ((length(varargin)==2) || (absdif >= threshFactor(end)*varargin{2})) )
        X = [X varargin{end}];
    end
%catch ME
%    display(X); celldisp(varargin);
%    rethrow(ME);
%end
end