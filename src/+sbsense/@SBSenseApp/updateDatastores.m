function [TF,TF2] = updateDatastores(app, idx0, varargin)
persistent bgPool;

TF = false;
TF2 = false;

sz = size(app.DataTable{1}, 1);
if ~sz && isempty(app.DataTable{1})
    return;
end

idx0Idx = find(app.DataTable{1}.Index==idx0, 1);

if ~idx0Idx
    return;
end
len = uint64(sz)+uint64(1)-min(uint64(sz)+uint64(1),uint64(idx0Idx));
if isempty(app.Composites) || isempty(app.Yrs) || any(len ~= length(app.Composites)) || any(len ~= length(app.Yrs))
    fprintf('Composites and Yrs are not the correct size (%u~=%u, %u~=%u)! Cannot update datastores.\n', ...
        length(app.Composites), len, length(app.Yrs), len);
    return;
end

if isempty(bgPool)
    bgPool = backgroundPool();
end

% futs = parallel.Future.empty(2, len, 0);

for i=idx0Idx:sz
    fname = ... % [ ...
        sprintf('%04u_%s.png', app.DataTable{1}.Index(i), ...
        string(app.DataTable{1}.RelTime(i) + app.TimeZero, ...
        'HHmmss-SSSS')); %'YYMMdd-HHmmss-SSSSS'));
    if ~(writeImage( fullfile(app.SessionDirectory, 'images', 'Composites', ['Y1-' fname]), app.Composites{i}) ...
        && writeImage( fullfile(app.SessionDirectory, 'images', 'Yrs', ['Yr-' fname]), app.Yrs{i}) ...
        && writeImage( fullfile(app.SessionDirectory, 'images', 'Ycs', ['Yc-' fname]), app.Ycs{i}))
        return;
    end

    % try
    %     futs(:,i,1) = [ ...
    %         parfeval(bgPool, @writeImage, 3, ...
    %         fullfile(app.SessionDirectory, 'Composites', ['Y1-' fname]), app.Composites{i}, false, i), ...
    %         parfeval(bgPool, @writeImage, 3, ...
    %         fullfile(app.SessionDirectory, 'Yrs', ['Yr-' fname]), app.Yrs{i}, true, i) ...
    %         ];
    % catch ME
    %     fprintf('Error "%s" occurred when spawning Future no. %u (for i=%u in range %u-%u, dpIdx0=%u) to write image with suffix %s: %s\n', ...
    %         ME.identifier, i, idx0Idx, sz, app.AnalysisParams.dpIdx0, fname, getReport(ME));
    %     cancel(futs(strcmp(futs.State,"queued")));
    %     return;
    % end
    % % futs = [ ...
    % %     parfeval(bgPool, @writeImage, 1, ...
    % %         fullfile(app.SessionDirectory, 'Composites', ['Y1-' fname]), ...
    % %         app.Composites{i}), ...
    % %     parfeval(bgPool, @writeImage, 1, ...
    % %         fullfile(app.SessionDirectory, 'Yrs', ['Yr-' fname]), ...
    % %         app.Yrs{i}), ...
    % %     parfeval(bgPool, @writeImage, 1, ...
    % %         fullfile(app.SessionDirectory, 'Ycs', ['Yc-' fname]), ...
    % %         app.Ycs{i}) ...
    % % ];
