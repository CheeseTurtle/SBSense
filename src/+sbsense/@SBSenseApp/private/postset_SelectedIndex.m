function postset_SelectedIndex(app, ~, ev)
persistent previousSelectedIndex;
if ev.EventName(2)=='r' % PreSet
    previousSelectedIndex = app.SelectedIndex;
    return;
end

if app.SelectedIndex > app.LargestIndexReceived
    app.SelectedIndex = app.LargestIndexReceived;
end
% persistent co;
if app.SelectedIndex % SelectedIndex > 0
    if ~app.tl.Children(1).Visible
        set(app.tl.Children, 'Visible', true);
    end
    app.DatapointIndexField.Value = num2str(app.SelectedIndex, '%u');
    if  bitget(app.XAxisModeIndex,2) % Time mode (absolute or relative)
        selPos = app.DataTable{1}.RelTime(app.SelectedIndex);
        if ~ismissing(selPos)
            if app.SelectedIndex == 1
                prevPos = seconds(0);
                app.LeftArrowButton.Enable = false;
                app.RightArrowButton.Enable = (app.LargestIndexReceived > 1);
            else
                app.LeftArrowButton.Enable = true;
                i = app.SelectedIndex;
                while i >= 2
                    i = i - 1;
                    prevPos = app.DataTable{1}.RelTime(i);
                    if ~ismissing(prevPos)
                        break;
                    end
                end
                if ismissing(prevPos)
                    prevPos = selPos - seconds(app.XResUnit);
                end
            end
            if app.SelectedIndex >= app.LargestIndexReceived
                nextPos = selPos + seconds(app.XResUnit);
                app.RightArrowButton.Enable = false;
            else
                app.RightArrowButton.Enable = true;
                i = app.SelectedIndex;
                imax = min(app.LargestIndexReceived, ...
                    size(app.DataTable{1}, 1));
                while i < imax
                    i = i + 1;
                    nextPos = app.DataTable{1}.RelTime(i);
                    if ~ismissing(nextPos)
                        break;
                    end
                end
                if ismissing(nextPos)
                    nextPos = selPos + seconds(app.XResUnit);
                end
            end
            if ~bitget(app.XAxisModeIndex, 1) % absolute time mode
                positions = [prevPos selPos nextPos] + app.TimeZero;
            else
                positions = [prevPos selPos nextPos];
            end
        end
    else % Index mode
        selPos = app.SelectedIndex;
        if selPos == 1
            positions = uint64([0 1 2]);
            app.LeftArrowButton.Enable = false;
            app.RightArrowButton.Enable = (app.LargestIndexReceived > 1);
        else
            if ~app.LeftArrowButton.Enable
                app.LeftArrowButton.Enable = true;
            end
            if selPos >= app.LargestIndexReceived
                app.RightArrowButton.Enable = false;
            elseif ~app.RightArrowButton.Enable
                app.RightArrowButton.Enable = true;
            end
            positions = [uint64(selPos - 1) uint64(selPos) uint64(selPos + 1)];
        end
    end

    % fprintf('[postset_SelectedIndex] Positions: %s\n', ...
    %     strip(formattedDisplayText(positions)));

    % TODO: Check for empty table
    pidxs = app.DataTable{1}{app.SelectedIndex, 'PSB'};
    if ~isempty(pidxs)
        app.PSBIndexes = pidxs;
        if any(pidxs==0)
            app.DataTable{1}{app.SelectedIndex, 'PSB'} = app.PSBIndices;
            app.DataTable{2}{ ...
                app.DataTable{1}{app.SelectedIndex,'RelTime'}, ...
                'PSB'} = app.PSBIndices;
            pidxs = double(app.PSBIndices);
        else
            pidxs = double(pidxs);
        end

        try
            app.PSBLeftSpinner.Value = double(pidxs(1));
            app.PSBRightSpinner.Value = double(pidxs(2));
            app.leftPSBLine.Position(:,1) = double(pidxs(1)) - 1;
            app.rightPSBLine.Position(:,1) = double(pidxs(2)) + 1;
        catch ME
            display(ME.identifier);
            disp({app.PSBLeftSpinner.Value, app.PSBLeftSpinner.Limits, pidxs(1)});
            disp({app.PSBRightSpinner.Value, app.PSBRightSpinner.Limits, pidxs(2)});
            rethrow(ME);
        end
    end
