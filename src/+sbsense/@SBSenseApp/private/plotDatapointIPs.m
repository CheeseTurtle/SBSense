function TF = plotDatapointIPs(app, varargin)
if nargin==1
    idx = app.SelectedIndex;
    argProfiles = false;
else
    idx = varargin{1};
    if nargin == 4
        channelIPs = varargin{2};
        channelFPs = varargin{3};
        argProfiles = true;
        disp({size(channelIPs), size(channelFPs)});
    else
        argProfiles = false;
    end
end

% z = findall(app.UIFigure, '-property', 'XData', '-or', '-property', 'YData');
% xs = cellfun(@size, get(z, 'XData'), 'UniformOutput', false);
% ys = cellfun(@size, get(z, 'YData'), 'UniformOutput', false);
% xs = vertcat(xs{:}); ys = vertcat(ys{:});
% msk = any(xs ~= ys, 2);
persistent co;

TF = true;

if ~(idx || argProfiles)
    return; % TODO (TF value?)
end

% if nargin>2
%     %if isempty(varargin{2}) && (size(app.ChunkTable,1)>1)
%     %else
%     updatePSZ = varargin{2};
%     if updatePSZ
%         try
%             chunkInfo = app.ChunkTable(app.CurrentChunkInfo{1}, {'PSZP', 'PSZW', 'PSZL1' 'PSZW1'});
%             % updatePSZ = any(chunkInfo>0);
%         catch ME
%             fprintf('[plotDatapointIPs] Could not retrieve PSZ information for datapoint %u from ChunkTable due to error: %s\n', ...
%                 idx, getReport(ME));
%         end
%     end
%     %end
% else
%     updatePSZ = false;
% end

if argProfiles
    hasIPs = ~isempty(channelIPs);
    hasFPs = hasIPs && ~isempty(channelFPs);
else
    try
        if length(app.ChannelIPsData)>=idx
            channelIPs = app.ChannelIPsData(idx).AllChannels;
            hasIPs = true;
            try
                if length(app.ChannelFPsData)>=idx
                    channelFPs = app.ChannelFPsData(idx).AllChannels;
                    hasFPs = true;
                else
                    fprintf('[plotDatapointIPs] channelFPs length (%g) is not long enough to access index %g.\n', ...
                        length(app.ChannelFPsData), idx);
                    hasFPs = false;
                end
            catch MEE % TODO: Abort unless certain exception identifier?
                fprintf('[plotDatapointIPs] Error: %s\n', getReport(MEE));
                hasFPs = false;
            end    
        else
            fprintf('[plotDatapointIPs] channelIPs length (%g) is not long enough to access index %g.\n', ...
                length(app.ChannelFPsData), idx);
            hasIPs = false;
            hasFPs = false;
        end
    catch MEE % TODO: Abort unless certain exception identifier?
        fprintf('[plotDatapointIPs] Error: %s\n', getReport(MEE));
        hasIPs = false;
        hasFPs = false;
    end
end

