function modifyPreviewSwitchTrueability(app,TF)
if TF==app.BGPreviewSwitch.Value
    return;
end
if TF % On is enabled, currently off
    if ~app.hasBG
        app.BGPreviewSwitch.Value = true; % Or use a prop to trigger other stuff too?
        if isa(app.vobj, 'videoinput') && isvalid(app.vobj)
            if ~isrunning(app.vobj)
                changeFrameRate(app, app.PreviewFramerate);
                start(app.vobj);
            end
            if ... %~app.vobj.Logging &&
                    (app.vobj.TriggerType=="manual") && ...
                    ~get(app.vobj,'FramesAcquiredFcnCount')
                fprintf('[modifyPreviewSwitchTrueability] trigger\n');
                trigger(app.vobj);
            end
        end % TODO: else warn?
    end
else% On is disabled, but currently on!
    app.BGPreviewSwitch.Value = false;
    if app.hasBG
        app.liveimg.CData = app.RefImage;
        drawnow limitrate;
    else % No BG to show, but live preview is also not available
        % TODO: fprintf
        app.liveimg.Visible = false;
    end
end
end