function postset_PreviewActive(app, ~, ~)
%fprintf('[postset_PreviewActive] value: %d.\n', ...
%    uint8(app.PreviewActive));
% TODO: Temporarily components?
if app.PreviewActive
    try
        % Assume component visibility is already handled??
        if isempty(app.vobj) || ~isa(app.vobj, 'videoinput')
            populateVInputDeviceDropdown(app);
            app.PreviewActive = false; 
        elseif isvalid(app.vobj)
            % START PREVIEW
            if ~isrunning(app.vobj)
                fprintf('[postset_PreviewActive] Calling start(app.vobj).\n');
                start(app.vobj);
                %if ~app.BGPreviewSwitch.Value
                    app.BGPreviewSwitch.Value = true;
                %end
            else
                fprintf('[postset_PreviewActive] app.vobj is already running!\n');
            end
            set(app.CropLines, 'Visible', false);
            %if ~get(app.vobj,'FramesAcquiredFcnCount') && (app.vobj.TriggerType=="manual")% Not using the timer
            %    trigger(app.vobj);
            %end
            % app.liveimg.Visible = true;
            % Visibility happens in the start fcn of the video
            % object
            app.CaptureBGButton.Enable = true;
        else
            % delete(app.vobj);
            populateVInputDeviceDropdown(app);
            app.PreviewActive = false;
            app.CaptureBGButton.Enable = false;
        end
    catch ME
        fprintf('[postset_PreviewActive] Encountered error "%s" while activating preview: %s\n', ...
            ME.identifier, getReport(ME));
        populateVInputDeviceDropdown(app);
    end
else
    if ~isempty(app.vobj) && isa(app.vobj, 'videoinput') ...
        && isvalid(app.vobj) && isrunning(app.vobj)
        stop(app.vobj); % TODO: Try/catch?
    end

    app.BGPreviewSwitch.Value = false;
    app.CaptureBGButton.Enable = false;
    
    if app.hasBG % STOP PREVIEW / SHOW BACKGROUND
        fprintf('[postset_PreviewActive] hasBG is true, so showing background.\n');
        set(app.liveimg, 'CData', app.RefImage);
        restorePreviewOrder(app);
        % TODO: Here we assume the ref image is the same size as the live preview images.
    else % STOP PREVIEW / HIDE IMG
        fprintf('[postset_PreviewActive] hasBG is false, so hiding image.\n');
        % app.liveimg.Visible = false;
    end
    app.liveimg.Visible = app.hasBG;
    set(app.CropLines, 'Visible', app.hasBG);
end
end