function postset_LargestIndexReceived(app, ~, ~)
    persistent pv;
    % if app.LargestIndexReceived < 0
    %     % TODO: Warn??
    %     app.LargestIndexReceived = 0;
    % end
    app.NumDatapointsField.Value = double(max(0,app.LargestIndexReceived));
    if ~app.LargestIndexReceived
        app.SelectedIndex = 0;
        app.DatapointIndexField.CharacterLimits = [0 20];
        app.DatapointIndexField.Value = '';
        enableAxes = false;
        % app.propListeners(end).Enabled = false;
    else
        enableAxes = (app.SelectedIndex > 1);
    end
    %set([app.PosAxesPanel app.HgtAxesPanel ...
    %    app.FPAxesGridPanel])
    if xor(pv,enableAxes)
        set(findobj(app.FPAxesGridPanel, '-property', 'Enable'), 'Enable', ...
            enableAxes);
    end
    pv = enableAxes;
end