function updateChunkTable(app, removeInactive, varargin) % TODO: Add arg for not changing RAB state
    if isempty(app.DataTable{1})
        fprintf('[updateChunkTable] Primary DataTable is empty. Clearing any remaining chunk table contents.\n');
        app.ChunkTable(:,:) = [];
        return;
    end
    chunkTableChanged = false;

    if issortedrows(app.DataTable{1}, 'Index')
        smallestIndex = app.DataTable{1}{1, 'Index'};
        largestIndex = app.DataTable{1}{end, 'Index'};
    else
        smallestIndex = min(app.DataTable{1}.Index, [], 'all', 'omitnan');
        largestIndex = max(app.DataTable{1}.Index, [], 'all', 'omitnan');
    end

    if isempty(app.ChunkTable)
        fprintf('[updateChunkTable] ChunkTable is unexpectedly empty! Reinstating default chunk.\n');
        if(smallestIndex ~= 1)
            fprintf('[updateChunkTable] Assertion failed (smallestIndex==1). smallestIndex: %g\n', smallestIndex);
        end
        assert(smallestIndex == 1);
        
        smolTime = app.DataTable{1}.RelTime(smallestIndex);
        % disp(smolTime);
        app.ChunkTable(smolTime,:) = { ...
            smallestIndex, largestIndex, ...
            true, 0, 0, largestIndex, 0, 0, ...
            0, false }; % TODO: Or use current PSZ???
        chunkTableChanged = chunkTableChanged || ~isempty(app.ChunkTable);
    elseif removeInactive % && ~isempty(app.ChunkTable)
        if (nargin > 2)
            msk = ~app.ChunkTable.IsActive;
            if isnumeric(varargin{1}) && (varargin{1} ~= 0)
                msk = msk & (app.ChunkTable.Index >= varargin{1});
            end
            if (nargin > 3) && isnumeric(varargin{2}) && (varargin{2} ~= 0)
                msk = msk & (app.ChunkTable.Index <= varargin{2});
            end
            if ~isempty(msk)
                fprintf('[updateChunkTable] Removing %d inactive chunks within range.\n', sum(msk));
                app.ChunkTable(msk, :) = [];
                chunkTableChanged = chunkTableChanged ||  true;
            end
        elseif any(~app.ChunkTable.IsActive)
            fprintf('[updateChunkTable] Removing %d inactive chunks.\n', sum(~app.ChunkTable.IsActive));
            app.ChunkTable = app.ChunkTable(app.ChunkTable.IsActive, :);
            chunkTableChanged =  true;
        end

        if isempty(app.ChunkTable)
            fprintf('[updateChunkTable] ChunkTable is unexpectedly empty after removing inactive chunks! Reinstating default chunk.\n');
            if(smallestIndex ~= 1)
                fprintf('[updateChunkTable] Assertion failed (smallestIndex==1). smallestIndex: %g\n', smallestIndex);
            end
            assert(smallestIndex == 1);
            app.ChunkTable(app.DataTable{1}.RelTime(smallestIndex),:) = { ...
                smallestIndex, largestIndex, ...
                true, 0, 0, largestIndex, 0, 0, ...
                0, false }; % TODO: Or use current PSZ???
            chunkTableChanged = chunkTableChanged ||  ~isempty(app.ChunkTable);
        end
    end

    lastIdx = app.ChunkTable{end, 'Index'};
    if (lastIdx ~= largestIndex) && ~issortedrows(app.ChunkTable, 'RelTime')
        fprintf('[updateChunkTable] Chunk table is unexpectedly unsorted! Sorting it now.\n');
        % disp(app.ChunkTable);
        app.ChunkTable = sortrows(app.ChunkTable);
        fprintf('[updateChunkTable] The chunk table has been sorted.\n');
        lastIdx = app.ChunkTable{end, 'Index'};
    end
    if lastIdx ~= largestIndex
        fprintf('[updateChunkTable] Updating definition of end chunk to cover the newly-added datapoints # %d through %d.\n', ...
            lastIdx, largestIndex);
        app.ChunkTable{end, 'EndIndex'} = largestIndex;
        chunkTableChanged = true;
    end

    if (nargin>2) && istimetable(varargin{1})
        if(size(varargin{1}, 1) ~= 1)
            fprintf('[updateChunkTable] Assertion failed (size(varargin{1}, 1)==1).\n');
            disp(size(varargin{1}));
        end
        assert(size(varargin{1}, 1) == 1); % Must be only a single row
        splitStatus = varargin{1}.SplitStatus;
        relTime = varargin{1}.RelTime;
        startIdx = varargin{1}.Index;

        activeRows = app.ChunkTable(app.ChunkTable.IsActive, :);
        if(isempty(activeRows))
            fprintf('[updateChunkTable] Assertion failed (~isempty(activeRows)).\n');
            disp(size(activeRows));
        end
        assert(~isempty(activeRows));

        prevRow = activeRows(timerange(seconds(-Inf), relTime, 'open'), :);
        if size(prevRow, 1) > 1
            prevRow = prevRow(end,:);
        end
        if(isempty(prevRow))
            fprintf('[updateChunkTable] Assertion failed (~isempty(prevRow)).\n');
            disp(size(prevRow));
        end
        assert(~isempty(prevRow));

        nextRow = activeRows(timerange(relTime, seconds(Inf), 'open'), :);
        if isempty(nextRow)
            endIdx = largestIndex;
        else
            if size(nextRow, 1) > 1
                nextRow = nextRow(1,:); %min(nextRow.RelTime, [], 'all', 'omitnan'), :);
                % assert(size(nextRow, 1) == 1);
                % nextRow = nextRow(1, :);
            end
            endIdx = nextRow.Index - 1; % (1);
        end

        clear activeRows;
        
        newRowActive = logical(bitget(splitStatus, 2));
        isUnsync = logical(bitget(splitStatus, 1));

        if ismember(relTime, app.ChunkTable.RelTime)
            % Already exists. Reactivate it.
            oldRow = app.ChunkTable(relTime, :);
            if oldRow.Index ~= startIdx
                fprintf('[updateChunkTable] WARNING: A chunk is listed as beginning at %g seconds elapsed, but the listed StartIdx %u unexpectedly differs from the expected StartIdx %g!\n', ...
                oldRow.Index, startIdx);
            end
            newRow = oldRow;
            newRow(:, ["IsActive" "Index" "EndIndex1"]) = { ...
                newRowActive, startIdx, endIdx };
            if isUnsync
                newRow.ChangeFlags = bitset(newRow.ChangeFlags, ...
                    2, endIdx~=newRow.EndIndex) | 1;
                newRow.IsChanged = true;
            else
                newRow.ChangeFlags = bitset(newRow.ChangeFlags, ...
                    2, endIdx~=newRow.EndIndex);
                newRow.IsChanged = logical(newRow.ChangeFlags);
            end
            % newRow = table2cell(newRow);
        else
            oldRow = [];
            % if bitget(splitStatus, 2) % Adding new split to table
            %     % newRow = { startIdx, 0, true, ...
            %     %     prevRow.PSZP, prevRow.PSZW, ...
            %     %     endIdx, ...
            %     %     prevRow.PSZL1, prevRow.PSZW1, ...
            %     %     bitor(prevRow.ChangeFlags, 3), true };
            % else % Removed split does not correspond to the start of any chunk...
            if ~newRowActive
                fprintf('[updateChunkTable] No matching entry (RelTime # seconds %g) found in the chunk table, so nothing needs to be removed.\n', ...
                    seconds(relTime));
                disp(varargin{1});
                disp(app.ChunkTable);
            end
            newRow = { startIdx, 0, newRowActive, ...
                prevRow.PSZP, prevRow.PSZW, ...
                endIdx, ...
                prevRow.PSZL1, prevRow.PSZW1, ...
                bitor(prevRow.ChangeFlags, 3), true };
        end
        
        if newRowActive
            newPrevEndIdx = startIdx - 1;
        else
            newPrevEndIdx = endIdx;
        end
        if isUnsync
            newPrevChangeFlags = bitset(prevRow.ChangeFlags, 2);
            newPrevIsChanged = true;
        else
            newPrevChangeFlags = bitset(prevRow.ChangeFlags, 2, ...
                newPrevEndIdx ~= prevRow.EndIndex);
            newPrevIsChanged = logical(newPrevChangeFlags);
        end

        % disp(prevRow);
        if ~isempty(oldRow) % Update existing entry
            if iscell(newRow)
                app.ChunkTable(relTime, :) = newRow;
            else
                app.ChunkTable(relTime, :) = table2cell(newRow);
            end
        elseif isempty(prevRow) % Insert above first row -- should not happen!!
            app.ChunkTable = vertcat(app.ChunkTable, newRow);
            app.ChunkTable.RelTime(end) = relTime;
            app.ChunkTable = app.ChunkTable([end, 1:end-1], :);
        elseif isempty(nextRow) && (prevRow.RelTime == app.ChunkTable.RelTime(end)) % Append row
            app.ChunkTable = vertcat(app.ChunkTable, newRow);
            app.ChunkTable.RelTime(end) = relTime;
        else % Insert row
            head = app.ChunkTable(timerange(seconds(-Inf), relTime, 'open'), :);
            app.ChunkTable = vertcat( ...
                head, ... % prevRow.RelTime, 'openleft'), :), ...
                newRow, ...
                app.ChunkTable(timerange(relTime, seconds(Inf), 'open'), :) ...
            );
            app.ChunkTable.RelTime(size(head,1)+1) = relTime;
        end

        try
            app.ChunkTable(prevRow.RelTime, ["EndIndex1" "ChangeFlags" "IsChanged"]) ...
                = { newPrevEndIdx, newPrevChangeFlags, newPrevIsChanged };
        catch ME
            fprintf(['[updateChunkTable] Error "%s" occurred while updating previous row.' ...
                '(Will now attempt to revert chunk table before rethrowing error.)' ...
                'Error report: %s\n'], ME.identifier, getReport(ME));
            if istimetable(oldRow)
                app.ChunkTable(relTime, :) = table2cell(oldRow);
            else
                disp(oldRow);
                app.ChunkTable(relTime, :) = oldRow;
            end

            rethrow(ME);
        end

        % if bitget(splitStatus, 2) % Split added
        %     if bitget(splitStatus, 1) % Is now out of sync
        %         if ~isempty(oldRow)
        %             oldRow.Active = true;
        %             if ~oldRow.IsChanged
        %                 fprintf('[updateChunkTable] Adding (unsynced) div, but old row (chunk [%g %g]) unexpectedly NOT marked as changed...\n', ...
        %                     oldRow.Index, oldRow.EndIndex);
        %                 disp(varargin{1});
        %                 disp(oldRow);
        %                 disp(app.ChunkTable);
        %             end
        %             if (oldRow.EndIndex ~= endIdx)
        %                 oldRow.ChangeFlags = bitset(oldRow.ChangeFlags, 2);
        %             end
        %             oldRow.EndIndex1 = endIdx;

        %             if ~isempty(prevRow)
        %                 if prevRow.EndIndex ~= (oldRow.Index - 1)
        %                     if prevRow.EndIndex1 = (oldRow.Index - 1)
        %                         fprintf('[updateChunkTable] Adding (unsynced) div, and prev row (chunk [%g %g]) unexpectedly already has EndIndex1 = the new div...\n', ...
        %                         oldRow.Index, oldRow.EndIndex);
        %                     end
        %                     app.ChunkTable(prevRow.RelTime, ["EndIndex1" "ChangeFlags" "IsChanged"]) = ...
        %                         {oldRow.Index - 1, bitor(prevRow.ChangeFlags, 2), true};
        %                 else
        %                     fprintf('[updateChunkTable] Adding (unsynced) div, and prev row chunk [%g %g] unexpectedly already ends at the new div...\n', ...
        %                         oldRow.Index, oldRow.EndIndex);
        %                 end
        %             else
        %                 fprintf('[updateChunkTable] No previous row (chunk [%g %g] occupies is the first row in the chunk table).\n', ...
        %                     oldRow.Index, oldRow.EndIndex);
        %             end
        %         else % Chunk does not exist
        %             chgFlags = 3;
        %             newRow;
        %         end
        %     else % Is now in sync
        %         if ~isempty(oldRow) % Need to reactivate existing chunk definition
        %             oldRow.Active = true;
        %         else % Chunk does not exist
        %             fprintf('[updateChunkTable] In sync, but chunk @ index %u unexpectedly does not exist in the ChunkTable.\n', startIdx);
        %             newRow;
        %         end
        %     end
        % else % Split removed
        %     if bitget(splitStatus, 1) % Is now out of sync
        %         if ~isempty(oldRow) % Need to reactivate existing chunk definition
        %             oldRow.Active = true;

        %         else % Chunk does not exist
        %             newRow;
        %         end
        %     else % Is now in sync
        %         if ~isempty(oldRow) % Need to reactivate existing chunk definition
        %             oldRow.Active = true;
        %             if ~oldRow.IsChanged
        %                 fprintf('[updateChunkTable] Adding (unsynced) div, but old row (chunk [%g %g]) unexpectedly NOT marked as changed...\n', ...
        %                     oldRow.Index, oldRow.EndIndex);
        %                 disp(varargin{1});
        %                 disp(oldRow);
        %                 disp(app.ChunkTable);
        %             end
        %         else % Chunk does not exist
        %             newRow;
        %         end
        %     end
        % end

        % if isempty(oldRow) % Chunk does not exist
        %     if isempty(prevRow)
        %         app.ChunkTable = vertcat(app.ChunkTable,newRow);
        %         app.ChunkTable = app.ChunkTable([end, 1:end-1], :);
        %      elseif isempty(nextRow) && (prevRow.RelTime == app.ChunkTable.RelTime(end))
        %          app.ChunkTable = vertcat(app.ChunkTable, newRow);
        %      else
        %          app.ChunkTable = vertcat( ...
        %              app.ChunkTable(timerange(seconds(-Inf), prevRow.RelTime, 'openleft'), :), ...
        %              newRow, ...
        %              app.ChunkTable(timerange(relTime, seconds(Inf), 'open'), :) ...
        %          );
        %      end
        % end
    elseif (nargin < 3) || ~istimetable(varargin{1})% No table row supplied as additional argument
        if ~issortedrows(app.DataTable{3})
            app.DataTable{3} = sortrows(app.DataTable{3});
        end

        discos = app.DataTable{3}(logical(bitget(app.DataTable{3}.SplitStatus, 2)), :);
        numDiscos = size(discos, 1); 

        if isempty(discos)
            fprintf('[updateChunkTable] No active discontinuities, so populating ChunkTable with a single row.\n');
            app.ChunkTable(:,:) = [];
            app.ChunkTable(app.DataTable{1}.RelTime(smallestIndex),:) = { ...
                smallestIndex, largestIndex, ...
                true, 0, 0, largestIndex, 0, 0, ...
                0, false }; % TODO: Or use current PSZ???
        else
            fprintf('[updateChunkTable] DiscoTable is empty, so populating ChunkTable with a single row.\n');
            if (nargin>2)
                if ((nargin==3) && isnumeric(varargin{1}) && (varargin{1}~=0) && (app.ChunkTable{end, 'EndIndex'} >= varargin{1}))  ...
                    || ((nargin>3) && (isnumeric(varargin{2}) && (varargin{2} ~= 0) && (app.ChunkTable{end, 'EndIndex'} >= varargin{2})))
                    app.ChunkTable{end, 'EndIndex'} = largestIndex;
                else
                    msk = app.ChunkTable.EndIndex==varargin{1};
                    switch sum(msk)
                        case 0
                            fprintf('[updateChunkTable] Unexpectedly, no rows have the given EndIndex %d.\n', varargin{1});
                            repopulateTable();
                        case 1
                            % TODO: Changes to "changed" status if datapoints added???
                            app.ChunkTable(msk).EndIndex = largestIndex;
                        otherwise
                            fprintf('[updateChunkTable] Unexpectedly, multiple rows have the same EndIndex!\n');
                            disp(app.ChunkTable);
                            % app.ChunkTable(msk).EndIndex = largestIndex;
                            repopulateTable();
                    end
                end
            else
                repopulateTable();
            end
        end
    end


    if app.SelectedIndex
        if size(app.ChunkTable, 1) > 1
            idxInTable = find(app.ChunkTable.IsActive & (app.ChunkTable.Index <= app.SelectedIndex), ...
                1, 'last');
            if(isempty(idxInTable))
                fprintf('[updateChunkTable] Assertion failed (~isempty(idxInTable)).\n');
                disp(size(idxInTable));
            end
            assert(~isempty(idxInTable));
        else
            idxInTable = 1;
            %app.CurrentChunkInfo = {app.ChunkTable.RelTime(1), ...
            %    [app.ChunkTable.Index(1) app.ChunkTable.EndIndex1(1)]};
        end
        app.CurrentChunkInfo = {app.ChunkTable.RelTime(idxInTable), ...
            [app.ChunkTable.Index(idxInTable) app.ChunkTable.EndIndex1(idxInTable)]};
        % fprintf('[updateChunkTable] Setting reanalyze button enable to ?.\n');
        if ~app.IsRecording && isequal(app.ReanalyzeButton.UserData, true) % && chunkTableChanged
            app.ReanalyzeButton.Enable =  ~(...
                plotDatapointIPs(app, app.SelectedIndex) ...
                && (length(app.Ycs)>=app.SelectedIndex) ...
                && ~isempty(app.Ycs{app.SelectedIndex})) ...
            ... % && ~isempty(showDatapointImage(app, app.SelectedIndex) )) ... % TODO: Replace sDI call with check for empty dataimg??
            || app.ChunkTable{idxInTable, 'IsChanged'} ; % || chunkTableChanged; % TODO
        end
    end

    % display(app.ChunkTable);

    function repopulateTable()
        chunksCopy = app.ChunkTable; % TODO: Copy only necessary columns (start/end index and changes and status)
        app.ChunkTable(:,:) = [];
        % lastIndex = smallestIndex;
        for rn = 1:numDiscos % (Assume DT3 rows are already sorted.)
            % row = discos(rn, [1 2]); % Index, SplitStatus
            rowIndex = discos.Index(rn);
            relTime = discos.RelTime(rn);
            if rowIndex == smallestIndex
                continue; % TODO: Ensure that first datapoint is never marked as a discontinuity...
            else
                startIdx = rowIndex;
                if rn < numDiscos
                    endIdx = discos.Index(rn+1) - 1;
                else
                    endIdx = largestIndex;
                end
                % msk = isequal(row{1, [1 2]}, chunksCopy{:, [1 2]});
                % msk = rowfun(@(v1,v2) (v1==row.Index) && (v2==row.EndIndex), chunksCopy, ...
                %     'InputVariables', [1 2], 'OutputFormat', 'uniform');
                % msk = (chunksCopy.RelTime == relTime) && ...
                %    (chunksCopy.Index == startIdx) & (chunksCopy.EndIndex == endIdx);
                if ismember(relTime, chunksCopy.RelTime)
                    oldRow = chunksCopy(relTime, :);
                    if (oldRow.Index == startIdx) && (oldRow.EndIndex1 == endIdx)
                        fprintf('[updateChunkTable] Restoring changes to chunk [%u %u].\n', ...
                            startIdx, endIdx);
                        if ~oldRow.IsActive
                            % TODO: How to determine if changes occurred after deactivating?
                            oldRow.IsActive = true;
                        end
                        app.ChunkTable(relTime, :) = table2cell(oldRow);
                    else
                        fprintf('[updateChunkTable] Defining new chunk [%u %u] with settings from previously-existing chunk with same start time position but different endindex1 (%d).\n', ...
                            startIdx, endIdx, oldRow.EndIndex1);
                        app.ChunkTable(relTime, :) = { ...
                            startIdx, oldRow.EndIndex, ...
                            true, 0, 0, endIdx, ...
                            oldRow.PSZL1, oldRow.PSZW1, ...
                            bitor(oldRow.ChangeFlags, 3), oldRow.IsChanged ...
                        };
                    end
                else
                    fprintf('[updateChunkTable] Defining new chunk [%u %u].\n', ...
                        rowIndex, endIdx);
                    app.ChunkTable(relTime, :) = { ...
                        startIdx, 0, ...
                        true, 0, 0, endIdx, ...
                        0, 0, 3, true ...
                    };
                end
            end
        end
    end
end

% app.ChunkTable = timetable('Size', [0, 10], ...
%     'VariableTypes', {'uint64', 'uint64', 'logical', 'uint16', 'uint16', ...
%         'uint64', 'uint16', 'uint16', ...
%         'uint8', 'logical'}, ...
%     'VariableNames', {'Index', 'EndIndex', 'IsActive', 'PSZP', 'PSZW', ...
%         'EndIndex1' ,'PSZL1', 'PSZW1', ...
%         'ChangeFlags', 'IsChanged'}, ...
%     'DimensionNames', {'RelTime', 'Variables'}, 'TimeStep', seconds(NaN));