
% app, newdom, tblrows
% OR
% app, Fs
% PREVIOUSLY:
% app, newdom, tblrows, varargin
%                       varargin = []
%                    or varargin = {[fut1 fut2], F}
function copyDataToPlots(app, varargin)
fprintf('[copyDataToPlots] %s', formattedDisplayText(varargin));
if nargin == 4
    hasFuts = false;
    [newLims, newPageLims, durs] = varargin{:};
elseif nargin == 7
    hasFuts = false;
    [newLims, newPageLims, durs, minDurReceived,maxDurReceived,durs2] = varargin{:};
    if isempty(durs) || isequal(durs, false)
        durs = durs2;
    end
else
    hasFuts = true;
    Fs = varargin{1};
    if isempty(Fs(1).Error)
        [newLims, newPageLims, durs] = Fs(1).OutputArguments{:};
    else
        for i = 1:length(Fs(1).Error)
            %ME = Fs(1).Error{i};
            ME = Fs(1).Error(i);
            fprintf('Error received from future0 (%d, %s): %s\n', ...
                i, ME.identifier, getReport(ME));
        end
        rethrow(Fs(1).Error(1));
    end
end

if isempty(durs) || isequal(durs,false)
    fprintf('[copyDataToPlots] durs is empty. --> Not copying anything or changing visible domain.\n');
    return;
end

% display(durs);
% display(newPageLims);
timeMode = bitget(app.XAxisModeIndex, 2);
timeIdx = timeMode+1;
if timeMode % Time mode
    trng = timerange(newPageLims(1),newPageLims(2),'closed');
    tblRows = app.DataTable{2}(trng, ["Index" "ELI" "PeakHgt" "PeakLoc"]);
else
    % Assume page lims (idx mode) are already constrained to correct range
    tblRows = app.DataTable{1}(newPageLims(1):newPageLims(2), ...
        ["Index" "RelTime" "ELI" "PeakHgt" "PeakLoc"]);
end

if isempty(tblRows)
    fprintf('[copyDataToPlots] tblRows is unexpectedly empty!! Returning without copying anything or changing visible domain.\n');
    return;
end

% % if bitget(app.XAxisModeIndex, 2) % abs or rel time --abs. already converted to rel
% if timeMode
%     newxdata = tblRows.RelTime;
%     if ~bitget(app.XAxisModeIndex, 1)
%         newxdata = newxdata + app.TimeZero;
%     end
% else
%     newxdata = tblRows.Index;
% end

% set(app.eliPlotLine, 'XData', newxdata, 'YData', tblRows.ELI);
% for ch=1:app.NumChannels
%     set(app.channelPeakPosLines(ch), 'XData', newxdata, ...
%         'YData', tblRows.PeakLoc(:, ch));
%     set(app.channelPeakHgtLines(ch), 'XData', newxdata, ...
%         'YData', tblRows.PeakHgt(:, ch));
% end

% % oldCallbackVal = app.AxisLimitsCallbackCalculatesPage;
% % app.AxisLimitsCallbackCalculatesPage = false;
% % % % app.PageLimits = newxdata([1 end]);
% % if ~bitget(app.XAxisModeIndex,2) % Index mode
% if ~timeMode
%     % % set([app.HgtAxes app.PosAxes], 'XLim', ...
%     % %     tblRows.Index(newLims)');
%     % newLims = tblRows.Index(newLims)';
%     if newLims(1)<=newLims(2)
%         newLims(2) = newLims(1) + app.XResUnitVals{?};
%     end
% %elseif bitget(app.XAxisModeIndex,1) % Relative time
% %    % set([app.HgtAxes app.PosAxes], 'XLim', newLims);
% %else % Absolute time
% else
%     if newLims(2)<=newLims(1)
%         newLims(2) = newLims(1) + seconds(app.XResUnitVals{?});
%     end
%     if ~bitget(app.XAxisModeIndex, 1) % Absolute time
%         % % % % app.PageLimits = app.PageLimits + app.TimeZero;
%         %set([app.HgtAxes app.PosAxes], 'XLim', newLims+app.TimeZero);
%         newLims = newLims + app.TimeZero;
%     end
% end

% % TODO: Remove rows with zero indexes???? And keep for later recheck??
% % newidxs = tblrows.Index(1) : tblrows.Index(end); % TODO: Assumes non-NaN and non-zero idxs
% % for lobj = [app.channelPeakPosLines app.channelPeakHgtLines ...
% %     app.eliPlotLine]
% %     lobj.XData(newidxs) = newxdata;
% % end
% % app.eliPlotLine.YData(newidxs) = tblrows.ELI';
% % %display(tblrows);
% % for ch = 1:app.NumChannels
% %     hl = app.channelPeakHgtLines(ch);
% %     pl = app.channelPeakPosLines(ch);
% %     hl.YData(newidxs) = tblrows.PeakHgt(:, ch)';
% %     pl.YData(newidxs) = tblrows.PeakLoc(:, ch)';
% % end

%fprintf('Class of app.HgtAxes: %s\n', class(app.HgtAxes));
% app.HgtAxes.XLim = newdom; % (PosAxes x is linked with HgtAxes x)

% display(newLims);
set([app.HgtAxes app.PosAxes], 'XLim', newLims);
setVisibleDomain(app, newLims);
drawnow; % limitrate; %nocallbacks; %limitrate;
fprintf('[copyDataToPlots] Drawing occurred.\n');
% app.AxisLimitsCallbackCalculatesPage = oldCallbackVal;


if hasFuts % nargin > 5 % varargin = {[fut1 fut2], F}
    Fs(1) = [];
    idx = 0;
    nfs = length(Fs);
    for fut = Fs
        idx = idx + 1;
        if ~isempty(fut.Error)
            %idx = isequal(varargin{5}(2),fut) + 1;
            for i = 1:length(fut.Error)
                ME = fut.Error{i};
                fprintf('Error received from Y-future %d/%d (%d, %s): %s\n', ...
                    idx, nfs, i, ME.identifier, getReport(ME));
            end
        elseif ~strcmp(fut.State,'Unavailable')
            res = fut.OutputArguments{1};
            if isequal(varargin{5}(2),fut)
                app.PosAxes.YLim = res;
            else
                app.HgtAxes.YLim = res;
            end
        end
    end
end

% if app.XNavZoomMode
%     newNavSliULim = newDomULim - newDomLLim;
%     if bitget(app.XAxisModeIndex, 2) % abs or rel time
%         newNavSliULim = seconds(newNavSliULim);
%     end
% end
%[app.channelPeakPosLines.XData app.channelPeakHgtLines.XData ...
%    app.eliPlotLine.XData] = deal(...)

end