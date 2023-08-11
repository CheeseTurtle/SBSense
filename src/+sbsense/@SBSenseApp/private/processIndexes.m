function futs1 = processIndexes(app, tobj, durs, minDurReceived,maxDurReceived)
fprintf('[processIndexes]\n');
pause(0);
if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
    break;
end        

% if ~app.IsRecording
%     return;
% end
%fprintf('[processIndexes] %s', ...
%    formattedDisplayText(tobj));

% try
%     if ~isempty(FPXModeDropdown.UserData)
%         wait(app.FPXModeDropdown.UserData);
%     end
% catch
%     % TODO: Print error
% end

%fprintf('Calling @processIndexesInternal...\n');
if isequal(durs,false) || isempty(durs)
    fprintf('[processIndexes] durs is empty --> returning from function\n');
    return;
end
timeMode = bitget(app.XAxisIndex, 2);
timeIdx = timeMode+1;
if isempty(app.DataTable{timeIdx})
    fprintf('[processIndexes] datatable{%d} is empty --> returning from function\n', timeIdx);
    send(app.PlotQueue, durs);
    return;
end
if isempty(app.PageLimits)
    app.PageLimits = app.HgtAxes.XLim; % TODO: Remove later
end

pause(0);
if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
    break;
end        

% switch app.XAxisModeIndex
%     case 1
%         %pageLims = app.DataTable{?}.RelTime(min(max(1,uint64(app.PageLimits)), size(app.DataTable{?},1)));
%         % currentLims = app.DataTable{?}.RelTime(pageLims);
%         % % newLims = currentLims + zoomSpan*app.SPPField.Value;
%         % zoomSpan = double(diff(app.HgtAxes.XLim))*seconds(app.SPPField.Value);
%         pageLims = app.PageLimits;
%         currentLims = app.HgtAxes.XLim;
%         zoomSpan = diff(currentLims);
%         assert(zoomSpan > 0);
%     case 2
%         pageLims = app.PageLimits - app.TimeZero;
%         currentLims = app.HgtAxes.XLim - app.TimeZero;
%         zoomSpan = diff(currentLims);
%         assert(zoomSpan > seconds(0));
%     otherwise
%         pageLims = app.PageLimits;
%         currentLims = app.HgtAxes.XLim;
%         zoomSpan = diff(currentLims);
%         assert(zoomSpan > seconds(0));
% end
currentLims = app.HgtAxes.XLim;
zoomSpan = diff(currentLims);
% pageLims = app.PageLimitsVals{app.XAxisModeIndex,2};
if timeMode
    if ~bitget(app.XAxisModeIndex,1) % absolute
        currentLims = currentLims - app.TimeZero; % convert abstime to reltime!
    end
    wingSize = 1.5*zoomSpan;
    dataRows = app.DataTable{2}(timerange(timerange(currentLims-wingSize, currentLims+wingSize, 'closed')), :);
    if isempty(dataRows)
        fprintf('####### empty dataRows (time mode) ##########\n');
        return;
    end
    relTimes = dataRows.RelTime';
    assert(~isempty(relTimes));
    if isscalar(relTimes)
        pageLimsRelTimes = duration.empty();
    else
        pageLimsRelTimes = relTimes([1 end]);
    end
    pageLimsIdxs = dataRows.Index([1 end])';
    
    if maxDurReceived >= currentLims(2)
        newLims = seconds([0 0]);
        newLims(2) = max(seconds(0),maxDurReceived) + app.XResUnitVals{2,2};
        if newLims(2) > zoomSpan
            newLims(1) = newLims(2) - zoomSpan;
        end
    else
        newLims = currentLims;
    end

    if bitget(app.XAxisModeIndex, 1) % Relative time
        newXData = relTimes;
    else % Absolute time
        newXData = relTimes + app.TimeZero;
        newLims = newLims + app.TimeZero;
    end
    newXData = ruler2num(newXData,app.HgtAxes.XAxis);
    % newYData = dataRows(:, ["ELI", "PeakLoc", "PeakHgt"]);
