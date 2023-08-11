function S = copyfields(SSrc, SDest, varargin, opts)
arguments(Input)
    SSrc struct;
    SDest struct;
end
arguments(Repeating)
    varargin;
end
arguments(Input)
    opts.RemoveFields = false;
end

fns = fieldnames(SSrc);
if(length(varargin))%if nargin < 3
%msk = zeros(size(varargin));
%mskRegex = matches(varargin, "-regex");

%msk(mskRegex) = 1;
exceptIdx = find(matches(varargin, "-except"), 1, 'first');
if(exceptIdx)
    exclusionsEnd = length(varargin);
    if exceptIdx == 1
        regexInclude = false;
        inclusionsEnd = 0;
        regexExclude = (exclusionsEnd > exceptIdx) ...
            && (varargin{exceptIdx+1}=="-regex");
    else
        inclusionsEnd = exceptIdx - 1;
        regexInclude = (varargin{1}=="-regex");
    end
elseif(varargin{1}=="-regex")
    regexExclude = false;
    exclusionsEnd = 0;
    regexInclude = true;
    inclusionsEnd = exceptIdx - 1;
else
    regexInclude = false;
    regexExclude = false;
    inclusionsEnd = length(varargin);
    exclusionsEnd = 0;
end

inclusions = varargin(1+regexInclude:inclusionsEnd);
exclusions = varargin(inclusionsEnd+1+regexExclude:exclusionsEnd);


if regexInclude
    inclusionsMask = matches(fns, regexpPattern(inclusions));
else
    inclusionsMask = matches(fns, inclusions);
end

end