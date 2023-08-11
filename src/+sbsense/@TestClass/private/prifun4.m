function prifun4(obj,varargin)
fprintf('[prifun4] varargin:\n');
if ~nargin
    fprintf('<empty>\n');
else
    disp([ {obj} varargin ]);
end
disp(who');
prifun2(varargin{:});
prifun3(varargin{:});
end