function onKeyboard(app, ~, ev)
% Character: ''
% Modifier: {'shift'}
%       Key: 'shift'
%    Source: [1×1 Figure]
% EventName: 'KeyPress'
if isequal(app.DbgEchoOn,-1)
    display(ev);
end
if isempty(ev.Character)
    %isCtrlOrShift = true;
    if (ev.EventName(end)=='s') && ismember(ev.Key, {'shift', 'control'})
        app.ShiftDown = ismember('shift', ev.Modifier);
        app.CtrlDown = ismember('control', ev.Modifier);
    elseif strcmp(ev.Key, 'shift')
        app.ShiftDown = false;
        app.CtrlDown = ismember('control', ev.Modifier);
    elseif strcmp(ev.Key, 'control')
        app.CtrlDown = false;
        app.ShiftDown = ismember('shift', ev.Modifier);
    end
    %if ~isCtrlOrShift && app.IPPanelActive && (app.MainTabGroup.SelectedTab.Tag=='2')
    %    % pageup key pressed -- DON'T ALLOW SELECTING INVALID PLOTS
    %    
    %elseif (app.MainTabGroup.SelectedTab.Tag=='2') && (app.LargestIndexReceived>1)
    % if app.DbgEchoOn
    %     disp({ev.EventName, strcmp(sprintf("%s", ev.Key), ["shift" "control"]), ...
    %         [ismember('shift', ev.Modifier), ismember('control', ev.Modifier)], ...
    %         [app.ShiftDown, app.CtrlDown]});
    %         %cellfun(@(x) ismember(x, ["shift" "control"]), ev.Modifier)});
    % end
    updateArrowButtonState(app);
elseif endsWith(ev.EventName, 'Release')
    return;
elseif app.IPPanelActive && endsWith(ev.Key, 'arrow') && (app.MainTabGroup.SelectedTab.Tag=='2')
    %fprintf('arrow key pressed (Selected plot index: %d).\n', app.IPPlotSelection);
    switch ev.Key(1)
        case 'd'
            if app.IPPlotSelection < app.NumChannels
                app.IPPlotSelection = app.IPPlotSelection + 1;
            else
                app.IPPlotSelection = 1;
            end
        case 'u'
            if app.IPPlotSelection > 1
                app.IPPlotSelection = app.IPPlotSelection - 1;
            else
                app.IPPlotSelection = app.NumChannels;
            end
        otherwise
            xext = 2\(app.AnalysisParams.PSZWidth - 1);
            if ~ishghandle(app.IPzoneRects(1,app.IPPlotSelection)) || ~isvalid(app.IPzoneRects(1,app.IPPlotSelection))
                return;
%                 if ev.Key(1)=='l'
%                     xpos = 1+xext;
%                 elseif ev.Key(1)=='r'
%                     xpos = app.fdm(2)-xext;
%                 end
%                 src = app.tl.Children(end+1-app.IPPlotSelection);
%                 app.IPzoneRects(1,app.IPPlotSelection) = images.roi.Rectangle('Parent', src, ...
%                     'Color', [0.8 0.8 0.8], 'SelectedColor', [1 0 1], ...
%                     'Selected', true, 'FixedAspectRatio', true, ...
%                     'LineWidth', eps, 'FaceAlpha', 0.4, ...
%                     "Deletable", true, "InteractionsAllowed", "translate", ...
%                     "FaceSelectable", true, "LabelVisible", "off", "Rotatable", false, ...
%                     'Tag', src.Tag, 'Visible', true, ...
%                     'Position', [xpos - xext, src.YLim(1)-1, app.AnalysisParams.PSZWidth, diff(src.YLim)+3], ...
%                     'DrawingArea', [src.XLim(1), src.YLim(1)-1, diff(src.XLim)+1, diff(src.YLim)+3]);
            elseif ev.Key(1)=='l'
                if (app.IPzoneRects(1,app.IPPlotSelection).Position(1) <= 1+xext)
                    return;
                end
                xpos = app.IPzoneRects(1,app.IPPlotSelection).Position(1) - 1;
                app.IPzoneRects(1,app.IPPlotSelection).Position(1) = xpos;
            elseif ev.Key(1)=='r'
                if (app.IPzoneRects(1,app.IPPlotSelection).Position(1) >= app.fdm(2)-xext)
                    return;
                end
                xpos = app.IPzoneRects(1,app.IPPlotSelection).Position(1) + 1;
                app.IPzoneRects(1,app.IPPlotSelection).Position(1) = xpos;
            else
                return; % This shouldn't happen anyway
            end
            % app.DataTable{1}{app.SelectedIndex, 'PSZL'}(app.IPPlotSelection) = xpos;
            % app.DataTable{2}{app.SelectedIndex, 'PSZL'}(app.IPPlotSelection) = xpos;
            setChunkTableItem(app, [], 'PSZL1', app.IPPlotSelection, xpos);
    end
    %isCtrlOrShift = false;
