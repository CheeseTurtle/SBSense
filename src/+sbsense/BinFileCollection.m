%
% 1 x 64*1   bits = 1 x 8*1   bytes :: (abs?) idx # -- must not be missing?
% 1 x 8*11   bits = 1 x 1*20  bytes :: (abs) timestamp char vector -- if missing...?
% 1 x 8*LxW  bits = 1 x 1*L*W bytes :: Y1 -- if img missing, warn and fill with 0s, or warn and discard???
% 1-2 x 32*LxW bits = 2 x 4*LxW bytes :: Yc and/or Yr -- if img missing, fill with NaN
% 2 x 32*7x2160 bits = 2 x 4*7x2160 bytes :: IP and FP for each channel (all IPs first, then FPs -- must fill with NaN)
% (3 x 8*LxW bits = 3 x 1*LxW bytes -- use bitsToUint8/sbsense.utils.uint8ToBits) :: mask imgs
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
        SlotsPerFile double = 20; %25;
    end

    properties(GetAccess=public,SetAccess=private)
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
            %if ~isempty(y1)
            %    assert(~all(y1==255, 'all'));
            %end
            fprintf('[BFC/appendData] Asserting image sizes.\n');
            disp({ size(y1), obj.ImageDims ; size(yc), obj.ScaledImageDims ; size(yr), obj.ScaledImageDims ; ...
                size(IPs), fliplr(obj.ProfileDims) ; size(FPs), fliplr(obj.ProfileDims) });
            if(~isequal(size(y1), obj.ImageDims) || ~isequal(size(yc), obj.ScaledImageDims) || ~isequal(size(yr), obj.ScaledImageDims) ...
                || ~isequal(size(y1), obj.ImageDims))
                fprintf('[BFC/appendData] Image size assertion(s) failed! Some data will be missing.\n');
            end
            assert(isequal(size(yc), obj.ScaledImageDims));
            assert(isequal(size(yr), obj.ScaledImageDims));
            if isequal(size(IPs), fliplr(obj.ProfileDims))
                IPs = IPs';
            else %  [numChans scaledImgDims(2)] = c x L
                if(~isequal(size(IPs), obj.ProfileDims))
                    fprintf('[BFC/appendData] IPs size assertion(s) failed! Some data will be missing.\n');
                end
                assert(isequal(size(IPs), obj.ProfileDims));
            end
            if isequal(size(FPs), fliplr(obj.ProfileDims))
                FPs = FPs';
            else %  [numChans scaledImgDims(2)] = c x L
                if(~isequal(size(FPs), obj.ProfileDims))
                    fprintf('[BFC/appendData] FPs size assertion(s) failed! Some data will be missing.\n');
                end
                assert(isequal(size(FPs), obj.ProfileDims));
            end
            if ~isempty(obj.FileNames) && (isempty(obj.fileHandle) || isequal(obj.fileHandle,-1))
                obj.currentFileNumber = obj.NumFiles;
                obj.fileHandle = fopen(obj.FileNames(end), 'a');
                assert(~isequal(obj.fileHandle, -1));
                obj.currentFilePos = ftell(obj.fileHandle);
            end
            if ~isequal(obj.fileHandle, -1)
                try
                    fseek(obj.fileHandle, 0, 0);
                    isvalidfileID = true;
                catch % TODO: Check error identifier?
                    isvalidfileID = false;
                end
            else
                isvalidfileID = false;
            end

            if ~isempty(obj.FileNames) && (~isvalidfileID || isequal(obj.fileHandle, -1) || (obj.currentSlotNumber > obj.SlotsPerFile))
                try
                    if ~isequal(obj.fileHandle, -1)
                        try
                            fclose(obj.fileHandle);
                        catch
                        end
                    end
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

                if ~isequal(obj.fileHandle, -1)
                    try
                        fclose(obj.fileHandle);
                    catch
                        % TODO?
                    end
                end
                obj.fileHandle = fopen(newfilename, 'a');
                try
                    assert(~isequal(obj.fileHandle, -1));
                catch ME
                    try
                        fclose(obj.fileHandle);
                    catch
                        % TODO?
                    end
                    rethrow(ME);
                end

                % obj.currentFilePos = 0;
                % obj.currentFilePos = ftell(obj.FileHandle);
                % assert(obj.currentFilePos==0); % TODO
                % obj.currentSlotNumber = 1;
                % assert(~fseek(obj.fileHandle, 0, "bof"));
                % else
                %    assert(~isequal(obj.fileHandle, -1));
            end
            try
                % display(obj.currentFilePos);
                obj.currentFilePos = ftell(obj.fileHandle);
                % disp({obj.currentSlotNumber,obj.currentFilePos});
                % if obj.currentFileNumber
                [obj.currentSlotNumber, bytesFromSlotStart] ...
                    = obj.filePosToIndexNumber(obj.currentFilePos);
                disp({obj.currentSlotNumber,obj.currentFilePos,bytesFromSlotStart});
                if bytesFromSlotStart % TODO: Fill slot and advance slot number??
                    fprintf('[BFC/appendData] WARNING: PARTIAL SLOT (fpos: %g, currSN: %g, bytesFromStart: %g; nextSlotOffsetInBytes: %g)\n', ...
                        obj.currentFilePos, obj.currentSlotNumber, bytesFromSlotStart, ...
                        obj.indexNumberToFilePos(obj.currentSlotNumber+1));
                    obj.currentSlotNumber = obj.currentSlotNumber + 1;
                    obj.currentFilePos = obj.indexNumberToFilePos(obj.currentSlotNumber);
                    display(obj.currentFilePos);
                    val = fseek(obj.fileHandle, obj.currentFilePos, -1);
                    if(val)
                        fprintf('[BFC/appendData] assertion failed (~val). val: '); disp(val);
                    end
                    assert(~val);
                    assert(ftell(obj.fileHandle)==obj.currentFilePos);
                else
                    assert(~fseek(obj.fileHandle, 0, 0));
                    assert(ftell(obj.fileHandle)==obj.currentFilePos);
                end
                % end
                % end
            catch ME
                fprintf('[BFC/appendData] Error encountered when fseeking before write: %s\n', getReport(ME));
                try
                    fclose(obj.fileHandle);
                catch ME2
                    fprintf('[BFC] Error when calling fseek back to orig pos in error handler: %s\n', getReport(ME2, 'extended'));
                end
