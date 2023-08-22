%
% 1 x 64*1   bits = 1 x 8*1   bytes :: (abs?) idx # -- must not be missing?
% 1 x 8*11   bits = 1 x 1*20  bytes :: (abs) timestamp char vector -- if missing...?
% 1 x 8*LxW  bits = 1 x 1*L*W bytes :: Y1 -- if img missing, warn and fill with 0s, or warn and discard???
% 1-2 x 32*LxW bits = 2 x 4*LxW bytes :: Yc and/or Yr -- if img missing, fill with NaN
% 2 x 32*7x2160 bits = 2 x 4*7x2160 bytes :: IP and FP for each channel (all IPs first, then FPs -- must fill with NaN)
% (3 x 8*LxW bits = 3 x 1*LxW bytes -- use bitsToUint8/uint8ToBits) :: mask imgs
%

classdef BinFileCollection < handle & matlab.mixin.SetGetExactNames
properties(GetAccess=public,SetAccess=private)
    % Files (1, :) memmapfile;
    FileNames (1,:) string;

end

properties(Dependent,GetAccess=public,SetAccess=immutable)
    NumFiles;
end

properties(Constant)
    % MaxFileSizeInBytes = 2e9;
    % MaxSlotsPerFile = 25;
    SlotsPerFile double = 25;
end

properties(Access=private)
    currentSlotNumber = 1;
    currentFilePos = 0;
    currentFileNumber = 0;
    fileHandle = -1;
    maxEOFPos;
    filenameFormat string;
    imgDimsProd;
    scaledImgDimsProd;
    slotSegSizesInBytes;
end

properties(GetAccess=public,SetAccess=immutable)
    % SlotDatatype string;
    % SlotDims double;
    % SlotDataSizeInBytes double;
    % SlotIndexDatatype string;
    % SlotIndexDims double;
    % SlotIndexSizeInBytes double;
    SlotSizeInBytes;
    % SlotsPerFile double;
    FilenameStem char;
    FilenameExtension char,
    FileNumberFormat char;
    ImageDims (1,2) double;
    ScaledImageDims (1,2) double;
    ProfileDims double;
    NumChannels double;
end

