function postdelete_PSZrect(app, src, event) %#ok<INUSD>
    idx = src.Tag - 48;
    
    % app.DataTable{1}{app.SelectedIndex, 'PSZW'}(idx) = NaN;
    % app.DataTable{2}{app.SelectedIndex, 'PSZW'}(idx) = NaN;

    app.AnalysisParams.PSZLocations(:, idx) = NaN;
    setChunkTableItem(app, [], 'PSZL1', app.IPPlotSelection, 0);


%     app.IPzoneRects(1,idx) = copyobj(src, src.Parent);
%     set(app.IPzoneRects(1,idx), 'Visible', false);
%     addlistener(app.IPzoneRects(1,idx), 'ROIMoved', @app.postmove_PSZrect);
%     % addlistener(app.IPzoneRects(1,idx), 'MovingROI', @app.postmove_PSZrect);
%     addlistener(app.IPzoneRects(1,idx), 'ROIClicked', @app.postclick_PSZrect);
%     addlistener(app.IPzoneRects(1,idx), 'DeletingROI', @app.postdelete_PSZrect);
end