try
    if hasIPs % && (size(channelIPs, 2)==app.fdm(2)) % ~isempty(app.ChannelIPs) && (size(app.ChannelIPs,1)>=idx)
        try
            ymax = max(channelIPs(:,:), [], 'all', 'omitnan');
            noSharedYMax = false;
            if hasFPs % ~isempty(app.ChannelFPs)
                try
                    % ymax = max(ymax, max(app.ChannelFPs(idx,:,:), [], 'all', 'omitnan'), 'omitnan');
                    hasFPs = true;
                catch ME3
                    fprintf('[plotDatapointIPs] Error "%s" occurred when trying to calculate ymax including FPs: %s\n', ...
                        ME3.identifier, getReport(ME3));
                    display(idx);
                    hasFPs = false;
                    %TF = false;
                end
            else
                hasFPs = false;
                %TF = false;
            end
        catch ME2
            fprintf('[plotDatapointIPs] Error "%s" occurred when trying to calculate ymax from IPs: %s\n', ...
                ME2.identifier, getReport(ME2));
            display(idx);
            hasFPs = false;
            noSharedYMax = true;
        end
        if isempty(co)
            co = colororder(app.UIFigure);
        end
        for ch = 1:app.NumChannels
            ax = nexttile(app.tl, ch);
            % if ~idx
            %     continue;
            % end
            if hasFPs % && (size(channelFPs, 2)==app.fdm(2))
                % hold(ax,"on");
                fp = squeeze(channelFPs(ch, :)); % TODO: Dimensions?
                if all(isnan(fp))
                    fprintf('[plotDatapointIPs] Ch %d FP is entirely NaN!\n', ch);
                    TF = false;
                    % else
                    %     plot(ax, fp, 'Color', [0 0 0], 'DisplayName', 'Fitted Curve');
                end
                set(app.IPfitLines(ch), 'YData', fp, 'Visible', TF);
            else
                set(app.IPfitLines(ch), 'Visible', false);
            end

            ip = squeeze(channelIPs(ch, :));
            if all(isnan(ip))
                fprintf('[plotDatapointIPs] Ch %d IP is entirely NaN!\n', ch);
                TF = false;
                set(app.IPdataLines(ch), 'YData', ip, 'Visible', false);
            else
                set(app.IPdataLines(ch), 'YData', ip, 'Visible', true);
            end

            try
                pos = app.DataTable{1}{idx, 'PeakLoc'}(ch);
                set(app.IPpeakLines(ch), 'Value', pos);%, 'Visible', ~isnan(pos));
            catch ME2
                fprintf('Could not set pos IPpeakLine value for channel %d due to error: %s\n', ch, getReport(ME2));
                set(app.IPpeakLines(ch), 'Value', NaN);%, 'Visible', false);
            end

            if noSharedYMax
                ymax = max(ip, [], 'all', 'omitnan');
                if hasFPs
                    ymax = max(ymax, max(fp, [], 'all', 'omitnan'), 'omitnan');
                end
            end

            if isnan(ymax) || isempty(ymax) || (ymax==0)
                ax.Color = [1 0 0];
                TF = false;
                continue;
            elseif ~isfinite(ymax) || ~ymax
                set(ax, 'YLimMode', 'auto', 'XLim', [1 app.fdm(2)]);
                TF = false;
            else
                if ~ax.Color(2)
                    ax.Color = [0.35 0.35 0.35];
                end
                % % % disp({[1 app.fdm(2)], [0 ymax]});
                set(ax, 'XLim', [1 app.fdm(2)], 'YLim', [0 ymax]);
            end
            disableDefaultInteractivity(ax); % TODO

            if (size(app.IPpatches,2)<ch) || ~isvalid(app.IPpatches(ch))
                app.IPpatches(ch) = matlab.graphics.primitive.Patch(ax, ...
                    'FaceAlpha', 1, 'LineStyle', 'none', 'FaceColor', [1 1 1], 'Visible', false);
            end
            if ishghandle(app.IPpatches(ch)) && isvalid(app.IPpatches(ch))
                set(app.IPpatches(ch), ...
                    'XData', app.PSBIndices([1 2 2 1]), ...
                    'YData', ax.YLim([1 1 2 2]), 'Visible', false);
            end
            % set(ax.YAxis, 'LimitsChangedFcn', @(src,ev) set(src.Parent.UserData, 'YData', ev.NewLimits([1 1 2 2])));

            if ~app.IsRecording
                try
                    PSZP = app.DataTable{1}{idx, 'PSZP'}(ch);
                    PSZW = app.DataTable{1}{idx, 'PSZW'}(ch);
                    if PSZP>0
                        assert(PSZW>0);
                        PSZP = double(PSZP);
                        hwd0 = 2\(double(PSZW) - 1);
                        xl0 = PSZP - hwd0;
                        xr0 = PSZP + hwd0;
                        set(app.IPzoneRects(2,ch), 'XData', [xl0 xl0 xr0 xr0], ...
                            'YData', app.tl.Children(end+1-ch).YLim([1 2 2 1]), ...
                            'Visible', true);
                    elseif app.IPzoneRects(2,ch).Visible
                        app.IPzoneRects(2,ch).Visible = false;
                    end
                catch ME1
                    fprintf('[plotDatapointIPs] ERROR "%s" while plotting used PSZ for ch. %u: %s\n', ...
                        ME1.identifier, ch, getReport(ME1));
                end

                if isempty(ax.UserData) || ~isequal([idx, app.IPDebugPlotSelection], ax.UserData{1})
                    if (size(ax.UserData,2)==2) && ~isempty(ax.UserData{2})
                        ax.UserData{2} = ax.UserData{2}(ishghandle(ax.UserData{2}));
                        delete(ax.UserData{2}(isvalid(ax.UserData{2})));
                        ax.UserData{2} = gobjects(0);
                    end

                    %if ~app.IsRecording
                    % if updatePSZ
                    %     try
                    %         xp0 = chunkInfo.PSZP(ch); xp1 = chunkInfo.PSZL1(ch);
                    %         wd0 = double(chunkInfo.PSZW(ch)); wd1 = double(chunkInfo.PSZW1(ch));
                    %         hwd0 = 2\(wd0 - 1); hwd1 = 2\(wd1-1);
                    %         xl0 = double(xp0) - hwd0; xl1 = double(xp1) - hwd1;
                    %         xr0 = double(xp0) + hwd0;
                    %         app.IPzoneRects(1,ch).Position =
                    %     catch ME1
                    %         fprintf('[plotDatapointIPs] ERROR "%s" while updating PSZ: %s\n', ...
                    %             ME1.identifier, ch, getReport(ME1));
                    %     end
                    % end
                    if app.IPDebugPlotSelection
                        xs = app.ChannelXData(idx,ch);
                        objs = gobjects(0);
                        hold(ax, "on");
                        try
                            if bitget(app.IPDebugPlotSelection,1)
                                objs = xline(ax, double(app.ChannelFBs(idx,:,ch)), 'Color', [1 0 0], 'LineStyle', '--');
                            end
                            if bitget(app.IPDebugPlotSelection,2)  && ~isempty(app.ChannelWgts{idx,ch})
                                objs(end+1) = plotdbg(app.ChannelWgts{idx,ch}, 'Color', [0 1 0], 'LineStyle', '-.');
                            end
                            if bitget(app.IPDebugPlotSelection,3) && ~isempty(app.ChannelWPs{idx,1,ch})
                                objs(end+1) = plotdbg(app.ChannelWPs{idx,1,ch}, 'Color', [0 0 1], 'LineStyle', ':');
                            end
                            % if bitget(app.IPDebugPlotSelection,4)  && ~isempty(app.ChannelWPs{idx,2,ch})
                            %     objs(end+1) = plotdbg(app.ChannelWPS{idx,2,ch});
                            % end
                            % if bitget(app.IPDebugPlotSelection,5)  && ~isempty(app.ChannelWPs{idx,3,ch})
                            %     objs(end+1) = plotdbg(app.ChannelWPS{idx,3,ch});
                            % end
                            % if bitget(app.IPDebugPlotSelection,6)  && ~isempty(app.ChannelWPs{idx,4,ch})
                            %     objs(end+1) = plotdbg(app.ChannelWPS{idx,4,ch});
                            % end
                            % if bitget(app.IPDebugPlotSelection,7)  && ~isempty(app.ChannelWPs{idx,5,ch})
                            %     objs(end+1) = plotdbg(app.ChannelWPS{idx,5,ch});
                            % end
                            % if bitget(app.IPDebugPlotSelection,8)  && ~isempty(app.ChannelWPs{idx,6,ch})
                            %     objs(end+1) = plotdbg(app.ChannelWPS{idx,6,ch});
                            % end
                            ax.UserData{1} = [idx, app.IPDebugPlotSelection];
                        catch ME1
                            fprintf('[plotDatapointIPs] ERROR "%s" while plotting debug data for ch. %u: %s\n', ...
                                ME1.identifier, ch, getReport(ME1));
                        end
                        ax.UserData{2} = objs;
                        hold(ax,"off");
                    else
                        ax.UserData = {[idx, app.IPDebugPlotSelection], gobjects(0)};
                    end
                    % end
                end
            end
            ax.Toolbar.Visible = false;
        end
        drawnow limitrate nocallbacks;
        TF = (idx==0) || (TF && hasFPs);
    else
        fprintf('[plotDatapointIPs] ChannelIPs is empty.\n');
        if ~idx
            TF = true;
            for i=1:app.NumChannels
                % cla(nexttile(app.tl,i));
                set([app.IPfitLines(i), app.IPdataLines(i), ...
                    app.IPpeakLines(i), app.IPzoneRects(1,i)], ...
                    'Visible', false); % 'Value', NaN
                app.IPpeakLines(i).Value = NaN;
            end
        else
            TF = false;
        end
    end
catch ME
    fprintf('[plotDatapointIPs] Error "%s": %s\n', ME.identifier, getReport(ME));
    TF = false;
end
    function obj = plotdbg(ydata,varargin)
        obj = plot(ax, xs, ydata, varargin{:});
    end
end