keyboard;
                rethrow(ME);
            end

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
                    count1 = 4*fwrite(obj.fileHandle, IPs, 'single'); % c x L
                    assert(count1==obj.slotSegSizesInBytes(6)); count = count + count1;
                    count1 = 4*fwrite(obj.fileHandle, FPs, 'single'); % c x L
                    assert(count1==obj.slotSegSizesInBytes(7)); count = count + count1;
                    if ~isequal(count, obj.SlotSizeInBytes)
                        fprintf('[BFC] count (%d) ~= obj.SlotSizeInBytes (%d)\n', ...
                            count, obj.SlotSizeInBytes);
                    end
                    assert(count == obj.SlotSizeInBytes);
                    newFilePos = ftell(obj.fileHandle);
                    if ~isequal(newFilePos, obj.currentFilePos + count)
                        fprintf('[BFC] count == obj.SlotSizeInBytes = %d, but newFilePos (%d) ~= (currentFilePos+count) (%d)!\n', ...
                            count, newFilePos, obj.currentFilePos + count);
                    end
                    assert(newFilePos==(obj.currentFilePos + count));
                    % if count > count0
                    obj.currentSlotNumber = obj.currentSlotNumber + 1;
                    obj.currentFilePos = newFilePos; % obj.currentFilePos + count;
                    % else
                    fprintf('[BFC] Wrote successfully. Resulting slot # & filepos: %d, %d\n', ...
                        obj.currentSlotNumber, obj.currentFilePos);
                catch ME0
                    if strcmp(ME0.identifier, "MATLAB:assertion:failed")
                        fprintf('[BFC] Warning: Writing data was unsuccessful due to failed assertion: %s\n', getReport(ME0, 'extended'));
                        assert(~fseek(obj.fileHandle, obj.currentFilePos, -1));
                        count = 0;
