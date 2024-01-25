function onXNavSliderMove(app, src, event)
persistent snappedVal lastSnappedVal pv oldCallbackVals rightmostPos maxIdxOrRelTime minDomWd;
if isempty(src)
    pv = false;
    return;
else
    cancel(src.UserData);
end
% if nargin==1
%     %iptremovecallback(app.UIFigure, 'WindowButtonUpFcn', cbID);
%     %clear cbID;
%     % mouseDown = false;
%     changing = false;
%     src = app.XNavSlider;
%     % clear cbID;
% else
%     src = varargin{1};
try
    changing = (event.EventName(end) == 'g'); %|| isa(event, 'matlab.ui.eventdata.ValueChangingData')
catch ME
    display(event);
    rethrow(ME);
end
% end
import sbsense.utils.fdt;

try
    if changing % VALUECHANGING
        if ~pv
            if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
                % try
                %     if ~issortedrows(app.DataTable{2}, 'RelTime')
                %         app.DataTable{2} = sortrows(app.DataTable{2}, 'RelTime');
                %     end
                % catch ME
                %     fprintf('[onXNavSliderMove] Error "%s" encountered while trying to sort the timetable: %s\n', ...
                %         ME.identifier, getReport(ME));
                % end
                %fprintf('[FPXModeDropdownChanged] Time mode\n');
                maxIdxOrRelTime = app.LatestTimeReceived;
                % fprintf('[onXNavSliderMove] maxIdxOrRelTime: %s\n', string(maxIdxOrRelTime));
                rightmostPos = maxIdxOrRelTime - mod(maxIdxOrRelTime, app.XResUnitVals{app.XAxisModeIndex, 2});
                if ~bitget(app.XAxisModeIndex, 1) % Absolute time
                    rightmostPos = rightmostPos + app.TimeZero;
                end
                
                minDomWd = 2*seconds(pow2(app.XResTimeMinorTicks(1))); % NOTE: this is a duration!!
            else % Index mode
                %fprintf('[FPXModeDropdownChanged] Index mode\n');
                maxIdxOrRelTime = app.LargestIndexReceived;
                rightmostPos = maxIdxOrRelTime - mod(maxIdxOrRelTime, app.XResUnitVals{app.XAxisModeIndex, 2});
                minDomWd = 2*max(1, uint64(pow2(app.XResFPHsMinorTicks(1))));
                % try
                %     if ~issortedrows(app.DataTable{1}, 'Index')
                %         app.DataTable{1} = sortrows(app.DataTable{1}, 'Index');
                %     end
                % catch ME
                %     fprintf('[onXNavSliderMove] Error "%s" encountered while trying to sort the data table: %s\n', ...
                %         ME.identifier, getReport(ME));
                %     % app.XNavSlider.Enable = true;
                % end
            end

            % sliEnab = src.Enable;
            cancel(src.UserData);
            set([app.FPXModeDropdown app.LockRangeButton ...
                app.LockLeftButton app.LockRightButton app.XResKnob], 'Enable', 'off');
            set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'TickValues', [], 'TickLabels', '');
            %set(app.XNavSlider, 'MajorTicks', []);%, 'MajorTickLabels', '');
            drawnow nocallbacks;
            if app.PlotTimer.Running(2)=='n'
                stop(app.PlotTimer);
                if ~isempty(app.PlotTimer.UserData)
                    cancel(app.PlotTimer.UserData);
                end
            elseif ~isempty(app.PlotTimer.UserData)
                wait(app.PlotTimer.UserData);
            end
            src.UserData = parallel.Future.empty();
            oldCallbackVals = [ app.AxisLimitsCallbackCalculatesPage ...
                app.AxisLimitsCallbackCalculatesTicks ];
            app.AxisLimitsCallbackCalculatesPage = true;
            app.AxisLimitsCallbackCalculatesTicks = false;
            % TODO: Also disable fields and nav buttons...
            pv = true;
            %if ~isempty(cbID)
            %    iptremovecallback(app.UIFigure, 'WindowButtonUpFcn', cbID);
            %end
            %cbID = iptaddcallback(app.UIFigure, 'WindowButtonUpFcn', @(varargin) onXNavSliderMove(app));
        end
        %if ~mouseDown
        %    mouseDown = true;
        %end
        %display(event);
        %display(class(event.Value));
        %display(event.Value);
        %display(src.MinorTicks);
        %display(src.SnapTicks);

        if ~isempty(src.SnapTicks)
            snappedVal = interp1(src.SnapTicks, src.SnapTicks, event.Value, ...
                'nearest', 'extrap');
        elseif ~isempty(src.MinorTicks)
            snappedVal = interp1(src.MinorTicks, src.MinorTicks, event.Value, ...
                'nearest', 'extrap');
        else
            snappedVal = interp1(src.MajorTicks, src.MajorTicks, event.Value, ...
                'nearest', 'extrap');
        end

        if ~isequal(lastSnappedVal, snappedVal)
            %             if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
            %                 rightmostPos = app.LatestTimeReceived;
            %                 if ~bitget(newModeIndex, 1) % Absolute time
            %                     rightmostPos = rightmostPos + app.TimeZero;
            %                 end
            %                 minDomWd = seconds(pow2(app.XResTimeMinorTicks(1)));
            %             else % Index mode
            %                 %fprintf('[FPXModeDropdownChanged] Index mode\n');
            %                 rightmostPos = app.LargestIndexReceived;
            %                 minDomWd = pow2(app.XResFPHsMinorTicks(1));
            %             end
            src.Tooltip = sprintf('%g', snappedVal);
            newLims = calcRulerLimsFromSliderValue(app.TimeZero, app.XAxisModeIndex, ...
                app.XNavZoomMode, minDomWd, rightmostPos, app.HgtAxes.XLim, snappedVal, false);
            % display(newLims);
            set([app.HgtAxes.XAxis app.PosAxes.XAxis], ...
                'Limits', newLims);
            %fut = parfeval(backgroundPool, @calcRulerLimsFromSliderValue, 1, ...
            %    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
            %    app.HgtAxes.XLim, snappedVal);
            %src.UserData = [fut afterEach(fut, ...
            %    @(alims) set([app.HgtAxes.XAxis, app.PosAxes.XAxis], ...
            %    'Limits', alims), 0, 'PassFuture', false)];
            lastSnappedVal = snappedVal;
            syncXFields(app);
            drawnow limitrate;
            %fut = parfeval(backgroundPool, @sbsense.SBSenseApp.navPos2AxisLims, 1, ...
            %    app.XNavZoomMode, app.XAxisModeIndex, app.TimeZero, ...
            %    pow2(app.XResKnob.Value), app.HgtAxes.XLIm, snappedVal);
            %src.UserData = [ fut, afterEach(fut, @app.applyCalculatedAxisLims, 0, 'PassFuture', true) ];
        end
        % lastRawVal = event.Value;
        %elseif ~pv % (CHANGED, but mouseup already happened)
        %    return;
        %elseif mouseDown
        %    return;
        return;
    else % (CHANGED) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % cancel(src.UserData);
        %pause(0.2);
        %fut = parfeval(backgroundPool, @pause, 0, 1);
        %src.UserData = [ fut, ...
        %    afterEach(fut, @(f) onNavSliderChanged(app, app.XNavSlider, snappedVal, f), 0, 'PassFuture', true) ];
        minWidth = 1*app.XResUnitVals{app.XAxisModeIndex,2}; % TODO
        snappedVal0 = snappedVal;

        if ~app.XNavZoomMode && (app.LargestIndexReceived>1) && ~ismissing(app.TimeZero) % was LIR>2
            switch app.XAxisModeIndex
                case 2
                    rightmostPos = app.LatestTimeReceived + app.TimeZero;
                    if isempty(minWidth)
                        minWidth = seconds(1);
                    end
                case 3
                    rightmostPos = app.LatestTimeReceived;
                    if isempty(minWidth)
                        %    minWidth = app.XResUnitVals{3,2}; % seconds(1);
                        %    if isempty(minWidth) || ~minWidth
                        minWidth = seconds(1);
                        %    end
                    end
                otherwise
                    rightmostPos = app.LargestIndexReceived;
                    if isempty(minWidth)
                        %    minWidth = app.XResUnitVals{1,2}; % 1;
                        %    if isempty(minWidth) || ~minWidth
                        minWidth = 4;
                        %    end
                    end
            end
            zoomSpan = diff(app.HgtAxes.XLim);
            if zoomSpan <= minWidth
                if ~isempty(src.MinorTicks)
                    snappedVal = src.MinorTicks(1);
                elseif ~isempty(src.SnapTicks)
                    snappedVal = src.SnapTicks(1);
                elseif ~isempty(src.MajorTicks)
                    snappedVal = src.MajorTicks(1);
                else
                    snappedVal = src.Limits(1);
                end
                fprintf('[onXNavSliderMove] zoomSpan %s <= minWidth %s ==> snappedVal = %g --> %\n', ...
                    fdt(zoomSpan), fdt(minWidth), snappedVal0, snappedVal);
                % TODOOOOOOOO
                %elseif rightmostPos < snappedVal
                %    snappedVal = rightmostPos;
            end
        end
        onNavSliderChanged(app, app.XNavSlider, snappedVal, [], oldCallbackVals);
        src.Tooltip = sprintf('(%g, %g) %g', snappedVal0, snappedVal, src.Value);
        pv = false; %#ok<NASGU>
    end
