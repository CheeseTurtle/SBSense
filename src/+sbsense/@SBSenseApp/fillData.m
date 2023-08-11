function futs = fillData(app)
% if isempty(app.NRulers)
%     setupFPAxes(app);
% end
app.HgtAxes.PlotBoxAspectRatioMode = 'auto';
app.HgtAxes.DataAspectRatioMode = 'auto';
app.HgtAxes.CameraViewAngleMode = 'auto';
set(app.HgtAxes.YAxis, 'TickValuesMode', 'auto', 'TickLabelsMode', 'auto');

app.PosAxes.PlotBoxAspectRatioMode = 'auto';
app.PosAxes.DataAspectRatioMode = 'auto';
app.PosAxes.CameraViewAngleMode = 'auto';
app.PosAxes.YAxis.TickValuesMode = 'auto';
app.PosAxes.YAxis.TickLabelsMode = 'auto';

set([app.PosAxesPanel app.HgtAxesPanel ...
    app.HgtAxes.YAxis(1) app.HgtAxes.YAxis(end) app.PosAxes.YAxis], ...
    'Visible', "off");

if ~isempty(app.channelPeakHgtLines)
        delete(app.channelPeakHgtLines);
    end
    if ~isempty(app.channelPeakPosLines)
        delete(app.channelPeakPosLines);
    end
    if isgraphics(app.eliPlotLine)
        delete(app.eliPlotLine);
    end
    co = colororder(app.UIFigure);
    yyaxis(app.HgtAxes, 'right');
    app.HgtAxes.YColor =  co(end, :);
    app.eliPlotLine = matlab.graphics.primitive.Line( ...
        'Parent', app.HgtAxes, 'Color', co(end,:), ...
        'MarkerSize', 4, 'Marker', 'x', ...
        'LineStyle', '--', 'LineWidth', 0.5, ...
        'XData', [], 'YData', [], ...
        'DisplayName', 'ELI');
    yyaxis(app.HgtAxes, 'left');
    app.HgtAxes.YColor = [0 0 0];
    app.channelPeakHgtLines = matlab.graphics.primitive.Line.empty(0, app.NumChannels);
    app.channelPeakPosLines = matlab.graphics.primitive.Line.empty(0, app.NumChannels);

    %  matlab.graphics.primitive.Line vs matlab.graphics.chart.primitive.Line
    
    for ch = 1:app.NumChannels
        dn = sprintf('Channel %d', ch);
        app.channelPeakHgtLines(ch) = matlab.graphics.primitive.Line( ...
        'Parent', app.HgtAxes, 'Color', co(ch,:), ...
        'MarkerSize', 6, 'Marker', '.', 'XData', [], 'YData', [], ...
        'LineStyle', '-', 'LineWidth', 1, 'DisplayName', dn);
        app.channelPeakPosLines(ch) = matlab.graphics.primitive.Line( ...
        'Parent', app.PosAxes, 'Color', co(ch,:), ...
        'MarkerSize', 6, 'Marker', '.', 'XData', [], 'YData', [], ...
        'LineStyle', '-', 'LineWidth', 1, 'DisplayName', dn);
    end
   

