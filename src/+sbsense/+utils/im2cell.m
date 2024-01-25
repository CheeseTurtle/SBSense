
function I = im2cell(I,dimn,minndims)
arguments(Input)
    I; %{mustBeNumericOrLogical};
    dimn {mustBeInteger, mustBeNonnegative} = 0;
    minndims {mustBeNonnegative} = 2;
end
nd = ndims(I);
if((nd <= minndims) || (nd < dimn))
    I = {I};
    return;
elseif(dimn==0)
    dimn = nd;
elseif(minndims>dimn)
    minndims = dimn-1;
end
while dimn > minndims
    sz = size(I);
    %disp([minndims dimn nd]);
    if(nd<dimn)
        break;
    end
    perm = [(1:nd) dimn];
    %fprintf('(%d) nd: %d, dimn: %d, sz: %s', minndims, nd, dimn, formattedDisplayText(sz));
    perm(dimn) = [];
    sz = sz(perm);
    I = permute(I, perm);
    args = {num2cell(sz(1:end-1)), {repelem(1, 1, sz(end))}};
    args = [args{:}];
    % disp(args);
    I = mat2cell(I, args{:});
    %while(iscell(I) && any(cellfun(@iscell, I, 'UniformOutput', true)))
    %    celldisp(I);
    %if(iscell(I))
    %    I = [I{:}];
    %end
    %end
    if(iscell(I) && any(cellfun(@iscell, I, 'UniformOutput', true)))
        I = [I{:}];
    end
    %while(iscell(I) && any(cellfun(@iscell, I, 'UniformOutput', true)))
    %    %I = cat(dimn, I{:});
    %end
    %I(msk) = cellfun( ...
    %            @(x) mat2cell(x, size(x,1), size(x,2), [1 1 1 1 1 1 1 1 1 1]))
    dimn = dimn - 1;
end
end