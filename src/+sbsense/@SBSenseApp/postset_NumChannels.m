function postset_NumChannels(app,varargin)%,~,~)%src,eventData)
fprintf('[postset_NumChannels] ');
onc = length(app.ChanDivLines)+1;
fprintf('onc: %d, app.NumChannels: ', onc);
if app.NumChannels > app.MaxNumChannels
    fprintf('%d --> clamped to ', app.NumChannels);
    app.NumChannels = app.MaxNumChannels;
end
fprintf('%d\n', app.NumChannels);
app.MinMinChanHeight = idivide(uint16(app.fdm(1)), ...
    app.MinChanHeightDenom, "ceil");
try
    if (app.NumChannels < onc)
        fprintf('Decreased # chans from %d to %d.\n', ...
            onc, app.NumChannels);
        set(app.ChanDivLines(app.NumChannels:end), ...
            'Visible', false);
        %set(app.ChanHgtFields(app.NumChannels+1:onc), ...
        %    'Enable', false, 'Value', 0); % TODO: Blank
        for i=1:length(app.ChanDivLines)
            fprintf('Deleting UserData for line %d\n', i);
            if ~isempty(app.ChanDivLines(i).UserData)
                delete(app.ChanDivLines(i).UserData);
            end
        end
        disp(app.NumChannels+1:onc);
        for i=app.NumChannels+1:onc
            set(app.ChanCtlGroups{i}, 'Enable', false);
        end
        set(app.ChanDivSpins(app.NumChannels:onc-1), 'Limits', [-1 0]);
        set([app.ChanHgtFields(app.NumChannels+1:onc) ...
            app.ChanDivSpins(app.NumChannels:onc-1)], 'Value', 0);
    elseif app.NumChannels > onc
        fprintf('Increased # chans from %d to %d.\n', ...
            onc, app.NumChannels);
        set(app.channelDivLines(1:app.NumChannels-1), ...
            'Visible', true);
        %set(app.ChanHgtFields(1:app.NumChannels), ...
        %    'Enable', true);
        disp(onc+1:app.NumChannels);
        for i=onc+1:app.NumChannels
            set(app.ChanCtlGroups{i}, 'Enable', true);
            %if isempty(app.channelDivLines(i-1).DrawingArea) || ~isnumeric(app.channelDivLines(i-1).DrawingArea)
                app.channelDivLines(i-1).DrawingArea = double([1 1 app.fdf]);
                app.channelDivLines(i-1).UserData = images.roi.Rectangle(...
                    'Tag', 'divdrawingarea', ...
                    'Parent', app.PreviewAxes, 'InteractionsAllowed', 'none', ...
                    'Visible', false, 'Position', double([1 1 app.fdf]));
            %else
            %    app.channelDivLines(i-1).DrawingArea([1 3]) = double([1 app.fdm(2)]);
            %    % app.channelDivLines(i-1).Position(:,1) = double([1 app.fdm(2)]);
            %end
        end
        %set([app.ChanHgtFields(onc+1:app.NumChannels) ...
        %    app.ChanDivSpins(onc:app.NumChannels-1)], 'Value', 0);
    end
catch ME
    fprintf('[postset_NumChannels] Error: %s\n', getReport(ME));
    return;
end
app.ChanDivLines = app.channelDivLines(1:app.NumChannels-1);

%recalcChannelHeightInfo(app);
%postset_EffSize(app, logical.empty());

if onc ~= app.NumChannels
    if isempty(app.tl)
        % TODO: Move to startup fcn
        app.tl = tiledlayout(app.IProfPanel, 1, ...
            1, "TileSpacing", "none", ...
            "Padding", "tight", "Interruptible", true, ... % Or Padding='tight', but nest inside a uigridlayout
            "TileIndexing", "rowmajor");
    elseif ~isempty(app.tl.Children)
        delete(app.tl.Children);
    end
    switch app.NumChannels
        case {0,1}
            set(app.tl,'GridSize', [1 1]);
        case 2
            set(app.tl,'GridSize', [2 1]);
        case 3
            set(app.tl,'GridSize', [3 1]);
        case 4
            set(app.tl,'GridSize', [2 2]);
        case 5
            set(app.tl,'GridSize', [3 2]);
        case 6
            set(app.tl,'GridSize', [3 2]);
        case 7
            set(app.tl,'GridSize', [4 2]);
        otherwise
            set(app.tl,'GridSize', [4 2]);
    end
    % for i=1:app.NumChannels
    %     ax = nexttile(app.tl, i);
    %     % cla(ax);
    %     setupIPAxis(app, ax, i);
    % end
end
end