else % SelectedIndex = 0;
    app.IPPanelActive = false;
    app.DatapointIndexField.Value = '';
    app.CurrentChunkInfo = {};
    set([app.LeftArrowButton app.RightArrowButton], ...
        'Enable', 0~=app.LargestIndexReceived);
    % for ax = app.tl.Children
    %     if isscalar(ax)
    %         % cla(ax);
    %         ax.Visible = false;
    %     else
    %         for i = 1:length(ax)
    %             % cla(ax(i));
    %             ax(i).Visible = false;
    %         end
    %     end
    % end
    set(app.tl.Children, 'Visible', false);
    selPos = NaN;
end

if ismissing(selPos)
    %if app.FPSelPatches(1).Visible
    set(app.FPSelPatches, 'Visible', false);
    %end
else
    % fprintf('[postset_SelectedIndex] positions:'); disp(positions);
    if bitget(app.XAxisModeIndex,2)
        positions = ruler2num(positions, app.HgtAxes.XAxis);
    else
        positions = double(positions);
    end
    positions(1) = positions(1) + 0.6*diff(positions([1 2]));
    positions(3) = positions(3) - 0.6*diff(positions([2 3]));
    % fprintf('[postset_SelectedIndex] positions:'); disp(positions);
    set(app.FPSelPatches, 'XData', ...
        positions([1 3 3 1]));
    %if ~any(app.FPSelPatches.Visible)
    app.FPSelPatches(1).YData = ...
        app.HgtAxes.YLim([1 1 2 2]);
    app.FPSelPatches(2).YData = ...
        app.PosAxes.YLim([1 1 2 2]);
    set(app.FPSelPatches, 'Visible', true);
    %end
end

if ~app.IsRecording
    app.SaveNotesButton.Enable = false;
    % TODO: Other parameters
    if app.SelectedIndex 
        syncRAB();
    end
    if ~app.SelectedIndex
        app.SelectedIndexImages = cell.empty(0, 3);
    elseif ~isempty(app.ImageStore) && (isempty(app.SelectedIndexImages) || (app.SelectedIndex ~= previousSelectedIndex))
        try
            % display(app.ImageStore);
            % disp(app.ImageStore.UnderlyingDatastores);
            try
                app.SelectedIndexImages = cellfun( ...
                    @(ds) readimage(ds, double(app.SelectedIndex)), ...
                    app.ImageStore.UnderlyingDatastores, ...
                    'UniformOutput', false ...
                    );
            catch ME0
                if strcmp(ME0.identifier, "MATLAB:ImageDatastore:notLessEqual")
                    app.SelectedIndexImages = cell.empty(0, 3);
                    % TODO: Warn?
                else
                    rethrow(ME0);
                end
            end
        catch ME
            fprintf('postset_SelectedIndex] Error encountered when setting SelectedIndexImages (%s): %s\n', ...
                ME.identifier, getReport(ME, 'extended'));
            try
                app.SelectedIndexImages = cell.empty(0, 3);
            catch
                % TODO
            end
        end
    end
    % if app.SelectedIndex
    %     plotDatapointIPs(app, app.SelectedIndex);
    %     showDatapointImage(app, app.SelectedIndex);
    %     % try
    %     %     pidxs = app.DataTable{1}{app.SelectedIndex, 'PSB'};
    %     %     if ~isempty(pidxs)
    %     %         app.leftPSBLine.Position(:,1) = double(pidxs(1)) - 1;
    %     %         app.rightPSBLine.Position(:,1) = double(pidxs(2)) + 1;
    %     %         app.PSBIndexes = pidxs;
    %     %         app.PSBLeftSpinner.Value = double(pidxs(1));
    %     %         app.PSBRightSpinner.Value = double(pidxs(2));
    %     %     end
    %     %     if ~isempty(app.ChannelIPs)
    %     %         if isempty(co)
    %     %             co = colororder(app.UIFigure);
    %     %         end
    %     %         for ch = 1:app.NumChannels
    %     %             ax = nexttile(app.tl, ch);
    %     %             hold(ax,"on");
    %     %             plot(ax, squeeze(app.ChannelIPs(app.SelectedIndex, :, ch)), ...
    %     %                 'Color', co(ch,:));
    %     %             plot(ax, squeeze(app.ChannelFPs(app.SelectedIndex, :, ch)), ...
    %     %                 'Color', [0 0 0]);
    %     %             hold(ax,"off");
    %     %             disableDefaultInteractivity(ax); % TODO
    %     %         end
    %     %     end
    %     % catch ME
    %     %     fprintf('[postset_SelectedIndex] Error "%s": %s\n', ME.identifier, getReport(ME));
    %     % end
    % end
