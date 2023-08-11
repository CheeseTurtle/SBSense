% Callback function: XResKnob, XResKnob
function XResKnobValueChange(app, varargin)
if nargin==2
    event = varargin{1};
    src = event.Source;
else
    [src, event] = varargin{:};
end
%display(event);
% value = app.XResKnob.Value;
changing = (event.EventName(end) == 'g'); % || isa(event, 'matlab.ui.eventdata.ValueChangingData');
persistent sliEnab lastRawVal snappedVal lastSnappedVal pv snappedUnit minResUnit oldCallbackVals;
try
    if changing
        if ~pv
            sliEnab = app.XNavSlider.Enable;
            oldCallbackVals = [ app.AxisLimitsCallbackCalculatesPage ...
                app.AxisLimitsCallbackCalculatesTicks ];
            app.AxisLimitsCallbackCalculatesPage = false;
            app.AxisLimitsCallbackCalculatesTicks = false;
            set([app.XNavSlider app.FPXModeDropdown ...
                app.LockRangeButton app.LockLeftButton ...
                app.LockRightButton ], 'Enable', false);
            set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'TickValues', []);
            % if ~isempty(app.XNavSlider.MajorTicks)
            %     set(app.XNavSlider, 'MajorTickLabels', app.XNavSlider.MajorTickLabels([1 end]), ...
            %         'MajorTicks', app.XNavSlider.MajorTicks([1 end]));
            % end
            domSpan = diff(app.HgtAxes.XLim);
            if isduration(domSpan)
                domSpan = seconds(domSpan);
            end
            minResUnit = domSpan/(5\app.HgtAxes.InnerPosition(3));
            pv = true;
        end
        if isempty(minResUnit)
            domSpan = diff(app.HgtAxes.XLim);
            if isduration(domSpan)
                domSpan = seconds(domSpan);
            end
            minResUnit = domSpan/(5\app.HgtAxes.InnerPosition(3));
        end
        ticks = src.MinorTicks;
        
        if (~isequal(lastRawVal, event.Value))
            snappedVal = interp1(ticks, ticks, event.Value, ...
                'nearest', 'extrap');
            if ~isequal(snappedVal, lastSnappedVal)
                snappedUnit = pow2(snappedVal);
                if snappedUnit >= minResUnit
                    % app, typeIdx, lims, axisModeIndex,
                    % ... zoomModeOn, resUnitVals, assumeChanged(, varargin)
                     if bitget(app.XAxisModeIndex,2) % time mode
                         updateTicks(app, true, app.HgtAxes.XLim, ...
                             app.XAxisModeIndex, app.XNavZoomMode, ...
                             seconds(snappedUnit), true, false); % Don't generate major ticks
                    else % index mode
                        updateTicks(app, true, app.HgtAxes.XLim, ...
                            app.XAxisModeIndex, app.XNavZoomMode, ...
                            snappedUnit, true, false); % Don't generate major ticks
                    end
                        %set([app.HgtAxes.XAxis app.PosAxes.XAxis], ...
                    %    'MinorTickValues', generateRulerTicks( ...
                    %    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
                    %    app.HgtAxes.XLim, snappedUnit, []));
                    drawnow limitrate;
                else
                    % fprintf('[XResKnobValueChange] Too small of resUnit. (%0.4g<%0.4g)\n', ...
                    %     snappedUnit, minResUnit);
                    set([app.HgtAxes.XAxis app.PosAxes.XAxis], ...
                        'MinorTickValues', []); 
                    % Previously only assigned to HgtAxes ruler (asssumed
                    % linkprop?)
                end
                lastSnappedVal = snappedVal;
            end
            lastRawVal = event.Value;
        end
        return;
    else % (CHANGED)
        if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
            maxIdxOrRelTime = app.LatestTimeReceived;
            rightmostPos = maxIdxOrRelTime;
            if ~bitget(app.XAxisModeIndex, 1) % Absolute time
                rightmostPos = rightmostPos + app.TimeZero;
            end
        else % Index mode
            maxIdxOrRelTime = app.LargestIndexReceived;
            rightmostPos = maxIdxOrRelTime;
        end

        try
            newUnit = restrictResUnit(app.XAxisModeIndex, false, pow2(src.MinorTicks), ...
                app.XNavSlider.Limits, snappedUnit, app.HgtAxes.XLim, maxIdxOrRelTime);
            set(src, 'Value', log2(newUnit));
            snappedUnit = newUnit;
        catch ME
            fprintf('[XResKnobValueChanged] Error when calling restrictResUnit: %s\n', getReport(ME));
            src.Value = snappedVal;
        end
        
        newMajorInfo = generateMajorUnitInfo(app.XAxisModeIndex, snappedUnit);
        
        if ~isempty(app.PlotTimer.UserData) % && app.IsRecording
            wait(app.PlotTimer.UserData);
        end
        
        lims0 = [app.HgtAxes.XLim(1), min(app.HgtAxes.XLim(2), rightmostPos)];
        rulLims = quantizeDomain(app.TimeZero, app.XAxisModeIndex, ...
            app.XNavZoomMode, snappedUnit, lims0);
        rulerTickArgs = updateTicksA(app.TimeZero, true, ...
            app.HgtAxes.InnerPosition(3), rulLims, ...
            app.XAxisModeIndex, app.XNavZoomMode, snappedUnit, true);
        %display(lims0);
        %[rulMin,rulMaj,rulLabels] = generateRulerTicks( ...
        %    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
        %    rulLims, snappedUnit, newMajorInfo);
        
        [sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
            app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
            snappedUnit, maxIdxOrRelTime, rulLims);
        sliTickArgs = updateTicksA(app.TimeZero, false, ...
            app.XNavSlider.InnerPosition(3), sliLims, ...
            app.XAxisModeIndex, app.XNavZoomMode, snappedUnit, true);
        %[sliMin, sliMaj, sliLabels] = generateSliderTicks( ...
        %    app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, sliLims, ...
        %    snappedUnit, newMajorInfo);
        
        % set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', rulLims, ...
        %     'MinorTickValues', rulMin, 'TickValues', rulMaj);
        % set(app.HgtAxes.XAxis, 'TickLabels', rulLabels);
        % app.PosAxes.TickLabels = '';
        % set(app.XNavSlider, 'Limits', sliLims, 'Value', sliVal, ...
        %     'MinorTicks', sliMin, 'MajorTicks', sliMaj, ...
        %     'MajorTickLabels', sliLabels);

        fprintf('[onXNavSliderMove] @@@ SETTING RULER LIMS TO rulLims = %s\n', fdt(rulLims));
        set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', rulLims);
        updateTicksB(app, true, rulLims, app.XAxisModeIndex, ...
            rulerTickArgs{:});
        fprintf('[onXNavSliderMove] @@@ CALLING updateTicksB for SLIDER, val / lims / enab = %g / [%g %g] / %s\n', ...
            sliVal, sliLims(1), sliLims(2), fdt(sliEnab));
        updateTicksB(app, false, sliLims, app.XAxisModeIndex, ...
            sliTickArgs{:}, 'Limits', sliLims, 'Value', sliVal, 'Enable', sliEnab);
        
        app.XResValue = snappedVal;
        app.XResUnit = snappedUnit;
        app.XResMajorInfo = newMajorInfo;

        % syncXFields(app);

        %set([app.XNavSlider app.XResKnob app.FPXModeDropdown ...
        %    app.LockRangeButton app.LockLeftButton ...
        %    app.LockRightButton], 'Enable', true);
    end
catch ME
    fprintf('[XResKnobValueChange] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
    %set([app.XNavSlider app.FPXModeDropdown ...
    %    app.LockRangeButton app.LockLeftButton ...
    %    app.LockRightButton], 'Enable', true);
    % drawnow nocallbacks;
    % app.AxisLimitsCallbackEnabled = true;
end
if isempty(oldCallbackVals)
    app.AxisLimitsCallbackCalculatesPage = true;
    app.AxisLimitsCallbackCalculatesTicks = true;
else
    app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
    app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
end
set([app.FPXModeDropdown ...
        app.LockRangeButton app.LockLeftButton ...
        app.LockRightButton], 'Enable', true);
app.XNavSlider.Enable = (isempty(sliEnab) || sliEnab);
pv = false;
end