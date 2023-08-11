function populateVFormatsDropdown(app, currDeviceName)
if isempty(currDeviceName) || isequal(currDeviceName,'(none)')% || isempty(currDeviceInfo) ...
    % || ~isa(app.vobj, 'videoinput') || ~isvalid(app.vobj)
    fprintf('[populateVFormatsDropdown] Current device is "(none)", so formats dropdown cannot be populated.\n');
    set(app.VInputResolutionDropdown, 'Items', {}, ...
        'ItemsData', {}, 'Enable', false);
    app.hasCamera = false;
else
    inf = imaqhwinfo(app.vobj);
    inf = imaqhwinfo(inf.AdaptorName, app.vobj.DeviceID);
    set(app.VInputResolutionDropdown, ...
        'Items', inf.SupportedFormats, ...
        'Enable', true); % inf.DefaultFormat);
    %fprintf('Setting format dropdown value to "%s".\n', ...
    %    app.vobj.VideoFormat);
    set(app.VInputResolutionDropdown, ...
        'Value', app.vobj.VideoFormat);
    fprintf('[populateVFormatsDropdown] Populated video formats dropdown.\n');
    %fprintf('Set format dropdown value to "%s".\n', ...
    %    app.vobj.VideoFormat);
    %fprintf('Setting source default settings.\n');
    setSourceDefaultSettings(app,true);
    fprintf('[populateVFormatsDropdown] Set source default settings.\n');
    %fprintf('Applying vsrc settings to vdev.\n');
    %applyVideoSourceSettings(app,true);
end
end