catch ME
    fprintf('[onXNavSliderMove] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
    % src.Enable = true;
    % sliEnab = true;
    % onXNavSliderMoveCleanup(app, oldCallbackVals);
    % pv = false;
    % mouseDown = false;
    %if ~isempty(cbID)
    %    iptremovecallback(app.UIFigure, 'WindowButtonUpFcn', cbID);
    %    clear cbID;
    %end
    % rethrow(ME);
end
onXNavSliderMoveCleanup(app, oldCallbackVals);
pv = false;

end

function onNavSliderChanged(app,src,snappedVal,fut,oldCallbackVals)
if ~isempty(fut) && ~isempty(fut.Error)
    fprintf('[onXNavSliderMove] Error "%s": %s\n', ...
        fut.Error.identifier, getReport(fut.Error));
    onXNavSliderMoveCleanup(app, oldCallbackVals);
    return;
    % mouseDown = false;
    %if ~isempty(cbID)
    %    iptremovecallback(app.UIFigure, 'WindowButtonUpFcn', cbID);
    %    clear cbID;
    %end
    % rethrow(ME);
end
%display(snappedVal);
%disp(class(snappedVal));
if ~isempty(src.UserData)
    wait(src.UserData);
    if ~isempty(src.UserData(end).Error)
        err = src.UserData(end).Error;
        if iscell(err)
            celldisp(err);
            err = err{1};
        end
        if isa(err, 'MException')
            fprintf('[onXNavSliderMove]:changed Error "%s": %s\n', ...
                err.identifier, ...
                getReport(err));
            %rethrow(err);
        else
            fprintf('[onXNavSliderMove]:changed Error:\n');
            disp(err);
        end
        %else % ??
        %    src.UserData = parallel.Future.empty();
    end
    src.UserData = parallel.Future.empty();
end


if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
    % try
    %     if ~issortedrows(app.DataTable{2}, 'RelTime')
    %         app.DataTable{2} = sortrows(app.DataTable{2}, 'RelTime');
    %     end
    % catch ME
    %     fprintf('[onXNavSliderMove] Error "%s" encountered while trying to sort the timetable: %s\n', ...
    %         ME.identifier, getReport(ME));
    % end
    %fprintf('[FPXModeDropdownChanged] Time mode\n');
    maxIdxOrRelTime = app.LatestTimeReceived;
    % fprintf('[onXNavSliderMove] maxIdxOrRelTime: %s\n', string(maxIdxOrRelTime));
    rightmostPos = maxIdxOrRelTime - mod(maxIdxOrRelTime, app.XResUnitVals{app.XAxisModeIndex, 2});
    if ~bitget(app.XAxisModeIndex, 1) % Absolute time
        rightmostPos = rightmostPos + app.TimeZero;
    end
%     if bitget(app.XAxisModeIndex, 1) % Absolute time
%         rightmostPos = maxIdxOrRelTime + app.TimeZero;
%         rightmostPos = rightmostPos - mod(rightmostPos-app.TimeZero, app.XResUnitVals{app.XAxisModeIndex, 2});
%         
%     else
%         rightmostPos = maxIdxOrRelTime;
%         rightmostPos = rightmostPos - mod(rightmostPos, app.XResUnitVals{app.XAxisModeIndex, 2});
%     end
    
    minDomWd = 2*seconds(pow2(app.XResTimeMinorTicks(1))); % NOTE: this is a duration!!
else % Index mode
    %fprintf('[FPXModeDropdownChanged] Index mode\n');
    maxIdxOrRelTime = app.LargestIndexReceived;
    rightmostPos = maxIdxOrRelTime - mod(maxIdxOrRelTime, app.XResUnitVals{app.XAxisModeIndex, 2});
    minDomWd = 2*max(1, uint64(pow2(app.XResFPHsMinorTicks(1))));
    % try
    %     if ~issortedrows(app.DataTable{1}, 'Index')
    %         app.DataTable{1} = sortrows(app.DataTable{1}, 'Index');
    %     end
    % catch ME
    %     fprintf('[onXNavSliderMove] Error "%s" encountered while trying to sort the data table: %s\n', ...
    %         ME.identifier, getReport(ME));
    %     % app.XNavSlider.Enable = true;
    % end
end

% newUnit = restrictResUnit(app.XAxisModeIndex, true, ...
%     pow2(app.XResKnob.MinorTicks),app.HgtAxes.XLim, ...
%     app.XResUnitVals{app.XAxisModeIndex, 1});
% When should we (re)calculate the restricted unit??
% if newUnit ~= app.XResUnitVals{app.XAxisModeIndex, 1}
%     app.XResKnob.Value = log2(newUnit);
%     app.XResUnit = newUnit;
% end

[clampLims, newSliVal] = calcRulerLimsFromSliderValue(app.TimeZero, app.XAxisModeIndex, ...
    app.XNavZoomMode, minDomWd, rightmostPos, app.HgtAxes.XLim, snappedVal, true);
% clampLims = clampDomain(app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
%    rightmostPos, minDomWd, app.HgtAxes.XLim);

newUnit = restrictResUnit(app.XAxisModeIndex, true, ...
    pow2(app.XResKnob.MinorTicks), clampLims, ...
    app.XResUnitVals{app.XAxisModeIndex, 1}, maxIdxOrRelTime);
if newUnit ~= app.XResUnitVals{app.XAxisModeIndex, 1}
    fprintf('************* RESUNIT SHOULD BE SWITCHED FROM %g to %g... *************\n', ...
        app.XResUnit, newUnit);
    % app.XResKnob.Value = log2(newUnit);
    % app.XResUnit = newUnit;
    % app.XResKnob.Tooltip = sprintf('%g', newUnit);
end

quantLims = quantizeDomain(app.TimeZero, app.XAxisModeIndex, ...
    app.XNavZoomMode, app.XResUnitVals, clampLims);

% if bitget(app.XAxisModeIndex, 2)
%     if ~bitget(app.XAxisModeIndex, 1)
%         dx = app.HgtAxes.XLim(2) - app.TimeZero;
%     else
%         dx = app.HgtAxes.XLim(2);
%     end
%     if dx > hours(2)
%         %error('dx is too large!!');
%     end
% else
%     dx = app.HgtAxes.XLim(2);
%     if dx > 2*app.LargestIndexReceived
%         %error('dx is too large!');
%     end
% end

% fprintf('[onXNavSliderMove] quantLims: %s', formattedDisplayText(quantLims));
rulerTickArgs = updateTicksA(app.TimeZero, true, ...
    app.HgtAxes.InnerPosition(3), quantLims, ...
    app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, false);

% fprintf('[onXNavSliderMove] Generated ruler ticks and labels.\n');

if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
    %maxIdxOrRelTime = app.DataTable{?}.RelTime(app.LargestIndexReceived);
    maxIdxOrRelTime = app.LatestTimeReceived;%app.DataTable{?}.Index(app.LatestTimeReceived);
else % Index mode
    maxIdxOrRelTime = app.LargestIndexReceived;
end

[sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
    app.XResUnitVals, maxIdxOrRelTime, quantLims);
% fprintf('[onXNavSliderMove] Calculated slider lims and value.\n');

% timeZero, typeIdx, pixelWidth, lims, ...
% axisModeIndex, zoomModeOn, resUnitVals, assumeChanged(, varargin)
sliTickArgs = updateTicksA(app.TimeZero, false, app.XNavSlider.InnerPosition(3), ...
    sliLims, app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, false);
%[sliMin, sliMaj, sliLabels] = generateSliderTicks( ...
%    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
%    sliLims, app.XResUnit, app.XResMajorInfo);
% fprintf('[onXNavSliderMove] Generated slider ticks and labels.\n');

%set([app.HgtAxes.XAxis app.PosAxes.XAxis], ...
%    'Limits', quantLims, 'MinorTickValues', rulerMin, ...
%    'TickValues', rulerMaj);
% app.HgtAxes.XAxis.TickLabels = rulerLabels;
%set(app.XNavSlider, 'Limits', sliLims, 'Value', sliVal, ...
%    'MinorTicks', sliMin, 'MajorTicks', sliMaj, ...
%    'MajorTickLabels', sliLabels);

fprintf('[onXNavSliderMove] @@@ SETTING RULER LIMS TO quantlims = %s\n', fdt(quantLims));
set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', quantLims);
% app, typeIdx, lims, axisModeIndex, outArgs{:}
updateTicksB(app, true, quantLims, app.XAxisModeIndex, ...
    rulerTickArgs{:});
fprintf('[onXNavSliderMove] @@@ CALLING updateTicksB for SLIDER, val / lims / enab = %g / [%g %g] / %s\n', ...
    sliVal, sliLims(1), sliLims(2), fdt(sliEnab));
updateTicksB(app, false, sliLims, app.XAxisModeIndex, ...
    sliTickArgs{:}, 'Limits', sliLims, 'Value', sliVal, 'Enable', sliEnab);

% disp({snappedVal,class(snappedVal), src.Value, src.Limits});
% display(src.Value);
% display(src.Limits);
% src.Value = snappedVal;
% src.Value = min(src.Limits(2), snappedVal);
% TODO: Check error status
% syncXFields(app); % Not needed?
% updatePaging(app);
onXNavSliderMoveCleanup(app, oldCallbackVals);
% onXNavSliderMove(app, [], []); % pv = false;
end

function onXNavSliderMoveCleanup(app, oldCallbackVals)
if isempty(oldCallbackVals)
    app.AxisLimitsCallbackCalculatesPage = true;
    app.AxisLimitsCallbackCalculatesTicks = true;
else
    app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
    app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
end
if app.IsRecording && (app.PlotTimer.Running(2)=='f')
    start(app.PlotTimer);
end
set([app.XNavSlider app.FPXModeDropdown app.LockRangeButton ...
    app.LockLeftButton app.LockRightButton app.XResKnob], 'Enable', 'on');
% drawnow limitrate nocallbacks;
%             if app.PlotQueue.QueueLength
%                 futs = processPlotQueue(app, []);
%             else
%                 futs = setXAxisModeAndResolution(app, ...
%                     pow2(app.XResKnob.Value));
%             end
%            wait(futs);
% app.AxisLimitsCallbackEnabled = true;
end
