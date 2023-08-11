function enablehier(handles,enable,varargin)
arguments(Input)
    handles;
    enable logical = true;
end
arguments(Input,Repeating)
    varargin;
end
set(findobj(handles, 'Enable', enable, varargin{:}), ...
    'Enable', enable);
end