elseif strcmp(ev.Key, 'return') && app.IPPanelActive && (app.MainTabGroup.SelectedTab.Tag=='2') % enter key pressed
    xext = 2\(app.AnalysisParams.PSZWidth - 1);
    xpos = double(app.DataTable{1}{app.SelectedIndex, 'PSZL'}(app.IPPlotSelection));
    xpos1 = app.DataTable{1}{app.SelectedIndex, 'PeakLoc'}(app.IPPlotSelection);
    src = app.tl.Children(end+1-app.IPPlotSelection);
    if ~ishghandle(app.IPzoneRects(1,app.IPPlotSelection)) || ~isvalid(app.IPzoneRects(1,app.IPPlotSelection))
        if isnan(xpos)
            if isnan(xpos1)
                xpos = double(idivide(app.fdm(2),2,'fix'));
            else
                xpos = xpos1;
            end
        end
        app.IPzoneRects(1,app.IPPlotSelection) = images.roi.Rectangle('Parent', src, ...
            'Color', [0.8 0.8 0.8], 'SelectedColor', [1 0 1], ...
            'Selected', true, 'FixedAspectRatio', true, ...
            'LineWidth', eps, 'FaceAlpha', 0.4, ...
            "Deletable", true, "InteractionsAllowed", "translate", ...
            "FaceSelectable", true, "LabelVisible", "off", "Rotatable", false, ...
            'Tag', src.Tag, 'Visible', true, ...
            'DrawingArea', [src.XLim(1), min(0,src.YLim(1))-2, diff(src.XLim)+1, diff(src.YLim)+4], ...
            'Position', [xpos - xext, min(0,src.YLim(1))-2, app.AnalysisParams.PSZWidth, diff(src.YLim)+4]);
    else
        if ~isnan(xpos1)
            xpos = xpos1;
        else %if isnan(xpos)
            return;
            %xpos = fix(2.0\app.fdm(2));
        end

        set(app.IPzoneRects(1,app.IPPlotSelection), ...
            'Color', [0.8 0.8 0.8], 'SelectedColor', [1 0 1], ...
            'Selected', true,  'Visible', true, ...
            'LineWidth', eps, 'FaceAlpha', 0.4, ...
            "InteractionsAllowed", "translate", ...
            'DrawingArea', [src.XLim(1), min(0,src.YLim(1))-2, diff(src.XLim)+1, diff(src.YLim)+4], ...
            'Position', [xpos - xext, min(0,src.YLim(1))-2, app.AnalysisParams.PSZWidth, diff(src.YLim)+4]);
    end
    % app.DataTable{1}{app.SelectedIndex, 'PSZL'}(app.IPPlotSelection) = xpos;
    % app.DataTable{2}{app.SelectedIndex, 'PSZL'}(app.IPPlotSelection) = xpos;
    setChunkTableItem(app, {}, 'PSZW1', app.IPPlotSelection, app.AnalysisParams.PSZWidth);
    setChunkTableItem(app, [], 'PSZL1', app.IPPlotSelection, xpos);
