function onFPXFieldChange(app, src, event)
    persistent lastVals;
    changing = (event.EventName(end) == 'g');
    absMode = ~bitget(app.XAxisModeIndex,1);
    timeMode = bitget(app.XAxisModeIndex,2);
    idxs = src.Tag - 48;
    if changing
        if isempty(event.Value)
            return;
        elseif isempty(lastVals)
            lastVals = { '' [] ; '' []};
        elseif isequal(event.Value, lastVals{idxs(1), idxs(2)})
            return;
        end
        if bitget(idxs(2),1) % 1st col (not 2nd col) --> (hours and) minutes field
            if absMode
                matchStr = regexp(event.Value, ... 
                    '(?:(?:(?<hour>0[0-9]?|1\d?|2[0-3]?):(?<minute>\d{0,2})?)))(?=.*$)', ...
                    'match', 'once', 'warnings');
            else
                matchStr = regexp(event.Value, ...
                    '^\d{1,5}(?=.*$)', 'match', 'once', 'warnings');
            end
            % if ~strcmp(event.Value, matchStr)
            src.Value = matchStr;
            lastVals{idxs(1), idxs(2)} = matchStr;
        else % 2nd col (not 1st col) --> secs field
            return;
        end
    else % (CHANGED)
        prevUD = app.FPXFields{idxs(1), 2}.UserData;
        prevVals = [app.FPXFields{idxs(1),1}.Value, app.FPXFields{idxs(1),2}.Value];
        prevNumericVal = app.FPXFields{idxs(1), 1}.NumericValue;
        if bitget(idxs(2),1) % 1st col (not 2nd col) --> (hours and) minutes field
            if absMode % Absolute mode
                toks = regexp(src.Value, ... 
                    '(?:(?:(?<hour>0[0-9]?|1\d?|2[0-3]?):(?<minute>[0-5][0-9]?|[6-9](?=[^\d]*$))?)))(?=.*$)', ...
                    'names', 'once', 'warnings');
                if isfield(toks, 'hour')
                    hr = str2num(toks.hour);
                else
                    hr = hour(app.TimeZero);
                end
                if isfield(toks, 'minute')
                    mn = str2num(toks.minute);
                else
                    mn = 0;
                end
                src.Value = sprintf('%02u:%02u', hr, mn);
                [y0,m0,d0] = ymd(app.TimeZero);
                src.NumericValue = datetime(y0,m0,d0,hr,mn,0);
                if src.NumericValue < app.TimeZero
                    src.NumericValue = src.NumericValue + days(1);
                end
            %elseif timeMode % relative time mode
            elseif timeMode
                src.NumericValue = minutes(num2str(src.Value));
                if src.NumericValue < app.DataTable{1}.RelTime(1)
                    src.NumericValue = app.DataTable{1}.RelTime(1);
                elseif src.NumericValue > app.LatestTimeReceived
                    src.NumericValue = app.LatestTimeReceived;
                end
                src.Value = num2str(minutes(src.NumericValue), '%u');
            else % Index mode
                src.NumericValue = fix(num2str(src.Value));
                if src.NumericValue < 1;
                    src.NumericValue = 1;
                elseif src.NumericValue > app.LargestIndexReceived
                    src.NumericValue = app.LargestIndexReceived;
                end
                src.Value = num2str(src.NumericValue, '%u');
            end
        else % 2nd col (not 1st col) --> secs field
            if event.Value >= 60
                hmField = app.FPXFields{idxs(1),1};
                % mnSurplus = mod(fix(event.Value), 60);
                mnSurplus = fix(event.Value / 60);
                hmField.NumericValue = hmField.NumericValue + minutes(mnSurplus);
                if absMode
                    hmField.Value = string(hmField.NumericValue, 'HH:mm');
                else
                    hmField.Value = num2str(minutes(hmField.NumericValue));
                end
                src.Value = event.Value - 60*mnSurplus;
            elseif event.Value < 0
                src.Value = 0;
            end
        end
    end
    
    try
        %if timeMode
            app.FPXFields{idxs(1), 2}.UserData = ...
                app.FPXFields{idxs(1),1}.NumericValue + seconds(app.FPXFields{idxs(1),2}.Value);
        %else % index mode
        %    app.FPXFields{idxs(1), 2}.UserData = ...
        %        app.FPXFields{idxs(1),1}.NumericValue;
        %        %app.DataTable{?}.RelTime(app.FPXFields{idxs(1),1});
        %end
        lims = [app.FPXFields{1,2}.UserData, app.FPXFields{2,2}.UserData];
        if timeMode
            setVisibleDomain(app, lims, false, false);
        else % Rulers are numeric, but fields are in relative time mode.
            lims = interp1(app.DataTable{2}.RelTime, app.DataTable{2}.Index, lims, 'linear', 'extrap');
            setVisibleDomain(app, lims, false, false);
    catch ME
        fprintf('[onFPXFieldChange] Error "%s": %s\n', ME.identifier, getReport(ME));
        app.FPXFields{idxs(1),2}.UserData = prevUD;
        app.FPXFields{idxs(1),2}.Value = prevVals(2);
        set(app.FPXFields{idxs(1),1}, 'Value', prevVals(1), 'NumericValue', prevNumericVal);
        % if bitget(idxs(2),1) % First column (hours/minutes/index)
        %     if absMode
        %         src.NumericValue = dateshift(prevUD, 'start', 'minute');
        %         src.Value = string(src.NumericValue, 'HH:mm');
        %     elseif timeMode
        %         src.NumericValue = dateshift(prevUD, 'start', 'minute');
        %         src.Value = num2str(minutes(src.NumericValue), '%u');
        %     else
        %         src.Value = num2str(prevUD, '%u');
        %         src.NumericValue = prevUD;
        %     end
        % else % Second column (seconds)
        %     if absMode
        %         src.Value = second(prevUD);
        %     elseif timeMode
        %         secs = seconds(prevUD);
        %         src.Value = secs - 60*fix(secs/60);
        %     else
        %         % TODO: Warn?
        %     end
        % end
        rethrow(ME);
    end
    % if bitget(idxs(1),1) % 1st row (not 2nd row) --> FPXMin
    % else % 2nd row (not 1st row) --> FPXMax
    % end
end