methods
    function obj = BinFileCollection(dataDir, baseFileName, imgDims, scaledImgDims, numChans, opts)
        arguments(Input)
            dataDir (1,1) string {mustBeFolder};
            baseFileName (1,1) string;
            imgDims (1,2) double;
            scaledImgDims (1,2) double;
            numChans double;
            opts.FileNumberFormat = '%04d';
        end
        if contains(baseFileName, '.')
            strs = split(baseFileName, '.');
            obj.FilenameStem = strs(1);
            obj.FilenameExtension = strjoin(strs(2:end), '.');
            % TODO: Handle empty rest?
        else
            obj.FilenameStem = baseFileName;
            obj.FilenameExtension = 'bin';
        end
        obj.FileNumberFormat = opts.FileNumberFormat;
        obj.ImageDims = imgDims;
        obj.ScaledImageDims = scaledImgDims;
        obj.imgDimsProd = prod(double(imgDims));
        obj.scaledImgDimsProd = prod(double(scaledImgDims));
        obj.ProfileDims = [numChans scaledImgDims(2)];
        obj.NumChannels = numChans;
        obj.slotSegSizesInBytes = [
            8, 11, obj.imgDimsProd*2, obj.scaledImgDimsProd*4*[1 1], 4*numChans*scaledImgDims(2)*[1 1] ...
        ];
        obj.SlotSizeInBytes = sum(obj.slotSegSizesInBytes, 'all');
        obj.maxEOFPos = obj.SlotSizeInBytes * obj.SlotsPerFile;
        obj.filenameFormat = replace(fullfile(dataDir, ...
            sprintf('%s_%s.%s', ...
            obj.FilenameStem, obj.FileNumberFormat, obj.FilenameExtension)), ...
            '\', '\\');
    end

    function val = get.NumFiles(obj)
        val = size(obj.FileNames, 2);
    end

    function count = appendData(obj, idx, absTime, y1, yc, yr, IPs, FPs)
        arguments(Input)
            obj;
            idx (1,1) uint64;
            absTime (1,1) datetime;
            y1 (:,:) uint16;
            yc (:,:) single;
            yr (:,:) single;
            IPs (:,:) single;
            FPs (:,:) single;
        end
        if ~isempty(y1)
            assert(~all(y1==255, 'all'));
        end
        assert(isequal(size(y1), obj.ImageDims));
        assert(isequal(size(yc), obj.ScaledImageDims));
        assert(isequal(size(yr), obj.ScaledImageDims));
        if isequal(size(IPs), fliplr(obj.ProfileDims))
            IPs = IPs';
        else
            assert(isequal(size(IPs), obj.ProfileDims));
        end
        if isequal(size(FPs), fliplr(obj.ProfileDims))
            FPs = FPs';
        else
            assert(isequal(size(FPs), obj.ProfileDims));
        end
        if ~isempty(obj.FileNames) && (isempty(obj.fileHandle) || isequal(obj.fileHandle,-1))
            obj.currentFileNumber = obj.NumFiles;
            obj.fileHandle = fopen(obj.FileNames(end), 'a');
            assert(~isequal(obj.fileHandle, -1));
            obj.currentFilePos = ftell(obj.fileHandle);
        end
        try
            fseek(obj.fileHandle, 0, 0);
            isvalidfileID = true;
        catch % TODO: Check error identifier?
            isvalidfileID = false;
        end
        if ~isempty(obj.FileNames) && (~isvalidfileID || isequal(obj.fileHandle, -1) || (obj.currentSlotNumber > obj.SlotsPerFile))
            try
                obj.fileHandle = fopen(obj.FileNames(end), 'a+'); 
                obj.currentFilePos = ftell(obj.fileHandle);
                obj.currentFileNumber = length(obj.FileNames);
                % TODO: slot number
                isvalidfileID = true;
            catch % TODO
                isvalidfileID = false;
            end
        end
        if isempty(obj.FileNames) || ~obj.currentFileNumber || ~isvalidfileID % || isequal(obj.fileHandle, -1) || (obj.currentSlotNumber > obj.SlotsPerFile)
            % obj.currentSlotNumber = 1;
            if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1)
                try
                    fclose(obj.fileHandle);
                catch % TODO
                end
            end
            
            fprintf('Making new filename...\n');
            newfilename = sprintf(obj.filenameFormat, obj.currentFileNumber);
            fprintf('Made new filename (%s).\n', newfilename);
            fclose(fopen(newfilename, 'a+')); % fhandle = fopen(newfilename, 'w');
            % fclose(fhandle);
            
            if isempty(obj.FileNames)
                obj.FileNames = newfilename;
                obj.currentFileNumber = 1;
            else
                obj.currentFileNumber = length(obj.FileNames)+1; % obj.currentFileNumber + 1;
                obj.FileNames(obj.currentFileNumber) = newfilename;
            end
            
            obj.fileHandle = fopen(newfilename, 'a');
            assert(~isequal(obj.fileHandle, -1));
            % obj.currentFilePos = 0;
            % obj.currentFilePos = ftell(obj.FileHandle);
            % assert(obj.currentFilePos==0); % TODO
            % obj.currentSlotNumber = 1;
            % assert(~fseek(obj.fileHandle, 0, "bof"));
        % else
        %    assert(~isequal(obj.fileHandle, -1));
        end
            % display(obj.currentFilePos);
            obj.currentFilePos = ftell(obj.fileHandle);
            % disp({obj.currentSlotNumber,obj.currentFilePos});
            % if obj.currentFileNumber
                [obj.currentSlotNumber, bytesFromSlotStart] ...
                    = obj.filePosToIndexNumber(obj.currentFilePos);
                disp({obj.currentSlotNumber,obj.currentFilePos,bytesFromSlotStart});
                if bytesFromSlotStart % TODO: Fill slot and advance slot number??
                    fprintf('WARNING: PARTIAL SLOT (fpos: %g, currSN: %g, bytesFromStart: %g\n', ...
                        obj.currentFilePos, obj.currentSlotNumber, bytesFromSlotStart);
                    obj.currentFilePos = obj.indexNumberToFilePos(obj.currentSlotNumber);
                    display(obj.currentFilePos);
                    assert(~fseek(obj.fileHandle, obj.currentFilePos, -1));
                else
                     assert(~fseek(obj.fileHandle, 0, 0));
                     assert(ftell(obj.fileHandle)==obj.currentFilePos);
                end
            % end
        % end
        % origPos = obj.currrentFilePos; % ftell(obj.fileHandle);
        fprintf('Writing data for idx %u @ slot %g in file (pos in file: %d).\n', ...
            idx, obj.currentSlotNumber, obj.currentFilePos);
        try
            count1 = fwrite(obj.fileHandle, uint64(idx), 'uint64');
            try
                assert(count1==1); count = 8;
                arr = char(string(absTime, 'HHmmss-SSSS'));
                % display(arr);
                assert(isequal(size(arr), [1 11]));
                count1 = fwrite(obj.fileHandle, arr, 'uchar'); % or schar?
                assert(count1==11); count = count + count1;
                count1 = 2*fwrite(obj.fileHandle, uint16(y1), 'uint16');
                assert(count1==obj.slotSegSizesInBytes(3)); count = count + count1;
                count1 = 4*fwrite(obj.fileHandle, yc, 'single');
                assert(count1==obj.slotSegSizesInBytes(4)); count = count + count1;
                count1 = 4*fwrite(obj.fileHandle, yr, 'single');
                assert(count1==obj.slotSegSizesInBytes(5)); count = count + count1;
                count1 = 4*fwrite(obj.fileHandle, IPs, 'single');
                assert(count1==obj.slotSegSizesInBytes(6)); count = count + count1;
                count1 = 4*fwrite(obj.fileHandle, FPs, 'single');
                assert(count1==obj.slotSegSizesInBytes(7)); count = count + count1;
                assert(count == obj.SlotSizeInBytes);
                newFilePos = ftell(obj.fileHandle);
                assert(newFilePos==(obj.currentFilePos + count));
                % if count > count0
                    obj.currentSlotNumber = obj.currentSlotNumber + 1;
                    obj.currentFilePos = obj.currentFilePos + count;
                % else
                fprintf('[BFC] Wrote successfully. Resulting slot # & filepos: %d, %d\n', ...
                    obj.currentSlotNumber, obj.currentFilePos);
            catch ME0
                if strcmp(ME0.identifier, "MATLAB:assertion:failed")
                    fprintf('[BFC] Warning: Writing data was unsuccessful due to failed assertion: %s\n', getReport(ME0, 'extended'));
                    assert(~fseek(obj.fileHandle, obj.currentFilePos, -1));
                    count = 0;
                else
                    rethrow(ME0);
                end
            end
        catch % ME
            if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1)
                try
                    assert(~fseek(obj.fileHandle, obj.currentFilePos, -1));
                catch ME2
                    fprintf('[BFC] Error (or failure) when calling fseek back to orig pos in error handler: %s\n', getReport(ME2, 'extended'));
                end
                % rethrow(ME);
            end
            return;
        end
    end

    % TODO: Write to ProfileDatastores at same time??
    function [TF,ids] = writeDataToStoresAndClear(obj, timeZero, tbl, y1fol, ycfol, yrfol, ids, pds)%, ps1, ps2, ds1, ds2)
        if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1) 
            try
                close(obj.fileHandle); % TODO: Tell/seek for error recovery?
            catch
            end
        end
        TF = false;
        i = 0; % overall slot index
        chkTab = table('Size', [0 4], 'VariableTypes', ["uint64" "uint64" "duration" "string"], ...
            'VariableNames', ["SlotIndex", "DPIdx", "RelTime", "FileNameIfLast"], ...
            'DimensionNames', ["FileNameBase", "Variables"]); % TODO: Capture index (does not reset between caps)
        timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")';
        % cmap = (0:255)/255;

        for fn=obj.FileNames
            if isempty(fn)
                continue;
            end
            if ~isscalar(fn)
                fprintf('fn is unexpectedly not a scalar value!!\n');
                display(fn);
                continue;
            end
            try
                assert(isfile(fn));
                fhandle = fopen(fn, 'r');
                assert(~isequal(fn, -1));
            catch ME
                fprintf('Error when asserting file status then calling fopen("%s", ''r''): %s\n', ...
                    strtrim(formattedDisplayText(fn, 'SuppressMarkup', true)), ...
                    getReport(ME));
                continue;
            end
            assert(~fseek(fhandle, 0, 1));
            maxPosInFile = ftell(fhandle);
            lastSlotPosInFile = maxPosInFile + 1 - obj.SlotSizeInBytes;
            assert(~fseek(fhandle, 0, -1));
            frewind(fhandle);
            currPosInFile = ftell(fhandle);
            assert(currPosInFile==0);
            % timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")';
            % display(fhandle);
            % disp(fopen(fhandle));