else % Index mode
    wingSize = uint64(ceil(1.5*double(zoomSpan)));
    if currentLims(1) <= wingSize
        pageLimsIdxs = [1 min(app.LargestIndexReceived, currentLims(2)+pageLims)];
    else
        pageLimsIdxs = [currentLims(1)-wingSize, min(app.LargestIndexReceived, currentLims(2)+wingSize)];
    end
    dataRows = app.DataTable{1}(pageLimsIdxs(1):pageLimsIdxs(2), :);
    % maxIdxReceived = app.DataTable{2}.Index(maxDurReceived);
    if isempty(dataRows) 
        fprintf('####### empty dataRows (index mode) ##########\n');
        return;
        % pageLimsRelTimes = duration.empty();
        % newLims = currentLims;
    elseif (maxDurReceived >= dataRows.RelTime(currentLims(2)))
        newXData = dataRows.Index';
        newLims = ones(1,2, 'uint64');
        %newLims(2) = max(1, maxDurReceived)+app.XResUnitVals{3,1};
        newLims(2) = max(1, app.DataTable{2}.Index(maxDurReceived))+app.XResUnitVals{1,2};
        if newLims(2) > zoomSpan
            newLims(1) = newLims(2) - zoomSpan;
        end
    else
        newXData = dataRows.Index';
        pageLimsRelTimes = dataRows.RelTime(pageLimsIdxs)';
        newLims = currentLims;
    end
    % newYData = dataRows(:, ["RelTime", "ELI", "PeakLoc", "PeakHgt"]);
end

newYData = dataRows(:, ["ELI", "PeakLoc", "PeakHgt"]);
pause(0);
if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
    return;
end

% TODO: Wrap in try/catch???
set(app.eliPlotLine, 'XData', newXData, 'YData', newYData.ELI);
for ch=1:app.NumChannels
    set(app.channelPeakPosLines(ch), 'XData', newXData, ...
        'YData', newYData.PeakLoc(:, ch)');
    set(app.channelPeakHgtLines(ch), 'XData', newXData, ...
        'YData', newYData.PeakHgt(:, ch)');
end

pageLimsRelTimesDbl = seconds(pageLimsRelTimes);
app.PageLimitsVals = { ...
    double(pageLimsIdxs), uint64(pageLimsIdxs) ; ...
    pageLimsRelTimesDbl, pageLimsRelTimes + app.TimeZero ; ...
    pageLimsRelTimesDbl, pageLimsRelTimes ...
};
postset_Page(app);
app.PageSize = wingSize; % TODO: ??

% set([app.HgtAxes app.PosAxes], 'XLim', newLims);

oldCallbackVals = 
    [ app.AxisLimitsCallbackCalculatesPage;
      app.AxisLimitsCallbackCalculatesTicks ];
app.AxisLimitsCallbackCalculatesPage = false;
app.AxisLimitsCallbackCalculatesTicks = false;

try
    setVisibleDomain(app, newLims);
    syncXFields(app);
catch ME
    app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
    app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
    rethrow(ME);
end

app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);

return;

if rulLims(2) <= rulLims(1)
    % app.XNavSlider.Enable = false;
    rulLims(2) = rulLims(1) + app.XResUnitVals{app.XAxisModeIndex,2};
% else
%    app.XNavSlider.Enable = true;
end

if timeMode % Absolute or relative time
    maxIdxOrRelTime = app.LatestTimeReceived;
    if ~bitget(app.XAxisModeIndex, 1) % Absolute time
        rightmostPos = maxIdxOrRelTime + app.TimeZero;
    else % Relative time
        rightmostPos = maxIdxOrRelTime;
    end
else % Index mode
    rightmostPos = app.LargestIndexReceived;
    maxIdxOrRelTime = rightmostPos;
end

rulerTickArgs = updateTicksA(app.TimeZero, true, ...
    app.HgtAxes.InnerPosition(3), newLims, ...
    app.XAxisModeIndex, app.XNavZoomMode, app.XResUnitVals, true);

if ~app.XNavZoomMode
    [sliLims, sliVal, sliEnab] = calcSliderLimsValFromRulerLims( ...
        app.TimeZero, app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, maxIdxOrRelTime, newLims);
    if sliLims(2) <= sliLims(1)
        app.XNavSlider.Enable = false;
        sliLims(2) = sliLims(1) + app.XResUnitVals{app.XAxisModeIndex,1};
    else
        app.XNavSlider.Enable = true;
    end
    sliTickArgs = updateTicksA(app.TimeZero, false, ...
        app.XNavSlider.InnerPosition(3), sliLims, ...
        app.XAxisModeIndex, app.XNavZoomMode, ...
        app.XResUnitVals, true);
    sliPropVals = get(app.XNavSlider, {'MinorTicks', 'MajorTicks', ...
    'MajorTickLabels', 'Limits', 'Value', 'Enable'});
end
rulPropVals = get(app.HgtAxes.XAxis, {'Limits', ...
    'MinorTickValues', 'TickValues'});
axMinorOn = app.HgtAxes.XMinorTick;
% TODO: Annotations / labels

%%%% oldCallbackVals = [ app.AxisLimitsCallbackCalculatesPage ...
%%%%    app.AxisLimitsCallbackCalculatesTicks ];
%%%% app.AxisLimitsCallbackCalculatesPage = false;
%%%% app.AxisLimitsCallbackCalculatesTicks = false;

try
    updateTicksB(app, true, newLims, app.XAxisModeIndex, ...
        rulerTickArgs{:});
    set([app.HgtAxes app.PosAxes], 'XLim', newLims);
    if ~app.XNavZoomMode
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
    app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
    app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
    rethrow(ME);
end
% app.AxisLimitsCallbackEnabled = true;
%%%%% app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
%%%%% app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
if app.IsRecording && (app.PlotTimer.Running(2)=='f')
    start(app.PlotTimer);
end

drawnow nocallbacks;

app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);

