function onDatapointIndexFieldChanged(app, ~, event)
    if isempty(event.Value) || all(event.Value=='0') || ~app.LargestIndexReceived
        app.SelectedIndex = 0;
    %elseif event.Value=='0'
    %    src.Value = '1';
    %elseif ~app.LargestIndexReceived
    %    % app.SelectedIndex = 0;
    %    src.Value = '';
    else
        % app.SelectedIndex = min(max(1, str2double(event.Value)), app.LargestIndexReceived);
        app.SelectedIndex = max(0,str2double(event.Value));
        panToIndex(app, 0, app.SelectedIndex, 2);
        %src.Value = num2str(numericValue, '%u')     
        if app.FPSelPatches(1).Visible
            app.FPSelPatches(1).YData = ...
                app.HgtAxes.YLim([1 1 2 2]);
        end
        if app.FPSelPatches(2).Visible
            app.FPSelPatches(2).YData = ...
                app.PosAxes.YLim([1 1 2 2]);
        end
    end
end