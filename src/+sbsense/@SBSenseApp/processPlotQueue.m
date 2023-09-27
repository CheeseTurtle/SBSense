function varargout = processPlotQueue(app, tobj) %#ok<INUSD> 
%fprintf('[processPlotQueue] ...\n');
persistent lastIndexDisplayed;
if app.LargestIndexReceived < 2
    clear lastIndexDisplayed;
    % fprintf('[processPlotQueue] need at least 2 points to plot --> returning from function\n');
    return;
end
if ~app.PlotQueue.QueueLength
    clear lastIndexDisplayed;
    %fprintf('[processPlotQueue] Empty queue.\n');
    return;
    %else
    %idxs = zeros(1,app.PlotQueue.QueueLength, 'uint64');
end
% fprintf('[processPlotQueue] Queue length: %u\n', app.PlotQueue.QueueLength);

try
    [x, TF] = poll(app.PlotQueue, 0);
    if TF && isempty(x)
        fprintf('[processPlotQueue] (Queue length: %d) idxReceived is unexpectedly empty!\n', ...
            app.PlotQueue.QueueLength);
    elseif TF
        [durReceived, y1,yc,yr,ips,fps] = x{:};
        % fprintf('[processPlotQueue] idxReceived: %s\n', idxReceived);
        fprintf('[processPlotQueue] (Queue length: %d) durReceived: %s\n', ...
            app.PlotQueue.QueueLength, string(durReceived,'mm:ss.SSSSS'));
    else
        fprintf('[processPlotQueue] (Queue length: %d) TF = false :/\n', app.PlotQueue.QueueLength);
        return;
    end
    % [idxReceived, TF] = poll(app.PlotQueue); % TODO: Timeout??

    %fprintf('[processPlotQueue] %d (%s) / %s', ...
    %    uint8(TF), formattedDisplayText(idxReceived'), formattedDisplayText(tobj));
    %if isempty(tobj)
    %    fprintf('\n');
    %end
    %if ~TF
    %    return;
    %end

    %idxReceived = uint64(idxReceived);
    durs = [{durReceived} cell(1,app.PlotQueue.QueueLength)];
    %idxs = idxReceived;
    if isscalar(durReceived)
        minIdxReceived = (durReceived);
        maxIdxReceived = (durReceived);
    else
        minIdxReceived = min(durReceived);
        maxIdxReceived = max(durReceived);
    end

    durReceived = duration.empty();
    maxIdxs = app.PlotQueue.QueueLength;
    TF = logical(maxIdxs);
    i = 2;
    while TF
        if ~isempty(durReceived)
            % durReceived = uint64(durReceived);
            i = i + 1; durs{i} = durReceived;
            %idxs = horzcat(idxs, idxReceived); %#ok<AGROW>
            if isscalar(durReceived)
                if any(maxIdxReceived < durReceived)
                    maxIdxReceived = durReceived;
                elseif any(minIdxReceived > durReceived)
                    minIdxReceived = durReceived;
                end
            else
                % maxIdxReceived = max(durReceived, maxIdxReceived);
                if durReceived > maxIdxReceived
                    maxIdxReceived = durReceived;
                    y1 = y1a;
                    yc = yca;
                    yr = yra;
                    ips = ipsa;
                    fps = fpsa;
                end
                minIdxReceived = min(durReceived, minIdxReceived);
            end
        end
        maxIdxs = maxIdxs - 1;
        if ~maxIdxs
            break;
        end
        [x, TF] = poll(app.PlotQueue);
        [durReceived, y1a, yca, yra, ipsa, fpsa] = x{:};
        % [durReceived, TF] = poll(app.PlotQueue); % NO timeout
    end

    clearvars durReceived x y1a yca yra ipsa fpsa;

    %fprintf('[processPlotQueue] idxs received: [ %s ]\n', ...
    %    num2str(idxs));
    durs = horzcat(durs{:});
    % display(durs);
    if nargout
        % varargout = {processIndexes(app, tobj, durs, minIdxReceived,maxIdxReceived)};
        varargout = parallel.Future.empty();
    end
    if true
        % processIndexes(app,tobj, durs, minIdxReceived,maxIdxReceived);
        % fprintf('[processIndexes:inline]\n');
        pause(0);
        % if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
        %     fprintf('[processIndexes:inline] [1] App is not recording, or plot timer is not running. Returning from function.\n');
        %     return;
        % end

        % if ~app.IsRecording
        %     return;
        % end
        %fprintf('[processIndexes:inline] %s', ...
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
            fprintf('[processIndexes:inline] durs is empty or false--> returning from function\n');
            return;
        end
        timeMode = bitget(app.XAxisModeIndex, 2);
        timeIdx = timeMode+1;
        if isempty(app.DataTable{timeIdx})
            fprintf('[processIndexes:inline] datatable{%d} is empty --> returning from function\n', timeIdx);
            send(app.PlotQueue, durs);
            return;
        end
        if isempty(app.PageLimits)
            app.PageLimits = app.HgtAxes.XLim; % TODO: Remove later
        end
        clearvars durs;

        % pause(0);
        % if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
        %     fprintf('[processIndexes:inline] [2] App is not recording, or plot timer is not running. Returning from function.\n');
        %     return;
        % end

        currentLims = app.HgtAxes.XLim;
        zoomSpan = diff(currentLims);
        % pageLims = app.PageLimitsVals{app.XAxisModeIndex,2};
        if timeMode
            minZS = seconds(5*app.XResUnitVals{app.XAxisModeIndex, 2});
            if zoomSpan < minZS
                zoomSpan = minZS;
            end
            if ~bitget(app.XAxisModeIndex,1) % absolute
                currentLims = currentLims - app.TimeZero; % convert abstime to reltime!
            end
            wingSize = max(1.5*zoomSpan, 5*app.XResUnitVals{app.XAxisModeIndex, 2});
            dataRows = app.DataTable{2}(timerange(timerange(currentLims-wingSize, currentLims+wingSize, 'closed')), :);
            if isempty(dataRows)
                fprintf('####### empty dataRows (time mode) ##########\n');
                display({'minIdxReceived,maxIdxReceived,maxIdx',minIdxReceived, maxIdxReceived, maxIdx}');
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

            if maxIdxReceived >= currentLims(2)
                newLims = seconds([0 0]);
                newLims(2) = max(seconds(0),maxIdxReceived) + app.XResUnitVals{2,2};
                if newLims(2) > zoomSpan
                    newLims(1) = newLims(2) - zoomSpan;
                end
            else
                newLims = currentLims;
            end

            if bitget(app.XAxisModeIndex, 1) % Relative time
                newXData = relTimes;
                fprintf('[processPlotQueue] newXData = relTimes\n');
            else % Absolute time
                newXData = relTimes + app.TimeZero;
                newLims = newLims + app.TimeZero;
                fprintf('[processPlotQueue] newXData = relTimes + app.TimeZero\n');
            end
            newXData = ruler2num(newXData,app.HgtAxes.XAxis);
            maxIdx = app.DataTable{2}{maxIdxReceived, 'Index'};
            % newYData = dataRows(:, ["ELI", "PeakLoc", "PeakHgt"]);
        else % Index mode
            maxIdx = max(1, app.DataTable{2}.Index(maxIdxReceived));
            if isempty(maxIdx)
                maxIdx = 1;
            end
            minZS = 5*app.XResUnitVals{1,2};
            if zoomSpan < minZS
                zoomSpan = minZS;
            end
            wingSize = max(5*app.XResUnitVals{1, 2}, uint64(ceil(1.5*single(zoomSpan))));
            if currentLims(1) <= wingSize
                pageLimsIdxs = [1 min(app.LargestIndexReceived, currentLims(2)+wingSize)];
            else
                pageLimsIdxs = [currentLims(1)-wingSize, min(app.LargestIndexReceived, currentLims(2)+wingSize)];
            end
            if currentLims(2) > size(app.DataTable{1},1)%app.LargestIndexReceived
                currentLims(2) = size(app.DataTable{1},1); % app.LargestIndexReceived;
            end
            if pageLimsIdxs(2) > size(app.DataTable{1},1) %app.LargestIndexReceived
                pageLimsIdxs(2) = size(app.DataTable{1},1); %app.LargestIndexReceived;
            end
            dataRows = app.DataTable{1}(pageLimsIdxs(1):pageLimsIdxs(2), :);
            % maxIdxReceived = app.DataTable{2}.Index(maxIdxReceived);
            if isempty(dataRows)
                fprintf('####### empty dataRows (index mode) ##########\n');
                display({'minIdxReceived,maxIdxReceived,maxIdx',minIdxReceived, maxIdxReceived, maxIdx}');
                return;
                % pageLimsRelTimes = duration.empty();
                % newLims = currentLims;
            elseif (maxIdxReceived >= app.DataTable{1}.RelTime(currentLims(2)))
                %newXData = dataRows.Index;
                newLims = ones(1,2, 'uint64');
                try
                    % maxIdx = max(1,app.DataTable{2}.Index(maxIdxReceived));
                    newLims(2) = maxIdx + app.XResUnitVals{1,2};
                catch ME
                    % keyboard;
                    rethrow(ME);
                end
                if newLims(2) > zoomSpan
                    newLims(1) = newLims(2) - zoomSpan;
                end
            else
                %newXData = dataRows.Index;
                %pageLimsRelTimes = dataRows.RelTime(pageLimsIdxs);
                newLims = currentLims;
                % maxIdx = max(1,app.DataTable{2}.Index(maxIdxReceived));
            end
            pageLimsRelTimes = (dataRows.RelTime([1 end]))'; %app.DataTable{1}.RelTime(pageLimsIdxs)';
            newXData = dataRows.Index';
            fprintf('[processPlotQueue] newXData = dataRows.Index\n');
            % newYData = dataRows(:, ["RelTime", "ELI", "PeakLoc", "PeakHgt"]);
        end

        newYData = dataRows(:, ["ELI", "PeakLoc", "PeakHgt"]);
        
        % pause(0);
        % if ~(app.IsRecording && (app.PlotTimer.Running(2)=='n'))
        %     fprintf('[processIndexes:inline] [3] App is not recording, or plot timer is not running. Returning from function.\n');
        %     return;
        % end
        
        %display(newXData);
        %display(newYData.ELI');
        %display(newYData.PeakLoc);
        %display(newYData.PeakHgt);
        % TODO: Wrap in try/catch???
        try
            if(numelements(newYData.ELI') ~= numelements(newXData))
                keyboard;
            end
        catch ME
            keyboard;
        end
        try
            set(app.eliPlotLine, 'XData', newXData, 'YData', newYData.ELI');
        catch ME
            fprintf('[processPlotQueue] Unable to set eliPlotLine XData and YData due to error "%s": %s\n', ...
                ME.identifier, getReport(ME));
                try
                    set(app.eliPlotLine, 'XData', newXData, 'YData', NaN(size(newXData)));
                catch
                    set(app.eliPlotLine, 'XData', [], 'YData', []);
                end
        end
        for ch=1:app.NumChannels
            %display(newXData);
            %display(newYData.PeakLoc(:,ch)');
            %display(newYData.PeakHgt(:,ch)');
            set(app.channelPeakPosLines(ch), 'XData', newXData, ...
                'YData', newYData.PeakLoc(:, ch)');
            set(app.channelPeakHgtLines(ch), 'XData', newXData, ...
                'YData', newYData.PeakHgt(:, ch)');
        end

        pageLimsRelTimesDbl = seconds(pageLimsRelTimes);
        app.PageLimitsVals = { ...
            single(pageLimsIdxs), uint64(pageLimsIdxs) ; ...
            pageLimsRelTimesDbl, pageLimsRelTimes + app.TimeZero ; ...
            pageLimsRelTimesDbl, pageLimsRelTimes ...
            };
        app.PageSize = wingSize; % TODO: ??
        postset_Page(app);

        oldCallbackVals = ...
        [ app.AxisLimitsCallbackCalculatesPage
            app.AxisLimitsCallbackCalculatesTicks ];
        app.AxisLimitsCallbackCalculatesPage = false;
        app.AxisLimitsCallbackCalculatesTicks = true;

        
        if isempty(lastIndexDisplayed) || (maxIdx >= lastIndexDisplayed) || (app.LargestIndexReceived == maxIdx)
            fprintf('[processPlotQueue] Plotting datapoint IPs...\n');
            plotDatapointIPs(app, maxIdx, ips', fps');
            fprintf('[processPlotQueue] Plotted IPs. Showing datapoint image...\n');
            showDatapointImage(app, {y1,yc,yr}); % maxIdx);
            fprintf('[processPlotQueue] Showed datapoint image.\n');
            app.DatapointIndexField.Value = int2str(maxIdx);
        else
            fprintf('[processPlotQueue] maxIdx %d (@ rel. time %s) ~= LIR %d\n', ...
                maxIdx, string(maxIdxReceived, 'mm:ss.SSSS'), app.LargestIndexReceived);
        end
        clearvars y1 yc yr ips fps;
        % try
        %     if ~isempty(app.ChannelIPs) && (size(app.ChannelIPs,1)>=app.LargestIndexReceived)
        %         chIPs = app.ChannelIPs(app.LargestIndexReceived, :, :);
        %         for ch=1:app.NumChannels
        %             ax = nexttile(app.tl, ch);
        %             plot(ax, squeeze(chIPs(1,:,ch))');
        %         end
        %     end
        % catch ME
        %     fprintf('[processPlotQueue] Encountered error "%s" while plotting intensity profiles: %s\n', ...
        %         ME.identifier, getReport(ME));
        % end

        try
            % drawnow nocallbacks;
            setVisibleDomain(app, newLims);
            % app.HgtAxes.Color = 1 - app.HgtAxes.Color;
            % app.AlertArea.Value = {erase(sprintf('newLims: %s', formattedDisplayText(newLims)),newline), ...
            %    erase(sprintf('HgtAxes.XLim: %s', formattedDisplayText(app.HgtAxes.XLim)),newline)};
            drawnow limitrate nocallbacks;
            syncXFields(app);
            
        catch ME
            app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
            app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
            rethrow(ME);
        end

        app.AxisLimitsCallbackCalculatesPage = oldCallbackVals(1);
        app.AxisLimitsCallbackCalculatesTicks = oldCallbackVals(2);
    end
    fprintf('[processPlotQueue] Returning from fcn.\n');
catch ME
    fprintf('[processPlotQueue] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
end
end