end
% % futs = [ futs ...
% %         parfeval(bgPool, @writeProfiles, 1, ...
% %             fullfile(app.SessionDirectory, {'data\IntensityProfiles\', 'data\FitProfiles\'}), ...
% %             app.NumChannels, ...
% %             app.DataTable{1}.Index(idx0Idx:end), ...
% %             app.ChannelIPs(idx0Idx:end), ...
% %             app.ChannelFPs(idx0Idx:end)) ...
% %         ];


% imagesStored = false(2,len);

% while ~isempty(futs)
%     try
%         % Unused: isRatioImage
%         [i,isSuccess,~,idx] = fetchNext(futs);
%         if isSuccess
%             imagesStored(idx,iRatioImage+1) = true;
%         else
%             fprintf('An image writing attempt was not successful. Aborting datastore update.\n');
%             disp(futs(i));
%             if isprop(futs(i), 'Diary')
%                 fprintf('%s', futs(i).Diary);
%             end
%             return;
%         end
%         futs(futs.ID==id) = [];
%     catch ME
%         fprintf('An image writing attempt was not successful due to an error. Aborting datastore update.\nError ("%s"): %s\n', ....
%             ME.identifier, getReport(ME));
%         disp(futs(i));
%         return;
%     end
% end

% if ~all(imagesStored)
%     fprintf('Not all images were stored. Aborting datastore update.\n');
%     return;
% end

try
    if isempty(app.ProfileStore)
        datadir = fullfile(app.SessionDirectory, 'data');
        app.ProfileStore = combine( ...
            ProfileDatastore(fullfile(datadir, 'intensityProfiles.bin'), ...
            app.NumChannels, app.fdm(1,2), ...
            32, ... % bits per unit
            'single', ... % output data type
            'ForceOverwrite', true, ...
            'CanWrite', true), ...
            ProfileDatastore(fullfile(datadir, 'fitProfiles.bin'), ...
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
    else
        app.ProfileStore.UnderlyingDatastores{1}.UnitsPerDatapoint = double(app.fdm(2));
        app.ProfileStore.UnderlyingDatastores{2}.UnitsPerDatapoint = double(app.fdm(2));
    end


    % if ~isequal(size(app.ChannelIPs, [1 2 3]), [double(app.LargestIndexReceived - app.AnalysisParams.dpIdx0), double(app.fdm(2)), double(app.NumChannels)])
    %     disp({size(app.ChannelIPs, [1 2 3]), [double(app.LargestIndexReceived - app.AnalysisParams.dpIdx0), double(app.fdm(2)), double(app.NumChannels)]});
    %     keyboard;
    % end
    write(app.ProfileStore.UnderlyingDatastores{1}, permute(app.ChannelIPs, [3 2 1]), idx0);
    write(app.ProfileStore.UnderlyingDatastores{2}, permute(app.ChannelFPs, [3 2 1]), idx0);
    reset(app.ProfileStore.UnderlyingDatastores{1}, true, false);
    reset(app.ProfileStore.UnderlyingDatastores{2}, true, false);
catch ME
    fprintf('Error occurred when storing channel profile(s) in the datastore. Aborting datastore update. Errror report:\n%s\n', getReport(ME));
    return;
end

% res = fetchOutputs(futs);
% if true%all(res, 'all')
if isempty(app.ImageStore)
    app.ImageStore = combine(...
        imageDatastore(fullfile(app.SessionDirectory, 'images', 'Composites'), ...
        'FileExtensions', '.png', 'ReadSize', 1), ...
        ... % imageDatastore(fullfile(app.SessionDirectory, 'images', 'Ycs'), ...
        ... %   'FileExtensions', '.png', 'ReadSize', 1), ...
        imageDatastore(fullfile(app.SessionDirectory, 'images', 'Yrs'), ...
        'FileExtensions', '.png', 'ReadSize', 1) ...
        );
else
    reset(app.ImageStore);
end

% TODO: Prevent interruption during this part???
TF = true;

%     if (varargin==3)
%         if isequal(varargin(1),false)
%         elseif isempty(varargin{1}) && ( app.MemoryIdx0 == app.PageLimitsVals{1,1}(1)) ...
%             && (len == 1+diff(app.PageLimitsVals{1,1}))
%             return;
%         else
%             newMemoryIdx0 = app.PageLimitsVals{1,1}(1);
%             newMemoryIdxLen = 1+diff(app.PageLimitsVals{1,1});
%
%             app.Composites = { };
%             app.Yrs = { };
%             app.Ycs = { };
%             app.ChannelIPs = NaN(0,0,app.NumChannels, 'single');
%             app.ChannelFPs = app.ChannelIPs;
%             TF2 = true;
%         end
%     end
% end

% app.ProfileStore = tabularTextDatastore(fullfile(app.SessionDirectory, 'data', 'profiles'), ...
%    'FileExtensions', {'.txt', '.csv'}, 'IncludeSubfolders', false, 'OutputType', 'table');
end

function [TF,kind,idx] = writeImage(path, I, kind,idx)
try
    %f = fopen(path, "w");
    try
        if isempty(I)
        else
            % imwrite(I, path); %, 'png');
            imwrite(I,path);
            %fclose(f);
        end
    catch ME1
        %             try
        %                 fclose(f);
        %             catch
        %             end
        rethrow(ME1);
    end

    TF = true;
catch ME
    TF = false;
    % rethrow(ME);
    fprintf('Error "%s" when writing image "%s": %s\n', ME.identifier, path, getReport(ME));
end
end