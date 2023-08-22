function onArrowButtonPushed(app, src, event)
persistent fut;
if ~isempty(fut)
    cancel(fut);
end
srcTag = int16(src.Tag);
if app.ShiftDown
    if app.CtrlDown % ctrl and 
        % TO NEXT ACTIVE DISCONTINUITY
        msk = logical(bitget(app.DataTable{3}.SplitStatus, 2));
        if ~any(msk) % || isempty(app.DataTable{1})
            return;
        end
        if isempty(app.ChunkTable)
            app.ReanalyzeButton.UserData = false;
            updateChunkTable(app);
        end
        splitIdxs = app.DataTable{3}{msk, 'Index'};
    else % Shift only
        if isempty(app.DataTable{3})
            return;
        end
        % TO NEXT DISCONTINUITY
        splitIdxs = app.DataTable{3}.Index;
    end
    if isempty(splitIdxs) % TODO
        return;
    end
    if bitget(srcTag, 2) % to the right
        if ~app.SelectedIndex
            app.SelectedIndex = splitIdxs(end);
            panToIndex(app, 0, app.SelectedIndex, 3);
        else
            idxIdx = find(splitIdxs>app.SelectedIndex,1,'first');
            if ~any(idxIdx) && (splitIdxs(end) ~= app.SelectedIndex)
                app.SelectedIndex = splitIdxs(end);
                panToIndex(app, 0, app.SelectedIndex, 2);
            else
                app.SelectedIndex = splitIdxs(idxIdx);
                panToIndex(app, 0, app.SelectedIndex, 2);
            end
        end 
    else % to the left
        if ~app.SelectedIndex
            app.SelectedIndex = splitIdxs(1);
            panToIndex(app, 0, app.SelectedIndex, 1);
        else
            idxIdx = find(splitIdxs<app.SelectedIndex,1,'last');
            if ~any(idxIdx) && (splitIdxs(1) ~= app.SelectedIndex)
                app.SelectedIndex = splitIdxs(1);
            else
                app.SelectedIndex = splitIdxs(idxIdx);
                panToIndex(app, 0, app.SelectedIndex, 2);
            end
        end
    end
elseif app.CtrlDown % ctrl only % TODOOOO
    % NEXT/PREV PAGE
    return;
    % TODO: QUANTIZE DOMAIN??
    if isempty(app.DataTable{1}) %#ok<UNRCH> 
        return;
    end
    if bitget(srcTag, 2) % to the right
        if app.XAxisModeIndex == 2
            rightEdge = app.HgtAxes.XLim(2) - app.TimeZero;
        else
            rightEdge = app.HgtAxes.XLim(2);
        end
        if bitget(app.XAxisModeIndex, 2) % Abs or rel time
            msk = app.DataTable{3}.RelTime > rightEdge;
        else
            msk = app.DataTable{1}.Index > rightEdge;
        end
        if any(msk)
            
        else
            return;
        end
        % switch app.XAxisModeIndex
        %     case 2
                
        %     case 3
        %     otherwise
        % end
    else % to the left
        if app.XAxisModeIndex == 2
            leftEdge = app.HgtAxes.XLim(1) - app.TimeZero;
        else
            leftEdge = app.HgtAxes.XLim(1);
        end
        if bitget(app.XAxisModeIndex, 2) % Abs or rel time
            msk = app.DataTable{3}.RelTime < leftEdge;
        else
            msk = app.DataTable{1}.Index < leftEdge;
        end
        if any(msk)
        else
            return;
        end
        % switch app.XAxisModeIndex
        %     case 2
                
        %     case 3
        %     otherwise
        % end
    end
else% if event.EventName(1) == 'B' % ButtonPushed
    % sgn = srcTag - int16(50); % -1 for left, 1 for right
    if app.SelectedIndex
        if bitget(srcTag, 2) % To the right
            app.SelectedIndex = app.SelectedIndex + 1;
            panToIndex(app, 0, app.SelectedIndex, -1);
        else % To the left
            app.SelectedIndex = app.SelectedIndex - 1;
            panToIndex(app, 0, app.SelectedIndex, -1);
        end
    else
        lims = app.HgtAxes.XLim;
        if ~bitget(app.XAxisModeIndex, 2) % Index mode
            if bitget(srcTag, 2) % To the right
                app.SelectedIndex = max(0,fix(lims(2)));
                panToIndex(app, 0, app.SelectedIndex, 3);
            else % To the left
                app.SelectedIndex = max(0,ceil(lims(1)));
                panToIndex(app, 0, app.SelectedIndex, 1);
            end
        else % Time mode
            if ~bitget(app.XAxisModeIndex, 1) % absolute time mode
                lims = lims - app.TimeZero;
            end
            idxs = app.DataTable{2}.Index(timerange(lims(1), lims(2)));
            if isempty(idxs)
                app.SelectedIndex = 0;
            elseif bitget(srcTag, 2) % To the right
                app.SelectedIndex = idxs(end);
                panToIndex(app, 0, app.SelectedIndex, 3);
            else % To the left
                app.SelectedIndex = idxs(1);
                panToIndex(app, 0, app.SelectedIndex, 1);
            end
        end
    end
% else
%    disp(event.EventName);
%    error('Unknown event name');
end

if ~app.IsRecording
    focus(app.UIFigure);
    fut = parfeval(backgroundPool, @pause, 0, 1);
    fut = [fut afterEach(fut, @app.updateArrowButtonState, 0)];


    % TODO: Keep selection in view
    % TODO: Click on plot

    
end
end