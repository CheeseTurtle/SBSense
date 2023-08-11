function setVisibleDomain(app, rulLims, varargin)
    if ~isempty(app.PlotTimer.UserData) % && app.IsRecording
        wait(app.PlotTimer.UserData);
    end
    stop(app.PlotTimer);

    timeMode = bitget(app.XAxisModeIndex,2);
    absMode = timeMode && ~bitget(app.XAxisModeIndex,1);

    if (nargin==2) || varargin{1} % Clamp rulLims
        if absMode
            rulLims(1) = max(rulLims(1), app.TimeZero);
        elseif timeMode
            rulLims(1) = max(rulLims(1), seconds(0));
        else % Index mode
            rulLims(1) = max(1, rulLims(1));
        end
    end

    if rulLims(2)<=rulLims(1)
        % app.XNavSlider.Enable = false;
        rulLims(2) = rulLims(1) + app.XResUnitVals{app.XAxisModeIndex,2};
        % if timeMode
        %     rulLims(2) = rulLims(1) + seconds(app.XResUnitVals{?});
        % else
        %     rulLims(2) = rulLims(1) + app.XResUnitVals{?};
        % end
    % else
    %     app.XNavSlider.Enable = true;
    end

    if timeMode % Absolute or relative time
        maxIdxOrRelTime = app.LatestTimeReceived;
%         if ~bitget(app.XAxisModeIndex, 1) % Absolute time
%             rightmostPos = maxIdxOrRelTime + app.TimeZero;
%         else % Relative time
%             rightmostPos = maxIdxOrRelTime;
%         end
    else % Index mode
        maxIdxOrRelTime = app.LargestIndexReceived;
        % rightmostPos = maxIdxOrRelTime;
    end
    
    rulerTickArgs = updateTicksA(app.TimeZero, true, ...
        app.HgtAxes.InnerPosition(3), rulLims, ...
        app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, true);

    % if isscalar(rulLims)
    %     rulLims(2) = min(rightmostPos, rulLims(1) + diff(app.HgtAxes.XLim));
    % elseif rulLims(2) <= rulLims(1)
    %     if timeMode
    %         rulLims(2) = min(rightmostPos, rulLims(2) + app.XResUnitVals{?});
    %     else
    %         rulLims(1) = min(rightmostPos, rulLims(2) + app.XResUnitVals{?});
    %     end
    % end

    if (nargin==4) && varargin{2} % Quantize
        rulLims = quantizeDomain(app.TimeZero, app.XAxisModeIndex, ...
            app.XNavZoomMode, app.XResUnitVals, rulLims);
    end
    
    [sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
        app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, maxIdxOrRelTime, rulLims);

    if sliLims(2)<=sliLims(1)
        app.XNavSlider.Enable = false;
        sliLims(2) = sliLims(1) + app.XResUnitVals{app.XAxisModeIndex,1};
    else
        app.XNavSlider.Enable = true;
    end
    
    sliTickArgs = updateTicksA(app.TimeZero, false, ...
        app.XNavSlider.InnerPosition(3), sliLims, ...
        app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, ~app.XNavZoomMode);
    
    sliPropVals = get(app.XNavSlider, {'MinorTicks', 'MajorTicks', ...
        'MajorTickLabels', 'Limits', 'Value', 'Enable'});
    rulPropVals = get(app.HgtAxes.XAxis, {'Limits', ...
        'MinorTickValues', 'TickValues'});
    axMinorOn = app.HgtAxes.XMinorTick;
    % TODO: Annotations / labels

    oldCallbackVals = [ app.AxisLimitsCallbackCalculatesPage ...
        app.AxisLimitsCallbackCalculatesTicks ];
    app.AxisLimitsCallbackCalculatesPage = false;
    app.AxisLimitsCallbackCalculatesTicks = false;

    try
        updateTicksB(app, true, rulLims, app.XAxisModeIndex, ...
            rulerTickArgs{:}, 'Limits', rulLims);
        set([app.HgtAxes app.PosAxes], 'XLim', rulLims);
        try
            updateTicksB(app, false, sliLims, app.XAxisModeIndex, ...
                sliTickArgs{:}, 'Limits', sliLims, 'Value', sliVal, 'Enable', sliEnab);
        catch ME2
            %fprintf('[setVisibleDomain] Error "%s": %s\n', ...
            %    ME2.identifier, getReport(ME2));
            if iscell(sliPropVals{1})
                sliPropVals{1} = cell2mat(sliPropVals{1});
            end
            if iscell(sliPropVals{2})
                sliPropVals{2} = cell2mat(sliPropVals{2});
            end
            set(app.XNavSlider, 'MinorTicks', sliPropVals{1}, ...
                'MajorTicks', sliPropVals{2}, 'MajorTickLabels', sliPropVals{3}, ...
                'Limits', sliPropVals{4}, 'Value', sliPropVals{5}, 'Enable', sliPropVals{6});
            rethrow(ME2);
        end
    catch ME
        fprintf('[setVisibleDomain] Error "%s": %s\n', ...
                ME.identifier, getReport(ME));
        if iscell(rulPropVals{2})
            rulPropVals{2} = cell2mat(rulPropVals{2});
        end
        if iscell(rulPropVals{3})
            rulPropVals{3} = cell2mat(rulPropVals{3});
        end
        set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', rulPropVals{1}, ...
            'MinorTickValues', rulPropVals{2}, 'TickValues', rulPropVals{3});
        set([app.HgtAxes app.PosAxes], 'XMinorTick', axMinorOn, ...
            'XMinorGrid', axMinorOn);
        % app.AxisLimitsCallbackEnabled = true;
        app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
        app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
        if app.IsRecording
            start(app.PlotTimer);
        end
        rethrow(ME);
    end
    % app.AxisLimitsCallbackEnabled = true;
    %%%%% app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
    %%%%% app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
    if app.IsRecording && (app.PlotTimer.Running(2)=='f')
        start(app.PlotTimer);
    end
end

% % rulLims, navSliderProperties
% function setVisibleDomain(app, noaxis, rulLims, varargin)
%     if (nargin > 3) && ~isempty(varargin{1})
%         applyNavParameters(varargin{:});
%         futs = [];
%     else
%         futs = [ ...
%             parfeval(backgroundPool, @fcn1, rulLims, app.XAxisModeIndex, pow2(app.XResSlider.Value), app.TimeZero) ...
%             parfeval(backgroundPool, @fcn2, rulLims, app.XAxisModeIndex, pow2(app.XResSlider.Value), app.TimeZero) ...
%         ];
%         fut1 = afterAll(futs, @applyNavParameters, 0, 'PassFuture', false);
%     end
%     % (Hide slider rect.)
%     if ~noaxis
%         set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', rulLims);
%     end
%     if ~isempty(futs)
%         wait([futs fut1]);
%     end
%     % (Set slider rect pos and unhide.)
% end