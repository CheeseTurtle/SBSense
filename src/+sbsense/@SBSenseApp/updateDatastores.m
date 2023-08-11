function TF = updateDatastores(app, idx0)
persistent bgPool;


TF = false;

sz = size(app.DataTable{1}, 1);
if ~sz && isempty(app.DataTable{1})
    return;
end

idx0Idx = find(app.DataTable{1}.Index==idx0, 1);
if ~idx0Idx
    return;
end

if isempty(bgPool)
    bgPool = backgroundPool();
end

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
    
    % futs = [ ...
    %     parfeval(bgPool, @writeImage, 1, ...
    %         fullfile(app.SessionDirectory, 'Composites', ['Y1-' fname]), ...
    %         app.Composites{i}), ...
    %     parfeval(bgPool, @writeImage, 1, ...
    %         fullfile(app.SessionDirectory, 'Yrs', ['Yr-' fname]), ...
    %         app.Yrs{i}), ...
    %     parfeval(bgPool, @writeImage, 1, ...
    %         fullfile(app.SessionDirectory, 'Ycs', ['Yc-' fname]), ...
    %         app.Ycs{i}) ...
    % ];
end
% futs = [ futs ...
%         parfeval(bgPool, @writeProfiles, 1, ...
%             fullfile(app.SessionDirectory, {'data\IntensityProfiles\', 'data\FitProfiles\'}), ...
%             app.NumChannels, ...
%             app.DataTable{1}.Index(idx0Idx:end), ...
%             app.ChannelIPs(idx0Idx:end), ...
%             app.ChannelFPs(idx0Idx:end)) ...
%         ];

if isempty(app.ProfileStore)
    datadir = fullfile(app.SessionDirectory, 'data');
    app.ProfileStore = combine( ...
        ProfileDatastore(datadir, 'intensityProfiles.bin', ...
            double(app.NumChannels), double(app.fdm(1,2)), 'ForceOverwrite', true), ...
        ProfileDatastore(datadir, 'fitProfiles.bin', ...
            double(app.NumChannels), double(app.fdm(1,2)), 'ForceOverwrite', true) ...
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

if ~isequal(size(app.ChannelIPs, [1 2 3]), [double(app.LargestIndexReceived - app.AnalysisParams.dpIdx0), double(app.fdm(2)), double(app.NumChannels)])
    disp({size(app.ChannelIPs, [1 2 3]), [double(app.LargestIndexReceived - app.AnalysisParams.dpIdx0), double(app.fdm(2)), double(app.NumChannels)]});
    keyboard;
end
write(app.ProfileStore.UnderlyingDatastores{1}, double(permute(app.ChannelIPs, [3 2 1])), idx0);
write(app.ProfileStore.UnderlyingDatastores{2}, double(permute(app.ChannelFPs, [3 2 1])), idx0);
reset(app.ProfileStore.UnderlyingDatastores{1});
reset(app.ProfileStore.UnderlyingDatastores{2});

% res = fetchOutputs(futs);
if true%all(res, 'all')
    if isempty(app.ImageStore)
        app.ImageStore = combine(...
            imageDatastore(fullfile(app.SessionDirectory, 'images', 'Composites'), ...
                'FileExtensions', '.png', 'ReadSize', 1), ...
            imageDatastore(fullfile(app.SessionDirectory, 'images', 'Ycs'), ...
                'FileExtensions', '.png', 'ReadSize', 1), ...
            imageDatastore(fullfile(app.SessionDirectory, 'images', 'Yrs'), ...
                'FileExtensions', '.png', 'ReadSize', 1) ...
        );
    else
        reset(app.ImageStore);
    end
    TF = true;
end

% app.ProfileStore = tabularTextDatastore(fullfile(app.SessionDirectory, 'data', 'profiles'), ...
%    'FileExtensions', {'.txt', '.csv'}, 'IncludeSubfolders', false, 'OutputType', 'table');
end

function TF = writeImage(path, I)
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