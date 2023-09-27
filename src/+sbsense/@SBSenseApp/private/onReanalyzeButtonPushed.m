function onReanalyzeButtonPushed(app, src, ~)
    idx = app.SelectedIndex;

    if ~idx
        fprintf('[onReanalyzeButtonPushed] No index selected. Returning.\n');
        return;
    end
    
    app.Analyzer.PSBL = app.PSBIndices(1);
    app.Analyzer.PSBR = app.PSBIndices(2);

    set([src, app.AutoReanalysisToggleButton, ...
        app.LeftArrowButton app.RightArrowButton ...
        app.DatapointIndexField app.FPXModeDropdown ...
        app.XResKnob app.XNavSlider ...
        app.FPXMinField app.FPXMinSecsField ...
        app.FPXMinColonLabel app.FPXMaxColonLabel ...
        app.FPXMaxField app.FPXMaxSecsField ...
        app.FPXModeDropdown app.IProfPanel ...
        app.RecButton app.RatePanel], 'Enable', false);
    % app.propListeners(end).Enabled = false;

    try
        set(app.FPSelPatches, 'FaceColor', [0.4 0.05 0.7]);
        % PSBs = app.PSBIndices;
        % 10: yes, synced
        % 11: yes: unsynced
        % 00: no, synced
        % 01: no, unsynced
        if isempty(app.CurrentChunkInfo)
            if isempty(app.DataTable{3})
                splitIdxs = [];
            else
                % splitIdxs = app.DataTable{3}{ismember(app.DataTable{3}.SplitStatus, [1 2]), 'Index'};
                splitIdxs = app.DataTable{3}{logical(bitget(app.DataTable{3}.SplitStatus, 2)), 'Index'};
            end
            if ~any(splitIdxs)
                startIdx = 1; endIdx = app.LargestIndexReceived;
            elseif ~any(splitIdxs<app.SelectedIndex)
                startIdx = 1; endIdx = splitIdxs(1);
            elseif ~any(splitIdxs>app.SelectedIndex)
                startIdx = splitIdxs(1); endIdx = app.LargestIndexReceived;
            else
                i1 = find(splitIdxs<=app.SelectedIndex,1,'last');
                i2 = find(splitIdxs>=app.SelectedIndex,1,'first');
                startIdx = splitIdxs(i1); endIdx = splitIdxs(i2);
            end
        else
            startIdx = app.CurrentChunkInfo{1,2}(1);
            endIdx = app.CurrentChunkInfo{1,2}(2);
        end

        numIdxs = double(endIdx - startIdx + 1);
        numRem = numIdxs;
        % oldPatchPositions = {app.FPSelPatches.Position};
        % TODO: Set visible domain?

        % Set analysis parameters

        msk = logical(bitget(app.DataTable{3}.SplitStatus, 1));
        mskIdxs = app.DataTable{3}.Index;
        msk = msk & (mskIdxs>=startIdx) & (mskIdxs<=endIdx);
        toSync = app.DataTable{3}{msk, 'Index'};

        % set(src, 'Enable', true)
        d = uiprogressdlg(app.UIFigure, 'Title', sprintf('Reanalyzing datapoints #%u through #%u...', startIdx, endIdx), ...
            'Message', { ...
                'Beginning reanalysis...', ...
                sprintf('Remaining datapoints: %d/%d', numIdxs, numIdxs) }, ...
            'Cancelable', 'on');

        if isequal(app.HgtAxes.XLim, app.PosAxes.XLim)
            oldDom = app.HgtAxes.XLim;
            if bitget(app.XAxisModeIndex, 2)
                if isequal([startIdx endIdx], app.DataTable{1}.Index([startIdx endIdx]))
                    if bitget(app.XAxisModeIndex, 1)
                        set([app.HgtAxes, app.PosAxes], 'XLim', ...
                            app.DataTable{1}.RelTime([startIdx endIdx]));
                    else
                        set([app.HgtAxes, app.PosAxes], 'XLim', ...
                            app.TimeZero + app.DataTable{1}.RelTime([startIdx endIdx]));
                    end
                
                else
                    oldDom = [];
                end
            else
                try 
                    set([app.HgtAxes, app.PosAxes], 'XLim', [startIdx endIdx]);
                catch ME3
                    oldDom = [];
                    fprintf('[onReanalysisButtonPushed] Error trying to set XLim to [%g %g]: %s\n', ...
                        startIdx, endIdx, getReport(ME3));
                end
            end    
        else
            oldDom = [];
        end

        try
            app.Analyzer.LogFile = fopen("SBSense_log.txt", "a");
            %fut = reanalyzeData(idx, ...
            %    PSBs... %app.DataTable{1}{idx, 'RelTime'}, ...
            %    app.Composites{idx});
            % fut = parfeval(backgroundPool, @sbsense.improc.analyzeHCs, 1, ...
            %     app.AnalysisParams, PSBs, true, false, false, ...
            %     app.Composites{idx}, []);
            % src.UserData = fut;
            % if isempty(fut)
            %     error('Empty future!');
            % end
            
            % res = [];
            % while isempty(res) % ~strcmp(fut.Status, 'finished')
            %     pause(0.050); % TODO: Unnecessary when using "fetchNext"?
            %     [~, res] = fetchNext(fut, 0); % wait(fut, 'finished', 0);
            % end
            % % res = fetchNext(fut);

            % if isempty(res)
            %     error('Empty result!');
            % elseif isa(res, 'MException')
            %     rethrow(res);
            % end
            prepareReanalysis(app.Analyzer);
            anySuccess = false;
            lastParams = double.empty();
            if ~isempty(app.ChunkTable) && ~isempty(app.CurrentChunkInfo)
                app.AnalysisParams.PSZLocations = ...
                    vertcat(app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL1'} ,...
                    app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW1'});
            end
            for idx = startIdx:1:endIdx
                if d.CancelRequested
                    break;
                end
                try
                    img = readimage(app.ImageStore.UnderlyingDatastores{1}, double(idx));
                    assert(all(size(img, [1 2]) > 1, 'all'));
                    data = sbsense.improc.analyzeHCsParallel(app.Analyzer, 1, app.AnalysisParams, ...
                        app.PSBIndices, true, idx, false, img, ... %app.Composites{idx}, ...
                        app.AnalysisParams.PSZLocations, double(lastParams)); % TODO: Make sure the PSZ & other analysis values are up-to-date
                    if d.CancelRequested
                        break; % TODO?
                    end
                    d.Message = { sprintf('Currently reanalyzing datapoint #%u.', idx), ...
                        sprintf('Remaining datapoints: %d/%d (%0.4f%% complete)', numRem, numIdxs, 1 - numRem/numIdxs) };
                    if isempty(data)
                        error('Empty result!');
                    elseif isa(data, 'MException')
                        rethrow(data);
                    elseif isstruct(data)
                        if isfield(data, 'EstParams') && ~isempty(data.EstParams) && ~anynan(data.EstParams)
                            lastParams = data.EstParams;
                        end
                        updatePlotAfterReanalysis();
                        anySuccess = true;
                    else
                        fprintf('[reanalysis] Received result of unexpected type "%s" while re-analyzing datapoint #%u.\n', ...
                            class(data), idx);
                    end
                catch ME1
                    fprintf('[reanalysis] Error "%s" occurred while re-analyzing datapoint #%u or storing the result: %s\n', ...
                        ME1.identifier, idx, getReport(ME1));
                    break;
                end
                numRem = numRem - 1;
                if ~d.CancelRequested
                    % set(d, 'Value', 1 - numRem/numIdxs, 'Message', sprintf('Remaining datapoints: %d/%d (%0.4f%% complete)', numRem, numIdxs, 1 - numRem/numIdxs));
                    d.Value = 1 - numRem/numIdxs;
                end
            end

            try 
                fclose(app.Analyzer.LogFile);
            catch ME
                fprintf('[stopRecording] Closing LogFile failed due to error: %s\n', getReport(ME));
            end
            
            if isvalid(d) 
                if d.CancelRequested
                    delete(d);
                    set(app.FPSelPatches, 'FaceColor', [1 1 0]);
                    set([app.AutoReanalysisToggleButton, ...
                        app.LeftArrowButton app.RightArrowButton ...
                        app.DatapointIndexField app.FPXModeDropdown ...
                        app.XResKnob app.XNavSlider ...
                        app.FPXMinField app.FPXMinSecsField ...
                        app.FPXMinColonLabel app.FPXMaxColonLabel ...
                        app.FPXMaxField app.FPXMaxSecsField ...
                        app.FPXModeDropdown ... % app.FPPosPanel app.FPHgtPanel ...
                        app.IProfPanel ...
                        app.RecButton app.RatePanel], 'Enable', true);
                    if ~isempty(oldDom)
                        set([app.HgtAxes, app.PosAxes], 'XLim', oldDom);
                    end
                    plotDatapointIPs(app, app.SelectedIndex);
                    showDatapointImage(app, app.SelectedIndex);
                    if app.SelectedIndex
                        app.DatapointIndexField.Value = int2str(app.SelectedIndex);
                    else
                        app.DatapointIndexField.Value = '';
                    end
                    return;
                else
                    % close(d);
                    delete(d);
                end
            end
        catch ME 
            % TODO: What to do here?
            % close(d);
            if ~isempty(oldDom)
                set([app.HgtAxes, app.PosAxes], 'XLim', oldDom);
            
            end
            delete(d);
            
            plotDatapointIPs(app, app.SelectedIndex);
            showDatapointImage(app, app.SelectedIndex);
            if app.SelectedIndex
                app.DatapointIndexField.Value = int2str(app.SelectedIndex);
            else
                app.DatapointIndexField.Value = '';
            end
            
            rethrow(ME);
        end

        if ~isempty(oldDom)
            set([app.HgtAxes, app.PosAxes], 'XLim', oldDom);
        end
        
        if app.SelectedIndex
            plotDatapointIPs(app, app.SelectedIndex);
            showDatapointImage(app, app.SelectedIndex);
            app.DatapointIndexField.Value = int2str(app.SelectedIndex);
        else
            app.SelectedIndex = idx; % app.DatapointIndexField.Value = '';
        end

        % TODO: Try/catch; another progress dialog?
        for idx = toSync
            rt = app.DataTable{1}{idx, 'RelTime'};
            cline = app.DataTable{3}{rt, 'ROI'};
            if ~isempty(cline) && all(isgraphics(cline)) && all(ishghandle(cline)) && all(isvalid(cline))
                if bitget(app.DataTable{3}{rt, 'SplitStatus'}, 2) % split at index
                    set(cline, 'LineStyle', '-', 'Color', [1 0 1], ...
                        'LineWidth', 1.5);
                    app.DataTable{3}{rt, 'SplitStatus'} = ...
                        bitset(app.DataTable{3}{rt, 'SplitStatus'}, 1, 0);
                elseif app.DataTable{3}{rt, 'IsDiscontinuity'}
                    set(cline, 'LineStyle', '-', 'LineWidth', 0.5, ...
                        'Color', [0 0 0]); %[0.5804 0.3412 0.4706]);
                    app.DataTable{3}{rt, 'SplitStatus'} = ...
                        bitset(app.DataTable{3}{rt, 'SplitStatus'}, 1, 0);
                else
                    delete(cline);
                    % clear cline;
                    try
                        app.DataTable{3}(rt,:) = []; % Delete row from data table.
                    catch ME3
                        display(app.DataTable{3});
                        rethrow(ME3);
                    end
                end
            else
                fprintf('[reanalysis] Warning: ConstantLine does not exist for datapoint %s.\n', fdt(idx));
            end
        end


        % TODO: Update chunk table
        

        try
            updateDiscontinuityTable(app, [startIdx endIdx]);
        catch ME
            fprintf('[reanalysis] Error occurred while updating discontinuity table after reanalysis of datapoints %u - %u: %s\n', ...
                startIdx, endIdx, getReport(ME));
        end

        % TODO: Set reanalysis button disable???? Shouldn't it already be disabled?

        set(app.FPSelPatches, 'FaceColor', [1 1 0]);
        app.ReanalyzeButton.Enable = false;
    catch ME0
        set(app.FPSelPatches, 'FaceColor', [1 1 0]);
        set([app.AutoReanalysisToggleButton, ...
            app.LeftArrowButton app.RightArrowButton ...
            app.DatapointIndexField app.FPXModeDropdown ...
            app.XResKnob app.XNavSlider ...
            app.FPXMinField app.FPXMinSecsField ...
            app.FPXMinColonLabel app.FPXMaxColonLabel ...
            app.FPXMaxField app.FPXMaxSecsField ...
            app.FPXModeDropdown app.IProfPanel ...
            ... % app.FPPosPanel app.FPHgtPanel ...
            app.RecButton app.RatePanel], 'Enable', true);
            % app.propListeners(end).Enabled = true;
        rethrow(ME0);
    end
    set([app.AutoReanalysisToggleButton, ...
        app.LeftArrowButton app.RightArrowButton ...
        app.DatapointIndexField app.FPXModeDropdown ...
        app.XResKnob app.XNavSlider ...
        app.FPXMinField app.FPXMinSecsField ...
        app.FPXMinColonLabel app.FPXMaxColonLabel ...
        app.FPXMaxField app.FPXMaxSecsField ...
        app.FPXModeDropdown app.IProfPanel ...
        ... % app.FPPosPanel app.FPHgtPanel ...
        app.RecButton app.RatePanel], 'Enable', true);
    % app.propListeners(end).Enabled = true;


    function updatePlotAfterReanalysis()
        if (data.SuccessCode<1) || ~isstruct(data)
            fprintf('[reanalysis] Analysis was of datapoint %u was not completely successful (SuccessCode: %d).\n', idx, data.SuccessCode);
            if isa(data, 'MException')
                fprintf('[reanalysis] Datapoint %u error report: %s\n', idx, getReport(data));
            end
            %if ~isempty(app.DataTable{1}) && ismember(idx, app.DataTable{1}.Index)
            %    && ~(isnan(app.DataTable{1}{idx, 'ELI'}))
            return; % TODO: IPs? When to not overwrite?
        end

        % app.Composites{idx} = data.CompositeImage;
        % app.Ycs{idx} = data.ScaledComposite;
        % app.Yrs{idx} = data.RatioImage;
        app.SampMask0s(idx,:) = data.SampMask0s;
        app.SampMasks(idx,:) = data.SampMasks;
        app.ROIMasks(idx,:) = data.ROIMasks;
        disp({size(data.IntensityProfiles), size(data.FitProfiles)});
        app.ChannelIPsData(idx).AllChannels = data.IntensityProfiles;
        app.ChannelFPsData(idx).AllChannels = data.FitProfiles;
        % app.ChannelIPs(idx, :, :) = shiftdim(data.IntensityProfiles, -1);
        % app.ChannelFPs(idx, :, :) = shiftdim(data.FitProfiles, -1);

        try
            app.ChannelFBs(idx,:,:) = shiftdim(data.CurveFitBounds,-1);
            app.ChannelWgts(idx,:) = data.ChannelWgts;
            app.ChannelWPs(idx,1:size(data.ChannelWPs,1),:) = shiftdim(data.ChannelWPs,-1);
            app.ChannelXData(idx,:) = data.ChannelXData;
        catch ME
            fprintf('Error "%s" occurred while storing fit bounds / weights: %s\n', ...
                ME.identifier, getReport(ME));
        end
        % avgPeakData = mean(data.PeakData, 2);
        % relTime = data.AbsTimePos - app.TimeZero;

        relTime = app.DataTable{1}{idx, 'RelTime'};

        if ~allfinite(data.PeakData)
            numNan = sum(isnan(data.PeakData), 'all');
            fprintf('####### WARNING: NAN PEAK DATA (%d/%d) @ relTime %s (idx: %d, size of datatable before adding: %d) #########\n', ...
                numNan, numel(data.PeakData), ...
                string(relTime, 'mm:ss.SSSSSSSSS'), idx, size(app.DataTable{1},1));
        end

        % TODO: Set status of modified splitlines in range to synced and update their appearance accordingly.
        
        % app.DataTable{1}(idx, :) = { ...
        %     idx, relTime, PSBs, avgPeakData(1,1), avgPeakData(2,1), ...
        %     data.ELI, data.PeakData(1,:), data.PeakData(2,:) };
        % app.DataTable{2}(relTime, :) = { ...
        %     idx, PSBs, avgPeakData(1,1), avgPeakData(2,1), ...
        %     data.ELI, data.PeakData(1,:), data.PeakData(2,:) };

        app.DataTable{1}(idx, :) = { ...
            idx, relTime, data.PeakSearchBounds, ...
            app.AnalysisParams.PSZLocations(1,:), ...
            app.AnalysisParams.PSZLocations(2,:), data.CurveFitBounds(1,:), ...
            data.CurveFitBounds(2,:), data.ResNorms, ...
            data.ELI, data.PeakData(1,:), data.PeakData(2,:) };

        app.DataTable{2}(relTime, :) = { ...
            idx, data.PeakSearchBounds, app.AnalysisParams.PSZLocations(1,:), ...
            app.AnalysisParams.PSZLocations(2,:), data.CurveFitBounds(1,:), ...
            data.CurveFitBounds(2,:), data.ResNorms, ...
            data.ELI, data.PeakData(1,:), data.PeakData(2,:) };

        if bitget(app.XAxisModeIndex, 2) % time mode
            if bitget(app.XAxisModeIndex, 1)
                x = relTime;
            else
                x = relTime + app.TimeZero;
            end
        else
            x = uint64(idx);
        end

        plotDatapointIPs(app, idx);
        showDatapointImage(app, idx);
        app.DatapointIndexField.Value = int2str(idx);

        if isempty(app.PageLimitsVals) ...
            || isempty(app.PageLimitsVals{app.XAxisModeIndex,2})
            updatePaging(app);
        end

        if (app.PageLimitsVals{app.XAxisModeIndex,2}(1) <= x) ...
            && (x <= app.PageLimitsVals{app.XAxisModeIndex, 2}(2))
            % Updated point is within current page, so plot
            if ~bitget(app.XAxisModeIndex,2)
                pidx = find(app.eliPlotLine.XData==ruler2num(x, app.HgtAxes.XAxis),1);
            else
                pidx = find(app.eliPlotLine.XData==idx,1);
            end

            if ~pidx
                fprintf('########## COULDN''T FIND PIDX. ##########\n');
                return; % TODO: Warn/error
            end

            % vals = num2cell(data.PeakData(1,:));
            app.eliPlotLine.YData(pidx) = data.ELI;
            for i=1:app.NumChannels
                app.channelPeakPosLines(i).YData(pidx) = data.PeakData(1,i);
                app.channelPeakHgtLines(i).YData(pidx) = data.PeakData(2,i);
            end
            drawnow limitrate;
        end
    end
end