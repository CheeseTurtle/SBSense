function postclick_PSZrect(app, src, event)
    if ~app.IPPanelActive
        app.IPPanelActive = true;
    end
    if app.IPPlotSelection ~= (src.Tag - 48)
        app.IPPlotSelection = src.Tag - 48;
    elseif ~src.Selected
        set(app.IPzoneRects, 'Selected', false);
        src.Selected = true;
        % TODO: ctrl to deselect?
    end
end