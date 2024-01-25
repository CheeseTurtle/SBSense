function onXAxisLimitsChanged(app,~,event)
% % arguments(Input)
% %     app; 
% %     %src matlab.graphics.axis.decorator.NumericRuler; 
% %     %src matlab.graphics.axis.decorator.DatetimeRuler;
% %     ~;%src matlab.graphics.axis.decorator.DurationRuler;
% %     event matlab.graphics.eventdata.LimitsChanged;
% % end
% % if event.OldLimits(2) < event.NewLimits(1)

% % if ~bitget(app.XAxisModeIndex, 1) % Abs. time mode
% %     newLims = event.NewLimits - app.TimeZero;
% % end
% % pause(0); % TODO: Remove?
% fprintf('[onXAxisLimitsChange] [%s %s]->[%s %s]\n', ...
%     fdt(event.OldLimits(1)), fdt(event.OldLimits(2)), fdt(event.NewLimits(1)), fdt(event.NewLimits(2)));

import sbsense.utils.fdt;

persistent fut;
if ~(app.IsRecording || isempty(fut))
    cancel(fut); clear fut;
end

try
    if app.AxisLimitsCallbackCalculatesPage && ...
        ~isempty(app.PageLimits) && ...
            ((event.NewLimits(1) < app.PageLimits(1)) ...
        || (event.NewLimits(2) > app.PageLimits(2)))
        % % if isnumeric(app.DataImageAxes.Color)
        % %    app.DataImageAxes.Color = 1 - app.DataImageAxes.Color;
        % % end
        % fprintf('[onXAxisLimitsChange] (%d) PageLimits: %s ==> UPDATING PAGING.\n', ...
        %     app.AxisLimitsCallbackCalculatesPage, fdt(app.PageLimits));
        updatePaging(app);
    % else
    %     fprintf('[onXAxisLimitsChange] (%d) PageLimits: %s ==> No page update.\n', ...
    %         app.AxisLimitsCallbackCalculatesPage, fdt(app.PageLimits));
    end

catch ME
    fprintf('[onXAxisLimitsChanged] Error "%s" while calling ''updatePaging(app)'': %s\n', ...
        ME.identifier, getReport(ME));
end

try
    if app.AxisLimitsCallbackCalculatesTicks
        % fprintf('[onXAxisLimitsChange] AxisLimitsCallbackCalculatesTicks: %d ==> UPDATING TICKS, syncing x fields\n', ...
        %     app.AxisLimitsCallbackCalculatesTicks);

        %if 
            updateTicks(app, true, event.NewLimits, app.XAxisModeIndex, ...
                app.XNavZoomMode, app.XResUnitVals, false);
            syncXFields(app, event.NewLimits);
        %end
    else
        % fprintf('[onXAxisLimitsChange] AxisLimitsCallbackCalculatesTicks: %d ==> no tick update, syncing x fields\n', ...
        %     app.AxisLimitsCallbackCalculatesTicks);
        syncXFields(app, event.NewLimits);
    end
catch ME
    fprintf('[onXAxisLimitsChanged] Error "%s" while updating ticks and/or x-fields: %s\n', ...
    ME.identifier, getReport(ME));
end

try
    % fprintf('[onXAxisLimitsChanged] Calling syncXAxisLabels for NewLimits %s.\n', fdt(event.NewLimits));
    syncXAxisLabels(app, event.NewLimits);
catch ME
    fprintf('[onXAxisLimitsChanged] Error "%s" while updating x-labels: %s\n', ...
    ME.identifier, getReport(ME));
end

% drawnow limitrate;

if ~app.IsRecording
    fut = parfeval(backgroundPool, @() pause(1), 0); % app.DataTable{bitget(app.XAxisModeIndex,2)+(app.XAxisModeIndex<3)}, ...
    fut = [fut afterEach(fut, @app.calcAndApplyVisibleYLims, 0)];
    %fut2 = afterEach(fut, @app.calcAndApplyVisibleYLims, 0);
    %fut = [fut, ... % afterEach(fut, @dispXAxFut, 0, 'PassFuture', true), ...
    %    fut2]; %, afterEach(fut2, @dispXAxFut, 0, 'PassFuture', true)];
end

pause(0);

end

function dispXAxFut(fut)
    display(fut);
    if ~isempty(fut.Error)
        if iscell(fut.Error)
            err = fut.Error{1};
        else
            err = fut.Error;
        end
        fprintf('XAxFut error report ("%s"): %s\n', err.identifier, getReport(err));
    end
end

% function [hgtLims, posLims] = calcVisibleYLims(hgtLines, posLines, axisModeIndex, xax, pauseAmt)
%     if bitget(axisModeIndex, 2)
%         xlims = ruler2num(xax.Limits, xax);
%     else
%         xlims = xax.Limits;
%     end

%     if isempty(hgtLines)
%         hgtLims = [];
%     else
%         hgtLines = hgtLines(hgtLines.Visible);
%         if isempty(hgtLines)
%             hgtLims = [];
%         else
%             % This assumes all hgtLines XData is the same length.
%             msk = [hgtLines.XData];
%             msk = (xlims(1)<=msk) & (msk<=xlims(2));
%             if any(msk)
%                 %mm = minmax([app.channelPeakPosLines(msk).YData]);
%                 ydat = [hgtLines(msk).YData];
%                 if ~allfinite(ydat)
%                     ydat = ydat(isfinite(ydat));
%                 end
%                 hgtLims = minmax(ydat);
%                 if isequal(hgtLims(1),hgtLims(2))
%                     hgtLims = [];
%                 end
%             else
%                 hgtLims = [];
%             end
%         end
%     end
%     if isempty(posLines)
%         posLims = [];
%     else
%         posLines = posLines(posLines.Visible);
%         if isempty(posLines)
%             posLims = [];
%         else
%             % This assumes all posLines XData is the same length.
%             msk = [posLines.XData];
%             msk = (xlims(1)<=msk) & (msk<=xlims(2));
%             if any(msk)
%                 ydat = [posLines(msk).YData];
%                 if ~allfinite(ydat)
%                     ydat = ydat(isfinite(ydat));
%                 end
%                 posLims = minmax(ydat);
%                 if isequal(posLims(1),posLims(2))
%                     posLims = [];
%                 end
%             else
%                 posLims = [];
%             end
%         end
%     end
%     if pauseAmt
%         pause(pauseAmt);
%     end
% end