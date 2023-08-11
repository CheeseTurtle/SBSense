function enablePhaseI(app, varargin)
    if nargin==1
        val = true;
    else
        val = varargin{1};
    end
    %set([app.VInputDeviceDropdown app.VInputResolutionDropdown ...
    %    app.RefExposureSpinner app.RefExposureCheckbox ...
    %    app.RefBrightnessSpinner app.RefBrightnessCheckbox ...
    %    app.RefGammaCheckbox app.RefGammaSpinner ...
    %    app.CaptureBGButton app.CaptureBGButtonLabel ...
    %    app.BGPreviewSwitch app.BGPreviewSwitchLabel ...
    %    app.NumChSpinner app.ChLayoutConfirmButton ...
    set([app.VInputDeviceDropdown app.VInputResolutionDropdown], ...
        'Editable', val);
    set([app.NumChSpinner app.MinYSpinner app.MaxYSpinner ...
        app.ChanDivSpins app.CropSpins], ...
        'Editable', val && app.hasBG);
    set([app.ChLayoutImportButton app.ChLayoutResetButton, ...
            app.BGPreviewSwitchLabel app.CaptureBGButtonLabel], ...
        'Enable', val);
    if val
        set([app.RefCapturePanel app.VInputSetupPanel], app.hasCamera);
        set(app.CropLines, 'InteractionsAllowed', 'translate', 'StripeColor', 'none');
    else
        set(app.CropLines, 'InteractionsAllowed', 'none', 'Selected', false, ...
            'StripeColor', 'white');
    end

    set([app.RefExposureCheckbox app.RefGammaCheckbox, ...
        app.CaptureBGButton ...
        app.RefBrightnessCheckbox app.CaptureBGButtonLabel], ...
            'Enable', val && app.hasCamera);
    
    set(app.BGPreviewSwitch, 'Enable', val && app.hasCamera && app.hasBG);

    set([app.RefExposureSpinner app.RefBrightnessSpinner ...
        app.RefGammaSpinner], ...
        'Editable', val && app.hasCamera);

    
end