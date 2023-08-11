function FPXModeDropdownChanged(app, src, event, varargin)
    % TODO: Also disable nav buttons and fields
    %fprintf('[FPXModeDropdownChanged] %s\n', event.EventName);
    oldCallbackVals = [ app.AxisLimitsCallbackCalculatesTicks, ...
        app.AxisLimitsCallbackCalculatesPage];
    app.AxisLimitsCallbackCalculatesTicks = false;
    app.AxisLimitsCallbackCalculatesPage = false;
    sliEnab = app.XNavSlider.Enable;
    set([src app.XNavSlider app.XResKnob app.LockRangeButton ...
        app.LockLeftButton app.LockRightButton], 'Enable', 'off');
    stop(app.PlotTimer);
    try
        if (nargin < 4) % || ~isnumeric(varargin{1})
            oldResVal = double(app.XResKnob.Value);
            oldResUnit = pow2(oldResVal);
            oldModeIndex = event.PreviousValue;
        else
            oldModeIndex = varargin{1};
            oldResUnit = app.ResTable{oldModeIndex, 1};
            oldResVal = double(log2(oldResUnit));
            fprintf('[FPXModeDropdownChanged] Called with explicit oldModeIndex %d.\n', oldModeIndex);
        end
        newModeIndex = event.Value;
        newResUnit = app.ResTable{newModeIndex, 1};
        newMajorInfo = table2cell(app.ResTable(newModeIndex, 2:end));
        fprintf('[FPXModeDropdownChanged] ####### Mode index / Res. unit: %d/%0.4g -> %d/%0.4g ######\n', ...
            oldModeIndex, oldResUnit, newModeIndex, newResUnit);
            
        if bitget(newModeIndex, 2) % Time mode (abs or rel)
            try
                if ~issortedrows(app.DataTable{2}, 'RelTime')
                    app.DataTable{2} = sortrows(app.DataTable{2}, 'RelTime');
                end
            catch ME
                fprintf('[FPXModeDropdownChanged] Error "%s" encountered while trying to sort the timetable: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            %fprintf('[FPXModeDropdownChanged] Time mode\n');
            maxIdxOrRelTime = app.LatestTimeReceived;
            fprintf('[FPXModeDropdownChanged] maxIdxOrRelTime: %s\n', string(maxIdxOrRelTime));
            rightmostPos = maxIdxOrRelTime;
            if ~bitget(newModeIndex, 1) % Absolute time
                rightmostPos = rightmostPos + app.TimeZero;
            end
            minDomWd = 2*seconds(pow2(app.XResTimeMinorTicks(1))); % NOTE: this is a duration!!
        else % Index mode
            %fprintf('[FPXModeDropdownChanged] Index mode\n');
            maxIdxOrRelTime = app.LargestIndexReceived;
            rightmostPos = maxIdxOrRelTime;
            minDomWd = 2*max(1, uint64(pow2(app.XResFPHsMinorTicks(1))));
            try
                if ~issortedrows(app.DataTable{1}, 'Index')
                    app.DataTable{1} = sortrows(app.DataTable{1}, 'Index');
                end
            catch ME
                fprintf('[FPXModeDropdownChanged] Error "%s" encountered while trying to sort the data table: %s\n', ...
                    ME.identifier, getReport(ME));
            end
        end
       
        %fprintf('[FPXModeDropdownChanged] Checking plot timer / recording status.\n');
        if app.IsRecording && ~isempty(app.PlotTimer.UserData)
            fprintf('[FPXModeDropdownChanged] Waiting for PlotTimer UD:\n');
            disp(app.PlotTimer.UserData);
            wait(app.PlotTimer.UserData);
            fprintf('[FPXModeDropdownChanged] Waited for PlotTimer UD.\n');
        end
        %fprintf('[FPXModeDropdownChanged] Checked plot timer / recording status.\n');
        
        try
            convLims = sbsense.SBSenseApp.convertAxisLimits(app.TimeZero, app.DataTable, ...
                app.FPRulers{oldModeIndex,1}.Limits, oldModeIndex, newModeIndex, ...
                rightmostPos, minDomWd);
            % display(convLims); display(rightmostPos);
            fprintf('[FPXModeDropdownChanged] convLims: %s\n', strrep(strip(formattedDisplayText(convLims)), '  ', ' '));
            newResUnit = restrictResUnit(newModeIndex, true, ...
                pow2(app.XResKnob.MinorTicks), convLims, newResUnit, maxIdxOrRelTime);
            newResVal = double(log2(newResUnit)); % new res knob value

            clampLims = clampDomain(app.TimeZero, newModeIndex, app.XNavZoomMode, ...
                rightmostPos, minDomWd, convLims);

            quantLims = quantizeDomain(app.TimeZero, newModeIndex, app.XNavZoomMode, ...
                newResUnit, clampLims);
            % fprintf('[FPXModeDropdownChanged] quantLims: %s\n', strrep(strip(formattedDisplayText(quantLims)), '  ', ' '));

            % [rulerMin,rulerMaj,rulerLabels] = generateRulerTicks( ...
            %     app.TimeZero, newModeIndex, app.XNavZoomMode, ...
            %     quantLims, newResUnit, newMajorInfo);
            rulerTickArgs = updateTicksA(app.TimeZero, true, ...
                app.HgtAxes.InnerPosition(3), quantLims, ...
                newModeIndex, app.XNavZoomMode, newResUnit, true);
            % fprintf('[FPXModeDropdownChanged] Generated ruler ticks.\n');
            [sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
                app.TimeZero, newModeIndex, app.XNavZoomMode, ...
                newResUnit, maxIdxOrRelTime, quantLims);
            % fprintf('[FPXModeDropdownChanged] Calculated slider lims and value.\n');

            sliTickArgs = updateTicksA(app.TimeZero, false, app.XNavSlider.InnerPosition(3), ...
                sliLims, newModeIndex, app.XNavZoomMode, newResUnit, true);
            % [sliMin, sliMaj, sliLabels] = generateSliderTicks( ...
            %     app.TimeZero, newModeIndex, app.XNavZoomMode, ...
            %     sliLims, newResUnit, newMajorInfo);
            % fprintf('[FPXModeDropdownChanged] Generated slider ticks.\n');
        catch ME
            fprintf('[FPXModeDropdownChanged] (Error with identifier "%s" occurred during calculation.)\n', ...
                ME.identifier);
            fprintf('%s\n', getReport(ME));
            types = ["matlab.graphics.axis.decorator.NumericRuler", ...
                    "matlab.graphics.axis.decorator.DatetimeRuler", ...
                    "matlab.graphics.axis.decorator.DurationRuler"];
            hgtModeIndex = find(types==class(app.HgtAxes.XAxis), 1);
            if ~isa(app.PosAxes.XAxis, types(hgtModeIndex)) || (hgtModeIndex ~= oldModeIndex)
                app.PosAxes.XAxis = app.FPRulers{hgtModeIndex, 2};
                if hgtModeIndex ~= oldModeIndex
                    fprintf('[FPXModeDropdownChanged] Reattempting with explicit oldModeIndex %d (instead of %d).\n', ...
                        hgtModeIndex, oldModeIndex);
                end
                FPXModeDropdownChanged(app, src, event, hgtModeIndex);
                return;
            else
                fprintf('[FPXModeDropdownChanged] hgtModeIndex=posModeIndex %d matches oldModeIndex %d. Rethrowing error.\n', ...
                    hgtModeIndex, oldModeIndex);
                rethrow(ME);
            end
        end
        % Get new x-data
        if app.SelectedIndex
            oldSelPos =  app.FPSelPatches(1).XData;
        end
        oldXData = app.eliPlotLine.XData;
        newXData = quantLims(1):quantLims(2);
        
        % fprintf('[FPXModeDropdownChanged] Got new xdata.\n');

        sliPropVals = get(app.XNavSlider, {'MinorTicks', 'MajorTicks', ...
            'MajorTickLabels', 'Limits', 'Value', 'Enable'});
        knoPropVals = get(app.XResKnob, {'MinorTicks', 'MajorTicks', ...
            'MajorTickLabels', 'Limits', 'Value'});

        % fprintf('[FPXModeDropdownChanged] Trying to apply calculated values...\n');
        try
            fprintf('[FPXModeDropdownChanged] @@@ CALLING updateTicksB for SLIDER, val / lims / enab = %g / [%g %g] / %s\n', ...
                sliVal, sliLims(1), sliLims(2), fdt(sliEnab));
            updateTicksB(app, false, sliLims, newModeIndex, ...
                sliTickArgs{:},  'Limits', sliLims, 'Value', sliVal, 'Enable', sliEnab);
            updateTicksB(app, true, quantLims, newModeIndex, ...
                rulerTickArgs{:});
            fprintf('[FPXModeDropdownChanged] @@@ SETTING RULER LIMS TO quantlims = %s\n', fdt(quantLims));
            set([app.FPRulers{newModeIndex,:}], 'Limits', quantLims);

            try
                if ~isempty(app.DataTable{3})
                    for i=1:size(app.DataTable{3},1)
                        if ~ishandle(app.DataTable{3}{i,'ROI'}) || ~isvalid(app.DataTable{3}{i,'ROI'})
                            continue;
                        end
                        if bitget(newModeIndex,2)
                            if bitget(newModeIndex,1)
                                for ii=1:size(app.DataTable{3},1)
                                    set(app.DataTable{3}{ii,'ROI'}, 'Value', ...
                                        ruler2num(app.DataTable{3}.RelTime(ii), ...
                                        app.FPRulers{newModeIndex,1}));
                                end
                            else
                                for ii=1:size(app.DataTable{3},1)
                                    set(app.DataTable{3}{ii,'ROI'}, 'Value', ...
                                        ruler2num(app.DataTable{3}.RelTime(ii) + app.TimeZero, ...
                                        app.FPRulers{newModeIndex,1}));
                                end
                            end
                        else
                            for ii=1:size(app.DataTable{3},1)
                                set(app.DataTable{3}{ii,'ROI'}, 'Value', ...
                                    app.DataTable{3}{ii,'Index'});
                            end
                        end
                    end
                end
            catch ME2
                fprintf('[FPXModeDropdownChanged] Error occurred while switching discontinuity position units: %s\n', getReport(ME2));
                % TODO: Throw error and restore to previous values
            end
            % fprintf('[FPXModeDropdownChanged] Applied tick/label changes.\n');
        catch ME
            fprintf('[FPXModeDropdownChanged] (Error with identifier "%s" occurred during assignment.)\n', ...
                ME.identifier);
            fprintf('Error report: %s\n', getReport(ME));
            types = ["matlab.graphics.axis.decorator.NumericRuler", ...
                    "matlab.graphics.axis.decorator.DatetimeRuler", ...
                    "matlab.graphics.axis.decorator.DurationRuler"];
            hgtModeIndex = find(strcmp(class(app.HgtAxes.XAxis), types), 1);
            if ~isa(app.PosAxes.XAxis, types(hgtModeIndex)) || (hgtModeIndex ~= oldModeIndex)
                app.PosAxes.XAxis = app.FPRulers{hgtModeIndex, 2};
                if hgtModeIndex ~= oldModeIndex
                    fprintf('[FPXModeDropdownChanged] Reattempting with explicit oldModeIndex %d (instead of %d).\n', ...
                        hgtModeIndex, oldModeIndex);
                end
                FPXModeDropdownChanged(app, src, event, hgtModeIndex);
                return;
            else
                fprintf('[FPXModeDropdownChanged] hgtModeIndex=posModeIndex %d matches oldModeIndex %d. Rethrowing error after restoring old values.\n', ...
                    hgtModeIndex, oldModeIndex);
                %fprintf('[FPXModeDropdownChanged] Error "%s": %s\n', ...
                %   ME.identifier, getReport(ME));
                [app.HgtAxes.XAxis, app.PosAxes.XAxis] = app.FPRulers{oldModeIndex,:}; 
                if iscell(sliPropVals{1})
                    sliPropVals{1} = cell2mat(sliPropVals{1});
                end
                if iscell(sliPropVals{2})
                    sliPropVals{2} = cell2mat(sliPropVals{2});
                end
                set(app.XNavSlider, 'MinorTicks', sliPropVals{1}, ...
                    'MajorTicks', sliPropVals{2}, 'MajorTickLabels', sliPropVals{3}, ...
                    'Limits', sliPropVals{4}, 'Value', sliPropVals{5}, 'Enable', sliPropVals{6});
                if iscell(knoPropVals{1})
                    knoPropVals{1} = cell2mat(knoPropVals{1});
                end
                if iscell(knoPropVals{2})
                    knoPropVals{2} = cell2mat(knoPropVals{2});
                end
                set(app.XResKnob, 'MinorTicks', knoPropVals{1}, ...
                    'MajorTicks', knoPropVals{2}, 'MajorTickLabels', knoPropVals{3}, ...
                    'Limits', knoPropVals{4}, 'Value', knoPropVals{5});
                [app.HgtAxes.XAxis, app.PosAxes.XAxis] = app.FPRulers{oldModeIndex, :};
                if ~isempty(oldXData)
                    isnum = isnumeric(oldXData);
                    if xor(isnum,isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.NumericRuler'))
                        if isnum
                            oldXData = num2ruler(oldXData, app.HgtAxes.XAxis);
                        else
                            oldXData = ruler2num(oldXData, app.HgtAxes.XAxis);
                        end
                    end
                    set([app.channelPeakHgtLines app.channelPeakPosLines app.eliPlotLine], ...
                        'XData', oldXData);
                    if app.SelectedIndex
                        set(app.FPSelPatches, 'XData', oldSelPos);
                    end
                end
            end
            rethrow(ME);
        end

        try
            [app.HgtAxes.XAxis, app.PosAxes.XAxis] = app.FPRulers{newModeIndex,:};
            % fprintf('[FPXModeDropdownChanged] Replaced axis rulers.\n');
            set([app.channelPeakHgtLines app.channelPeakPosLines app.eliPlotLine], ...
                'XData', ruler2num(newXData,app.HgtAxes.XAxis));
            % fprintf('[FPXModeDropdownChanged] Replaced axis xdata.\n');
        catch ME
            fprintf('[FPXModeDropdownChanged] Error "%s": %s\n', ...
                ME.identifier, getReport(ME));
            [app.HgtAxes.XAxis, app.PosAxes.XAxis] = app.FPRulers{oldModeIndex,:};
            if iscell(sliPropVals{1})
                sliPropVals{1} = cell2mat(sliPropVals{1});
            end
            if iscell(sliPropVals{2})
                sliPropVals{2} = cell2mat(sliPropVals{2});
            end
            set(app.XNavSlider, 'MinorTicks', sliPropVals{1}, ...
                'MajorTicks', sliPropVals{2}, 'MajorTickLabels', sliPropVals{3}, ...
                'Limits', sliPropVals{4}, 'Value', sliPropVals{5}, 'Enable', sliPropVals{6});
            if iscell(knoPropVals{1})
                knoPropVals{1} = cell2mat(knoPropVals{1});
            end
            if iscell(knoPropVals{2})
                knoPropVals{2} = cell2mat(knoPropVals{2});
            end
            set(app.XResKnob, 'MinorTicks', knoPropVals{1}, ...
                'MajorTicks', knoPropVals{2}, 'MajorTickLabels', knoPropVals{3}, ...
                'Limits', knoPropVals{4}, 'Value', knoPropVals{5});
            [app.HgtAxes.XAxis, app.PosAxes.XAxis] = app.FPRulers{oldModeIndex, :};
            if ~isempty(oldXData)
                isnum = isnumeric(oldXData);
                if xor(isnum,isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.NumericRuler'))
                    if isnum
                        oldXData = num2ruler(oldXData, app.HgtAxes.XAxis);
                    else
                        oldXData = ruler2num(oldXData, app.HgtAxes.XAxis);
                    end
                end
                set([app.channelPeakHgtLines app.channelPeakPosLines app.eliPlotLine], ...
                    'XData', oldXData);
                if app.SelectedIndex
                    set(app.FPSelPatches, 'XData', oldSelPos);
                end
            end
            rethrow(ME);
        end

        % fprintf('[FPXModeDropdownChanged] Setting up knob.\n');
        if newModeIndex == 1
            set(app.XResKnob, 'MajorTicks', app.XResFPHsMajorTicks, ...
            'MinorTicks', app.XResFPHsMinorTicks, ...
            'MajorTickLabels', app.XResFPHsMajorTickLabels, ...
            'Limits', app.XResFPHsRange, 'Value', newResVal);
        elseif oldModeIndex == 1
            set(app.XResKnob, 'MajorTicks', app.XResTimeMajorTicks, ...
                'MinorTicks', app.XResTimeMinorTicks, ...
                'MajorTickLabels', app.XResTimeMajorTickLabels, ...
                'Limits', app.XResTimeRange, 'Value', newResVal);
        else
            app.XResKnob.Value = newResVal;
        end
        % fprintf('[FPXModeDropdownChanged] Done setting up knob.\n');

        app.XAxisModeIndex = newModeIndex;
        app.XResUnit = newResUnit;
        app.XResValue = newResVal;
        app.XResMajorInfo = newMajorInfo;

        if (oldModeIndex~=1) || (fix(oldResUnit)>0)
            fprintf('[FPXModeDropdownChanged] Storing in res table: pow(%0.4g)=%0.4g for axis mode %d.\n', ...
                oldResVal, oldResUnit, oldModeIndex);
            app.ResTable{oldModeIndex, 1} = oldResUnit;
            fprintf('[FPXModeDropdownChanged] Stored old res value.\n');
        else
            fprintf('[FPXModeDropdownChanged] WARNING: Not storing invalid/incompatible res value pow(%0.4g)=%0.4g for axis mode %d.\n', ...
                oldResVal, oldResUnit, oldModeIndex);
        end
        
        timeMode = logical(bitget(newModeIndex, 2));
        set([app.FPXMinSecsField app.FPXMinColonLabel ...
            app.FPXMaxSecsField app.FPXMaxColonLabel], ...
            'Visible', timeMode, 'Enable', timeMode);
            
        syncXFields(app);
        updatePaging(app);
        onAxesPanelSizeChange(app,app.HgtAxesPanel,[]);
        %onAxesPanelSizeChange(app,app.PosAxesPanel,[]);
        if app.SelectedIndex
            app.SelectedIndex = app.SelectedIndex; % NOTE: SelectedIndex mustn't have the "AbortSet" attribute
            % fprintf('[FPXModeDropdownChanged] Replaced patch xdata.\n');
        end
        % drawnow nocallbacks;
        % fprintf('[FPXModeDropdownChanged] Done changing axis mode.\n');
    catch ME
        fprintf('[FPXModeDropdownChanged] Error "%s": %s\n', ...
            ME.identifier, getReport(ME));
        app.FPXModeDropdown.Value = app.XAxisModeIndex;
        % FPXModeDropdownChangedCleanup(app, oldCallbackVals);
    end
    FPXModeDropdownChangedCleanup(app, oldCallbackVals, sliEnab);
end

function FPXModeDropdownChangedCleanup(app, oldCallbackVals, sliEnab, varargin)
    % TODO: Also enable nav buttons and fields
    app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(1);
    app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(2);
    % if (nargin > 1) && isnumeric(varargin{1})
    %     cleanupLevel = uint8(varargin{1});
    % else
    %     cleanupLevel = uint8(3);
    % end
    
    % app.AxisLimitsCallbackCalculatesPage = true;
    % if bitget(cleanupLevel, 1)
    %     app.AxisLimitsCallbackEnabled = true;
    %     if bitget(cleanupLevel,2)
    %         if cleanupLevel==3
    %             onAxesPanelSizeChange(app,app.HgtAxesPanel,[]);
    %             %onAxesPanelSizeChange(app,app.PosAxesPanel,[]);
    %         end
    %         drawnow nocallbacks;
    %     else
    %         drawnow limitrate nocallbacks;
    %     end
    % end

%             if app.PlotQueue.QueueLength
%                 futs = processPlotQueue(app, []);
%             else
%                 futs = setXAxisModeAndResolution(app, ...
%                     pow2(app.XResKnob.Value));
%             end
%            wait(futs);
    if app.IsRecording && app.PlotTimer.Running(2)=='f'
        start(app.PlotTimer);
    end
    set([app.FPXModeDropdown app.XResKnob app.LockRangeButton ...
        app.LockLeftButton app.LockRightButton], 'Enable', 'on');
    app.XNavSlider.Enable = (isempty(sliEnab) || sliEnab);
    drawnow nocallbacks;
    if (nargin > 3) && isa(varargin{end}, 'parallel.Future')
        fut = varargin{end};
        if ~isempty(fut.Error)
            fprintf('[FPXModeDropdownChangedCleanup] fut.Error "%s": %s\n', ...
                fut.Error.identifier, getReport(fut.Error));
        end
    end
end