%             try
%                 fclose(fhandle);
%             catch
%             end
            try
                for sn = 1:obj.SlotsPerFile
                    try
                        close(fhandle);
                    catch
                    end
                    fhandle = fopen(fn, 'r');
                    fseek(fhandle, (sn-1)*obj.SlotSizeInBytes, -1);
                    try
                        eof = feof(fhandle);
                    catch % "badfid_mx"
                        eof = false;
                    end
                    if (currPosInFile > lastSlotPosInFile) || eof % TODO: Handle incomplete slots
                        if ~isempty(chkTab)
                            chkTab.FileNameIfLast(end) = fn;
                        end
                        try
                            fclose(fhandle);
                        catch
                        end
                        break;
                    end
                    try
                        % origIdx = ...
                            fread(fhandle, [1 1], '*uint64');
                        timeStamp = char(fread(fhandle, [1 11], '*uchar'));
                        % timePos = datetime(timeStamp, 'InputFormat', 'HHmmss-SSSS');
                        % display(timeStamp);
                        rowNum = find(strcmp(timeStamp, timeStamps), 1);
                        if isempty(rowNum)% || isequal(rowNum, 0)
                            fprintf('Cant find timeStamp "%s" in timeStamps.\n', ...
                                timeStamp);
                            display(timeStamp);
                            display(timeStamps);
                            disp(find(strcmp(timeStamp, timeStamps)));
                        end
                        % assert(~isempty(rowNum)); assert(rowNum); % or isscalar instead of ~isempty?
                        if isempty(rowNum)
                            fclose(fhandle);
                            continue;
                        end
                        idx = tbl.Index(rowNum);
                        y1 = fread(fhandle, obj.ImageDims, '*uint16');
                        assert(~all(y1==255, 'all'));
                        yc = fread(fhandle, obj.ScaledImageDims, '*single');
                        yr = fread(fhandle, obj.ScaledImageDims, '*single');
                        ips = fread(fhandle, obj.ProfileDims, '*single');
                        fps = fread(fhandle, obj.ProfileDims, '*single');
                        currPosInFile = ftell(fhandle);
                        fclose(fhandle);
                        % data = fread(fhandle, ... % colormap("gray"), ...
                        %    obj.SlotDims, obj.SlotDatatype);
                    catch ME1 % TODO: Error identifier (eof)
                        fprintf('Error encountered while reading from file "%s" (%s): %s\n', ...
                            replace(fn,'\','\\'), ME1.identifier, getReport(ME1, 'extended'));
                        % continue;
                        try
                            fclose(fhandle);
                        catch
                        end
                        rethrow(ME1);
                    end
                    i = i + 1;
                    % Also Copyright, Disclaimer, Warning, Description, Comment, Author, 
                    % Gamma, Chromaticities, Alpha/Transparency, Background
                    ctime = timeZero + tbl.RelTime(rowNum);
                    dIPs = permute(nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single'), [3 2 1]);
                    imwrite(y1, ... 
                        fullfile(y1fol, ['Y1-' timeStamp '.png']), ...
                        'png', ...
                        ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                        'InterlaceType', 'none', ...
                        'CreationTime', ctime, ...
                        ... % 'ImageModTime', datetime('now'), ...
                        ... % 'Source', '', ... % device
                        'Software', "SBSense (MATLAB ver. ?)" ...
                    );
                    imwrite(yc, ...
                        fullfile(ycfol, ['Yc-' timeStamp '.png']), ...
                        'png', ...
                        ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                        'InterlaceType', 'none', ...
                        'CreationTime', ctime, ...
                        ... % 'ImageModTime', datetime('now'), ...
                        ... % 'Source', '', ... % device
                        'Software', "SBSense (MATLAB ver. ?)" ...
                    );
                    imwrite(yr, ...
                        fullfile(yrfol, ['Yr-' timeStamp '.png']), ...
                        'png', ...
                        ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                        'InterlaceType', 'none', ...
                        'CreationTime', ctime, ...
                        ... % 'ImageModTime', datetime('now'), ...
                        ... % 'Source', '', ... % device
                        'Software', "SBSense (MATLAB ver. ?)" ...
                    );
                    % TODO: assert?
                    len = size(fps,2);
                    pd = prod(obj.ProfileDims);
                    if len < pd
                        disp(size(ips));
                        ips = [ips zeros(obj.NumChannels, pd-len, 'single')]; %#ok<AGROW> 
                    end
                    len = size(fps,2);
                    if len < pd
                        disp(size(fps));
                        fps = [fps zeros(obj.NumChannels, pd-len, 'single')]; %#ok<AGROW> 
                    end
                    count1 = write(pds{1}, permute(ips, [3 2 1]), idx);
                    if ~isequal(count1, pd)
                        fprintf('count1 ~= ProfileDims! %s\n', ...
                            strtrim(formattedDisplayText({count1, pd}, 'SuppressMarkup', true)));
                        disp(size(ips));
                        ips = permute(ips, [3 2 1]);
                        count1 = write(pds{1}, ips, idx);
                        fprintf('New count1: %g\n', count1);
                        if ~isequal(count1, pd)
                            count1 = write(pds{1}, dIPs, idx);
                            fprintf('New count1: %g\n', count1);
                        end
                    end
                    assert(isequal(count1,pd));
                    count2 = write(pds{2}, permute(fps, [3 2 1]), idx);
                    if ~isequal(count2, pd)
                        fprintf('count2 ~= ProfileDims! %s\n', ...
                            strtrim(formattedDisplayText({count2, pd}, 'SuppressMarkup', true)));
                        disp(size(fps));
                        fps = permute(fps, [3 2 1]);
                        count2 = write(pds{2}, fps, idx);
                        fprintf('New count2: %g\n', count1);
                        if ~isequal(count2, pd)
                            count2 = write(pds{2}, dIPs, idx);
                            fprintf('New count2: %g\n', count2);
                        end
                    end
                    assert(isequal(count2,pd));
                    % imwrite(data, ...
                    %     imgFileNames(i), 'png', 'InterlaceType', 'none');
                    chkTab(i, :) = {i, idx, tbl.RelTime(rowNum), ""};
                    chkTab.FileNameBase{i} = timeStamp;
                end
                % fprintf('Closing fhandle for fn %s.\n', fn);
                try
                     fclose(fhandle);
                catch
                end
            catch ME
                try
                    fprintf('Closing fhandle for fn %s.\n', replace(fn, '\', '\\'));
                    fclose(fhandle);
                catch
                end
                rethrow(ME); % return;
            end
            % delete(fn);
            % obj.FileNames(obj.FileNames==fn) = [];
            if ~isempty(chkTab)
                chkTab.FileNameIfLast(end) = fn;
            end
        end

        % if ~isempty(chkTab)
        % chkTab.FileNameIfLast(end) = fn;
        %end
        sz = size(tbl, 1);
        dIPs = []; % dFPs = [];
        % dImg = single(NaN);
        % timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")';
        for rowNum=1:sz
            timeStamp=char(timeStamps(rowNum));
            % if contains(timeStamp, chkTab.FileNameBase)
            %     continue;
            % end
            y1fn = fullfile(y1fol, ['Y1-' timeStamp '.png']);
            ycfn = fullfile(ycfol, ['Yc-' timeStamp '.png']);
            yrfn = fullfile(yrfol, ['Yr-' timeStamp '.png']);
            ctime = timeZero + tbl.RelTime(rowNum);
            if ~isfile(y1fn)
                imwrite(im2uint16(zeros(1,1,'uint16')), y1fn, 'png', ...
                    'BitDepth', 16, 'SignificantBits', 16, ...
                    'InterlaceType', 'none', ...
                    'CreationTime', ctime, ...
                    ... % 'ImageModTime', datetime('now'), ...
                    ... % 'Source', '', ... % device
                    'Software', "SBSense (MATLAB ver. ?)" ...
                );
            end
            if ~isfile(ycfn)
                imwrite(zeros(1,1,'single'), ycfn, 'png', ...
                    ... 'BitDepth', 32, 'SignificantBits', 32, ...
                    'InterlaceType', 'none', ...
                    'CreationTime', ctime, ...
                    ... % 'ImageModTime', datetime('now'), ...
                    ... % 'Source', '', ... % device
                    'Software', "SBSense (MATLAB ver. ?)" ...
                );
            end
            if ~isfile(yrfn)
                imwrite(zeros(1,1,'single'), yrfn, 'png', ...
                    ... 'BitDepth', 32, 'SignificantBits', 32, ...
                    'InterlaceType', 'none', ...
                    'CreationTime', ctime, ...
                    ... % 'ImageModTime', datetime('now'), ...
                    ... % 'Source', '', ... % device
                    'Software', "SBSense (MATLAB ver. ?)" ...
                );
            end
            idx = tbl.Index(rowNum);
            if contains(timeStamp, chkTab.FileNameBase)
                chkTab(timeStamp, 1:3) = {0, idx, tbl.RelTime(rowNum)};
                % fprintf('Row already present (%u, %s).\n', idx, timeStamp);
            else
                if isempty(dIPs) % || isempty(dFPs)
                    dIPs = nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single');
                    % dFPs = dIPs;
                end
                write(pds{1}, permute(dIPs, [3 2 1]), idx);
                write(pds{2}, permute(dIPs, [3 2 1]), idx);
                fprintf('Adding row (%u, %s)...\n', idx, timeStamp);
                % disp(chkTab);
                % disp(timeStamp);
                % disp(chkTab.FileNameBase);
                % disp(contains(timeStamp, chkTab.FileNameBase));
                chkTab(end+1, :) = {0, idx, tbl.RelTime(rowNum), ""}; %#ok<AGROW>
                %if ~isempty(chkTab)
                    chkTab.FileNameBase{end} = timeStamp;
                %end % TODO: else warn?
                fprintf('Added row (%u, %s).\n', idx, timeStamp);
            end
        end
        
        % display(tbl(1:end, :));
        % display(chkTab(1:end, :));
        if ~issortedrows(chkTab, 'DPIdx')
            chkTab = sortrows(chkTab, 'DPIdx');
            % display(chkTab(1:end, :));
        end

        %if isempty(ids)
        %    try
                ids = { ...
                    imageDatastore(y1fol, ...
                    'FileExtensions', '.png', 'ReadSize', 1), ...
                    imageDatastore(ycfol, ...
                    'FileExtensions', '.png', 'ReadSize', 1), ...
                    imageDatastore(yrfol, ...
                    'FileExtensions', '.png', 'ReadSize', 1) ...
                    };
        %    catch ME1
        %        fprintf('Error when creating datastores (%s): %s\n', ...
        %            ME1.identifier, getReport(ME1));
        %        return;
        %    end
        %else
        %    %if ~isempty(ids) && iscell(ids)
        %        reset(ids{1}); reset(ids{2}); reset(ids{3});
        %    %end
        %end
        reset(pds{1}, true, false); % norewind, noremap
        reset(pds{2}, true, false); % norewind, noremap
        % fns = obj.FileNames;
        % fnum = 1;
        try
            fclose(obj.fileHandle);
        catch
        end
        fprintf('Checking datastore integrity...\n');
        len = size(chkTab, 1);
        for rowNum=1:len
            fnBase = chkTab.FileNameBase{rowNum};
            try 
                % TODO: Also verify that info.FileSize is appropriate??
                % TODO: Also check profile data??
                % Yx-HHmmss-SSSS.png
                %    4         14 
                dpIdx = double(chkTab{fnBase, 'DPIdx'});
                [~,info] = readimage(ids{1}, dpIdx); fn = char(info.Filename);
                if ~strcmp(fn((end-14):(end-4)), fnBase)
                    fprintf('fn((end-14):(end-4)): %s, fnBase: %s\n', ...
                    replace(fn((end-14):(end-4)),'\','\\'), fnBase);
                end
                assert(strcmp(fn((end-14):(end-4)), fnBase));
                [~,info] = readimage(ids{2}, dpIdx); fn = char(info.Filename);
                if ~strcmp(fn((end-14):(end-4)), fnBase)
                    fprintf('fn((end-14):(end-4)): %s, fnBase: %s\n', ...
                        replace(fn((end-14):(end-4)),'\','\\'), fnBase);
                end
                assert(strcmp(fn((end-14):(end-4)), fnBase));
                [~,info] = readimage(ids{3}, dpIdx); fn = char(info.Filename);
                if ~strcmp(fn((end-14):(end-4)), fnBase)
                    fprintf('fn((end-14):(end-4)): %s, fnBase: %s\n', ...
                    replace(fn((end-14):(end-4)),'\','\\'), fnBase);
                end
                assert(strcmp(fn((end-14):(end-4)), fnBase));
                % display(info.Filename);
                % assert(strcmp(info.Filename(4:14), fnBase));
                % assert(strcmp(info.Filename((end-14):(end-4)), fnBase));
            catch ME % TODO
                display(dpIdx);
                display(info.Filename);
                display(fnBase);
                fprintf('Error occurred when checking datastore integrity (dpIdx: %g, info.Filename: %s, fnBase: %s): %s\n', ...
                    dpIdx, replace(info.Filename,'\','\\'), fnBase, getReport(ME));
                rethrow(ME);
            end
            % TODO: Try/catch for this part also?
            binFileName = chkTab{fnBase, 'FileNameIfLast'};
            if (rowNum<len) && (~strlength(binFileName) || (length(obj.FileNames)==1))
                continue;
                % TODO: Guarantee no delete data that's not been read yet?
            elseif(isempty(obj.FileNames))
                break;
            elseif (rowNum >= len) && ~strlength(binFileName)
                binFileName = obj.FileNames(end);
            end
            msk = strcmp(binFileName,obj.FileNames);
            if ~any(msk)
                continue;
            end
            try
                assert(sum(msk)==1);
            catch ME
                display(binFileName);
                display(obj.FileNames);
                display(msk);
                display(msk==1);
                disp(sum(msk));
                rethrow(ME);
            end
            fprintf('Deleting file %s.\n', replace(binFileName, '\', '\\'));
            try
                try
                    fclose(obj.fileHandle);
                catch
                end
                delete(binFileName);
                obj.FileNames(msk) = [];
            catch ME
                fprintf('[BFC] Could not delete temp bin file due to error "%s": %s\n',...
                    ME.identifier, getReport(ME));
            end
        end
        % obj.FileNames = [];
        fprintf('Datastore integrity confirmed.\n');
        TF = true;
        % TODO: If currentFileNumber>0, fopen fileHandle and determine current slot number
        % obj.CurrentFileNumber = 0;
        % obj.currentSlotNumber = 1;
        obj.currentFileNumber = obj.NumFiles;
        % TODO: Calc slot number and new pos in file??
        % TODO: Another return param for whether or not all files were removed??
    end

    function delete(obj)
        % if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1)
            try
                fclose(obj.fileHandle);
            catch ME
                if ~(strcmp(ME.identifier, "MATLAB:FileIO:InvalidFid") ...
                        || strcmp(ME.identifier, "MATLAB:badfid_mx"))
                    % disp(ME.identifier);
                    fprintf('[BinFileCollection/delete] Warning: Could not close temporary file file due to error (%s): %s\n', ...
                        ME.identifier, getReport(ME, 'extended'));
                    % rethrow(ME);
                end
            end
        % end
        if ~isempty(obj.FileNames)
            for fn=obj.FileNames
                if isfile(fn)
                    try
                        fhandle = fopen(fn, 'w+');
                        try
                            fclose(fhandle);
                        catch ME
                            try
                                fclose(fhandle);
                            catch
                            end
                            rethrow(ME);
                        end
                        delete(fn);
                    catch ME
                        try
                            fprintf('[BinFileCollection/delete] Warning: Could not delete temporary file "%s" due to error (%s): %s\n', ...
                                replace(fn,'\','\\'), ME.identifier, getReport(ME, 'extended'));
                        catch
                            fprintf('[BinFileCollection/delete] Warning: Could not delete temporary file due to error (%s): %s\n', ...
                                ME.identifier, getReport(ME, 'extended'));
                            disp(fn);
                            % keyboard;
                        end
                    end
                end
            end
        end
    end
end

methods(Access=protected)
    function p = indexNumberToFilePos(obj, n)
        p = (n-1)*(obj.SlotSizeInBytes);
    end

    function [n,bytesFromSlotStart,bytesToNextSlot] = filePosToIndexNumber(obj, p)
        n = fix(p/obj.SlotSizeInBytes) + 1; % ceil((p-1)/(obj.SlotSizeInBytes)); % idivide(p, obj.SlotSizeInBytes+1, 'ceil');
        if bitget(nargout,2)
            bytesFromSlotStart = mod(p, obj.SlotSizeInBytes);
            if bytesFromSlotStart
                % p0 = (n-1)*(obj.SlotSizeInBytes+1);
                bytesToNextSlot = obj.SlotSizeInBytes - bytesFromSlotStart;
            else
                bytesToNextSlot = 0; % TODO?
            end
        end
    end
end
end