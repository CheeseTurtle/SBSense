function prifun4(obj,varargin)
    fprintf('[prifun4 outside of private folder] Calling method in private folder.\n');
    disp(who()');
    % obj.prifun4(varargin{:}); % Infinite recursion
    prifun4(obj,varargin{:});
end