function [F,nlevels] = collapsecell(C, recurse, forceCollapse, dimCheck, nlevels)
arguments(Input)
    C cell;
    recurse {mustBeNumericOrLogical} = true;
    forceCollapse logical = true;
    dimCheck logical = false;
    %nocheck logical = false; % Don't check whether C is cell
    nlevels uint8 = 0;
end
arguments(Output)
    F;
    nlevels (1,1) uint8; % TODO: What type?
end
%if(~nocheck && ~iscell(C))
%    F = C;
%    return;
%end

chk = cellfun(@iscell, C, 'UniformOutput', true);
if((forceCollapse && iscell(C)) || any(chk))
    dims = cellfun(@size, C(~chk), 'UniformOutput', false);
    %dims = {dims, cellfun(@size, C(chk), 'UniformOutput', false)};
    %dims = [dims{:}];
    if(length(dims) > 1)
        comp = cellfun(@(x) isequal(dims{1}, x), dims(2:end), ...
            'UniformOutput',true);
    elseif any(chk)
        comp = true;
    else
        F = C;
        return;
    end
%elseif forceCollapse
%    comp = false;
else
    F = C;
    return;
end

if all(comp) && any(chk)
    fprintf('Collapsing.\n');
    F = [C{:}];
else
    %disp(dims);
    %disp(comp);
    nds = cellfun(@ndims, C(~chk), 'UniformOutput', true);
    minCommonDim = min(nds);%, [], "all");
    msk = (nds==minCommonDim);
    if(minCommonDim == 0)
        F = C;
        F(msk) = [];
        %C(msk) = [];
        %F = C; % TODO: Remove cell elements without copy-assigning?
    else
        Cnoncell = C(~chk);
        dim = size(Cnoncell{1}, minCommonDim);
        if(dimCheck && any(cellfun(@(x) size(x,minCommonDim) ~= dim, Cnoncell(2:end))))
            F = C;
            return;
        end
        %maxCommonDim = max(nds);
        %if(maxCommonDim ~= minCommonDim)
        %    C(~msk) = cellfun(@(x) flattencell_rearr(minCommonDim,x), C(~msk), 'UniformOutput', false);
        %end
        %disp(minCommonDim);
        %disp(C);
        try
            F = cat(minCommonDim, C{:});
        catch ME
            fprintf('mCD: %d\n', minCommonDim);
            fprintf('Error (%s): %s', ME.identifier, ME.message);
            % F = cat(1, C{:});
            rethrow(ME);
        end
    end
end
nlevels = nlevels + 1;
disp({recurse, iscell(F), islogical(recurse), (~isnumeric(recurse) || (recurse>1))});
%disp('Recurse: %d, iscell(F): %d, (islogical(recurse) || (recurse>1)): (%d || %d)\n', ...
%    uint8(recurse), uint8(iscell(F)), uint8(islogical(recurse)), uint8(~isnumeric(recurse) || (recurse>1)));
if(recurse && iscell(F) && (islogical(recurse) || (recurse>1)))
    if isnumeric(recurse)
        recurse = recurse - 1;
    elseif isequal(F,C) % Stop infinite recursion if nothing changes
        fprintf('Nothing changed.\n');
        return;
    end
    fprintf('Going again...\n');
    [F,nlevels] = collapsecell(F, recurse, forceCollapse, dimCheck, nlevels);
else
    %F = C;
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


% collapsecell({randi(2,2),randi(2,2),{randi(3,2),randi(3,2),{randi(4,2),randi(4,2)},{randi(4,2),randi(4,2)},randi(3,2),randi(3,2,10)}})
% collapsecell({randi(2,2),randi(2,2),{randi(2,2),randi(2,2),{randi(2,2),randi(2,2)},{randi(2,2),randi(2,2)},randi(2,2),randi(3,10,2)}})

% collapsecell({randi(2,2,2,2),randi(2,2,2,2),{randi(3,2,2,2),randi(3,2,2,2),{randi(4,2,2,2),randi(4,2,2,2)},{randi(4,2,2,2),randi(4,2,2,2)},randi(3,2,2,2),randi(3,2,2,2)}})
% collapsecell({randi(2,2,2,2),randi(2,2,2,2),{randi(3,2,2,2),randi(3,2,2,2),{randi(4,2,2,2),randi(4,2,2,2)},{randi(4,2,2,2),randi(4,2,2,2)},randi(3,2,2,2),randi(3,2,2,3)}})
% collapsecell({randi(2,2,2,1),randi(2,2,2,1),{randi(3,2,2,1),randi(3,2,2,1),{randi(4,2,2,1),randi(4,2,2,1)},{randi(4,2,2,1),randi(4,2,2,1)},randi(3,2,2,1),randi(3,2,2,2)}})
