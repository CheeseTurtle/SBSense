classdef ProfileDatastore < matlab.io.Datastore & handle ...
        & matlab.mixin.SetGetExactNames & matlab.io.datastore.Partitionable ...
        & matlab.io.datastore.Subsettable
    % 'matlab.io.datastore.CustomReadDatastore'
    % 'matlab.io.datastore.internal.util.SubsasgnableFileSetLabels'
    % 'matlab.io.datastore.internal.ScalarBase' >> matlab.mixin.internal.Scalar
    %      (cat, horzcat, vertcat, empty)
    % 'matlab.io.datastore.Shuffleable'
    % 'matlab.mixin.CustomDisplay'
    % 'matlab.io.datastore.FileWritable'

    properties(Access = public, NonCopyable,Transient)
        % CurrentFileIndex double
        % FileSet matlab.io.datastore.DsFileSet
        % Reader matlab.io.datastore.DsFileReader;
        FileHandle;
        MemMap;
        ChMemMap;
    end

    properties(SetAccess=private,GetAccess=public,NonCopyable=true,Transient=true)
        CanWrite = true;
    end

    properties(SetAccess=private,GetAccess=public)
        IndexRange double = [];
        RelativeIndices (1,:) double = [];
        IndexOffset (1,1) double = 0;
        CurrentRelativeIndex double = 0;
        ReadDim (1,2) double;
        ReadPrecision = '';
        % IPFileSet matlab.io.datastore.DsFileSet
        % FPFileSet matlab.io.datastore.DsFileSet
    end

    properties(SetAccess=private, GetAccess=public)
        %IPDirectory char = '';
        %FPDirectory char = '';
        %ChannelNum uint8 = 1;
        NumChannels uint8;
        NumDatapoints uint64;
        DatatypeName char = '';
        OutputDatatypeName char = '';
        SplitSize double;
    end

    properties(SetAccess=immutable,GetAccess=public)%,SetObservable=true,AbortSet=false)
        % Directory = '';
        FilePath = '';
    end

    properties(Access=public, SetObservable=true, AbortSet=false)
        UnitsPerDatapoint double;
        BytesPerUnit double;
    end

    properties(GetAccess=public,SetAccess=private)
        BytesPerChannelDatapoint double;
    end

    properties(GetAccess=public,SetAccess=private,SetObservable,AbortSet=false)
        BytesPerDatapoint double;
    end

    properties(GetAccess=public,SetAccess=private)%,Dependent)
        FileSize double;
    end

    properties(Access=public)
        ReadSize {mustBePositive, mustBeInteger} = 1;
    end

    methods

        %         function val = get.FileSize(obj)
        %             [hf,io,oldPos] = hasfile(obj);
        %             if hf
        %                 if ~io
        %                     obj.FileHandle = fopen(obj.FilePath, "r+", 'n'); %, 'UTF-8');
        %                 end
        %                 try
        %                     fseek(obj.FileHandle, 0, 1);
        %                     val = ftell(obj.FileHandle);
        %                     if val==-1
        %                         val = 0; % TODO: ???
        %                     end
        %                     if io
        %                         if oldPos
        %                             fseek(obj.FileHandle, oldPos, -1);
        %                         else
        %                             frewind(obj.FileHandle);
        %                         end
        %                         return;
        %                     end
        %                 catch ME
        %                     fclose(obj.FileHandle);
        %                     rethrow(ME);
        %                 end
        %                 fclose(obj.FileHandle);
        %             else
        %                 val = 0;
        %             end
        %         end

        function obj = ProfileDatastore(fileName, numChannels, ...
                unitsPerDatapoint, bitsPerUnit, outputClass, opts)
            arguments(Input)
                %dir {mustBeFolder};
                fileName {mustBeTextScalar, mustBeNonzeroLengthText};
                numChannels uint8;
                unitsPerDatapoint double;
                bitsPerUnit double = 64;
                %inputClass = 'double';
                outputClass = 'double';
                opts.ForceOverwrite = false;
                opts.CanWrite = true;
                opts.MemMap = [];
                opts.ChMemMap = [];
                opts.IndexRange = [];
                opts.Indices = [];
            end
            numChannels = double(max(1,numChannels));
            if unitsPerDatapoint==0
                unitsPerDatapoint = 1;
            end
            if bitsPerUnit==0
                bitsPerUnit = 1;
            end
            obj.CanWrite = opts.CanWrite;

            % obj.Directory = dir;
            obj.NumChannels = numChannels;
            obj.BytesPerUnit = ceil(bitsPerUnit/8);
            if bitsPerUnit<=8
                obj.DatatypeName = 'uint8';
            elseif bitsPerUnit <= 16
                obj.DatatypeName = 'uint16';
            elseif bitsPerUnit <= 32
                obj.DatatypeName = 'uint32';

                %elseif bitsPerUnit <= 64
                %    obj.DatatypeName = 'uint64';
            else
                obj.DatatypeName = 'double';
            end

            if isequal(outputClass, obj.DatatypeName)
                obj.ReadPrecision = ['*' outputClass];
            else
                obj.ReadPrecision = sprintf('%s=>%s', obj.DatatypeName, outputClass); % sprintf('ubit%u=>%s', bitsPerUnit, outputClass);
            end

            obj.UnitsPerDatapoint = unitsPerDatapoint;
            obj.BytesPerChannelDatapoint = bitsPerUnit*unitsPerDatapoint;
            obj.BytesPerDatapoint = obj.BytesPerChannelDatapoint*double(numChannels);
            obj.SplitSize = obj.BytesPerDatapoint;
            obj.ReadDim = [double(numChannels) double(unitsPerDatapoint)];
            obj.OutputDatatypeName = outputClass;

            % obj.FilePath = fullfile(dir, fileName); %compose('ch%u.bin', numChannels));
            obj.FilePath = fileName;
            if ~isempty(opts.Indices)
                obj.RelativeIndices = opts.Indices;
                obj.IndexOffset = min(obj.RelativeIndices) - 1;
                obj.RelativeIndices = opts.Indices - obj.IndexOffset;
                obj.NumDatapoints = length(opts.Indices);%range(opts.Indices);
                % opts.IndexRange = minmax(opts.Indices);
            end
            if ~isempty(opts.IndexRange)
                obj.IndexRange = opts.IndexRange;
                obj.IndexOffset = opts.IndexRange(1) - 1;
                obj.FileHandle = fopen(obj.FilePath, "r+");
                obj.NumDatapoints = 1 + diff(opts.IndexRange);
                fclose(obj.FileHandle);
            elseif opts.CanWrite
                if isfile(obj.FilePath)
                    if ~opts.ForceOverwrite
                        error("ProfileDatastore:existingFile", 'File "%s" already exists', obj.FilePath);
                    end
                    try
                        obj.FileHandle = fopen(obj.FilePath, "w+");
                        if obj.FileHandle ~= -1
                            fclose(obj.FileHandle);
                        end
                    catch ME
                        fprintf('(%s) %s\n', ME.identifier, getReport(ME));
                        disp(obj.FileHandle);
                    end
                else
                    fclose(fopen(obj.FilePath, "w+"));
                end
            else
                obj.FileHandle = fopen(obj.FilePath, "r+");
                fclose(obj.FileHandle);
            end

            if isempty(opts.MemMap)
                obj.MemMap = memmapfile(obj.FilePath, 'Writable', false, 'Offset', 0, ...
                    'Format', {obj.DatatypeName, [prod(obj.ReadDim, 'all') 1], 'AllChannels'}, 'Repeat', 1);
            else
                obj.MemMap = opts.MemMap;
            end
            if isempty(opts.ChMemMap)
                chMemMapFormat = repmat({obj.DatatypeName, [1 unitsPerDatapoint]}, numChannels, 1);
                chMemMapFormat(:, 3) = compose('Ch%u', 1:numChannels);
                obj.ChMemMap = memmapfile(obj.FilePath, 'Writable', false, 'Offset', 0, ...
                    'Format', chMemMapFormat, 'Repeat', 1);
                clear chMemMapFormat;
            else
                obj.ChMemMap = opts.ChMemMap;
            end

            %             obj.FileSet = matlab.io.datastore.DsFileSet( ...
            %                  fns, 'IncludeSubfolders', false, ...
            %                 'FileExtensions', '.bin', ...'FileSplitSize', 'file'); % 'FileSplitSize', 8*1024);
            % obj.FileHandle = fopen(obj.FilePath, "r+", "n"); %, "UTF-8");
            reset(obj,false,true); % no remap
            % fclose(obj.FileHandle);

            obj.CurrentRelativeIndex = 1;
            addlistener(obj, {'BytesPerUnit', 'UnitsPerDatapoint'}, 'PostSet',  ...
                @obj.postset_SplitSize);
        end

        function [TF,isOpen,t] = hasfile(obj)
            if isempty(obj.FileHandle) || (obj.FileHandle==1) || (obj.FileHandle==2)
                TF = false;
                isOpen = false;
                t = 0;
            else
                try
                    t = ftell(obj.FileHandle);
                    TF = true; % TODO: or check ferror(...)?
                    isOpen = (t~=-1);
                catch ME % MATLAB:badfid_mx
                    t = 0;
                    if ismember(ME.identifier, ["MATLAB:badfid_mx" "MATLAB:FileIO:InvalidFid"])
                        TF = false;
                        isOpen = false;
                    else
                        disp(ME.identifier);
                        rethrow(ME); % TODO -- context?
                    end
                end
            end
        end

        %         function val = get.BytesPerDatapoint(obj)
        %             val = obj.FileSet.FileSplitSize;
        %         end
        %         function set.BytesPerDatapoint(obj,val)
        %             obj.FileSet.FileSplitSize = val;
        %             reset(obj);
        %         end
        % Define the hasdata method
        function tf = hasdata(obj)
            % Return true if more data is available
            % tf = hasfile(myds.FileSet);
            % pos = ftell(obj.FileHandle);
            % tf = ~((pos==-1) || feof(obj.FileHandle));
            tf = (hasfile(obj) && ~feof(obj.FileHandle) || ~isempty(obj.MemMap)) && (obj.CurrentRelativeIndex <= obj.NumDatapoints);
        end

        function ps = datapointIdxToBytePosition(obj, idx, varargin)
            ps = double(idx-1)*(obj.SplitSize);
            if nargin==3
                ps = ps + double(varargin{1}-1).*(obj.BytesPerChannelDatapoint); % + 1;
                %else
                %    ps = ps + 1;
            end
        end

        function open(obj,varargin)
            try
                if ftell(obj.FileHandle)==-1
                    fopen(obj.FileHandle);
                end
            catch ME
                if ME.identifier=="MATLAB:badfid_mx"
                    obj.FileHandle = fopen(obj.FilePath, "r+", "n"); % , "UTF-8");
                else
                    rethrow(ME);
                end
            end
            if nargin > 1
                fseek(obj.FileHandle, varargin{1}, -1);
            end
        end

        function close(obj)
            try
                fclose(obj.FileHandle);
            catch ME
                if ME.identifier=="MATLAB:badfid_mx"
                    return; % TODO: warn?
                else
                    fprintf('Error "%s" occurred when calling fclose on file "%s": %s\n', ...
                        ME.identifier, obj.FileHandle, getReport(ME));
                end
            end
        end

        function A = readpoints(obj, idxs, isRange, varargin)
            if isempty(obj.ChMemMap) && isempty(obj.RelativeIndices)
                A = readfpoints(obj,idxs,isRange,varargin);
                return;
            elseif isempty(idxs)
                A = zeros(0,obj.OutputDatatypeName);
                return;
            end

            chNums = 1:obj.NumChannels;
            if (nargin<4) || isempty(varargin{1})
                allChannels = true;
            else
                msk = ismember(chNums, varargin{1});
                if all(msk)
                    allChannels = true;
                elseif any(msk)
                    allChannels = false;
                    chNums = chNums(msk);
                else
                    A = zeros(0,obj.OutputDatatypeName);
                    return;
                end
            end

            if isscalar(idxs)
                % isRange = false;
                isConsec = true;
            elseif isRange && (length(idxs)==2)
                isConsec = true;
                %                 %st = idxs(1);
                %                 %en = min(obj.NumDatapoints, idxs(2));
                idxs = idxs(1):1:idxs(2);
                %                 % clear idxs;
            elseif all(1==diff(idxs))
                isConsec = true;
                %                 %st = idxs(1);
                %                 %en = idxs(end);
                %                 % clear idxs;
                %                 % idxs = [st en];
            else
                isConsec = false;
                % %                 msk = idxs > obj.NumDatapoints;
                % %                 if any(msk)
                % %                     outOfRange = true;
                % %                     idxs(msk) = 0;
                % %                 else
                % %                     outofRange = false;
                % %                 end

            end
            if ~isempty(obj.RelativeIndices)
                idxs = idxs - obj.IndexOffset;
                idxs = idxs(ismember(idxs, obj.RelativeIndices));
                idxs = arrayfun(@(i) find(i==obj.RelativeIndices, 1), idxs);
                % idxs = horzcat(idxs{:});
            elseif obj.IndexOffset
                idxs = idxs - obj.IndexOffset;
            end

            if allChannels
                %if isConsec && (n==obj.NumDatapoints) % TODO: don't generate idxs list if all are included
                %    A = reshape(obj.MemMap.Data.AllChannels, ...
                %        obj.NumChannels, obj.UnitsPerDatapoint, []);
                %else %elseif isConsec
                    A = permute(reshape( ...
                        obj.MemMap.Data.AllChannels(:,idxs), ...
                        obj.UnitsPerDatapoint, obj.NumChannels, []), [2 1 3]);
                %else
                %    A = reshape(@(i) arrayfun(obj.MemMap.Data.AllChannels(:,i), idxs, 'UniformOutput', true), ...
                %        obj.NumChannels, obj.UnitsPerDatapoint, []);
                %end
            elseif isscalar(chNums)
                if false && n==obj.NumDatapoints
                    A = obj.ChMemMap.Data;
                else
                    A = obj.ChMemMap.Data(idxs);
                end
                A = vertcat(A.(['Ch' char(chNums+48)]));
            else
                % A = {obj.ChMemMap.Data(idxs).(compose("Ch%u", chNums))};
                %                 if n==obj.NumDatapoints
                %                 else
                %
                %                 end
                if (nargin==5) && varargin{2}
                    c = compose("Ch%u", chNums);
                    fun0 = @(d) arrayfun(@(v) d.(v), c, 'UniformOutput', false);
                    fun = @(x) vertcat(x{:});
                    A = arrayfun(@(d) fun(fun0(d)), ...
                        obj.ChMemMap.Data(idxs), 'UniformOutput', false);
                else
                    d = obj.ChMemMap.Data(idxs);
                    A = arrayfun( @(v) vertcat(d.(v)), ...
                        compose("Ch%u", chNums), 'UniformOutput', false);
                end
            end
        end

        function A = readfpoints(obj, idxs, isRange, varargin)
            if isempty(idxs)
                A = zeros(0,obj.OutputDatatypeName);
                return;
            end
            chNums = 1:obj.NumChannels;
            if (nargin==3) || isempty(varargin{1})
                allChannels = true;
            else
                msk = ismember(chNums, varargin{1});
                if all(msk)
                    allChannels = true;
                elseif any(msk)
                    allChannels = false;
                    chNums = chNums(msk);
                else
                    A = zeros(0,obj.OutputDatatypeName);
                    return;
                end
            end
            %             [hf,io] = hasfile(obj);
            %             if ~(hf && io)
            %                 obj.FileHandle = fopen(obj.FilePath, "r+", "n"); %, "UTF-8");
            %             end

            if isRange
                isConsec = true;
                st = idxs(1);
                en = idxs(2);
                % clear idxs;
            elseif all(1==diff(idxs))
                isConsec = true;
                st = idxs(1);
                en = idxs(end);
                % clear idxs;
                idxs = [st en];
            end


            %if ftell(obj.FileHandle)
            %    fclose(obj.FileHandle);
            %end

            [~,io,pos0] = hasfile(obj.FileHandle);
            if io
                f = obj.FileHandle;
                % fseek(obj.FileHandle, 0, 0);
            else
                f = fopen(obj.FilePath, "r+", "n"); %, "UTF-8");
            end

            try
                if isConsec
                    n = en+1-st;
                    A = zeros(obj.NumChannels, obj.UnitsPerDatapoint, n, obj.OutputDatatypeName);
                    if obj.ReadPrecision(1)=='*'
                        readPrec = obj.ReadPrecision;
                    else
                        readPrec = ['*' obj.ReadPrecision];
                    end


                    if allChannels
                        readFcn = @() fread(obj.FileHandle, obj.ReadDim, readPrec, 0, "n");
                        % skip = 0;
                    else
                        readFcn0 = @(A,rs) A(rs,:);
                        readDim = obj.ReadDim;
                        if (chNums(end)==obj.NumChannels)
                            skip = 0;
                            readPrec = [int2str(double(obj.UnitsPerDatapoint)*obj.NumChannels) readPrec];
                        else
                            skip = double(obj.NumChannels-chNums(end))*obj.BytesPerChannelDatapoint;
                            readDim(1) = chNums(end);
                            readPrec = [int2str(double(obj.UnitsPerDatapoint)*chNums(end)) obj.ReadPrecision];
                            % readFcn = @() fread(obj.FileHandle, obj.ReadDim, obj.ReadPrecision, skip, "n");
                        end
                        readFcn = @() readFcn0( ...
                            fread(obj.FileHandle, readDim, readPrec, skip, "n"), ...
                            chNums);
                    end
                    fseek(f, datapointIdxToBytePosition(obj,st), -1);

                    for ii=1:n
                        A(:,:,ii) = readFcn();
                        st = st + 1;
                    end
                else % nonconsecutive
                    A = zeros(obj.NumChannels, obj.UnitsPerDatapoint, length(idxs), obj.OutputDatatypeName);
                    if allChannels
                        readFcn = @() fread(obj.FileHandle, obj.ReadDim, obj.ReadPrecision, 0, "n");
                        % skip = 0;
                    else
                        readFcn0 = @(A,rs) A(rs,:);
                        % readDim = obj.ReadDim;
                        %                         if (chNums(end)==obj.NumChannels)
                        %                             skip = 0;
                        %                         else
                        %                             skip = double(obj.NumChannels-chNums(end))*obj.BytesPerChannelDatapoint;
                        %                             readDim(1) = chNums(end);
                        %                             % readFcn = @() fread(obj.FileHandle, obj.ReadDim, obj.ReadPrecision, skip, "n");
                        %                         end
                        readFcn = @() readFcn0( ...
                            fread(obj.FileHandle, obj.ReadDim, obj.ReadPrecision, 0, "n"), ...
                            chNums);
                    end

                    ii = 1;
                    lastIdx = idxs(1);
                    lastPos = datapointIdxToBytePosition(obj, lastIdx);
                    for i=idxs
                        if isConsec
                            fseek(obj.FileHandle, lastPos + obj.BytesPerDatapoint*(i - lastIdx));
                        elseif i==lastIdx
                            fseek(obj.FileHandle, lastPos, -1);
                        end
                        A(:,:,ii) = readFcn();
                        ii = ii + 1;
                    end
                end
                fseek(obj.FileHandle, pos0, -1);
                fclose(f);
            catch ME
                fclose(f);
                rethrow(ME);
            end
            %  fseek(obj.FileHandle, pos0, -1);
            %             try
            %                 fopen(obj.FileHandle);
            %             catch
            %                 % TODO: ???
            %             end
        end

        function data = readall(obj, varargin)
            if isempty(obj.MemMap)
                % TODO
                error('Not implemented yet!');
            end
            if (nargin==2) && varargin{2}
                data = permute(reshape(obj.MemMap.Data.AllChannels, ...
                    obj.UnitsPerDatapoint, obj.NumChannels, []), [2 1 3]);
            elseif obj.CanWrite
                data = readall@matlab.io.Datastore(obj);
                % data = reshape(obj.MemMap.Data.AllChannels, ...
                %    obj.UnitsPerDatapoint, obj.NumChannels, []);
            else
                if isempty(obj.RelativeIndices)
                    d = obj.MemMap.Data.AllChannels;
                else
                    try
                        d = obj.MemMap.Data.AllChannels(:,obj.RelativeIndices);
                    catch % ME
                        if isempty(obj.MemMap.Data.AllChannels)
                            data = []; % TODO
                            return;
                        end
                    end
                end
                if mod(size(d,1)/obj.UnitsPerDatapoint, obj.NumChannels)
                    data = zeros(obj.UnitsPerDatapoint * obj.NumChannels, obj.NumDatapoints, obj.OutputDatatypeName);
                    data(1:size(d,1),:) = d;
                    data = permute(reshape(data, obj.UnitsPerDatapoint, obj.NumChannels, []), [2 3 1]);
                else
                    data = permute(reshape(d, obj.UnitsPerDatapoint, obj.NumChannels, []), [2 3 1]);
                end
                data = reshape(data, double(obj.NumChannels)*obj.NumDatapoints, []);
                
            end
        end

        % Define the read method
        function [data,info] = read(obj)
            if isempty(obj.MemMap) && isempty(obj.RelativeIndices)
                assert(obj.ReadSize==1);
                [data,info] = readf(obj);
                return;
            end

            if obj.CurrentRelativeIndex > obj.NumDatapoints
                msgII = ['Use the reset method to reset the datastore ',...
                    'to the start of the data.'];
                msgIII = ['Before calling the read method, ',...
                    'check if data is available to read ',...
                    'by using the hasdata method.'];
                error('No more data to read.\n%s\n%s\n',msgII,msgIII);
                %else
                %    fseek(obj.FileHandle, 0, 0);
            end

            d = obj.MemMap.Data;
            if (obj.ReadSize==1)
                nextIdx = obj.CurrentRelativeIndex + 1;
                n = 1;
                if isempty(obj.RelativeIndices)
                    data = reshape(d.AllChannels(:,obj.CurrentRelativeIndex), ...
                        fliplr(obj.ReadDim))';
                else
                    data = d.AllChannels(:,obj.RelativeIndices(obj.CurrentRelativeIndex));% obj.IndexOffset + obj.RelativeIndices(obj.CurrentRelativeIndex) - 1);
                    if ~isempty(data)
                        data = reshape(data, fliplr(obj.ReadDim));
                    end
                end
            else
                nextIdx = obj.CurrentRelativeIndex + obj.ReadSize;
                if isempty(obj.ChMemMap)
                    numpts = obj.NumDatapoints;
                else
                    numpts = numel(obj.ChMemMap.Data);
                end
                if  numpts <= nextIdx
                    n = numpts + 1 - obj.CurrentRelativeIndex;
                else
                    n = nextIdx + 1 - obj.CurrentRelativeIndex;
                end
                if isempty(obj.RelativeIndices)
                    data = permute(reshape(d.AllChannels(:,obj.CurrentRelativeIndex + 0:(n-1)), ...
                        obj.UnitsPerDatapoint, obj.NumChannels, numpts), [2 1 3]);
                else
                    data = permute(reshape(...
                        d.AllChannels(:, ...
                        ... % arrayfun(@(i) find(i==obj.RelativeIndices, 1), idxs - obj.IndexOffset)), ...
                         obj.RelativeIndices(obj.CurrentRelativeIndex + 0:(n-1) - 1)), ...
                        obj.UnitsPerDatapoint, obj.NumChannels, numpts), [2 1 3]);
                end
            end
            clear d;

            if nargout > 1
                info = struct('Size', n*obj.UnitsPerDatapoint, ...
                    'FileName', obj.FilePath, 'Offset', ...
                    datapointIdxToBytePosition(obj, obj.CurrentRelativeIndex));
            end

            obj.CurrentRelativeIndex = nextIdx;
        end

        function [data,info] = readf(obj)
            % Read data and information about the extracted data
            % See also: MyFileReader()
            assert(obj.CanWrite);
            [hf,io,offset] = hasfile(obj);
            if ~hf
                error('Missing or invalid file identifier. Call open on the obj first.\n');
            elseif ~io
                obj.FileHandle = fopen(obj.FileHandle, "r+", 'n');
                if obj.CurrentRelativeIndex ~= 1
                    if obj.CurrentRelativeIndex > 1
                        fseek(obj.FileHandle, datapointIdxToBytePosition(obj, obj.CurrentRelativeIndex), -1);
                    else
                        obj.CurrentRelativeIndex = 1;
                    end
                end
            elseif feof(obj.FileHandle) % ~hasdata(obj)
                msgII = ['Use the reset method to reset the datastore ',...
                    'to the start of the data.'];
                msgIII = ['Before calling the read method, ',...
                    'check if data is available to read ',...
                    'by using the hasdata method.'];
                error('No more data to read.\n%s\n%s\n',msgII,msgIII);
                %else
                %    fseek(obj.FileHandle, 0, 0);
            end

            try
                if obj.ReadPrecision(1)=='*'
                    readPrec = obj.ReadPrecision;
                else
                    readPrec = ['*' obj.ReadPrecision];
                end
                readPrec = [int2str(double(obj.UnitsPerDatapoint)*double(obj.NumChannels)) readPrec];
                [data,n] = fread(obj.FileHandle, obj.ReadDim, readPrec, 0, "n");
                if n
                    obj.CurrentRelativeIndex = obj.CurrentRelativeIndex + 1;
                end
                info = struct('Size', n, 'FileName', obj.FilePath, 'Offset', offset);
            catch ME
                fclose(obj.FileHandle);
                rethrow(ME);
            end
            fclose(obj.FileHandle);
            % %             if ftell(obj.FileHandle)==-1
            % %                 fseek(obj.FileHandle, 0, "bof");
            % %             end
            %
            %             % Read a single datapoint, each channel
            %             data = zeros(obj.UnitsPerDatapoint, obj.NumChannels, obj.DatatypeName);
            %
            %
            %             % info = struct('Size',{}, 'FileName',{}, 'Offset', {});
            %             sizes = zeros(1,obj.NumChannels,'double');
            %             fns = strings(1,obj.NumChannels);
            %             offsets = zeros(1,obj.NumChannels, 'double');
            %             % data = cell(1,obj.NumChannels);
            %             for i=1:obj.NumChannels
            %                 fileInfoTbl = nextfile(obj.FileSet);
            %                 data(:,i) = readProfileFile();
            %                 sizes(i) = length(data(:,i))*double(obj.BytesPerUnit);
            %                 fns(i) = fileInfoTbl.FileName;
            %                 offsets(i) = fileInfoTbl.Offset;
            %             end
            %             info = struct('Size', sizes, 'FileName', fns, 'Offset', offsets);
            %
            % %             function A = readProfileFile()
            % %                 reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);
            % %                 seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');
            % %                 if double(fileInfoTbl.Offset) + double(obj.BytesPerDatapoint) > double(fileInfoTbl.SplitSize + 1)
            % %                     A = read(reader, double(fileInfoTbl.SplitSize) - double(fileInfoTbl.Offset + 1), ...
            % %                         'OutputType', obj.OutputDatatypeName);
            % %                 else
            % %                     A = read(reader, obj.BytesPerDatapoint, 'OutputType', obj.OutputDatatypeName);
            % %                 end
            % %             end
            %
            %             function A = readProfileFile()
            %
            %                 %reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);
            %                 %seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');
            %                 if double(fileInfoTbl.Offset) + double(obj.BytesPerChannelDatapoint) > double(fileInfoTbl.SplitSize + 1)
            %                     A = read(reader, double(fileInfoTbl.SplitSize) - double(fileInfoTbl.Offset + 1), ...
            %                         'OutputType', obj.OutputDatatypeName);
            %                 else
            %                     A = read(reader, obj.BytesPerChannelDatapoint, 'OutputType', obj.OutputDatatypeName);
            %                 end
            %             end
            %
            % %             fileInfoTbl = nextfile(myds.FileSet);
            % %             data = readFile(fileInfoTbl);
            % %             info.Size = size(data);
            % %             info.FileName = fileInfoTbl.FileName;
            % %             info.Offset = fileInfoTbl.Offset;
            % %
            % %             % Update CurrentFileIndex for tracking progress
            % %             if fileInfoTbl.Offset + fileInfoTbl.SplitSize >= ...
            % %                     fileInfoTbl.FileSize
            % %                 myds.CurrentFileIndex = myds.CurrentFileIndex + 1 ;
            % %             end
        end

        function clear(obj)
            [hf,io] = hasfile(obj);
            if hf
                if io
                    fclose(obj.FileHandle);
                end
                obj.FileHandle = fopen(obj.FilePath, "w+", "n");
                try
                    fclose(obj.FileHandle);
                catch ME
                    if ME.identifier ~= "MATLAB:FileIO:InvalidFid"
                        rethrow(ME);
                    end
                end
            else
                obj.FileHandle = fopen(obj.FilePath, "w+", "n");
                try
                    fclose(obj.FileHandle);
                catch ME
                    if ME.identifier ~= "MATLAB:FileIO:InvalidFid"
                        rethrow(ME);
                    end
                end
            end
            obj.FileHandle = fopen(obj.FilePath, "r+", "n");
            try
                fclose(obj.FileHandle);
            catch ME
                if ME.identifier ~= "MATLAB:FileIO:InvalidFid"
                    rethrow(ME);
                end
            end
            if obj.FileHandle == -1
                return;
            end
            obj.NumDatapoints = 0;
            obj.FileSize = 0;
            obj.MemMap.Repeat = 1;
            obj.MemMap.Repeat = 1;
            obj.CurrentRelativeIndex = 1;
        end

        function count = write(obj, data, varargin)
            assert(obj.CanWrite);
            disp({'size(data)', size(data), '[numChannels,unitsPerDatapoint]', [double(obj.NumChannels), double(obj.UnitsPerDatapoint)]});
            %             if size(data,1)~=obj.NumChannels
            %                 if size(data,3)==obj.NumChannels
            %                     data = permute(data, [3,2,1]);
            %                 else
            %                     assert(size(data,2)==obj.NumChannels);
            %                     if size(data,2)==obj.UnitsPerDatapoint
            %                         data = permute(data, [3 1 2]);
            %                     else
            %                         assert(size(data,2)==obj.UnitsPerDatapoint);
            %                         % data = permute(data, [1 2 3]);
            %                     end
            %                 end
            %             end
            %             assert(size(data,2)==obj.UnitsPerDatapoint);
            if ~hasfile(obj)
                obj.FileHandle = fopen(obj.FilePath, "r+", "n");
            elseif ftell(obj.FileHandle)==-1
                fopen(obj.FileHandle);
            end
            if (nargin==2) || (varargin{1}>obj.NumDatapoints)
                %if ~feof(obj.FileHandle)
                fseek(obj.FileHandle, 0, 1);
                %else
                %    fseek()
            elseif varargin{1}<=1
                frewind(obj.FileHandle);
            else
                disp({'Bytepos', datapointIdxToBytePosition(obj,varargin{1})});
                fseek(obj.FileHandle, datapointIdxToBytePosition(obj,varargin{1}), -1);
            end
            %if isequal(class(data),obj.DatatypeName)
            %    prec = ['*' obj.DatatypeName];
            %else
            %    prec = [class(data) '=>' obj.DatatypeName];
            %end
            %disp(prec);
            try
                % NumChannels x UnitsPerDatapoint x n
                % ==> UnitsPerDatapoint x NumChannels x n ??
                data = reshape(permute(data, [2 1 3]), 1, [], 1);
                count = fwrite(obj.FileHandle, double(data), ...
                    'double'); %, 0, "n");
                disp({'Size',size(data),'count',count});
                fclose(obj.FileHandle);
            catch ME
                fclose(obj.FileHandle);
                rethrow(ME);
            end
        end

        % Define the reset method
        function reset(obj, varargin) % norewind=false, noremap=false
            % Reset to the start of the data
            % reset(myds.FileSet);
            % myds.CurrentFileIndex = 1;
            [hf,io,oldPos] = hasfile(obj);
            if hf && io
                fclose(obj.FileHandle);
                %fseek(obj.FileHandle, 0, 1);
                %obj.FileSize = double(max(0, ftell(obj.FileHandle)));
                %obj.NumDatapoints = fix(double(obj.FileSize) / double(obj.BytesPerDatapoint));
                %frewind(obj.FileHandle); %fseek(myds.FileHandle, 0, -1);
            end
            %else
            %if hf
            % fopen(obj.FileHandle, "r+", "n");
            %else
            obj.FileHandle = fopen(obj.FilePath, "r+", "n"); %, "UTF-8");
            %end
            %                 if bitand(nargin,2)
            %                     if varargin{1}
            %                         rewind = -1;
            %                     else
            %                         rewind = oldPos;
            %                     end
            %
            %                     if (nargin==3)
            %                     end
            %                 else
            %                     rewind = oldPos;
            %                 end
            %
            if obj.CanWrite
                fseek(obj.FileHandle, 0, 1);
                obj.FileSize = double(max(0, ftell(obj.FileHandle)) * obj.BytesPerUnit);
                obj.NumDatapoints = fix(double(obj.FileSize) / double(obj.BytesPerDatapoint));
                % obj.IndexRange(2) = obj.IndexRange(1) + uint64(obj.NumDatapoints);-
            end
            %                 if rewind==0
            %                     frewind(obj.FileHandle);
            %                     obj.CurrentDatapointIndex = 1;
            %                 elseif rewind > 0
            %                     fseek(obj.FileHandle, oldPos, -1);
            %                 end

            if bitand(nargin,2)
                if obj.CanWrite
                    if varargin{1} && oldPos % norewind (==> restore old pos)
                        fseek(obj.FileHandle, oldPos, -1);
                    else % rewind to beginning of file
                        frewind(obj.FileHandle);
                        obj.CurrentRelativeIndex = 1;
                    end
                end
                if ~(nargin==3 && varargin{2}) % noremap = true
                    fclose(obj.FileHandle);
                    return;
                end
            else
                if obj.CanWrite
                    frewind(obj.FileHandle);
                end
                obj.CurrentRelativeIndex = 1;
            end
            fclose(obj.FileHandle);

            % (noremap = false)
            if obj.CanWrite
                obj.MemMap = memmapfile(obj.FilePath, ...
                    'Format', {obj.MemMap.Format{1} [double(obj.ReadDim(1)*obj.ReadDim(2)) max(1,double(obj.NumDatapoints))] obj.MemMap.Format{3}}, ...
                    'Repeat', 1, ...%max(1,obj.NumDatapoints), ...
                    'Offset', obj.MemMap.Offset);
                obj.ChMemMap = memmapfile(obj.FilePath, ...
                    'Format', obj.ChMemMap.Format, 'Repeat', max(1,obj.NumDatapoints), ...
                    'Offset', obj.ChMemMap.Offset);
                %                 if obj.NumDatapoints
                %                     obj.MemMap.Repeat = obj.NumDatapoints;
                %                     obj.ChMemMap.Repeat = obj.NumDatapoints;
                %                 else
                %                     obj.MemMap.Repeat = inf;
                %                     obj.ChMemMap.Repeat = inf;
                %                 end
                %end
            else
                obj.MemMap = memmapfile(obj.MemMap.Filename, ...
                    'Format', obj.MemMap.Format, 'Repeat', obj.MemMap.Repeat, ...
                    'Offset', obj.MemMap.Offset, 'Writable', false);
                obj.ChMemMap = memmapfile(obj.ChMemMap.Filename, ...
                    'Format', obj.ChMemMap.Format, 'Repeat', obj.ChMemMap.Repeat, ...
                    'Offset', obj.ChMemMap.Offset, 'Writable', false);
            end
        end

        function subds = partition(obj, n, varargin)
            if nargin > 2
                ii = varargin{1};
            elseif obj.NumDatapoints
                ii = n;
                % n = obj.NumChannels;
                n = obj.NumDatapoints;
            else
                error('Cannot partition empty datastore (NumDatapoints=0).\n');
            end

            if (n==1) || (ii==1)
                % offFcn = @(~) 0;
                off = 0;
            else
                % offFcn = @(n) (n-1)*obj.BytesPerDatapoint;
                off = (ii-1)*obj.BytesPerDatapoint;
            end

            subds = copy(obj);
            subds.CanWrite = false;

            if isempty(obj.MemMap)
                % reset(obj,true,true);
                if obj.NumDatapoints
                    rep = obj.NumDatapoints + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = 1;
                    subds.NumDatapoints = 0;
                end
            elseif isfinite(obj.MemMap.Repeat)
                rep = obj.MemMap.Repeat + 1 - ii;
                subds.NumDatapoints = rep;
            elseif isempty(obj.MemMap.Data)
                % reset(obj,true,true);
                if obj.NumDatapoints
                    rep = obj.NumDatapoints + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = 1;
                    subds.NumDatapoints = 0;
                end
            elseif isstruct(obj.MemMap.Data)
                if isscalar(obj.MemMap.Data)
                    rep = floor(size(obj.MemMap.Data.AllChannels, 2) / ...
                        obj.NumChannels) + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = numel(obj.MemMap.Data);
                    subds.NumDatapoints = rep;
                end
            else
                rep = floor(size(obj.MemMap.Data, 2) / ...
                    obj.NumChannels) + 1 - ii;
                subds.NumDatapoints = rep;
            end
            subds.MemMap = memmapfile(obj.FilePath, ...
                'Format', obj.MemMap.Format, 'Repeat', max(1,rep), ...
                'Offset', obj.MemMap.Offset + off);

            if isempty(obj.ChMemMap)
                % reset(obj,true,true);
                if obj.NumDatapoints
                    rep = obj.NumDatapoints + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = 1;
                    subds.NumDatapoints = 0;
                end
            elseif isfinite(obj.ChMemMap.Repeat)
                rep = obj.ChMemMap.Repeat + 1 - ii;
                subds.NumDatapoints = rep;
            elseif isempty(obj.ChMemMap.Data)
                % reset(obj,true,true);
                if obj.NumDatapoints
                    rep = obj.NumDatapoints + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = 1;
                    subds.NumDatapoints = 0;
                end
            elseif isstruct(obj.ChMemMap.Data)
                if isscalar(obj.ChMemMap.Data)
                    rep = floor(size(obj.ChMemMap.Data.Ch1, 1) / ...
                        obj.NumChannels) + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = numel(obj.ChMemMap.Data);
                    subds.NumDatapoints = rep;
                end
            else
                rep = floor(size(obj.ChMemMap.Data, 1) / ...
                    obj.NumChannels) + 1 - ii;
                subds.NumDatapoints = rep;
            end
            subds.ChMemMap = memmapfile(obj.FilePath, ...
                'Format', obj.ChMemMap.Format, 'Repeat', max(1,rep), ...
                'Offset', obj.ChMemMap.Offset+off);

            subds.CurrentDatapointIndex = 1;

            %             subds = copy(myds);
            %             subds.IPFileSet = partition(myds.IPFileSet,n,ii);
            %             subds.FPFileSet = partition(myds.FPFileSet,n,ii);
            %             reset(subds);
        end
    end

    methods (Hidden = true)
        % Define the progress method
        function frac = progress(myds)
            % Determine percentage of data read from datastore
            if hasfile(myds)
                if feof(myds.FileHandle)
                    frac = 1;
                else
                    t = ftell(myds.FileHandle);
                    if t==-1 % TODO: ???
                        frac = 0;
                    else
                        %frac = double(t) / double(obj.FileSize);
                        frac = double(myds.CurrentRelativeIndex) / double(myds.NumDatapoints);
                    end
                end
            else
                frac = 0;
            end
            %if hasdata(myds)
            %    frac = (myds.CurrentFileIndex-1)/...
            %        myds.FPFileSet.NumFiles;
            %else
            %    frac = 1;
            %end
        end

        function postset_SplitSize(obj, src, ev)
            if src.Name([1 9])=="BD" % BytesPerDatapoint
                obj.SplitSize = ev.Value;
                obj.ReadDim = [double(numChannels) max(1,double(obj.UnitsPerDatapoint))];
                reset(obj);
            else
                obj.BytesPerChannelDatapoint = double(obj.UnitsPerDatapoint) ...
                    * double(obj.BytesPerUnit);
                obj.BytesPerDatapoint = double(obj.NumChannels)*obj.BytesPerChannelDatapoint;
                if src.Name(1)=='B' % BytesPerUnit
                    if obj.BytesPerUnit <= 1
                        obj.DatatypeName = 'uint8';
                    elseif ev.Value <= 2
                        obj.DatatypeName = 'uint16';
                    elseif ev.Value <= 4
                        obj.DatatypeName = 'uint32';
                    elseif ev.Value <= 8
                        obj.DatatypeName = 'uint64';
                    else
                        obj.DatatypeName = 'double';
                    end
                else % Units per Channel Datapoint
                    obj.ReadDim(2) = double(obj.UnitsPerDatapoint);
                end
            end
        end
    end

    methods(Access = protected)
        % If you use the  FileSet property in the datastore,
        % then you must define the copyElement method. The
        % copyElement method allows methods such as readall
        % and preview to remain stateless
        function dscopy = copyElement(ds)
            dscopy = copyElement@matlab.mixin.Copyable(ds);
            dscopy.FileHandle = fopen(dscopy.FilePath, "r+", "n");
            dscopy.MemMap = ds.MemMap;
            dscopy.ChMemMap = ds.ChMemMap;
            dscopy.CanWrite = true;

            fclose(dscopy.FileHandle);
            % dscopy.FileSet = copy(ds.FileSet);
        end

        % Define the maxpartitions method
        function n = maxpartitions(myds)
            % n = maxpartitions(myds.FileSet);
            n = myds.NumDatapoints;
        end

        function subds = subsetByReadIndices(ds, indices)
            indices = sort(unique(indices));
            if all(diff(indices)==1, 'all')
                indexRange = indices([1 end]); indices = [];
                %if indexRange(1)<=1
                %    offset = 0;
                %else
                % offset = max(0,datapointIdxToBytePosition(ds, indexRange(1)-1));
                %end
                offset = double(indexRange(1) - 1)*ds.BytesPerDatapoint/ds.BytesPerUnit;
                n = double(max(1,diff(indexRange)+1));
            else
                indexRange = [];
                %if min(indices)<=1
                %    offset = 0;
                %else
                %    offset = max(0,datapointIdxToBytePosition(ds, min(indices)-1));
                offset = double(min(indices) - 1)*ds.BytesPerDatapoint/ds.BytesPerUnit;
                %end
                n = double(max(1,range(indices)+1));
            end

            subds = sbsense.ProfileDatastore(ds.FilePath, ds.NumChannels, ...
                ds.UnitsPerDatapoint, 8*ds.BytesPerUnit, ds.OutputDatatypeName, ...
                "CanWrite", false, 'IndexRange', indexRange, 'Indices', indices, ...
                'MemMap', memmapfile(ds.FilePath, 'Format', ...
                {ds.MemMap.Format{1} [double(ds.ReadDim(1)*ds.ReadDim(2)) n] ds.MemMap.Format{3}}, ...
                'Offset', offset, 'Writable', false, 'Repeat', 1), ...
                'ChMemMap', memmapfile(ds.FilePath, 'Format', ds.ChMemMap.Format, ...
                'Offset', offset, 'Writable', false, 'Repeat', n));
        end
    end
    % end

    %% STEP 3: IMPLEMENT YOUR CUSTOM FILE READING FUNCTION
    % function data = readProfiles(fileInfoTbl)
    % % create a reader object using FileName
    % reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);
    %
    % % seek to the offset
    % seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');
    %
    % % read fileInfoTbl.SplitSize amount of data
    % data = read(reader,fileInfoTbl.SplitSize);
    %
    % end

end

% lvls = repmat(shiftdim(1:6,-1), 4, 8, 1);
% dat0 = [11 12 13 14 15 16 17 18 ; 21 22 23 24 25 26 27 28 ; 31 32 33 34 35 36 37 38 ; 41 42 43 44 45 46 47 48];
% dat = repmat(dat0,1,1,6) + lvls*100;
% p = sbsense.ProfileDatastore('C:\Users\stan\SBSense\text.txt', 4, 8, 'ForceOverwrite', true, 'CanWrite', true);
% write(p, dat, 1); reset(p);

% i = imageDatastore('.\*', 'IncludeSubfolders', false)