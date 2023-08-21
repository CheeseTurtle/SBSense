classdef MemoryMappedFileCollection < handle & matlab.mixin.SetGetExactNames
properties(GetAccess=public,SetAccess=private)
    % Files (1, :) memmapfile;
    FileNames (:,1) string;
end

properties(Dependent,GetAccess=public,SetAccess=immutable)
    NumFiles;
end

properties(Constant)
    MaxFileSizeInBytes = 2e9;
end

properties(Access=private)
    currentSlotNumber = 1;
    currentFileNumber = 0;
    fileHandle = -1;
    maxPos;
    filenameFormat string;
end

properties(GetAccess=public,SetAccess=immutable)
    SlotDatatype string;
    SlotDims double;
    SlotDataSizeInBytes double;
    SlotIndexDatatype string;
    SlotIndexDims double;
    SlotIndexSizeInBytes double;
    SlotSizeInBytes;
    SlotsPerFile double;
    FilenameStem char;
    FilenameExtension char,
    FileNumberFormat char;
end

methods
    function obj = MemoryMappedFileCollection(baseFileName, ...
            slotDatatype, slotDatatypeBits, slotDims, ...
            slotIndexType, slotIndexDatatypeBits, slotIndexDims, opts)
        arguments(Input)
            baseFileName (1,1) string;
            slotDatatype;
            slotDatatypeBits;
            slotDims;
            slotIndexType;
            slotIndexDatatypeBits;
            slotIndexDims;
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
        obj.SlotDims = slotDims;
        obj.SlotDataSizeInBytes = ceil(8\prod([slotDatatypeBits obj.SlotDims]));
        obj.SlotIndexDims = slotIndexDims;
        obj.SlotIndexSizeInBytes = ceil(8\prod([slotIndexDatatypeBits obj.SlotIndexDims]));
        obj.SlotSizeInBytes = obj.SlotDataSizeInBytes + obj.SlotIndexSizeInBytes;
        obj.SlotsPerFile = fix(obj.MaxFileSizeInBytes / obj.SlotSizeInBytes);
        assert(obj.SlotsPerFile >= 1);
        obj.maxPos = obj.SlotSizeInBytes * obj.SlotsPerFile;
        obj.SlotDatatype = slotDatatype;
        obj.SlotIndexDatatype = SlotIndexDatatype;
        obj.filenameFormat = sprintf('%s_%s.%s', ...
            obj.FileNameStem, obj.FileNumberFormat, obj.FilenameExtension);
    end

    function val = get.NumFiles(obj)
        val = size(obj.Files, 2);
    end

    function count = appendData(obj, idx, data)
        assert(class(idx)==obj.SlotIndexDatatype);
        assert(class(data)==obj.SlotDatatype);
        assert(isequal(size(idx), obj.SlotIndexDims));
        assert(isequal(size(data), obj.SlotDims));
        if ~isempty(obj.FileNames) && (isempty(obj.fileHandle) || isequal(obj.fileHandle,-1))
            obj.currentFileNumber = obj.NumFiles;
            obj.fileHandle = fopen(obj.FileNames(end), 'a');
            assert(~isequal(obj.fileHandle, -1));
            obj.currentSlotNumber = fix(ftell(obj.fileHandle) / obj.SlotSizeInBytes);
            % TODO: Seek to position at slot boundary if not at slot boundary!
        end
        if isempty(obj.FileNames) || ~obj.currentFileNumber || (obj.currentSlotNumber > obj.SlotsPerFile)
            % obj.currentSlotNumber = 1;
            if ~isempty(obj.fileHandle)
                try
                    fclose(obj.fileHandle);
                catch % TODO
                end
            end

            newfilename = sprintf(obj.filenameFormat, obj.currentFileNumber);
            fhandle = fopen(newfilename, 'w');
            fclose(fhandle);
            
            if ~obj.currentFileNumber %isempty(obj.FileNames)
                obj.FileNames = newfilename;
                obj.currentFileNumber = 1;
            else
                obj.currentFileNumber = obj.currentFileNumber + 1;
                obj.FileNames(obj.currentFileNumber) = newfilename;
            end
            
            obj.fileHandle = fopen(newfilename, 'w+');
            assert(~isequal(obj.fileHandle, -1));
            % assert(~fseek(obj.fileHandle, 0, "bof"));
        % else
        %    assert(~isequal(obj.fileHandle, -1));
        end
        origPos = ftell(obj.fileHandle);
        try
            count0 = fwrite(obj.fileHandle, idx, obj.SlotIndexDatatype);
            if count0 > 0
                count = count0 + fwrite(obj.fileHandle, data, obj.SlotDatatype);
                if count > count0
                    obj.currentSlotNumber = obj.currentSlotNumber + 1;
                else
                    assert(~fseek(obj.fileHandle, 0, origPos));
                    count = 0;
                end
            else
                count = 0;
            end
        catch ME
            try
                assert(~fseek(obj.fileHandle, 0, origPos));
            catch ME2
                fprintf('Error (or failure) when calling fseek in error handler: %s\n', getReport(ME2, 'extended'));
            end
            rethrow(ME);
        end
    end

    % TODO: Write to ProfileDatastores at same time??
    function TF = writeImagesToFolderAndClear(obj, tbl)%, ps1, ps2, ds1, ds2)
        try
            close(obj.fileHandle); % TODO: Tell/seek for error recovery?
        catch
        end
        TF = false; %#ok<NASGU> 
        i = 1;
        for fn=obj.FileNames
            fhandle = fopen(fn, 'r');
            try
                for sn = 1:obj.SlotsPerFile
                    if feof(fhandle) % TODO: Handle incomplete slots
                        break;
                    end
                    try
                        idx = fread(fhandle, ...
                            obj.SlotIndexDims, obj.SlotIndexDatatype);
                        data = fread(fhandle, ... % colormap("gray"), ...
                            obj.SlotDims, obj.SlotDatatype);
                    catch ME1 % TODO: Error identifier (eof)
                        fprintf('Error encountered while reading from file "%s" (%s): %s\n', ...
                            fn, ME1.identifier, getReport(ME1, 'extended'));
                        continue;
                    end
                    imwrite(data, ...
                        imgFileNames(i), 'png', 'InterlaceType', 'none');
                    i = i + 1;
                end
                fclose(fhandle);
            catch ME
                try
                    fclose(fhandle);
                catch
                end
                rethrow(ME); % return;
            end
            delete(fn);
            obj.FileNames(obj.FileNames==fn) = [];
        end
        % obj.FileNames = [];
        TF = true;
    end
    obj.currentFileNumber = obj.NumFiles;
end
end