return;






fprintf('[processIndexes] invoking processIndexesInternal\n');
%fut0 = parfeval(backgroundPool, @processIndexesInternal, 3, ...
%    currentLims, pageLims, zoomSpan, ...
%    durs, minDurReceived, maxDurReceived);
[a,b,c] = processIndexesInternal(currentLims,pageLims,zoomSpan,durs,minDurReceived,maxDurReceived);
copyDataToPlots(app,a,b,c,minDurReceived,maxDurReceived,durs);
fprintf('Called @processIndexesInternal.\n');
futs1 = parfeval(backgroundPool, @() pause(0), 0);
return;
% Todo: test auto-y enable status to avoid passing data when not necessary? or??
% TODO: Depending on auto-Y settings, spawn parallel Future(s)
% to re-evaluate entire visible domain (fetch from DataTable{})
futs0 = parallel.Future.empty(0,2);

% if nargout
%     varargout = {newdom, tblrows, [fut0 futs]};
% elseif ~isempty(futs)
%     futs(end+1) = afterAll(futs, ...
%         @(F) parfeval(backgroundPool, @app.copyDataToPlots, 0, ...
%         newdom, tblrows, futs, F), 0, 'PassFuture', true);
% else
%     copyDataToPlots(newdom, tblrows, futs);
% end

if ~isempty(futs0)
    futs = futs0(futs0.ID>0);
    %fidxs = (futs0(2)==futs)+1;
else
    futs = futs0;
    %fidxs = uint8.empty();
end

%fprintf('Setting up call to @app.copyDataToPlots...\n');
futs1 = [ fut0 futs0 ...
    afterAll([fut0 futs], ...
    @(F) copyDataToPlots(app, F), ...
    0, 'PassFuture', true) ];
%fprintf('Set up call to @app.copyDataToPlots.\n');

% timerValid = (ishandle(tobj) && isvalid(tobj) && ...
%    isa(tobj, 'timer') && (tobj.Running=="on"));
if isscalar(tobj) && ishandle(tobj) && isvalid(tobj) && isa(tobj, 'timer') ...
        && (tobj.Running(2)=='n')%strcmp(tobj.Running,'on')
    tobj.UserData = futs1;
    fprintf('Set tobj.UserData.\n');
end

while ~wait(futs1, 'finished', 0.01)
    pause(0);
end
display(futs1);
%if nargout
%    varargout = {futs1};
%    fprintf('Set varargout{1}.\n');
%end

end


function [lims, pageLims, limsChg, durs] = processIndexesInternal( ...
    lims, pageLims, zoomSpan, durs, minDurReceived, maxDurReceived)
% zoomSpan = diff(currentLims);
limsChg = (lims(2) < maxDurReceived) && ~(lims(2) < minDurReceived);
if limsChg
    newLims = max(seconds(0), maxDurReceived - [zoomSpan 0]);
    dx = newLims - lims;
    pageLims = pageLims + dx;
    lims = newLims;
end
%durs(durs<pageLims(1)) = [];
%durs(durs>pageLims(2)) = [];
end
