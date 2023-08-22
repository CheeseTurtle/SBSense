function postmove_PSZrect(app, src, varargin)
    idx = src.Tag - 48;
    %if app.IPPlotSelection ~= idx
    %    app.IPPlotSelecton = idx;
    % set(app.IPzoneRects(1,ishghandle(app.IPzoneRects) & (app.IPzoneRects ~= src)) , 'Selected', false);
    %    src.Selected = true;
    %end
    % display([app.IPzoneRects.Selected]);

    xext = fix(2\(src.Position(3)-1));
    xpos = fix(src.Position(1)) + xext;
    
    % app.DataTable{1}{app.SelectedIndex, 'PSZP'}(idx) = xpos;
    % app.DataTable{2}{app.SelectedIndex, 'PSZP'}(idx) = xpos;

    %app.AnalysisParams.PSZLocations(idx, :) = [fix(src.Position(1)), xpos+xext];
    newVal = [fix(src.Position(1)), xpos+xext];
    if isempty(newVal) || anynan(newVal)
        newVal = [NaN NaN];
    end
    app.AnalysisParams.PSZLocations(:, idx) = newVal;
    if ~isequal(size(app.AnalysisParams.PSZLocations), [2 app.NumChannels])
        fprintf('[postmove_PSZrect] Size of PSZLocations is not correct.\n');
        disp(app.AnalysisParams.PSZLocations);
    end
    
    setChunkTableItem(app, [], 'PSZL1', idx, xpos);
    % app.ReanalyzeButton.Enable = true;
end