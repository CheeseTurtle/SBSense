function updatePaging(app) % ,varargin)
lims0 = app.HgtAxes.XLim;
fprintf('####### [updatePaging (isRecording: %d, axis lims = %s) #######\n', app.IsRecording, fdt(lims0)); % , fdt(varargin));
% app.PageLimits = app.FPRulers{app.XAxisModeIndex,1}.Limits; %app.HgtAxes.XLim;
persistent lastlims;

% if ~bitget(app.XAxisModeIndex, 1) % Absolute time mode
%     lims = app.HgtAxes.XLim - app.TimeZero;
% elseif ~bitget(app.XAxisModeIndex, 2) % relative time mode
%     lims = app.HgtAxes.XLim;
%end

if isequal(lastlims, lims0)
    fprintf('[updatePaging] <<< (no change)\n');
    return;
end

switch app.XAxisModeIndex
    case 2
        lims = lims0 - app.TimeZero;
    case 3
        lims = lims0;
    otherwise
        lims = double(lims0);
end

fprintf('[updatePaging]     (before update) PageSize=%s, PageLims=%s\n', ...
    fdt(app.PageSize), fdt(app.PageLimits));

% if nargin==1
if bitget(app.XAxisModeIndex, 2) % TIME MODE (absolute or relative)
    app.PageSize = max(1.5*diff(lims), 4*app.XResUnitVals{app.XAxisModeIndex, 2});
    % really half of the resulting alotted size though ("wing size")
    minLLim = seconds(0); % absolute already converted to relative
    if lims(1) <= minLLim
        copyLims = [minLLim, lims(2) + app.PageSize];
    else
        copyLims = lims + [-app.PageSize, app.PageSize];
    end
    copyLims(2) = min(copyLims(2), app.LatestTimeReceived);
    dataRows = app.DataTable{2}(timerange(copyLims(1), copyLims(2), 'closed'), :);
    newxdata = dataRows.RelTime';
    if ~bitget(app.XAxisModeIndex, 1) % absolute time
        newxdata = ruler2num(newxdata + app.TimeZero, app.HgtAxes.XAxis);
        copyLims = copyLims + app.TimeZero;
    else
        newxdata = ruler2num(newxdata, app.HgtAxes.XAxis);
    end
else % Index mode
    app.PageSize = max(uint64(ceil(1.5*diff(lims0))), 4*app.XResUnitVals{1,2});
    if lims0(1) <= app.PageSize
        copyLims = [1 lims0(2)+app.PageSize];
    else
        copyLims = [lims0(1)-app.PageSize, lims0(2)+app.PageSize];
    end
    % copyLims(2) = min(size(app.DataTable{1},1), copyLims(2));
    % if size(app.DataTable{1},1) < copyLims(2)
    %     copyLims(2) = size(app.DataTable{1},1); % TODO: Append NaN rows?
    % end
    copyLims(2) = min(copyLims(2), app.LargestIndexReceived);
    try
        dataRows = app.DataTable{1}(copyLims(1):copyLims(2), :);
        newxdata = dataRows.Index';
    catch ME
        if ME.identifier=="MATLAB:table:RowIndexOutOfRange"
            % keyboard;
            return;
        else
            rethrow(ME);
        end
    end
end
% else
%     [oldLims,newLims] = varargin{:};
%     if (oldLims(1) < newLims(1)) && (newLims(1) < oldLims(2))
%         copyLims = [oldLims(2) newLims(2)];
%     elseif (oldLims(1) < newLims(2)) && (newLims(2) < oldLims(1))
%
%     else
%         updatePaging(app);
%         return;
%     end
% end

% RelTime, Index (uint64), PSB (uint16), AvgPL (double), AvgPH (double), ELI (double), PeakLocs, PeakHeights
set(app.eliPlotLine, 'XData', newxdata, 'YData', dataRows.ELI');
for ch = 1:app.NumChannels
    set(app.channelPeakHgtLines(ch), 'XData', ...
        newxdata, 'YData', dataRows.PeakHgt(:,ch)');
    set(app.channelPeakPosLines(ch), 'XData', ...
        newxdata, 'YData', dataRows.PeakLoc(:,ch)');
end

app.PageLimits = copyLims;
lastlims = lims0;

fprintf('####### [updatePaging] <<< PageSize=%s, PageLims=%s #######\n', ...
    fdt(app.PageSize), fdt(app.PageLimits));

[app.FPPagePatches.XData] = deal(ruler2num(copyLims([1 2 2 1]), app.HgtAxes.XAxis));

    % TODO: Move this to a separate fcn?
try
    calcAndApplyVisibleYLims(app, copyLims);
    % if ~isempty(app.channelPeakPosLines)
    %     msk = logical([app.channelPeakPosLines.Visible]);
    %     if any(msk)
    %         mm = minmax([app.channelPeakPosLines(msk).YData]);
    %         if ~isempty(mm) && ~anynan(mm) && allfinite(mm)
    %             % app.PosAxes.YLim = mm; % TODO: Round to ticks
    %             app.PosAxes.YAxis(1).Limits = mm;
    %             app.FPPagePatches(2).YData = mm([1 1 2 2]);
    %         end
    %     end
    % end
    % if ~isempty(app.channelPeakHgtLines)
    %     msk = logical([app.channelPeakHgtLines.Visible]);
    %     if any(msk)
    %         mm = minmax([app.channelPeakHgtLines(msk).YData]);
    %         if ~isempty(mm) && ~anynan(mm) && allfinite(mm)
    %             app.HgtAxes.YAxis(1).Limits = mm; % TODO: Round to ticks
    %             app.FPPagePatches(1).YData = mm([1 1 2 2]);
    %         end
    %     end
    % end
catch ME
    fprintf('[updatePaging] Error "%s" occurred while updating YLim: %s\n', ...
        ME.identifier, getReport(ME));
    % disp(ME);
    % rethrow(ME);
end

drawnow limitrate nocallbacks;

end