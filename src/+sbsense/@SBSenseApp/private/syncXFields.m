function syncXFields(app, varargin)
persistent lastLims;
if bitget(nargin,2)
    lims = varargin{1};
else
    lims = app.HgtAxes.XAxis.Limits;
end

if isequal(lastLims, lims)
    return;
end

% timeMode = bitget(app.XAxisModeIndex, 2);
% if ~timeMode
%     if lims(2) > app.LargestIndexReceived
%         lims(2) = app.LargestIndexReceived;
%         app.HgtAxes.XLim(2) = app.LargestIndexReceived;
%     end
%     lims = app.DataTable{?}.RelTime(lims);
% end
%if ~relMode % Also includes index mode (which already has been converted to rel.)
%    lims = lims - app.TimeZero;
%end

if bitget(app.XAxisModeIndex, 2) % Absolute or relative time
    relMode = bitget(app.XAxisModeIndex,1); % timeMode &&
    vals = cell(1,2);
    if ~isequal(app.FPXMinSecsField.UserData,lims(1))
        % if ~isempty(app.FPXMinField.UserData)
        %     cancel(app.FPXMinField.UserData);
        % end
        if relMode % (duration)
            numMins = fix(minutes(lims(1)));
            vals{2} = seconds(lims(1)) - 60*numMins;
            vals{1} = num2str(numMins, '%u');
        else % Absolute time (datetime)
            vals{2} = second(lims(1));
            vals{1} = string(dateshift(lims(1), 'start', 'minute'), 'HH:mm');
        end

        app.FPXMinField.Value = vals{1};
        app.FPXMinSecsField.Value = vals{2};
        app.FPXMinSecsField.UserData = lims(1);
    end

    % if ~isequal(app.FPXMaxSecsField.UserData, lims(2))
    %     % if ~isempty(app.FPXMaxField.UserData)
    %     %     cancel(app.FPXMaxField.UserData);
    %     % end
    % end
    if relMode % (duration)
        numMins = fix(minutes(lims(2)));
        vals{2} = seconds(lims(2)) - 60*numMins;
        vals{1} = num2str(numMins, '%u');
    else % Absolute time (datetime)
        vals{2} = second(lims(2));
        vals{1} = string(dateshift(lims(2), 'start', 'minute'), 'HH:mm');
    end
    %[app.FPXFields(2,:).Value] = vals{:};
    app.FPXMaxField.Value = vals{1};
    try
        app.FPXMaxSecsField.Value = vals{2};
    catch ME
        display(vals{2});
        display(app.FPXMaxSecsField.Limits);
        rethrow(ME);
    end
    app.FPXMaxSecsField.UserData = lims(2);
else % Index mode
    % lims(1) = max(lims(1), 1);
    app.FPXMinSecsField.UserData = double(lims(1));
    app.FPXMaxSecsField.UserData = double(lims(2));
    app.FPXMinField.Value = num2str(lims(1), '%u');
    app.FPXMaxField.Value = num2str(lims(2), '%u');
end
lastLims = lims;
end