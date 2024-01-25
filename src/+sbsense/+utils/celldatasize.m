function sz = celldatasize(c, recurse, cellsizevalue)
arguments(Input)
    c; % Cell contents
    recurse logical = false;
    cellsizevalue = [];
end
if(iscell(c))
    if(recurse)
        sz = cellfun(@(x) celldatasize(x,recurse,cellsizevalue), c, ...
            'UniformOutput', false);
        if((length(sz)==1) || all(cellfun(@(x) isequal(sz, sz{1}))))
            sz = sz{1};
        end
    else
        sz = cellsizevalue;
    end
end