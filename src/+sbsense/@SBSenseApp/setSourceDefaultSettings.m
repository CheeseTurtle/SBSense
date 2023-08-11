function setSourceDefaultSettings(app, includeConfigurable)
arguments(Input)
    app sbsense.SBSenseApp; includeConfigurable = false;
end
%pi = propinfo(app.vsrc);
%pnames = string(fieldnames(pi));
pnames = string(properties(app.vsrc));
for pname=pnames
    switch pname
        case 'BacklightCompensation'
            val = 'off';
        case 'ColorEnable'
            val = 'on';
        case {'ExposureMode', 'FocusMode', ...
                'WhiteBalanceMode', 'IrisMode'}
            val = 'manual';
        case {'Sharpness', 'Roll', 'Tilt', 'Pan', 'Hue', ...
                'HorizontalFlip', 'VerticalFlip', 'Iris'}
            val = 0;
        case 'Contrast'
            val = 30;
            %case 'Gain'
            %    if ~includeConfigurable
            %        continue;
            %    end
            %    val = 0;
        case 'Saturation'
            val = 60;
        case 'Zoom'
            pi = propinfo(app.vsrc, pname);
            val = pi.ConstraintValue(1);
        case 'WhiteBalance'
            pi = propinfo(app.vsrc, pname);
            val = pi.ConstraintValue(2);
        case 'Gamma'
            if ~includeConfigurable
                continue;
            end
            val = 72;
            app.RefGammaSpinner.Value = val;
        case 'Brightness'
            if ~includeConfigurable
                continue;
            end
            pi = propinfo(app.vsrc, pname);
            val = max(-100, pi.ConstraintValue(1));
            app.RefBrightnessSpinner.Value = val;
        case 'Exposure'
            if ~includeConfigurable
                continue;
            end
            val = -7;
            app.RefExposureSpinner.Value = val;
        otherwise
            continue;
    end
    set(app.vsrc, pname, val);
end
if includeConfigurable
    app.RefCaptureSyncLamp.Color = 'red';
end
end