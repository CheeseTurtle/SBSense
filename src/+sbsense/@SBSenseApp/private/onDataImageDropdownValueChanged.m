function onDataImageDropdownValueChanged(app, src, event)
    if ~app.SelectedIndex
        return; % TODO
    end

    oldCDatas = {app.liveimg.CData, app.maskimg.CData, ...
        app.liveimg.Visible, app.maskimg.Visible};
    try
        if ~isempty(showDatapointImage(app))
            if ~app.liveimg.Visible
                app.liveimg.Visible = true;
            end
            if xor(app.DI_ShowMaskToggleMenu.Checked, app.maskimg.Visible)
                app.maskimg.Visible = app.DI_ShowMaskToggleMenu.Checked;
            end
            if ~isempty(app.overimg.UserData) ...
                || updateChannelOverlayImage(app,true)
                %if event.Value(2)=='0'
                %elseif event.PreviousValue(2)=='0'
                %end
                app.overimg.Visible = ...
                    app.DI_ShowChannelsToggleMenu.Checked;
            end
            drawnow;
            return;
        end % if showDatapointImage(app) returns empty, does not return!
    catch ME
        fprintf('[onDataImageDropdownValueChanged] Error "%s": %s\n', ...
            ME.identifier, getReport(ME));
    end
    % Only reached when error occurs, or when showDatapointImage(app) returns empty
    set(app.liveimg, 'CData', oldCDatas{1}, 'Visible', oldCDatas{3});
    set(app.maskimg, 'CData', oldCDatas{2}, 'Visible', oldCDatas{4});
end