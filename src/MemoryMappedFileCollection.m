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
    filenameFormat string;
end

properties(GetAccess=public,SetAccess=immutable)
    SlotDatatype string;
    SlotDims double;
    SlotSizeInBytes double;
    SlotsPerFile double;
    FilenameStem char;
    FilenameExtension char,
    FileNumberFormat char;
end

methods
    function obj = MemoryMappedFileCollection(baseFileName, ...
            slotDatatype, slotDatatypeBits, slotDims, opts)
        arguments(Input)
            baseFileName (1,1) string;
            slotDatatype;
            slotDatatypeBits;
            slotDims;
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
        obj.SlotSizeInBytes = prod([ceil(slotDatatypeBits/8) obj.SlotDims]);
        obj.SlotsPerFile = fix(obj.MaxFileSizeInBytes / obj.SlotSizeInBytes);
        assert(obj.SlotsPerFile >= 1);
        obj.SlotDatatype = slotDatatype;
        obj.filenameFormat = sprintf('%s_%s.%s', ...
            obj.FileNameStem, obj.FileNumberFormat, obj.FilenameExtension);
    end

    function val = get.NumFiles(obj)
        val = size(obj.Files, 2);
    end

    function count = appendData(obj, data)
        assert(class(data)==obj.SlotDatatype);
        assert(isequal(size(data), obj.SlotDims));
        if obj.currentSlotNumber > obj.SlotsPerFile
            obj.currentSlotNumber = 1;
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
            if ~isempty(obj.fileHandle)
                try
                    fclose(obj.fileHandle);
                catch % TODO
                end
            end
            obj.fileHandle = fopen(newfilename, 'w+');
            assert(~isequal(obj.fileHandle, -1));
            % assert(~fseek(obj.fileHandle, 0, "bof"));
        end
        count = fwrite(obj.fileHandle, data, obj.SlotDatatype);
        if count > 0
            obj.currentSlotNumber = obj.currentSlotNumber + 1;
        end
    end

    function TF = writeImagesToFolderAndClear(obj, imgFileNames)
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
                    if feof(fhandle)
                        break;
                    end
                    try
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
        end
        obj.FileNames = [];
        TF = true;
    end
end
end