%     set(app.PosAxes, 'XAxis', app.NRulers(2), ...
%         'GridAlphaMode', 'manual', 'GridColorMode', 'manual', ...
%         'XColorMode', 'manual', 'MinorGridAlphaMode', 'manual', ...
%         'MinorGridColorMode', 'manual', ...
%         'CameraViewAngleMode', 'auto', ...
%         'DataAspectRatioMode', 'auto', ...
%         'PlotBoxAspectRatioMode', 'auto' ...
%         );
%     set(app.HgtAxes, 'XAxis', app.NRulers(1), ...
%         'CameraViewAngleMode', 'auto', ...
%         'DataAspectRatioMode', 'auto', ...
%         'PlotBoxAspectRatioMode', 'auto');

    sbsense.SBSenseApp.enablehier(app.Phase2RightGridPanel);
    sbsense.SBSenseApp.showhier([app.Phase2RightGridPanel app.Phase2RightGrid]);
    set([app.FPXMaxColonLabel, app.FPXMaxSecsField, ...
        app.FPXMinColonLabel, app.FPXMinSecsField], ...
            'Visible', false);
    % TODO: Change / set / reapply x axis mode...

    set(app.DataImageAxes, 'Visible', true, ...
        'XLim', app.PreviewAxes.XLim, ...
        'YLim', app.PreviewAxes.YLim);


    app.LargestIndexReceived = 0;
    app.LatestTimeReceived = seconds(0);
    app.SelectedIndex = 0;
    % set([app.PosAxes app.HgtAxes], 'XLim', [1,app.LargestIndexReceived], 'XLimMode', 'manual');
    % app.PageLimits = app.HgtAxes.XLim;
    % app.PageSize = app.LargestIndexReceived;
    set([app.PosAxesPanel app.HgtAxesPanel ...
        app.HgtAxes.YAxis(1), app.HgtAxes.YAxis(end) app.PosAxes.YAxis], ...
        'Visible', "on");
    set(app.DataNavGrid.Children, 'Enable', true);
    return;

    % plot(0:15, pdf('Weibull', 0:15, 10, 1.8));
    % plot(0:15, pdf('Gamma', 0:15, 3, 3));
    % plot(0:15, pdf('Gamma', 0:15, 3, 3) + 0.05*cos(pi/15 * (0:15)))
    % plot(0:15, pdf('Weibull', 0:15, 10, 1.8) + 0.05*cos(pi/15 * (0:15)));
    % random("T", repmat([0.1+eps 0.1+eps 1],1,1,5),1, 3, 5)
    % plot(random("tlocationscale", 0, 1, 1, 1, 100))

    xs = (0:0.25:15)';
    data1 = pdf('Gamma', xs, 3, 3) + 0.025*(1+cos(pi/15 * xs));
    data2 = pdf('Weibull', xs, 10, 1.8) + 0.025*(1+cos(pi/15 * xs));
    peakLocData = arrayfun(@(~) fillDataFnc(data1,data2,length(xs)), ...
        repelem(length(xs),1,app.NumChannels), 'UniformOutput', false);
    peakHgtData = arrayfun(@(~) fillDataFnc(data1,data2,length(xs)), ...
        repelem(length(xs),1,app.NumChannels)', 'UniformOutput', false);
    %disp({size(data1),size(data2), size(peakLocData{1}), size(peakLocData{2})});
    peakLocData = horzcat(peakLocData{:});
    peakHgtData = horzcat(peakHgtData{:});
    %disp(peakLocData);
    avgLocData = mean(peakLocData,2);
    %disp(avgLocData);
    avgHgtData = mean(peakHgtData,2);
    
    ELIData = zeros(length(xs),1,'double');
    ELIData(1) = random("tLocationScale", 1, 0.5, 0.2);
    for i=2:length(xs)
        ELIData(i) = 0.3*random("tLocationScale", ELIData(i-1), 0.5, 1) + ...
            0.7*random("tLocationScale", 1, 0.5, 0.6);
    end
    ELIData = normalize(ELIData, 'range');
    peakHgtData = normalize(peakHgtData, 'range');

    psbs = zeros(length(xs), 2, 'uint16');
    idxs = (1:length(xs))';
    secs = 0.5*seconds(idxs-1);
    %disp({size(idxs),size(psbs),size(ELIData), size(avgLocData), size(avgHgtData), ...
    %    size(peakLocData), size(peakHgtData)}');
    app.DataTable{1}(:,:) = [];
    app.DataTable{1} = removevars(app.DataTable{1}, {'PeakLoc', 'PeakHgt'});
    app.DataTable{1}(idxs,:) = table(secs, psbs, avgLocData, avgHgtData, ELIData);
    app.DataTable{1} = addvars(app.DataTable{1}, peakLocData, peakHgtData, 'NewVariableNames', {'PeakLoc', 'PeakHgt'});

    app.DataTable{2}(:,:) = [];
    app.DataTable{2} = removevars(app.DataTable{2}, {'PeakLoc', 'PeakHgt'});
    app.DataTable{2}(secs,:) = table(idxs, psbs, avgLocData, avgHgtData, ELIData);
    app.DataTable{2} = addvars(app.DataTable{2}, peakLocData, peakHgtData, 'NewVariableNames', {'PeakLoc', 'PeakHgt'});
    
    app.DataTable{3}(:,:) = [];
    
    % send(app.PlotQueue, idxs);
    send(app.PlotQueue, secs);
    
    app.TimeZero = datetime('now');
    tc = matlab.uitest.TestCase.forInteractiveUse;
    tc.choose(app.FPXModeDropdown, app.FPXModeDropdown.ItemsData(1));
    % tc.choose(app.XResKnob, app.XResKnob.MinorTicks(1));

    %app.HgtAxes.XAxis = app.NRulers(1);
    %app.PosAxes.XAxis = app.NRulers(2);
    app.LargestIndexReceived = idxs(end); %length(idxs);
    assert(isscalar(app.LargestIndexReceived));
    assert(~isempty(app.LargestIndexReceived));
    app.LatestTimeReceived = secs(end);
    app.SelectedIndex = 0;
    set([app.PosAxes app.HgtAxes], 'XLim', [1,app.LargestIndexReceived], 'XLimMode', 'manual');
    app.PageLimits = app.HgtAxes.XLim;
    app.PageSize = app.LargestIndexReceived;
    futs = processPlotQueue(app, []);

    rulLims = quantizeDomain(app.TimeZero, ...
        app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, app.HgtAxes.XLim);
    rulerTickArgs = updateTicksA(app.TimeZero, true, ...
        app.HgtAxes.InnerPosition(3), app.HgtAxes.XLim, ...
        app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, false);

    if bitget(app.XAxisModeIndex, 2) % Time mode (abs or rel)
        maxIdxOrRelTime = app.LatestTimeReceived;
    else % Index mode
        maxIdxOrRelTime = app.LargestIndexReceived;
    end
    [sliLims, sliVal] = calcSliderLimsValFromRulerLims( ...
        app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, maxIdxOrRelTime, rulLims);
    if sliLims(2)<=sliLims(1)
        app.XNavSlider.Enable = false;
        sliLims(2) = sliLims(1) + app.XResUnitVals{app.XAxisModeIndex,1};
    else
        app.XNavSlider.Enable = true;
    end
    sliTickArgs = updateTicksA(app.TimeZero, false, app.XNavSlider.InnerPosition(3), ...
            sliLims, app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, false);    

    set([app.HgtAxes.XAxis app.PosAxes.XAxis], 'Limits', rulLims);
    updateTicksB(app, true, app.HgtAxes.XLim, app.XAxisModeIndex, rulerTickArgs{:});
    
    
    % disp(sliLims);
    %set(app.XNavSlider, 'Limits', double(sliLims), 'Value', double(sliVal), ...
    %    'MinorTicks', double(sliMin), 'MajorTicks', double(sliMaj), ...
    %    'MajorTickLabels', sliLabels);
    updateTicksB(app, false, sliLims, app.XAxisModeIndex, ...
        sliTickArgs{:},'Limits', sliLims, 'Value', sliVal);
     
    minPeakHgt = min(app.DataTable{2}{:,{'ELI', 'PeakHgt'}}, [], "all");
    maxPeakHgt = max(app.DataTable{2}{:,{'ELI', 'PeakHgt'}}, [], "all");
    minPeakLoc = min(app.DataTable{2}.PeakLoc, [], "all");
    maxPeakLoc = max(app.DataTable{2}.PeakLoc, [], "all");
    bufHgt = 0.025*(maxPeakHgt-minPeakHgt);
    bufLoc = 0.025*(maxPeakLoc-minPeakLoc);
    set([app.PosAxesPanel app.HgtAxesPanel ...
        app.HgtAxes.YAxis(1), app.HgtAxes.YAxis(end) app.PosAxes.YAxis], ...
        'Visible', "on");
    set(app.DataNavGrid.Children, 'Enable', true);

    %app.HgtAxes.YLimMode = 'auto';
    %app.PosAxes.YLimMode = "auto";
    set(app.HgtAxes.YAxis, 'Limits', [minPeakHgt - bufHgt, maxPeakHgt + bufHgt]);
    app.PosAxes.YLim = [max(0, minPeakLoc - bufLoc), min(...
        max(app.fdm(1),24000), maxPeakLoc + bufLoc)];
    syncXFields(app);
    %wait(futs);
    %if isempty([futs.Error])
    %end
end

% Returns a column vector
function y = fillDataFnc(data1, data2, len)
    sel = random("tLocationScale", 0, 0.3, 10, len, 1) ...
        + sin(((0:len-1)' - randn(1,1))*pi*(2.25-rand(1,1)));
    sel = normalize(sel, "range");
    y = ((data1.*sel) + (data2.*(1-sel)));
end