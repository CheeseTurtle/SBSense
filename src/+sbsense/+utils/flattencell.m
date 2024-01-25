function [F,nlevels] = flattencell(C, recurse, nlevels)
arguments(Input)
    C cell;
    recurse {mustBeNumericOrLogical} = true;
    %nocheck logical = false; % Don't check whether C is cell
    nlevels uint8 = 0;
end
arguments(Output)
    F cell;
    nlevels (1,1) uint8; % TODO: What type?
end
%if(~nocheck && ~iscell(C))
%    F = C;
%    return;
%end

chk = cellfun(@iscell, C, 'UniformOutput', true);
if(~any(chk))
    F = C;
    return;
end

dims = cellfun(@size, C(chk), 'UniformOutput', false);

if(length(dims) > 1)
    comp = cellfun(@(x) isequal(dims{1}, x), dims(2:end), ...
        'UniformOutput',true);
else
    comp = true;
end

if(all(comp))
    F = [C{:}];
else
    %disp(dims);
    %disp(comp);
    nds = cellfun(@ndims, C, 'UniformOutput', true);
    minCommonDim = min(nds);%, [], "all");
    msk = (nds==minCommonDim);
    if(minCommonDim == 0)
        F = C;
        F(msk) = [];
        %C(msk) = [];
        %F = C; % TODO: Remove cell elements without copy-assigning?
    else
        %maxCommonDim = max(nds);
        %if(maxCommonDim ~= minCommonDim)
        %    C(~msk) = cellfun(@(x) flattencell_rearr(minCommonDim,x), C(~msk), 'UniformOutput', false);
        %end
        F = cat(minCommonDim, C{:});
    end
end
nlevels = nlevels + 1;
if(recurse && iscell(F) && (islogical(recurse) || (recurse>1)))
    if ~islogical(recurse)
        recurse = recurse - 1;
    elseif isequal(F,C) % Stop infinite recursion if nothing changes
        return;
    end
    [F,nlevels] = sbsense.utils.flattencell(F, recurse, nlevels);
else
    F = C;
end
end

% c1 = {randi(1,2), {randi(2,2),randi(2,2),{randi(3,2),randi(3,2),{randi(4,2),randi(4,2)},{randi(4,2),randi(4,2)},randi(3,2),randi(3,2)}, {randi(3,2),{randi(4,2),{randi(5,2),{randi(6,2),randi(6,2)},randi(5,2)},randi(4,2)},randi(3,2),randi(3,2)},randi(2,2)},randi(1,2),randi(1,2),randi(1,2)};
% c2 = [c1{:}];
% c3 = [c2{:}]; % Not the same as c3=c2{:};
% c4 = [c3{:}];
% c5 = [c4{:}];
% c6 = [c5{:}]; % Class of c6  is 'cell'   ( 1 x 24)
% c7a= [c6{:}]; % Class of c7a is 'double' ( 2 x 48)
% c7 = [c6(:)]; % Class of c7  is 'cell'   (24 x  1)
% c8 = [c7{:}]; % Equal to c7a

% c1 = {randi(1,2), {randi(2,2),randi(2,2),{randi(3,2,3),randi(3,2,3),{randi(4,4),randi(4,4)},{randi(4,2),randi(4,2)},randi(3,2),randi(3,2)}, {randi(3,2),{randi(4,2),{randi(5,2),{randi(6,2),randi(6,2)},randi(5,2)},randi(4,2)},randi(3,2),randi(3,2)},randi(2,2)},randi(1,2),randi(1,2),randi(1,2)};
% c2 = [c1{:}];
% c3 = [c2{:}]; % Not the same as c3=c2{:};
% c4 = [c3{:}];
% c5 = [c4{:}];
% c6 = [c5{:}]; % Class of c6  is 'cell'   ( 1 x 24)
% c7a= [c6{:}]; % Class of c7a is 'double' ( 2 x 48)
% c7 = [c6(:)]; % Class of c7  is 'cell'   (24 x  1)
% c8 = [c7{:}]; % Equal to c7a