end

    function syncRAB()
        if ~isempty(app.ChunkTable)
            if size(app.ChunkTable, 1) > 1
                idxInTable = find(app.ChunkTable.IsActive & (app.ChunkTable.Index <= app.SelectedIndex), ...
                    1, 'last');
                if isempty(idxInTable)
                    app.ReanalyzeButton.UserData = true; % true;
                    updateChunkTable(app, false);
                end
            else
                idxInTable = 1;
                %app.CurrentChunkInfo = {app.ChunkTable.RelTime(1), ...
                %    [app.ChunkTable.Index(1) app.ChunkTable.EndIndex1(1)]};
            end
            newChunkSE = [app.ChunkTable.Index(idxInTable) app.ChunkTable.EndIndex1(idxInTable)];
            chunkChanged = isempty(app.CurrentChunkInfo) ... %  || (app.ChunkTable.Index(idxInTable)==app.SelectedIndex) ...
                || ~isequal(app.CurrentChunkInfo{2}, newChunkSE);
            app.CurrentChunkInfo = {app.ChunkTable.RelTime(idxInTable), newChunkSE};
            if chunkChanged
                reanalysisEnable = ~(...
                    plotDatapointIPs(app, app.SelectedIndex) ...
                    && ~isempty(showDatapointImage(app, app.SelectedIndex) )) ...
                    || app.ChunkTable{idxInTable, 'IsChanged'};
                try
                    chunkInfo = app.ChunkTable(idxInTable, {'PSZP', 'PSZW', 'PSZL1' 'PSZW1'});
                    for ch=1:app.NumChannels
                        % if chunkInfo.PSZP
                        %     assert(chunkInfo.PSZW);
                        %     xp0 = chunkInfo.PSZP(ch);
                        %     wd0 = double(chunkInfo.PSZW(ch));
                        %     hwd0 = 2\(wd0 - 1);
                        %     xl0 = double(xp0) - hwd0;
                        %     xr0 = double(xp0) + hwd0;
                        %     set(app.IPzoneRects(2,ch), 'XData', [xl0 xl0 xr0 xr0], ...
                        %         'YData', app.tl.Children(end+1-ch).YLim([1 2 2 1]), ...
                        %         'Visible', true);
                        % elseif app.IPzoneRects(2,ch).Visible
                        %     app.IPzoneRects(2,ch).Visible = false;
                        % end
                        if ishghandle(app.IPzoneRects(1,ch)) && isvalid(app.IPzoneRects(1,ch))
                            if chunkInfo.PSZL1(ch)>0
                                if(chunkInfo.PSZW1(ch)<=0)
                                    fprintf('Assertion failed (chunkInfo.PSZW1>0). PSZW1 = %g\n', chunkInfo.PSZW1);
                                end
                                assert(chunkInfo.PSZW1(ch)>0);
                                %if ~isequal(app.IPzoneRects(1,ch).Position(3)), [chunkInfo.PSZL1(ch), chunkInfo.PSZW1(ch)])
                                wd1 = double(chunkInfo.PSZW1(ch));
                                xl1 = double(chunkInfo.PSZL1(ch)) - 2\(wd1-1);
                                % app.IPzoneRects(1,ch).Position(1,[1 3]) = [xl1 wd1];
                                yl = app.IPzoneRects(1,ch).Parent.YLim;
                                app.IPzoneRects(1,ch).Position = [xl1 min(0,yl(1))-2 wd1 diff(yl)+4];
                            else
                                app.IPzoneRects(1,ch).Visible = false;
                            end
                        end
                    end
                catch ME1
                    fprintf('[postset_SelectedIndex] ERROR "%s" while updating PSZ rects for channel %u: %s\n', ...
                        ME1.identifier, ch, getReport(ME1));
                end
                % fprintf('[postset_SelectedIndex] Setting reanalysis button enable to %d.\n', reanalysisEnable);
                app.ReanalyzeButton.Enable = reanalysisEnable;
            else
                % fprintf('[postset_SelectedIndex] Setting reanalysis button enable to %d.\n', ~(...
                %     plotDatapointIPs(app, app.SelectedIndex) ...
                %     && ~isempty(showDatapointImage(app, app.SelectedIndex) )));
                app.ReanalyzeButton.Enable = ~(...
                    plotDatapointIPs(app, app.SelectedIndex) ...
                    && ~isempty(showDatapointImage(app, app.SelectedIndex) ));
            end
        else
            % fprintf('[postset_SelectedIndex] Setting reanalysis button enable to %d.\n', ~(...
            %         plotDatapointIPs(app, app.SelectedIndex) ...
            %         && ~isempty(showDatapointImage(app, app.SelectedIndex) )));
            app.ReanalyzeButton.Enable = ~(...
                        plotDatapointIPs(app, app.SelectedIndex) ...
                        && ~isempty(showDatapointImage(app, app.SelectedIndex) ));
        end
    end
end