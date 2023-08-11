function handleResData(app, data) % data is a struct
    % fprintf('Received data:'), disp(data);
    % struct( ... % 'DatapointIndex', datapointIndex, ...
    % 'RelativeDatapointIndex', datapointIndex, ...
    % 'AbsTimePos', timePos, 'PeakSearchBounds', ...
    % peakSearchBounds, 'ELI', estimatedLaserIntensity, ...
    % 'SuccessCode', successCode, 'PeakData', peakData, ...
    % 'IntensityProfiles', intprofs, 'EstParams', p1s, ...
    % 'CurveFitBounds', cfitBoundses, ...
    % 'FitProfiles', fitprofs, ...
    % 'CompositeImage', Y1, 'ScaledComposite', Yc, ...
    % 'RatioImage', Yr);

    % RelTime, Index (uint64), PSB (uint16), AvgPL (double), AvgPH (double), ELI (double), PeakLocs, PeakHeights
    % app.ChannelIPs = NaN(0,0,

    % Why did this (without the isempty check) cause a warning?
    %if ~isempty(data) && ~isfield(data) && isnumeric(data) && ~isscalar(data) && isvector(data)
    %    data = datetime(data); % TODO: Streamline / consolidate approach
    %end

    persistent lastException;

    if isdatetime(data)
        if ismissing(app.TimeZero) && ~ismissing(data)
            app.DataTable{1}.Properties.UserData = {app.TimeZero, data};
            app.TimeZero = data;
            fprintf('#### Received new TimeZero: %s ####\n', string(data, 'HH:mm:ss.SSSSSSSSS'));
        end
        clear lastException;
        return;
    elseif isa(data, 'MException')
        if isequal(data, lastException)
            fprintf('###################### MException "%s" received (same as previous) ####################\n', data.identifier);
            return;
        else
            fprintf('###################### MException "%s" received: ######################################\n', data.identifier);
            fprintf('%s\n', strip(getReport(data, 'extended', 'hyperlinks', 'default')));
            lastException = data;
            return;
        end
    elseif ~isstruct(data)
        fprintf('####################### WARNING: Data is unexpectedly neither a struct nor an MException!! ############################\n');
        display(data); % TODO: Warn??
        clear lastException;
        return;
    end
    if isfield(data, 'DatapointIndex')
        idx = data.DatapointIndex;
        clear lastException;
    else % TODO: Error/warn?
        fprintf('####################### WARNING: Data does not contain an index number!! ############################\n');
        display(data);
        return;
        % idx = app.LargestIndexReceived + 1; %size(app.DataTable{2},1)+1;
    end

    if ismissing(data.AbsTimePos)
        fprintf('####################### WARNING: Data for idx %d has NaN AbsTimePos!! ############################\n', idx);
        display(data);
        return;
    end

    % stopRecording(app);
    app.Composites{idx} = data.CompositeImage;
    app.Ycs{idx} = data.ScaledComposite;
    app.Yrs{idx} = data.RatioImage;
    app.SampMask0s(idx,:) = data.SampMask0s;
    app.SampMasks(idx,:) = data.SampMasks;
    app.ROIMasks(idx,:) = data.ROIMasks;
    try % TODO: Data table...?
        app.ChannelFBs(idx,:,:) = shiftdim(data.CurveFitBounds,-1);
        app.ChannelWgts(idx,:) = data.ChannelWgts; % TODO: All weights (table...?)
        app.ChannelWPs(idx,1:size(data.ChannelWPs,1),:) = shiftdim(data.ChannelWPs,-1);
        app.ChannelXData(idx,:) = data.ChannelXData;
    catch ME
        fprintf('Error "%s" occurred while storing fit bounds / weights: %s\n', ...
            ME.identifier, getReport(ME));
    end

    if idx<=1
        % TODO: Error if idx = 0?
        app.ChannelIPs = shiftdim(data.IntensityProfiles, -1);
        app.ChannelFPs = shiftdim(data.FitProfiles, -1);
        %app.ChannelIPs = reshape(data.IntensityProfiles, 1, [], app.NumChannels);
            %app.ChannelFPs = reshape(data.FitProfiles, 1, [], app.NumChannels);
    else
        if isempty(app.ChannelIPs) % TODO: Warn??
            emptyProfiles = NaN([(idx-1) size(data.IntensityProfiles)]);
            app.ChannelIPs = cat(1, emptyProfiles, ...
                shiftdim(data.IntensityProfiles, -1));
            app.ChannelFPs = cat(1, emptyProfiles, ...
                shiftdim(data.FitProfiles, -1));
        else
            %app.ChannelIPs(idx,:,:) = reshape(data.IntensityProfiles, 1, [], app.NumChannels);
            %app.ChannelFPs(idx,:,:) = reshape(data.FitProfiles, 1, [], app.NumChannels);
            if isempty(data.IntensityProfiles)
                app.ChannelIPs(idx,1:app.fdm(2),1:app.NumChannels) = NaN;
            else
                app.ChannelIPs(idx,:,:) = shiftdim(data.IntensityProfiles, -1);
            end
            if isempty(data.FitProfiles)
                app.ChannelFPs(idx,1:app.fdm(2),1:app.NumChannels) = NaN;
            else
                app.ChannelFPs(idx,:,:) = shiftdim(data.FitProfiles, -1);
            end
        end
    end

    % avgPeakData = mean(data.PeakData, 2);

    if ismissing(app.TimeZero)
        app.TimeZero = data.AbsTimePos;
    end
    relTime = data.AbsTimePos - app.TimeZero;
    if ~isscalar(idx)
        fprintf('####### WARNING: EMPTY idx @ absTime %s #########\n', string(data.AbsTimePos, 'HH:mm:ss.SSSSS'));
        display(idx);
        return;
    end
    if ~allfinite(data.PeakData)
        numNan = sum(isnan(data.PeakData), 'all');
        fprintf('####### WARNING: NAN PEAK DATA (%d/%d) @ relTime %s (idx: %d, size of datatable before adding: %d) #########\n', ...
            numNan, numel(data.PeakData), ...
            string(relTime, 'mm:ss.SSSSSSSSS'), idx, app.LargestIndexReceived); %size(app.DataTable{?},1));
    end

    % data.PeakSearchZones(isnan(data.PeakSearchZones)) = 0;
    % data.CurveFitBounds(isnan(data.CurveFitBounds)) = 0;
    % disp(cellfun(@iscell, {idx, data.PeakSearchBounds, data.PeakSearchZones, data.CurveFitBounds, data.ResNorms}));
    % display(idx);
    % display(data.PeakSearchBounds);
    % display(data.PeakSearchZones);
    % display(data.CurveFitBounds);

    try
        app.DataTable{1}(idx, :) = { ...
            idx, relTime, data.PeakSearchBounds, ...
            data.PeakSearchZones(1,:), ...
            data.PeakSearchZones(2,:), data.CurveFitBounds(1,:), ...
            data.CurveFitBounds(2,:), data.ResNorms, ...
            data.ELI, data.PeakData(1,:), data.PeakData(2,:) };
    catch ME
        fprintf('[handleResData] Error "%s" occurred while assigning to DT 1: %s\n', ...
            ME.identifier, getReport(ME));
        display(app.DataTable{1});
        display({ ...
            idx, relTime, data.PeakSearchBounds, ...
            data.PeakSearchZones(1,:), ...
            data.PeakSearchZones(2,:), data.CurveFitBounds(1,:), ...
            data.CurveFitBounds(2,:), data.ResNorms, ...
            data.ELI, data.PeakData(1,:), data.PeakData(2,:) });
    end
    %app.DataTable{?}.RelTime(idx) = data.AbsTimePos - app.TimeZero;

    % Index, (RelTime), PSB, PSZL, PSZW, CFBL, CFBR, ResNorm, ELI, PeakLoc, PeakHgt
    
    try
        % fprintf('[handleResData] data.PeakSearchZones:\n'); display(data.PeakSearchZones);
        app.DataTable{2}(relTime, :) = { ...
        idx, data.PeakSearchBounds, data.PeakSearchZones(1,:), ...
        data.PeakSearchZones(2,:), data.CurveFitBounds(1,:), ...
        data.CurveFitBounds(2,:), data.ResNorms, ...
        data.ELI, data.PeakData(1,:), data.PeakData(2,:) };
    catch ME
        fprintf('[handleResData] Error "%s" occurred while assigning to DT 1: %s\n', ...
            ME.identifier, getReport(ME));
        display(app.DataTable{2});
        display({ ...
        idx, relTime, data.PeakSearchBounds, data.PeakSearchZones(1,:), ...
        data.PeakSearchZones(2,:), data.CurveFitBounds(1,:), ...
        data.CurveFitBounds(2,:), data.ResNorms, ...
        data.ELI, data.PeakData(1,:), data.PeakData(2,:) });
    end
    if relTime > app.LatestTimeReceived
        app.LatestTimeReceived = relTime;
        app.LargestIndexReceived = idx; %min(idx, size(app.DataTable{?},1));
        assert(isscalar(app.LargestIndexReceived));
    %elseif idx > app.LargestIndexReceived
    %    app.LargestIndexReceived = idx;
    %    %app.LargestIndexReceived = min(idx, size(app.DataTable{2},1));
    %    app.LatestTimeReceived = max(app.LatestTimeReceived, relTime);
    end

    % fprintf('[handleResData] idx: %d, absTime: %s, relTime: %s\n', idx, string(data.AbsTimePos, 'HH:mm:ss.SSSSSSSSSSSS'), string(relTime, 'mm:ss.SSSSSSSSS'));
    send(app.PlotQueue, relTime);

    % drawnow limitrate;
    pause(0);
    
    if ~app.IsRecording
        cleanDataTables(app);
        if app.PlotTimer.Running(2)=='f'
            processPlotQueue(app, []);
        end
    end

end