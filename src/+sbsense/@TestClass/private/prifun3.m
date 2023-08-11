function prifun3(varargin)
fprintf('[prifun3] varargin:\n');
if ~nargin
    fprintf('<empty>\n');
else
    disp(varargin);
end
disp(cellstr(who)');
end