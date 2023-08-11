function postset_IPPanelSelect(app, src, ~)
    % TODO: Wrap cond. (sub)blocks in try/catch for failsafe
    persistent co lastSelection;
    if src.Name(5)=='o' % IPPlotSelection was set
        if isempty(lastSelection)
            lastSelection = 1;
        end
        if ~app.IPPanelActive
            % fprintf('Plot %d is now selected (previous selection: %d); however, panel is not active.\n', app.IPPlotSelection, lastSelection);
            lastSelection = app.IPPlotSelection;
            return; % Return without changing any visual properties
        end
        % fprintf('Plot %d is now selected (previous selection: %d).\n', app.IPPlotSelection, lastSelection);
        if isempty(co)
            co = colororder(app.UIFigure);
        end
        % Apply 'unselected' look to previous selection
        try
            set(app.tl.Children(end+1-lastSelection), 'Color', [0.6 0.6 0.6]);
            %set(app.IPdataLines(lastSelection), 'Marker', 'o', 'MarkerSize', 2);
            set(app.IPfitLines(lastSelection), 'EdgeColor', [0.8 0.8 0.8], ...
                'LineStyle', '-', 'FaceAlpha', 0.2);
            set(app.IPpeakLines(lastSelection), 'Color', [1 0.6 0.4]);
            if ~isempty(app.IPzoneRects) && ishghandle(app.IPzoneRects(1,lastSelection))
                set(app.IPzoneRects(1,lastSelection), 'FaceAlpha', 0.2, 'Selected', false, ...
                    'InteractionsAllowed', 'none');
            end
        catch ME
            fprintf(getReport(ME));
            disp(lastSelection);
        end
        set(app.tl.Children(end+1-app.IPPlotSelection), 'Color', [1 1 1]);
        set(app.IPdataLines(app.IPPlotSelection), 'Marker', '.', 'MarkerSize', 4, ...
            'MarkerEdgeColor', co(app.IPPlotSelection,:));
        set(app.IPfitLines(app.IPPlotSelection), 'LineStyle', 'none', 'FaceAlpha', 0.4);
        set(app.IPpeakLines(app.IPPlotSelection), 'Color', [1 0 0]);

        lastSelection = app.IPPlotSelection;
    else % IPPanelActive was set
        if isempty(co)
            co = colororder(app.UIFigure);
        end
        % Apply (un)selected style to panel and currently-selected plot
        if app.IPPanelActive
            % fprintf('IProfPanel is active (current selected plot: %d).\n', app.IPPlotSelection);
            set(app.IProfPanel, 'BackgroundColor', [0.7 0.95 1], 'BorderWidth', 2, ...
                'HighlightColor', 'blue', 'FontWeight', 'bold', 'ForegroundColor', [0.1 0.25 0.6]);
            % set(app.tl.Children(end+1-app.IPPlotSelection), ...)
            idxs = [1:uint8((app.IPPlotSelection-1)) uint8((app.IPPlotSelection+1)):uint8(app.NumChannels)]; % TODO: Change datatype of NumChannels property
            set(app.tl.Children(end+1-idxs), 'Color', [0.6 0.6 0.6]);
            %set(app.IPdataLines(idxs), 'Marker', 'o', 'MarkerSize', 2);
            set(app.IPfitLines(idxs), 'EdgeColor', [0.8 0.8 0.8], 'LineStyle', '-', ...
                'FaceAlpha', 0.2);
            set(app.IPpeakLines(idxs), 'Color', [1 0.6 0.4]);
            if ~isempty(app.IPzoneRects)
                for rect = app.IPzoneRects(1,idxs)
                    if ishghandle(rect)
                        rect.FaceAlpha = 0.8;
                    end
                end
            end
        else
            % fprintf('IProfPanel is inactive (current selection index: %d).\n', app.IPPlotSelection);
            set(app.IProfPanel, 'BackgroundColor', [0.94 0.94 0.94], 'BorderWidth', 1, ...
                'HighlightColor', [0.4902 0.4902 0.4902], 'FontWeight', 'normal', 'ForegroundColor', [0 0 0]);
            % Deselect all
            if ~isempty(app.IPzoneRects)
                set(app.IPzoneRects(isa(app.IPzoneRects, 'images.roi.Rectangle')), ...
                    'Selected', false, "InteractionsAllowed", "none", ...
                    'LineWidth', eps, 'FaceAlpha', 0.4);
                %'Color', [0.8 0.8 0.8], ...
            end
            % for i=1:app.NumChannels
            %     set(app.IPdataLines, 'MarkerEdgeColor', co(i,:), ...
            %         'Color', min(co(i,:) + 1.5*(1-max(co(i,:))), 1), ...
            %         'Marker', '.', 'MarkerSize', 4, ...
            %         'LineWidth', 0.01, 'LineStyle', 'none');
            % end
            for dataLine=app.IPdataLines
                set(dataLine, 'MarkerEdgeColor', dataLine.UserData(3,:), ...
                'Color', dataLine.UserData(2,:), ...
                'Marker', '.', 'MarkerSize', 4, ...
                'LineWidth', 0.01, 'LineStyle', 'none');
            end
            set(app.IPpeakLines, 'Color', 'red', 'LineWidth', 0.5);
            set(app.IPfitLines, 'EdgeColor', [0 0 0], 'LineStyle', 'none', ...
                'FaceColor', [0 0 0], 'FaceAlpha', 0.4);
            set(app.tl.Children, 'Color', [1 1 1]);
            drawnow;
            return;
        end
    end

    % Apply 'selected' look to current selection (incl. ROIs/lines)
    if ~isempty(app.IPzoneRects) && ishghandle(app.IPzoneRects(1,app.IPPlotSelection))
        set(app.IPzoneRects(1,app.IPPlotSelection), 'Selected', true, ...
            'InteractionsAllowed', 'translate');
    end

    drawnow;
end