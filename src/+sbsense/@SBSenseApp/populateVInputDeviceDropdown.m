function TF = populateVInputDeviceDropdown(app,currDeviceName,doreset)
arguments(Input)
    app; currDeviceName = char.empty();
    doreset = true;
end
if doreset
    imaqreset();
    currDeviceName = char.empty();
elseif isequal(currDeviceName, "(none)")
    currDeviceName = char.empty();
end

[devnames, vinputInfos] = app.getAvailableInputDevices();

if isempty(devnames)
    TF = false;
    currDeviceName = char.empty();
    devnames = {'(none)'};
    vinputInfos = { char.empty() };
else
    if isempty(currDeviceName) || ~any(cellfun(@(x) isequal(x, currDeviceName), devnames)) % ~ismember(currDeviceName, devnames)
        % TODO: Warn and disconnect if currDeviceName was
        % previously NOT empty
        TF = false;
        currDeviceName = char.empty();
    end
    devnames = [ {'(none)'} ; devnames(:) ];
    vinputInfos = [ {char.empty() } ; vinputInfos(:) ];
end
set(app.VInputDeviceDropdown, 'Items', devnames, ...
    'ItemsData', vinputInfos);
app.VInputDeviceDropdown.Value = currDeviceName;

if isempty(currDeviceName)
    % set(app.VInputDeviceDropdown, 'Items', {}, 'ItemsData', {});
    set(app.VInputResolutionDropdown, 'Items', {}, ...
        'ItemsData', {}, 'Enable', false);
    app.hasCamera = false;
    % app.BGPreviewSwitch.Value = false;
    fprintf('currDevName is false --> Disabling and hiding capture-related panels and controls.\n');
else
    populateVFormatsDropdown(app, currDeviceName);
end
end