keyboard;
                    else
                        rethrow(ME0);
                    end
                end
            catch ME
                fprintf('[BFC] Error when writing to file: %s\n', getReport(ME));
                if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1)
                    try
                        assert(~fseek(obj.fileHandle, obj.currentFilePos, -1));
                    catch ME2
                        fprintf('[BFC] Error (or failure) when calling fseek back to orig pos in error handler: %s\n', getReport(ME2, 'extended'));
                        try
                            fclose(obj.fileHandle);
                        catch ME3
                            fprintf('[BFC] Error when calling fclose pos in last error handler: %s\n', getReport(ME3, 'extended'));
                        end
                    end
                    % rethrow(ME);
                end
                % return;
            end
        end

        % TODO: Write to ProfileDatastores at same time??
        function [TF,ids] = writeDataToStoresAndClear(obj, timeZero, tbl, y1fol, ycfol, yrfol, ~, pds)%, ps1, ps2, ds1, ds2)

            % Close the file handle so we can open the first file in the .bin collection
            if ~isempty(obj.fileHandle) && ~isequal(obj.fileHandle, -1)
                try
                    fclose(obj.fileHandle); % TODO: Tell/seek for error recovery?
                catch
                end
            end
            
            % Return state (success/failure)
            TF = false; %#ok<NASGU> 

            % Now we will iterate over each slot in each .bin file and write to the datastores (`pds`)
            i = 0; % overall slot index
            chkTab = table('Size', [0 4], 'VariableTypes', ["uint64" "uint64" "duration" "string"], ...
                'VariableNames', ["SlotIndex", "DPIdx", "RelTime", "FileNameIfLast"], ...
                'DimensionNames', ["FileNameBase", "Variables"]); % TODO: Capture index (does not reset between caps)
            timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")'; % absolute times
            % cmap = (0:255)/255;
            
            for fn=obj.FileNames %%% FOR EACH .BIN FILE
                if isempty(fn)
                    continue;
                end
                if ~isscalar(fn) % If fn is not scalar, then it probably needs to be transposed before iteration
                    fprintf('[BFC/WDSC] fn is unexpectedly not a scalar value!!\n');
                    display(fn);
                    continue;
                end
                try % Try to open the .bin file for reading
                    assert(isfile(fn));
                    fhandle = fopen(fn, 'r'); %%% OPEN FILE HANDLE
                    assert(~isequal(fn, -1)); % Assert success
                catch ME
                    fprintf('[BFC/WDSC] Error when asserting file status then calling fopen("%s", ''r''): %s\n', ...
                        strtrim(formattedDisplayText(fn, 'SuppressMarkup', true)), ...
                        getReport(ME));
                    continue;
                end
                
                % Determine file size for stopping ==> calculate number of slots in file
                assert(~fseek(fhandle, 0, 1)); % Go to end of file (assert success?? or that we moved?)
                maxPosInFile = ftell(fhandle);
                lastSlotPosInFile = maxPosInFile + 1 - obj.SlotSizeInBytes;
                assert(~fseek(fhandle, 0, -1)); % assert not EOF?? or what does this do???
                frewind(fhandle); % rewind to the beginning (is this redundant with the line above?)
                currPosInFile = ftell(fhandle); assert(currPosInFile==0); % assert that we are indeed at the beginning of the file
                % timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")';
                % display(fhandle);
                % disp(fopen(fhandle));
                %             try
                %                 fclose(fhandle);
                %             catch
                %             end
                
                
                % Now we iterate over the slots in this .bin file.
                try
                    for sn = 1:obj.SlotsPerFile %%% FOR EACH SLOT
                        % TODO: Eliminate redundant
                        if ~isequal(fhandle, -1)
                            try
                                fprintf('[BFC/WDSC] Closing fhandle for fn %s.\n', replace(fn, '\', '\\'));
                                fclose(fhandle); %%% CLOSE FILE HANDLE (Unnecessary?)
                            catch ME2
                                if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                                    fprintf('[BFC/WDSC] Closing file handle failed due to error: %s\n', getReport(ME2, 'basic'));
                                end
                            end
                        end
                        fhandle = fopen(fn, 'r'); %%% OPEN FILE HANDLE
                        fprintf('[BFC/WDSC] Opened fhandle for fn %s.\n', replace(fn, '\', '\\'));

                        thisPos = (sn-1)*obj.SlotSizeInBytes;
                        if(ftell(fhandle) == thisPos)
                            fprintf("Already at the correct position (%g bytes).\n", thisPos);
                        else
                            fseek(fhandle, thisPos, -1);
                        end
                        
                        try
                            eof = feof(fhandle);
                        catch MEE % "badfid_mx"
                            fprintf("###### ERROR: feof(fhandle) failed! ########\n%s\n", ...
                                getReport(MEE));
                            eof = false; %%% WHY?? (TODO: What would cause this???)
                        end
                        
                        % We've already passed the last slot in this file, so we move on (break).
                        if (currPosInFile > lastSlotPosInFile) || eof
                            % TODO: Handle incomplete slots
                            if ~isempty(chkTab)
                                chkTab.FileNameIfLast(end) = fn; %%% PREV CHUNK'S FILE (???)
                            end
                            try
                                fprintf('[BFC/WDSC] Closing fhandle for fn %s.\n', replace(fn, '\', '\\'));
                                fclose(fhandle);
                                %%% TODO: NEED TO REOPEN!! (or don't close...?)
                            catch ME2
                                if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                                    fprintf('[BFC/WDSC] Closing file handle failed due to error: %s\n', getReport(ME2, 'basic'));
                                    % TODO: How else should this be handled? Should the profile store update be aborted?
                                end
                            end
                            break;
                        end

                        % If we're still here, then we're not yet at the end of the file / past its last slot.
                        try %%% READ FROM .BIN FILE
                            % Read fields: [index], absTime (==> rowNum ==> index), y1, yc, yr, ips, fps
                            % origIdx = ... % TODO: Is this index relevant?
                            fread(fhandle, [1 1], '*uint64');
                            timeStamp = char(fread(fhandle, [1 11], '*uchar')); % this is absolute time
                            % timePos = datetime(timeStamp, 'InputFormat', 'HHmmss-SSSS');
                            % display(timeStamp);
                            rowNum = find(strcmp(timeStamp, timeStamps), 1); % find in time stamps
                            if isempty(rowNum)% || isequal(rowNum, 0)
                                fprintf('[BFC/WDSC] Cant find timeStamp "%s" in timeStamps.\n', ...
                                    timeStamp);
                                display(timeStamp);
                                display(timeStamps);
                                disp(find(strcmp(timeStamp, timeStamps)));
                            end
                            % assert(~isempty(rowNum)); assert(rowNum); % or isscalar instead of ~isempty?
                            if isempty(rowNum)
                                try
                                    fprintf('[BFC/WDSC] Closing fhandle for fn %s due to empty rowNum.\n', replace(fn, '\', '\\'));
                                    fclose(fhandle);
                                catch ME2
                                    if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                                        fprintf('[BFC/WDSC] Closing file handle failed due to error: %s\n', getReport(ME2, 'basic'));
                                    end
                                end
                                continue;
                            end
                            idx = tbl.Index(rowNum);
                            y1 = fread(fhandle, obj.ImageDims, '*uint16');
                            % assert(~all(y1==255, 'all'));
                            yc = fread(fhandle, obj.ScaledImageDims, '*single');
                            yr = fread(fhandle, obj.ScaledImageDims, '*single');
                            ips = fread(fhandle, obj.ProfileDims, '*single');
                            fps = fread(fhandle, obj.ProfileDims, '*single');
                            
                            currPosInFile = ftell(fhandle); %%% Update curr pos
                            
                            if(currPosInFile >= lastSlotPosInFile) % TODO: Write message? Also, is this unnecessary?
                                fclose(fhandle); %%% CLOSE FILE
                            end
                            % data = fread(fhandle, ... % colormap("gray"), ...
                            %    obj.SlotDims, obj.SlotDatatype);
                        catch ME1 % TODO: Error identifier (eof)
                            fprintf('[BFC/WDSC] (IMAGE FILES WILL NOT BE WRITTEN.) Error encountered while reading from file "%s" (%s): %s\n', ...
                                replace(fn,'\','\\'), ME1.identifier, getReport(ME1, 'extended'));
                            try
                                fprintf('[BFC/WDSC] Closing fhandle for fn %s (after catching error during read).\n', replace(fn, '\', '\\'));
                                fclose(fhandle);
                            catch ME2
                                if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                                    fprintf('[BFC/WDSC] Closing file handle failed due to error (during read error catch!): %s\n', getReport(ME2, 'basic'));
                                end
                            end
                            rethrow(ME1);
                        end
                        i = i + 1; %%% Increment i (overall slot index)
                        

                        % WRITE IMAGE FILES:
                        %
                        % Also Copyright, Disclaimer, Warning, Description, Comment, Author,
                        % Gamma, Chromaticities, Alpha/Transparency, Background
                        ctime = timeZero + tbl.RelTime(rowNum); % or use pre-calculated timestamps?
                        % Why this permutation??
                        % dIPs = permute(nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single'), [3 2 1]);
                        % [1 x L x c]
                        dIPs = nan([1 fliplr(obj.ProfileDims)], 'single');
                        % [1,<3072>*<4>(, implied 1)] --> permute [3 2 1] -->
                        %                            [implied 1, <3072>*<4>, 1]
                        %                            = ?x(LC)xn
                        imwrite(y1, ... % uint16
                            fullfile(y1fol, ['Y1-' timeStamp '.png']), ...
                            'png', ...
                            ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                            'InterlaceType', 'none', ...
                            'CreationTime', ctime, ...
                            ... % 'ImageModTime', datetime('now'), ...
                            ... % 'Source', '', ... % device
                            'Software', "SBSense (MATLAB ver. ?)" ...
                            );
                        imwrite(yc, ... % single
                            fullfile(ycfol, ['Yc-' timeStamp '.png']), ...
                            'png', ...
                            ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                            'InterlaceType', 'none', ...
                            'CreationTime', ctime, ...
                            ... % 'ImageModTime', datetime('now'), ...
                            ... % 'Source', '', ... % device
                            'Software', "SBSense (MATLAB ver. ?)" ...
                            );
                        imwrite(yr, ... % single
                            fullfile(yrfol, ['Yr-' timeStamp '.png']), ...
                            'png', ...
                            ... % 'BitDepth', 8, 'SignificantBits', 8, ...
                            'InterlaceType', 'none', ...
                            'CreationTime', ctime, ...
                            ... % 'ImageModTime', datetime('now'), ...
                            ... % 'Source', '', ... % device
                            'Software', "SBSense (MATLAB ver. ?)" ...
                            );
                        
                        % TODO: assert? (???)

                        % pd = [numChans scaledImgDims(2)];
                        pd = obj.ProfileDims(2); % prod(obj.ProfileDims);
                        len = size(ips,2); % length of intensity profile (should be scaledImgDims(2), right?)
                        if isequal(size(ips), obj.ProfileDims([2 1])) % Need to transpose?
                            ips = ips';
                            len = obj.ProfileDims(2); % len = size(ips, 2);
                        elseif ~isequal(size(ips), obj.ProfileDims) && (len < pd) % Dimensions are not correct. Probably incomplete. Pad (or fill) with zeros
                            disp({size(ips), len, pd});
keyboard;
                            ips = [ips zeros(obj.NumChannels, pd-len, 'single')]; %#ok<AGROW>

                            % TODO TODO TODO!!!!
                        end
                        assert(isequal(size(ips), obj.ProfileDims));

                        len = size(fps,2);
                        if isequal(size(fps), obj.ProfileDims([2 1])) % Check if need to transpose
                            fps = fps';
                            len = obj.ProfileDims(2); % len = size(fps, 2);
                        elseif ~isequal(size(fps), obj.ProfileDims) && (len < pd) % Dimensions are not correct. Probably incomplete. Pad (or fill) with 
                            disp({size(fps), len, pd});
keyboard;
                            fps = [fps zeros(obj.NumChannels, pd-len, 'single')]; %#ok<AGROW>
                            % TODO TODO TODO!!!!
                        end
                        assert(isequal(size(fps), obj.ProfileDims));

                        pd = prod(obj.ProfileDims); % TODO: Is this necessary? (Number of bytes to write)
                        
                        % Write to first ProfileDatastore.
                        % Returns the number of bytes written                        
                        % TODO: Check permutation
                        % c x L (x 1) ===> [1 x L x c]
                        count1 = write(pds{1}, permute(ips, [3 2 1]), idx);
                        if ~isequal(count1, pd)
                            fprintf('[BFC/WDSC] count1 ~= ProfileDims! %s\n', ...
                                strtrim(formattedDisplayText({count1, pd}, 'SuppressMarkup', true)));
                            disp(size(ips));
                            % ips = permute(ips, [3 2 1]); % TODO: Why don't we permute here like below?
                            count1 = write(pds{1}, ips, idx); % We specify the index so it'll retry at the same spot
                            fprintf('[BFC/WDSC] New count1: %g\n', count1);
                            if ~isequal(count1, pd)
                                count1 = write(pds{1}, dIPs, idx); % Failed again, so fill with zeros
                                fprintf('[BFC/WDSC] New count1: %g (filled with zeros after 2nd failure)\n', count1);
                            end
                        end
                        assert(isequal(count1,pd));

                        fps = permute(fps, [3 2 1]); % The count should be the same as the above --no need to multiply again
                        count2 = write(pds{2}, fps, idx);
                        if ~isequal(count2, pd)
                            fprintf('[BFC/WDSC] count2 ~= ProfileDims! %s\n', ...
                                strtrim(formattedDisplayText({count2, pd}, 'SuppressMarkup', true)));
                            disp(size(fps));
                            % fps = permute(fps, [3 2 1]); % TODO: Why do we permute here but not above?
                            count2 = write(pds{2}, fps, idx);
                            fprintf('[BFC/WDSC] New count2: %g\n', count1);
                            if ~isequal(count2, pd)
                                count2 = write(pds{2}, dIPs, idx); % Failed again, so fill with zeros
                                fprintf('[BFC/WDSC] New count2: %g (filled with zeros after 2nd failure)\n', count2);
                            end
                        end
                        assert(isequal(count2,pd));
                        % imwrite(data, ...
                        %     imgFileNames(i), 'png', 'InterlaceType', 'none');
                        
                        chkTab(i, :) = {i, idx, tbl.RelTime(rowNum), ""}; %%% ADD ROW TO CHKTAB
                        chkTab.FileNameBase{i} = timeStamp; % TODO: Can this be combined with the above line???
                    end %%% END OF FOR EACH SLOT
                    % ME2 = [];
                    try
                        fprintf('[BFC/WDSC] Done writing. Closing fhandle for fn %s.\n', replace(fn, '\', '\\'));
                        fclose(fhandle);
                    catch ME2
                        if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                            fprintf('[BFC/WDSC] Closing file handle failed due to error: %s\n', getReport(ME2, 'basic'));
                        end
                    end
                catch ME
                    fprintf('[BFC/WDSC] (SOME/ALL IMAGE FILE(S) MAY NOT BE WRITTEN.) Error occurred during reading from .bin file and writing to datastores (to be rethrown): %s\n', ...
                        getReport(ME));
                    try
                        fprintf('[BFC/WDSC] (In error handler for slot loop) Closing fhandle for fn %s.\n', replace(fn, '\', '\\'));
                        fclose(fhandle);
                    catch ME2
                        if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                            fprintf('[BFC/WDSC] (In error handler for slot loop) Closing file handle failed due to error: %s\n', getReport(ME2, 'basic'));
                        end
                    end
                    rethrow(ME); % return;
                end %%% END OF catch ME (iterating over slots in this .bin file)
                % delete(fn);
                % obj.FileNames(obj.FileNames==fn) = [];
                if ~isempty(chkTab) %%% STORE FILENAME IN CHKTAB (done populating)
                    chkTab.FileNameIfLast(end) = fn; %%% SET FILENAME (so we know to delete this file later)
                end
            end %%% END OF FOR EACH .BIN FILE

            % if ~isempty(chkTab)
            % chkTab.FileNameIfLast(end) = fn;
            %end

            sz = size(tbl, 1);
            dIPs = []; dFPs = [];
            % dImg = single(NaN);
            % timeStamps = string(tbl.RelTime + timeZero, "HHmmss-SSSS")';
            
            if(isempty(pds))
                hasPD1 = false;
                hasPD2 = false;
            else % pds is not empty
                try
                    if(isa(pds{1}, 'sbsense.ProfileDatastore') && ...
                            isobject(pds{1}.MemMap) && ...
                            ~isempty(pds{1}.MemMap.Data))
                        hasPD1 = true;
                    else
                        hasPD1 = false;
                    end
                catch
                    hasPD1 = false;
                end
                try
                    if(isa(pds{2}, 'sbsense.ProfileDatastore') && ...
                            isobject(pds{2}.MemMap) && ...
                            ~isempty(pds{2}.MemMap.Data))
                        hasPD2 = true;
                    else
                        hasPD2 = false;
                    end
                catch
                    hasPD2 = false;
                end
            end

            % Now we fill in the "holes"
            % TODO: Avoid overwriting with null!
            for rowNum=1:sz %%% FOR EACH ROW TO WRITE
                %%% GET TIMESTAMP
                timeStamp=char(timeStamps(rowNum));
                % if contains(timeStamp, chkTab.FileNameBase)
                %     continue;
                % end
                %%% WRITE IMAGES
                y1fn = fullfile(y1fol, ['Y1-' timeStamp '.png']);
                ycfn = fullfile(ycfol, ['Yc-' timeStamp '.png']);
                yrfn = fullfile(yrfol, ['Yr-' timeStamp '.png']);
                % Calculate absolute time from input table (datatype: Datetime)
                ctime = timeZero + tbl.RelTime(rowNum); %%% or use calculated timestamps??
                if ~isfile(y1fn)
                    fprintf('[writeDataToStoresAndClear] y1fn %s is not an existing file!\n', y1fn);
                    imwrite(zeros(1,1,'uint16'), y1fn, 'png', ...
                        ... % 'BitDepth', 16, 'SignificantBits', 16, ...
                        'InterlaceType', 'none', ...
                        'CreationTime', ctime, ...
                        ... % 'ImageModTime', datetime('now'), ...
                        ... % 'Source', '', ... % device
                        'Software', "SBSense (MATLAB ver. ?)" ...
                        );
                end
                if ~isfile(ycfn)
                    fprintf('[writeDataToStoresAndClear] ycfn %s is not an existing file!\n', ycfn);
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
                    fprintf('[writeDataToStoresAndClear] yrfn %s is not an existing file!\n', yrfn);
                    imwrite(zeros(1,1,'single'), yrfn, 'png', ...
                        ... 'BitDepth', 32, 'SignificantBits', 32, ...
                        'InterlaceType', 'none', ...
                        'CreationTime', ctime, ...
                        ... % 'ImageModTime', datetime('now'), ...
                        ... % 'Source', '', ... % device
                        'Software', "SBSense (MATLAB ver. ?)" ...
                        );
                end
                
                % Now that all image files exist, we look for possible mismatches/offsets? (TODO)

                idx = tbl.Index(rowNum); %%% LOOKUP INDEX IN INPUT TABLE
                if contains(timeStamp, chkTab.FileNameBase) %%% MATCHES
                    chkTab(timeStamp, 1:3) = {0, idx, tbl.RelTime(rowNum)}; %%% STORE IN CHKTAB (indexed by timestamp)
                    % fprintf('[writeDataToStoresAndClear] Row already present (%u, %s).\n', idx, timeStamp);
                else %%% DOESN'T MATCH
                    if isempty(dIPs) % || isempty(dFPs)
                        try
                            if(hasPD1 && (length(pds{1}.MemMap.Data) >= idx))
                                writeIP = false;
                            else
                                writeIP = true;
                                dIPs = nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single');
                            end
                        catch
                            writeIP = true;
                            dIPs = nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single');
                        end
                    else % TODO: Additional validation?
                        writeIP = true;
                    end

                    if isempty(dFPs)
                        try
                            if(hasPD2 && (length(pds{2}.MemMap.Data) >= idx))
                                writeFP = false;
                            else
                                writeFP = true;
                                dFPs = nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single');
                            end
                        catch
                            writeFP = true;
                            dFPs = nan(1, double(obj.ScaledImageDims(2))*double(obj.NumChannels), 'single');
                        end
                    else % TODO: Additional validation?
                        writeFP = true;
                    end

                    % TODO: What is the meaning of writeIP and writeFP?????
                    
                    if writeIP
                        write(pds{1}, dIPs, idx);
                    else
                        fprintf('[BFC/WDSC] Not writing IPs for index %d.\n', idx);
                    end
                    if writeFP
                        write(pds{2}, dFPs, idx); % TODO on writing profiles!!
                    else
                        fprintf('[BFC/WDSC] Not writing FPs for index %d.\n', idx);
                    end
                    fprintf('[BFC/WDSC] Adding row (%u, %s)...\n', idx, timeStamp);
                    % disp(chkTab);
                    % disp(timeStamp);
                    % disp(chkTab.FileNameBase);
                    % disp(contains(timeStamp, chkTab.FileNameBase));
                    chkTab(end+1, :) = {0, idx, tbl.RelTime(rowNum), ""}; %#ok<AGROW>
                    if ~isempty(chkTab) % Set row name
                        % display(chkTab);
                        % display(chkTab.FileNameBase);
                        if isempty(chkTab.FileNameBase) %%% SET ROW NAME
                            chkTab.FileNameBase = {char(timeStamp)};
                        else
                            chkTab.FileNameBase{end} = char(timeStamp);
                        end
                    else
                        fprintf('[BFC/WDSC] WARNING: chkTab is unexpectedly empty! (Adding a row was not successful.)\n');
                    end % TODO: else warn?
                    fprintf('[BFC/WDSC] Added row (%u, %s).\n', idx, timeStamp);
                end
            end %%% END OF FOR EACH INPUT ROW (trying to fill in holes in data???)



            % display(tbl(1:end, :));
            % display(chkTab(1:end, :));
            if ~issortedrows(chkTab, 'DPIdx') % Ensure chkTab is sorted by DPIdx
                chkTab = sortrows(chkTab, 'DPIdx');
                % display(chkTab(1:end, :));
            end

            %if isempty(ids)
            %    try
            % Return value
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

            % Reset datastores so that they update with the new data
            reset(pds{1}, true, false); % norewind, noremap
            reset(pds{2}, true, false); % norewind, noremap
            % fns = obj.FileNames;
            % fnum = 1;
            if ~isequal(obj.fileHandle, -1)
                try
                    fprintf('[BFC/WDSC] Closing obj.fileHandle.\n');
                    fclose(obj.fileHandle);
                catch ME2
                    if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                        fprintf('[BFC/WDSC] Could not close obj.fileHandle due to error "%s": %s\n', ...
                            ME2.identifier, getReport(ME2, 'basic'));
                    end
                end
            end




            fprintf('[BFC/WDSC] Checking datastore integrity...\n');
            len = size(chkTab, 1);
            for rowNum=1:len %%% FOR EACH CHKTAB ROW
                fnBase = chkTab.FileNameBase{rowNum};
                try
                    % TODO: Also verify that info.FileSize is appropriate??
                    % TODO: Also check profile data??
                    % Yx-HHmmss-SSSS.png
                    %    4         14
                    dpIdx = double(chkTab{fnBase, 'DPIdx'});
                    [~,info] = readimage(ids{1}, dpIdx); fn1 = char(info.Filename);
                    if ~strcmp(fn1((end-14):(end-4)), fnBase)
                        fprintf('fn1((end-14):(end-4)): %s, fnBase: %s\n', ...
                            replace(fn1((end-14):(end-4)),'\','\\'), fnBase);
                            if ~adjustDatastore(1) %% what does this do?
                                assert(strcmp(fn1((end-14):(end-4)), fnBase));
                            end
                    end
                    % assert(strcmp(fn1((end-14):(end-4)), fnBase));
                    [~,info] = readimage(ids{2}, dpIdx); fn2 = char(info.Filename);
                    if ~strcmp(fn2((end-14):(end-4)), fnBase)
                        fprintf('fn2((end-14):(end-4)): %s, fnBase: %s\n', ...
                            replace(fn2((end-14):(end-4)),'\','\\'), fnBase);
                        if ~adjustDatastore(2) % what does this do?
                            assert(strcmp(fn2((end-14):(end-4)), fnBase));
                        end
                    end
                    [~,info] = readimage(ids{3}, dpIdx); fn3 = char(info.Filename);
                    if ~strcmp(fn3((end-14):(end-4)), fnBase)
                        fprintf('fn3((end-14):(end-4)): %s, fnBase: %s\n', ...
                            replace(fn3((end-14):(end-4)),'\','\\'), fnBase);
                        if ~adjustDatastore(3) % what does this
                            assert(strcmp(fn3((end-14):(end-4)), fnBase));
                        end
                    end
                    % display(info.Filename);
                    % assert(strcmp(info.Filename(4:14), fnBase));
                    % assert(strcmp(info.Filename((end-14):(end-4)), fnBase));
                catch ME % TODO
                    display(dpIdx);
                    display(info.Filename);
                    display(fnBase);
                    fprintf('[BFC/WDSC] Error occurred when checking datastore integrity (dpIdx: %g, info.Filename: %s, fnBase: %s): %s\n', ...
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
                if isfile(binFileName)
                    fprintf('[BFC/WDSC] Deleting file %s.\n', replace(binFileName, '\', '\\'));
                    del = false;
                    try
                        if ~isequal(obj.fileHandle, -1)
                            try
                                fclose(obj.fileHandle);
                            catch ME2
                                if ~strcmp(ME2.identifier, "MATLAB:badfid_mx")
                                    fprintf('[BFC/WDSC] Could not close obj.fileHandle due to error "%s": %s\n', ...
                                        ME2.identifier, getReport(ME2, 'basic'));
                                end
                            end
                        end
                        delete(binFileName);
                        del = true;
                    catch ME
                        fprintf('[BFC/WDSC] Could not delete temp bin file due to error "%s": %s\n',...
                            ME.identifier, getReport(ME));
                        if isequal(obj.fileHandle, -1)
                            try
                                fclose(fopen(binFileName, 'w'));
                                del = true;
                                fprintf('[BFC/WDSC] Cleared file (but could not delete)\n');
                            catch
                                % TODO
                            end
                        end
                    end
                else  % TODO: else warn that file does not exist?
                    del = true;
                end
                if del
                    obj.FileNames(msk) = []; %strings(0);
                end
            end %%% END OF FOR EACH CHKTAB ROW
            % obj.FileNames = [];
            fprintf('[BFC/WDSC] Datastore integrity confirmed.\n');
            TF = true;
            % TODO: If currentFileNumber>0, fopen fileHandle and determine current slot number
            % obj.CurrentFileNumber = 0;
            % obj.currentSlotNumber = 1;
            obj.currentFileNumber = obj.NumFiles;
            % TODO: Calc slot number and new pos in file??
            % TODO: Another return param for whether or not all files were removed??

            % TODO: What does this do????
            function TF = adjustDatastore(dsNum)
                idx = find(contains(ids{dsNum}.Files(dpIdx+1:end), fnBase), 1);
                if(isempty(idx))
                    fprintf('[adjustDatastore] Couldn''t find any files matching fnBase "%s".\n', fnBase);
                    TF = false;
                    return;
                end
                idx = idx + dpIdx - 1;
                % assert(strcmp(fn((end-14):(end-4)), fnBase));
                while(idx >= dpIdx)
                    [~,info] = readimage(ids{dsNum}, dpIdx); fn0 = char(info.Filename);
                    if(strcmp(fn0((end-14):(end-4)), fnBase)) % This shouldn't occur, but just in case?
                        break;
                    end
                    [dir,barename,ext] = fileparts(fn0);
                    try
                        % disp({fn, dir, barename, ext});
                        % disp(fullfile(dir, '..', [barename ext]));
                        movefile(fn0, fullfile(dir, '..', [barename ext]));
                        reset(ids{dsNum});
                    catch MEE
                        fprintf('[adjustDatastore] Couldn''t move file "%s" due to error "%s": %s', ...
                            fn0, MEE.identifier, getReport(MEE));
                    end
                    idx = idx - 1;
                end
                TF = (idx == dpIdx);
            end
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