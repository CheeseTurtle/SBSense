function [TF,TF2] = updateDatastores(app, idx0, varargin)
TF = false;
TF2 = false;

sz = size(app.DataTable{1}, 1);
if ~sz && isempty(app.DataTable{1})
    return;
end
% TODO: Assumes datatables are already cleaned anyway (bc sorted), so index should match row number.
% TODO: Check for empty table
idx0Idx = find(app.DataTable{1}.Index==idx0, 1);

if ~idx0Idx
    return;
end

% len = uint64(sz)+uint64(1)-min(uint64(sz)+uint64(1),uint64(idx0Idx));
% if isempty(app.Composites) || isempty(app.Yrs) || any(len ~= length(app.Composites)) || any(len ~= length(app.Yrs))
%     % TODO
%     fprintf('Composites and Yrs are not the correct size (%u~=%u, %u~=%u)! Cannot update datastores.\n', ...
%         length(app.Composites), len, length(app.Yrs), len);
%     return;
% end

if isempty(app.ProfileStore)
    try
        datadir = fullfile(app.SessionDirectory, 'data');
        ipFile = fullfile(datadir, 'intensityProfiles.bin');
        fpFile = fullfile(datadir, 'fitProfiles.bin');
        % if ~isfile(ipFile)
        %     fclose(fopen(ipFile, 'a+'));
        % end
        % if ~isfile(fpFile)
        %     fclose(fopen(fpFile, 'a+'));
        % end
        app.ProfileStore = combine( ...
            sbsense.ProfileDatastore(ipFile, ...
            app.NumChannels, app.fdm(2), ...
            32, ... % bits per unit
            'single', ... % output data type
            'ForceOverwrite', true, ...
            'CanWrite', true), ...
            sbsense.ProfileDatastore(fpFile, ...
            app.NumChannels, app.fdm(2), ...
            32, ... % bits per unit
            'single', ... % output data type
            'ForceOverwrite', true, ...
            'CanWrite', true) ...
            );
        % elseif idx0<=1
        %     clear(app.ProfileStore.UnderlyingDatastores{1});
        %     clear(app.ProfileStore.UnderlyingDatastores{2});
        %     reset(app.ProfileStore.UnderlyingDatastores{1});
        %     reset(app.ProfileStore.UnderlyingDatastores{2});
    catch ME
        fprintf('Error occurred when creating profile datastores. Aborting datastore update. Error report:\n%s\n', getReport(ME));
        return;
    end
else
    app.ProfileStore.UnderlyingDatastores{1}.NumChannels = app.NumChannels;    
    app.ProfileStore.UnderlyingDatastores{2}.NumChannels = app.NumChannels;
    app.ProfileStore.UnderlyingDatastores{1}.UnitsPerChannelDatapoint = double(app.fdm(2));
    app.ProfileStore.UnderlyingDatastores{2}.UnitsPerChannelDatapoint = double(app.fdm(2));
end


y1Dir = fullfile(app.SessionDirectory, 'images', 'Composites');
yrDir = fullfile(app.SessionDirectory, 'images', 'Yrs');
ycDir = fullfile(app.SessionDirectory, 'images', 'Ycs');
% if isempty(app.ImageStore)
%     app.ImageStore = combine(...
%         imageDatastore(y1Dir, ...
%         'FileExtensions', '.png', 'ReadSize', 1), ...
%         imageDatastore(ycDir, ...
%         'FileExtensions', '.png', 'ReadSize', 1), ...
%         imageDatastore(yrDir, ...
%         'FileExtensions', '.png', 'ReadSize', 1) ...
%         );
% % else
% %     reset(app.ImageStore);
% end

TF = true; % TODO: Meaning of var??

try
    % obj, timeZero, tbl, y1fol, yrcfol, ids1, ids2, ds1, ds2
    %if isempty(app.ImageStore)
        [TF, ids] = writeDataToStoresAndClear(app.BinFileCollection, ...
            app.TimeZero, app.DataTable{1}, y1Dir, ycDir, yrDir, ...
            logical.empty(), app.ProfileStore.UnderlyingDatastores);
        if TF
            app.ImageStore = combine(ids{:});
            try
                app.ChannelIPsData = app.ProfileStore.UnderlyingDatastores{1}.MemMap.Data;
                if ~isempty(app.ChannelIPsData)
                    app.ChannelIPsData(1);
                end
            catch
                % TODO
            end
            try
                app.ChannelFPsData = app.ProfileStore.UnderlyingDatastores{2}.MemMap.Data;
                if ~isempty(app.ChannelFPsData)
                    app.ChannelFPsData(1);
                end
            catch
                % TODO
            end
        end
    %else
    %    writeDataToStoresAndClear(app.BinFileCollection, ...
    %        app.TimeZero, app.DataTable{1}, y1Dir, ycDir, yrDir, ...
    %        app.ImageStore.UnderlyingDatastores, app.ProfileStore.UnderlyingDatastores);
    %end
    TF2 = true;
catch ME
    fprintf('Error occurred when transferring binary data to datastores (%s): %s\n', ...
        ME.identifier, getReport(ME, 'extended'));
end
end