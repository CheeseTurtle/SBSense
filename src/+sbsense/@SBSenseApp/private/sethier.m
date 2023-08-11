function sethier(handles,lvl,varargin)%, prop, val)
arguments(Input)
    handles;
    lvl {mustBeNumericOrLogical} = true;
end
arguments(Input,Repeating)
    varargin;
end
narginchk(3,Inf);
set(handles, varargin{:});
if islogical(lvl)
    objs = findobj(handles);
    set(objs, varargin{:});
else
    objs = handles.Children;
    while lvl > 0
        % TODO
        lvl = lvl - 1;
    end
end
% msk = arrayfun(@(x) hasbehavior(x, 'Children'), handles);
% ch = handles.Children;
% ch = get(handles, 'Children');
%ch = {handles.Children};
%chs = ch{:};

end