elseif (app.MainTabGroup.SelectedTab.Tag=='2')
    if isequal(ev.Key, 'backquote') %|| ismember(ev.Character, {'`', '~'})
        fprintf('`/~ key pressed (char: %s).\n', ev.Character);
        if ~app.IPPanelActive
            app.IPPanelActive = true;
        end
    elseif isequal(ev.Key, 'escape')
        fprintf('Escape key pressed.\n');
        if app.IPPanelActive
            app.IPPanelActive = false;
        end
    elseif isequal(ev.Key, 'delete')
        fprintf('Delete key pressed.\n');
        if app.IPPanelActive && isvalid(app.IPzoneRects(1,app.IPPlotSelection))
            delete(app.IPzoneRects(1,app.IPPlotSelection));
            app.AnalysisParams.PSZLocations(:, app.IPPlotSelection) = NaN;
            setChunkTableItem(app, {}, 'PSZW1', app.IPPlotSelection, 0);
            setChunkTableItem(app, [], 'PSZL1', app.IPPlotSelection, 0);
            % app.IPzoneRects(1,app.IPPlotSelection) = images.roi.Rectangle.empty();
            % TODO: Change appearance of IPpeakLine
        end
    elseif ev.Character=='[' % Key: leftbracket...
        % TODO: With shift, go to next discontinuity
        if app.SelectedIndex > 1
            app.SelectedIndex = app.SelectedIndex - 1;
        end
    elseif ev.Character==']' % Key: rightbracket...
        % TODO: With shift, go to next discontinuity
        if (app.LargestIndexReceived > 2) && (app.SelectedIndex < app.LargestIndexReceived)
            app.SelectedIndex = app.SelectedIndex + 1;
        end
    elseif ev.Character=='\' % Key: backslash...
        % TODO: With shift, alter behavior??
        if ~app.SelectedIndex || (app.LargestIndexReceived < 3)
            return;
        end
        if ~ismember(app.SelectedIndex, app.DataTable{3}.Index)
            % Need to add to data table
            ax = app.HgtAxes;
            relTime = app.DataTable{1}{app.SelectedIndex, 'RelTime'};

            if ~bitget(app.XAxisModeIndex,2)
               val = double(app.SelectedIndex);
            elseif bitget(app.XAxisModeIndex,1)
                val = double(ruler2num(relTime, ax.XAxis));
            else
                val = double(ruler2num(relTime + app.TimeZero, ax.XAxis));
            end

            constLine = matlab.graphics.chart.decoration.ConstantLine('InterceptAxis', 'x', ...
                'Parent', ax, 'Value', NaN(1,1,'double'), 'Color', [1 0 1], 'LineWidth', 2, 'LineStyle', ':', 'Alpha', 1.0); % Line width?
            % set(constLine, 'Color', [1 0 1], 'LineWidth', 1.5);
            constLine.Value = double(val);
            % constLine.Value = double(constLine.Value);
            %mskBefore = app.DataTable{3}.SelectedIndex < app.SelectedIndex;
            %mskAfter = app.DataTable{3}.SelectedIndex > app.SelectedIndex;
            %app.DataTable{3} = vertcat(app.DataTable{3}(mskBefore, :), ...
            %    {}, ...
            %    app.DataTable{3}(mskAfter, )

            % RelTime | Index, SplitStatus, IsDiscontinuity, Discontinuities, ROI
            app.DataTable{3}(relTime, :) = ... %['Index', 'SplitStatus', 'ROI']) ...
                { app.SelectedIndex, 3, false, false(1,app.NumChannels), constLine };
            updateChunkTable(app, false, app.DataTable{3}(relTime, :));
            app.ReanalyzeButton.Enable = true;
        else
            relTime = app.DataTable{1}{app.SelectedIndex, 'RelTime'};
            ss = app.DataTable{3}{relTime, 'SplitStatus'};
            ss1 = bitxor(ss, 3);

            % 10: yes, synced
            % 11: yes: unsynced
            % 00: no, synced
            % 01: no, unsynced
            constLine = app.DataTable{3}{relTime,'ROI'};
            if bitget(ss, 2) % Currently "yes" (whether synced or unsynced)
                if app.DataTable{3}{relTime, 'IsDiscontinuity'}
                    % SPLIT -> DISC
                    if bitget(ss1, 1) % Is in sync; will be out of sync
                        % i SPLIT -> o DISC :: dashed, light magenta
                        % Assume the line exists.
                        constLine.Color = [1 0.6 1];
                        constLine.LineStyle = ':';
                        constLine.LineWidth = 1.5; % Line width?
                    else % Is out of sync; will be in sync
                        % o SPLIT -> i DISC :: solid, dk gray
                        % Assume the line exists.
                        constLine.LineStyle = '-';
                        constLine.Color = [0 0 0]; % [0.35 0.35 0.35];
                        constLine.LineWidth = 0.5;
                    end
                elseif bitget(ss1, 1) % Is in sync; will be out of sync
                    % i SPLIT -> o NONE :: dashed, lt magenta
                    % Assume the line exists.
                    set(constLine, 'LineStyle', '--', 'Color', [1 0.65 0.85], 'LineWidth', 2); % Line width?
                else % Is out of sync; will be in sync
                    % o SPLIT -> i NONE :: no line
                    if isgraphics(constLine) && ishghandle(constLine) && isvalid(constLine)
                        constLine.LineStyle = 'none';
                        delete(constLine);
                    end
                    % app.DataTable{3}{relTime, 'ROI'} = gobjects(1);
                    % constLine.Visible = false;
                    % if ~ss1
                    %     app.DataTable{3}{relTime, 'SplitStatus'} = ss1;
                    %     app.DataTable{3}(relTime, :) = [];
                    % else
                    %     display(ss1);
                    % end
                end
            else % Currently no split --> add split
                % NONE/DISC -> SPLIT :: Add (unsync) boundary line...
                if ~ishghandle(constLine) || ~isvalid(constLine) % Assume out of sync, since no ROI exists?
                    % (Assume there is no discontinuity here.)
                    % i NONE -> o SPLIT :: (bold?) dotted, magenta
                    ax = app.HgtAxes;
                    relTime = app.DataTable{1}{app.SelectedIndex, 'RelTime'};
                    if ~bitget(app.XAxisModeIndex,2)
                        val = double(app.SelectedIndex);
                    elseif bitget(app.XAxisModeIndex,1)
                        val = double(ruler2num(relTime, ax.XAxis));
                    else
                        val = double(ruler2num(relTime + app.TimeZero, ax.XAxis));
                    end
                    constLine = matlab.graphics.chart.decoration.ConstantLine('InterceptAxis', 'x', ...
                        'Parent', ax, 'Value', NaN(1,1,'double'), 'LineStyle', ':', 'Color', [1 0 1], 'LineWidth', 1.5, 'Alpha', 1.0);
                    constLine.Value = double(val);
                    % constLine.Value = double(constLine.Value);
                    app.DataTable{3}{relTime, 'ROI'} = constLine;
                elseif bitget(ss1, 1) % Will be out of sync (and ROI already exists)
                    % i NONE/DISC -> o SPLIT :: (bold?) dotted, magenta
                    set(constLine, 'LineStyle', ':', 'LineWidth', 1.5, ...
                        'Color', [1 0 1]);
                else % Will be in sync (and ROI already exists)
                    % o NONE/DISC -> i SPLIT :: (bold?) solid, magenta
                    set(constLine, 'LineStyle', '-', 'LineWidth', 1.5, ...
                        'Color', [1 0 1]);
                end
            end
            % if ss1
            %     app.DataTable{3}{relTime, 'SplitStatus'} = ss1;
            % end
            app.DataTable{3}{relTime, 'SplitStatus'} = ss1;
            updateChunkTable(app, false, app.DataTable{3}(relTime, :));
            if ~ss1
                app.DataTable{3}(relTime, :) = [];
            end
            % if bitget(ss1, 1)
            %     app.ReanalyzeButton.Enable = true;
            % else
            %     % app.ReanalyzeButton.Enable = any(bitget(app.DataTable{3}.SplitStatus, 1));
            %     % TODO
            % end
        end
    elseif ev.Character=='+'
        if app.SelectedIndex && app.IPPanelActive && app.IPPlotSelection &&  ~isempty(app.CurrentChunkInfo)
            currentPSZWidth = app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW1'}(app.IPPlotSelection) + 2;
            currentPSZHW = 2\(currentPSZWidth-1);
            currentPSZPos = app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL1'}(app.IPPlotSelection);
            if (currentPSZWidth < app.fdm(2)) && (currentPSZPos - currentPSZHW >= 1) && (currentPSZPos+currentPSZHW <= app.fdm(2))
                setChunkTableItem(app, [], 'PSZW1', app.IPPlotSelection, currentPSZWidth);
                app.IPzoneRects(1,app.IPPlotSelection).Position([1 3]) = ...
                    double([currentPSZPos - 2\(currentPSZWidth-1), ...
                    currentPSZWidth]); 
            end
        end
    elseif ev.Character=='-'
        if app.SelectedIndex && app.IPPanelActive && app.IPPlotSelection &&  ~isempty(app.CurrentChunkInfo)
            currentPSZWidth = app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW1'}(app.IPPlotSelection);
            if (currentPSZWidth > 3)
                setChunkTableItem(app, [], 'PSZW1', app.IPPlotSelection, currentPSZWidth - 2);
                app.IPzoneRects(1,app.IPPlotSelection).Position([1 3]) = ...
                    double([app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL1'}(app.IPPlotSelection) - 2\(currentPSZWidth-3), ...
                    currentPSZWidth]);
            end
        end
    elseif ev.Character=='='
        if app.SelectedIndex && app.IPPanelActive && app.IPPlotSelection &&  ~isempty(app.CurrentChunkInfo)
            if (app.AnalysisParams.PSZWidth ~= app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW1'}(app.IPPlotSelection))
                currentPSZPos = app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL1'}(app.IPPlotSelection);
                newHW = 2\(app.AnalysisParams.PSZWidth-1);
                if currentPSZPos - newHW < 1
                    newPos = 1 + newHW;
                    setChunkTableItem(app, {}, 'PSZL1', app.IPPlotSelection, newPos);
                elseif currentPSZPos + newHW > app.fdm(2)
                    newPos = app.fdm(2) - newHW;
                    setChunkTableItem(app, {}, 'PSZL1', app.IPPlotSelection, newPos);
                else
                    newPos = currentPSZPos;
                end
                setChunkTableItem(app, [], 'PSZW1', app.IPPlotSelection, app.AnalysisParams.PSZWidth);
                app.IPzoneRects(1,app.IPPlotSelection).Position([1 3]) = ...
                    double([newPos - newHW, app.AnalysisParams.PSZWidth]);
            end
        end
    elseif ev.Character=='>' % Key: period w/ modifier {'shift'}
    elseif ev.Character=='<' % Key: comma w/ modifier {'shift'}
    elseif app.DbgEchoOn
        display(ev);
    end
elseif app.DbgEchoOn
        display(ev);
end