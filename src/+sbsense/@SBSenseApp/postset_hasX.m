function postset_hasX(app, src, ~)
arguments(Input)
    app sbsense.SBSenseApp;
    src meta.property;
    ~; %eventData event.EventData;
end
fprintf('[postset_hasX] % 9s = %d. [hasBG: %d, hasCamera: %d].\n', ...
    src.Name, uint8(app.(src.Name)), ...
    uint8(app.hasBG), uint8(app.hasCamera));
sn4 = src.Name(4);
switch bitor(bitshift(uint8(app.hasCamera),1), uint8(app.hasBG))
    case 1 %     hasBG, ~hasCamera
        fprintf('[postset_hasX] hasBG, ~hasCamera --> Showing img and axes and enabling switch and setting to false.\n');
        if sn4=='C'
            app.PreviewActive = false;
        end
        set([ app.liveimg, app.PreviewAxes ], 'Visible', true);
        % app.liveimg.AlphaData = 1; % Set when setting
        % ReferenceImage
        set(app.BGPreviewSwitch, 'Enable', false, ...
            'Value',  false);
        % app.BGPreviewSwitch.Value = false;
        % Assume resolution variables have already been set,
        % since hasBG is set to true from the
        % set.ReferenceImage function --but this function
        % won't be invoked if hasBG was already true,
        % even if the resolution changed (loaded image, etc)
    case 2 %    ~hasBG,  hasCamera
        fprintf('[postset_hasX] ~hasBG, hasCamera --> Showing axes, enabling switch and setting to true, and setting PreviewActive=true.\n');
        app.PreviewActive = true;
        set(app.PreviewAxes, 'Visible', true);
        %set(app.BGPreviewSwitch, 'Enable', false, ...
        %    'Value', true);
        app.BGPreviewSwitch.Value = true;
        
        % set(app.BGPreviewSwitch, 'Value', true);
        % startPreview(app);
    case 3 %     hasBG,  hasCamera
        fprintf('[postset_hasX] hasBG, hasCamera --> Enabling switch.\n');
        % set([ app.BGPreviewSwitch ], 'Enable', true);
    otherwise % ~hasBG, ~hasCamera
        fprintf('[postset_hasX] ~hasBG, ~hasCamera --> Disabling switch, hiding axes and image.\n');
        % set([ app.BGPreviewSwitch ], 'Enable', false);
        if sn4=='C'
            fprintf('[postset_hasX] hasBG, ~hasCamera (contd) --> Setting PreviewActive=false since hasCamera=false is what triggered this callback.\n');
            app.PreviewActive = false;
        end
        set([ app.liveimg, app.PreviewAxes ], 'Visible', false);
end

% h a s B G
% h a s C a m e r a
if (sn4=='C') % hasCamera was set
    %set(app.PreviewAxesGridPanel, 'Enable', false);
    %set([app.PreviewAxes, app.PreviewAxesGrid, ...
    %    app.PreviewAxesGridPanel], 'Visible', false);
    fprintf('[postset_hasX] src=hasCamera --> Enabling capture-related controls.\n');
    set([app.RefCapturePanel, app.CaptureBGButton, ...
        app.BGPreviewSwitch, app.RefExposureCheckbox ...
        app.RefCaptureSyncLamp, app.RefCaptureSyncLabel, ...
        app.RefExposureSpinner, app.RefBrightnessSpinner, ...
        app.RefGammaSpinner, app.RefBrightnessCheckbox, ...
        app.RefGammaCheckbox], 'Enable', app.hasCamera);
else % hasBG was set
    fprintf('[postset_hasX] src=hasBG --> Enabling export button and export menu item.\n');
    set([app.ExportBGButton, app.ExportReferenceImageMenu], ...
        'Enable', app.hasBG);
end

%if src.Name=="hasBG"
set([app.CropRangePanel app.ChLayoutPanel app.ExportBGButton ...
    app.ExportReferenceImageMenu], 'Enable', app.hasBG);
%elseif src.Name=="hasCamera"
set([app.BGPreviewSwitch app.CaptureBGButtonLabel app.CaptureBGButton ...
app.RefCapturePanel], 'Enable', app.hasCamera);
%end
end