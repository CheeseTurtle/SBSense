
function pxset_XNavZoomMode(app, ~, event)
    if event.EventName(2) == 'o' % PostSet
        % TODO: Try/catch, restoring values...?
        if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
            %fprintf('[FPXModeDropdownChanged] Time mode\n');
            % maxIdxOrRelTime = app.DataTable{?}.RelTime(app.LargestIndexReceived);
            maxIdxOrRelTime = app.LatestTimeReceived;
%             rightmostPos = maxIdxOrRelTime;
%             if ~bitget(newModeIndex, 1) % Absolute time
%                 rightmostPos = rightmostPos + app.TimeZero;
%             end
        else % Index mode
            %fprintf('[FPXModeDropdownChanged] Index mode\n');
            maxIdxOrRelTime = app.LargestIndexReceived;
%             rightmostPos = maxIdxOrRelTime;
        end

        [sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
            app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
            app.XResUnit, maxIdxOrRelTime, app.HgtAxes.XLim);
        fprintf('[pxset_XNavZoomMode] Calculated slider lims and value. Calling updateTicksA and updateTicksB...\n');
        sliTickArgs = updateTicksA(app.TimeZero, false, app.XNavSlider.InnerPosition(3), ...
            sliLims, app.XAxisModeIndex, app.XNavZoomMode, app.XResUnit, false);
        updateTicksB(app, false, sliLims, app.XAxisModeIndex, ...
            sliTickArgs{:}, 'Limits', sliLims, 'Value', sliVal, 'Enable', sliEnab);
        drawnow;
        % TODO: Enable relevant controls
        if app.IsRecording && (app.PlotTimer.Running(2)=='f')
            start(app.PlotTimer);
        end
    else % PreSet
        stop(app.PlotTimer);
        % TODO: Disable relevant controls
        if ~isempty(app.PlotTimer.UserData) ...
            &&  isa(app.PlotTimer.UserData, 'parallelFuture')
            wait(app.PlotTimer.UserData);
            %futs = parallel.Future.empty();
        %else
            %futs = app.PlotTimer.UserData;
        end
        for ctl = [app.XNavSlider app.FPXModeDropdown app.XResKnob ...
                app.FPXMaxField app.FPXMinField app.FPXMinSecsField ...
                app.FPXMaxSecsField]
            if ~isempty(ctl.UserData) && isa(ctl.UserData, 'parallel.Future')
                %futs = [futs x.UserData];
                wait(ctl.UserData);
            end
        end
        %if ~isempty(futs)
        %    wait(futs); % TODO: Timeout handling?
        %end
    end
end