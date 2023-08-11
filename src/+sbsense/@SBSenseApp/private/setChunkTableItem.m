function setChunkTableItem(app, isChanged, varName, varargin)
    if isempty(app.CurrentChunkInfo)
        fprintf('[setChunkTableItem] WARNING: UNEXPECTEDLY EMPTY CHUNK INFO. ATTEMPTING TO POPULATE.\n');
        try
            if size(app.ChunkTable, 1) > 1
                idxInTable = find(app.ChunkTable.IsActive & (app.ChunkTable.Index <= app.SelectedIndex), ...
                    1, 'last');
                assert(~isempty(idxInTable));
            else
                if isempty(app.ChunkTable)
                    updateChunkTable(app);
                end
                assert(~isempty(app.ChunkTable));
                idxInTable = 1;
                %app.CurrentChunkInfo = {app.ChunkTable.RelTime(1), ...
                %    [app.ChunkTable.Index(1) app.ChunkTable.EndIndex1(1)]};
            end
            app.CurrentChunkInfo = {app.ChunkTable.RelTime(idxInTable), ...
                [app.ChunkTable.Index(idxInTable) app.ChunkTable.EndIndex1(idxInTable)]};
        catch ME
            fprintf('[setChunkTableItem] Error occurred while attempting to populate CurrentChunkInfo. CANNOT UPDATE ANALYSIS PARAMETERS FOR REANALYSIS.\n\t\tError message: %s\n', getReport(ME));
            return;
        end
    end

    if nargin > 4
        if ~isempty(varargin{2})
            app.ChunkTable{app.CurrentChunkInfo{1}, varName}(varargin{1}) = varargin{2};
        end
    elseif ~isempty(varargin{1})
        app.ChunkTable{app.CurrentChunkInfo{1}, varName} = varargin{1};
    end

    switch varName
        case 'PSZL1'
            bitIdx = 3;
            if isempty(varargin{2})
                app.ChunkTable{app.CurrentChunkInfo{1}, varName}(varargin{1}) = ...
                app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL'}(varargin{1});
                isChanged = false;
            elseif isempty(isChanged)
                isChanged = ~isequal(app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZL'}(varargin{1}), varargin{2});
            end
        case 'PSZW1'
            bitIdx = 4;
            if isempty(varargin{2})
                app.ChunkTable{app.CurrentChunkInfo{1}, varName}(varargin{1}) = ...
                app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW'}(varargin{1});
                isChanged = false;
            elseif isempty(isChanged)
                isChanged = ~isequal(app.ChunkTable{app.CurrentChunkInfo{1}, 'PSZW'}(varargin{1}), varargin{2});
            end
        case 'EndIndex1'
            bitIdx = 2;
            if isempty(varargin{1})
                app.ChunkTable{app.CurrentChunkInfo{1}, varName} = ...
                    app.ChunkTable.EndIndex(app.CurrentChunkInfo{1});
                isChanged = false;
            elseif isempty(isChanged)
                isChanged = ~isequal(app.ChunkTable{app.CurrentChunkInfo{1}, 'EndIndex'}, varargin{1});
            end
        otherwise
            error('Unrecognized ChunkTable variable name "%s".', varName);
    end

    app.ChunkTable.ChangeFlags(app.CurrentChunkInfo{1}) = ...
        bitset(app.ChunkTable.ChangeFlags(app.CurrentChunkInfo{1}), ...
        bitIdx, logical(isChanged));
    app.ChunkTable.IsChanged(app.CurrentChunkInfo{1}) = ...
        logical(app.ChunkTable.ChangeFlags(app.CurrentChunkInfo{1}));
    
    if ~iscell(isChanged) && app.SelectedIndex % && ~app.IsRecording
        % This function should never be called during recording anyway.
        app.ReanalyzeButton.Enable =  ~(...
            plotDatapointIPs(app, app.SelectedIndex) ...
            && (length(app.Ycs)>=app.SelectedIndex) ...
            && ~isempty(app.Ycs{app.SelectedIndex})) ...
            ... % && ~isempty(showDatapointImage(app, app.SelectedIndex) )) ... % TODO: Replace sDI call with check for empty dataimg??
            || app.ChunkTable.IsChanged(app.CurrentChunkInfo{1});
    end
        
    % app.ChunkTable.PSZL1(app.SelectedIndex, app.IPPlotSelection) ...
    %     = app.ChunkTable.PSZL(app.SelectedIndex, app.IPPlotSelection);
    % app.ChunkTable.ChangeFlags(app.SelectedIndex) ...
    %     = bitset(app.ChunkTable.ChangeFlags(app.SelectedIndex), 3, false);
    % updateReanalysisState(app);
end