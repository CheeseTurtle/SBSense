function syncXAxisLabels(app, varargin)
    if bitget(nargin,2)
        lims = varargin{1};
    else
        lims = app.HgtAxes.XLim;
    end
    if isnumeric(lims(1)) % Index
        if ~isequal(app.FPXAxisLeftLabel.UserData, lims(1))
            app.FPXAxisLeftLabel.Text = sprintf('%u', lims(1));
            app.FPXAxisLeftLabel.UserData = lims(1);
        end
        if ~isequal(app.FPXAxisRightLabel.UserData, lims(2))
            app.FPXAxisRightLabel.Text = sprintf('%u', lims(2));
            app.FPXAxisRightLabel.UserData = lims(2);
        end
    elseif isdatetime(lims(1)) % Abs time
        if ~isequal(app.FPXAxisLeftLabel.UserData, lims(1))
            app.FPXAxisLeftLabel.Text = formatTimeLabel('HH', lims(1));
            app.FPXAxisLeftLabel.UserData = lims(1);
        end
        if ~isequal(app.FPXAxisRightLabel.UserData, lims(2))
            app.FPXAxisRightLabel.Text = formatTimeLabel('HH', lims(2));
            app.FPXAxisRightLabel.UserData = lims(2);
        end
    elseif isduration(lims(1)) % Rel time
        if ~isequal(app.FPXAxisLeftLabel.UserData, lims(1))
            app.FPXAxisLeftLabel.Text = formatTimeLabel('hh', lims(1));
            app.FPXAxisLeftLabel.UserData = lims(1);
        end
        if ~isequal(app.FPXAxisRightLabel.UserData, lims(2))
            app.FPXAxisRightLabel.Text = formatTimeLabel('hh', lims(2));
            app.FPXAxisRightLabel.UserData = lims(2);
        end
    else
        error('[syncXAxisLabels] Unknown x-limit datatype "%s".', class(lims));
    end
end

function labelText = formatTimeLabel(hourFmt, t)
    labelText = string(t, [hourFmt ':mm:ss.SSSS']);
end