function setSelectedIndex(app, varargin)
    if bitget(nargin,2)
        if varargin{1}
            app.SelectedIndex = varargin{1};
        else
            app.SelectedIndex = 0;
            return;
        end
    end

    updateArrowButtonState(app);
    panToIndex(app);
end