function showhier(handles,show,varargin)
arguments(Input)
    handles;
    show logical = true;
end
arguments(Input,Repeating)
    varargin;
end
set(findobj(handles, 'Visible', ~show, varargin{:}), ...
    'Visible', show);
end