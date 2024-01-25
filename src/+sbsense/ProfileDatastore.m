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
        Listener;
        % IPFileSet matlab.io.datastore.DsFileSet
        % FPFileSet matlab.io.datastore.DsFileSet
    end

    properties(SetAccess=private, GetAccess=public)
        %IPDirectory char = '';
        %FPDirectory char = '';
        %ChannelNum uint8 = 1;
        NumDatapoints uint64;
        DatatypeName char = '';
        OutputDatatypeName char = '';
        SplitSize double;
    end

    properties(SetAccess=immutable,GetAccess=public)%,SetObservable=true,AbortSet=false)
        % Directory = '';
        FilePath = '';
    end

    properties(Access=private, SetObservable=true, AbortSet=false)
        UnitsPerChannelDatapointVar double;
        BytesPerUnitVar double;
        NumChannelsVar double;
    end
    properties(Access=public,SetObservable=false,Dependent=true)
        UnitsPerChannelDatapoint double;
        BytesPerUnit;
        NumChannels uint8;
    end

    properties(GetAccess=public,SetAccess=private)
        BytesPerChannelDatapoint double;
    end

    properties(GetAccess=public,SetAccess=private,SetObservable,AbortSet=false)
        BytesPerDatapoint double;
    end

    properties(GetAccess=public,SetAccess=private)%,Dependent)
        FileSize double; % IN BYTES
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
                unitsPerChannelDatapoint, bitsPerUnit, outputClass, opts)
            arguments(Input)
                %dir {mustBeFolder};
                fileName {mustBeTextScalar, mustBeNonzeroLengthText};
                numChannels uint8;
                unitsPerChannelDatapoint double;
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
            if unitsPerChannelDatapoint==0
                unitsPerChannelDatapoint = 1;
            end
            if bitsPerUnit==0
                bitsPerUnit = 1;
            end
            obj.CanWrite = opts.CanWrite;

            % obj.Directory = dir;
            obj.NumChannelsVar = numChannels;
            obj.BytesPerUnitVar = ceil(bitsPerUnit/8);
            if bitsPerUnit<=8
                obj.DatatypeName = 'uint8';
            elseif bitsPerUnit <= 16
                obj.DatatypeName = 'uint16';
            elseif bitsPerUnit <= 32
                obj.DatatypeName = 'single'; % 'uint32';

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

            obj.BytesPerUnitVar = ceil(bitsPerUnit/8);
            obj.UnitsPerChannelDatapointVar = unitsPerChannelDatapoint;
            obj.BytesPerChannelDatapoint = obj.BytesPerUnitVar*unitsPerChannelDatapoint;
            obj.BytesPerDatapoint = obj.BytesPerChannelDatapoint*double(numChannels);
            obj.SplitSize = obj.BytesPerDatapoint;
            obj.ReadDim = [double(numChannels) double(unitsPerChannelDatapoint)];
            obj.OutputDatatypeName = outputClass;

            % obj.Listener = addlistener(obj, {'BytesPerUnitVar', 'UnitsPerChannelDatapointVar', 'NumChannels'}, 'PostSet',  ...
            %     @obj.postset_SplitSize);

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
                obj.FileHandle = fopen(obj.FilePath, "r+", "n");
                obj.NumDatapoints = 1 + diff(opts.IndexRange);
                fclose(obj.FileHandle);
            elseif opts.CanWrite
                if isfile(obj.FilePath)
                    if ~opts.ForceOverwrite
                        error("ProfileDatastore:existingFile", 'File "%s" already exists', obj.FilePath);
                    end
                    try
                        obj.FileHandle = fopen(obj.FilePath, "w+", "n");
                        if obj.FileHandle ~= -1
                            fclose(obj.FileHandle);
                        end
                    catch ME
                        fprintf('[ProfileDatastore/constructor] (%s) %s\n', ME.identifier, getReport(ME));
                        display(obj.FileHandle);
                    end
                else
                    fclose(fopen(obj.FilePath, "a+", "n"));
                end
            else
                obj.FileHandle = fopen(obj.FilePath, "r+", "n");
                fclose(obj.FileHandle);
            end

            if isempty(opts.MemMap)
                obj.MemMap = memmapfile(obj.FilePath, 'Writable', false, 'Offset', 0, ...
                    'Format', ... % {obj.DatatypeName, [prod(obj.ReadDim, 'all') 1], 'AllChannels'}, 'Repeat', 1);
                    {obj.DatatypeName, fliplr(double([double(obj.NumChannelsVar) obj.UnitsPerChannelDatapoint])), 'AllChannels'}, ...
                    'Repeat', 1);
            else
                obj.MemMap = opts.MemMap;
            end
            if isempty(opts.ChMemMap)
                chMemMapFormat = repmat({obj.DatatypeName, [1 unitsPerChannelDatapoint]}, obj.NumChannelsVar, 1);
                chMemMapFormat(:, 3) = compose('Ch%u', 1:obj.NumChannelsVar);
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

        function val = get.UnitsPerChannelDatapoint(obj)
            val = obj.UnitsPerChannelDatapointVar;
        end
        function val = get.BytesPerUnit(obj)
            val = obj.BytesPerUnitVar;
        end
        function val = get.NumChannels(obj)
            val = obj.NumChannelsVar;
        end
        function set.UnitsPerChannelDatapoint(obj, val)
            obj.UnitsPerChannelDatapointVar = val;
            postset_SplitSize(obj, ...
                struct('Name', 'UnitsPerChannelDatapoint'), ...
                struct('Value', val));
        end
        function set.BytesPerUnit(obj, val)
            obj.BytesPerUnitVar = val;
            postset_SplitSize(obj, struct('Name', 'BytesPerUnit'), ...
                struct('Value', val));
        end
        function set.NumChannels(obj, val)
            obj.NumChannelsVar = val;
            postset_SplitSize(obj, struct('Name', 'NumChannels'), ...
                struct('Value', val));
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
                    fopen(obj.FileHandle, "r+", "n");
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
                    fprintf('[ProfileDatastore/close] Error "%s" occurred when calling fclose on file "%s": %s\n', ...
                        ME.identifier, obj.FileHandle, getReport(ME));
                end
            end
        end

        function A = readpoints(obj, idxs, isRange, varargin)
            if (isempty(obj.ChMemMap) && isempty(obj.RelativeIndices))
                A = readfpoints(obj,idxs,isRange,varargin);
                return;
            elseif isempty(idxs)
                A = zeros(0,obj.OutputDatatypeName);
                fprintf('[ProfileDatastore/readpoints] idxs is empty!\n');
                return;
            else
                true;
            end
            chNums = 1:obj.NumChannelsVar;
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
                    fprintf('[ProfileDatastore/readpoints] empty!\n');
                    return;
                end
            end

            if isscalar(idxs)
                % isRange = false;
                isConsec = true; %#ok<NASGU> 
            elseif isRange && (length(idxs)==2)
                isConsec = true; %#ok<NASGU> 
                %                 %st = idxs(1);
                %                 %en = min(obj.NumDatapoints, idxs(2));
                idxs = idxs(1):1:idxs(2);
                %                 % clear idxs;
            elseif all(1==diff(idxs))
                isConsec = true; %#ok<NASGU> 
                %                 %st = idxs(1);
                %                 %en = idxs(end);
                %                 % clear idxs;
                %                 % idxs = [st en];
            else
                isConsec = false; %#ok<NASGU> 
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
                % %if isConsec && (n==obj.NumDatapoints) % TODO: don't generate idxs list if all are included
                % %    A = reshape(obj.MemMap.Data.AllChannels, ...
                % %        obj.NumChannelsVar, obj.UnitsPerChannelDatapoint, []);
                % %else %elseif isConsec
                %     A = permute(reshape( ...
                %         obj.MemMap.Data.AllChannels(:,idxs), ...
                %         obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, []), [2 1 3]);
                % %else
                % %    A = reshape(@(i) arrayfun(obj.MemMap.Data.AllChannels(:,i), idxs, 'UniformOutput', true), ...
                % %        obj.NumChannelsVar, obj.UnitsPerChannelDatapoint, []);
                % %end
                subset = [obj.MemMap.Data(idxs)];
                A = cat(3, subset.AllChannels); % n x L x C
                A = permute(A, [1 3 2]);
            elseif isscalar(chNums) % TODO
                if false && n==obj.NumDatapoints
                    A = obj.ChMemMap.Data; %#ok<UNRCH>
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
                fprintf('[ProfileDatastore/readfpoints] idxs is empty!\n');
                return;
            end
            chNums = 1:obj.NumChannelsVar;
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
                    fprintf('[ProfileDatastore/readfpoints] empty!\n');
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
                    A = zeros(obj.NumChannelsVar, obj.UnitsPerChannelDatapointVar, n, obj.OutputDatatypeName);
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
                        if (chNums(end)==obj.NumChannelsVar)
                            skip = 0;
                            readPrec = [int2str(double(obj.UnitsPerChannelDatapointVar)*double(obj.NumChannelsVar)) readPrec];
                        else
                            skip = double(obj.NumChannelsVar-chNums(end))*obj.BytesPerChannelDatapoint;
                            readDim(1) = chNums(end);
                            readPrec = [int2str(double(obj.UnitsPerChannelDatapointVar)*chNums(end)) obj.ReadPrecision];
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
                    A = zeros(obj.NumChannelsVar, obj.UnitsPerChannelDatapointVar, length(idxs), obj.OutputDatatypeName);
                    if allChannels
                        readFcn = @() fread(obj.FileHandle, obj.ReadDim, obj.ReadPrecision, 0, "n");
                        % skip = 0;
                    else
                        readFcn0 = @(A,rs) A(rs,:);
                        % readDim = obj.ReadDim;
                        %                         if (chNums(end)==obj.NumChannelsVar)
                        %                             skip = 0;
                        %                         else
                        %                             skip = double(obj.NumChannelsVar-chNums(end))*obj.BytesPerChannelDatapoint;
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
                try
                    fclose(f);
                catch
                end
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
            if (nargin==2) && varargin{end}
                error("NOT IMPLEMENTED YET");
                % TODO
                % data = permute(reshape(obj.MemMap.Data.AllChannels, ...
                %    obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, []), [2 1 3]);
            elseif obj.CanWrite
                data = readall@matlab.io.Datastore(obj);
                % data = reshape(obj.MemMap.Data.AllChannels, ...
                %    obj.UnitsPerChannelDatapoint, obj.NumChannelsVar, []);
            else
                if isempty(obj.RelativeIndices)
                    % TODO
                    d = obj.MemMap.Data.AllChannels;
                else
                    try
                        % TODO
                        d = obj.MemMap.Data.AllChannels(:,obj.RelativeIndices);
                    catch % ME
                        % TODO
                        if isempty(obj.MemMap.Data.AllChannels)
                            data = []; % TODO
                            fprintf('[ProfileDatastore/readall] AllChannels is empty!\n');
                            return;
                        end
                    end
                end
                if mod(size(d,1)/obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar)
                    data = zeros(obj.UnitsPerChannelDatapointVar * obj.NumChannelsVar, obj.NumDatapoints, obj.OutputDatatypeName);
                    data(1:size(d,1),:) = d;
                    data = permute(reshape(data, obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, []), [2 3 1]);
                else
                    data = permute(reshape(d, obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, []), [2 3 1]);
                end
                data = reshape(data, double(obj.NumChannelsVar)*obj.NumDatapoints, []);
                if isempty(data)
                    fprintf('[ProfileDatastore/readall] data is empty!\n');
                    keyboard;
                end
            end
        end

        % Define the read method
        function [data,info] = read(obj)
            if isempty(obj.MemMap) && isempty(obj.RelativeIndices)
                assert(obj.ReadSize==1);
                [data,info] = readf(obj);
                fprintf('[ProfileDatastore/read] MemMap and RelativeIndices are both empty!\n');
                return;
            end

            if obj.CurrentRelativeIndex > obj.NumDatapoints
                msgII = ['Use the reset method to reset the datastore ',...
                    'to the start of the data.'];
                msgIII = ['Before calling the read method, ',...
                    'check if data is available to read ',...
                    'by using the hasdata method.'];
                error('[ProfileDatastore/read] No more data to read.\n%s\n%s\n',msgII,msgIII);
                %else
                %    fseek(obj.FileHandle, 0, 0);
            end

            d = obj.MemMap.Data;
            if (obj.ReadSize==1)
                nextIdx = obj.CurrentRelativeIndex + 1;
                n = 1;
                if isempty(obj.RelativeIndices)
                    % TODO
                    data = reshape(d.AllChannels(:,obj.CurrentRelativeIndex), ...
                        fliplr(obj.ReadDim))';
                else
                    % TODO
                    data = d.AllChannels(:,obj.RelativeIndices(obj.CurrentRelativeIndex));% obj.IndexOffset + obj.RelativeIndices(obj.CurrentRelativeIndex) - 1);
                    if ~isempty(data)
                        data = reshape(data, fliplr(obj.ReadDim));
                    else
                        fprintf('[ProfileDatastore/read]:ReadSize==1 :: data is empty!\n');
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
                    % TODO
                    data = permute(reshape(d.AllChannels(:,obj.CurrentRelativeIndex + 0:(n-1)), ...
                        obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, numpts), [2 1 3]);
                else
                    data = permute(reshape(... % TODO
                        d.AllChannels(:, ...
                        ... % arrayfun(@(i) find(i==obj.RelativeIndices, 1), idxs - obj.IndexOffset)), ...
                         obj.RelativeIndices(obj.CurrentRelativeIndex + 0:(n-1) - 1)), ...
                        obj.UnitsPerChannelDatapointVar, obj.NumChannelsVar, numpts), [2 1 3]);
                    if isempty(data)
                        fprintf('[ProfileDatastore/read]:ReadSize~=1 :: data is empty!\n');
                    end
                end
            end
            clear d;

            if nargout > 1
                info = struct('Size', n*obj.UnitsPerChannelDatapointVar, ...
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
                error('[ProfileDatastore/readf] Missing or invalid file identifier. Call open on the obj first.\n');
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
                error('[ProfileDatastore/readf] No more data to read.\n%s\n%s\n',msgII,msgIII);
                %else
                %    fseek(obj.FileHandle, 0, 0);
            end

            try
                if obj.ReadPrecision(1)=='*'
                    readPrec = obj.ReadPrecision;
                else
                    readPrec = ['*' obj.ReadPrecision];
                end
                readPrec = [int2str(double(obj.UnitsPerChannelDatapointVar)*double(obj.NumChannelsVar)) readPrec];
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
            %             data = zeros(obj.UnitsChannelPerDatapoint, obj.NumChannelsVar, obj.DatatypeName);
            %
            %
            %             % info = struct('Size',{}, 'FileName',{}, 'Offset', {});
            %             sizes = zeros(1,obj.NumChannelsVar,'double');
            %             fns = strings(1,obj.NumChannelsVar);
            %             offsets = zeros(1,obj.NumChannelsVar, 'double');
            %             % data = cell(1,obj.NumChannelsVar);
            %             for i=1:obj.NumChannelsVar
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
            obj.FileHandle = fopen(obj.FilePath, "w+", "n");
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

        % receives [1=n x L x C] --is this what it expects?
        function count = write(obj, data, varargin)
            assert(obj.CanWrite);

            if ~hasfile(obj)
                obj.FileHandle = fopen(obj.FilePath, "a+", "n");
            elseif ftell(obj.FileHandle)==-1
                obj.FileHandle = fopen(obj.FileHandle, "a+", "n");
            else
                fclose(obj.FileHandle);
                obj.FileHandle = fopen(obj.FilePath, 'a+', 'n');
            end

            if (nargin==2) || (varargin{1}>obj.NumDatapoints)
                fseek(obj.FileHandle, 0, 1);
            elseif varargin{1}<=1
                frewind(obj.FileHandle);
            else
                % disp({'Bytepos', datapointIdxToBytePosition(obj,varargin{1})});
                fseek(obj.FileHandle, datapointIdxToBytePosition(obj,varargin{1}), -1);
            end

            try
                % NumChannels x UnitsPerDatapoint x n
                % ==> UnitsPerDatapoint x NumChannels x n ??
                if isempty(data)
                    keyboard;
                end
                fprintf('[ProfileDatastore/write] Size of data (CxLxn): '); disp(size(data));
                % [1=n x L x C] ==> [L x 1=n x C] ==> [1 x LC]
                data = reshape(permute(data, [2 1 3]), 1, [], 1);
                % Result: { 3. Each datapoint { 2. Each row { 1. Each IP point } } }

                fprintf('[ProfileDatastore/write] New size of data (LxCxn): '); disp(size(data));
                count = fwrite(obj.FileHandle, ...
                    data, obj.DatatypeName);
                if(~count)
                    keyboard;
                else
                    fprintf('[ProfileDatastore/write] count: %g\n', count);
                end
                % fprintf('[ProfileDatastore.write] (after fwrite): \n');
                % disp({'Size',size(data),'count',count});
                fclose(obj.FileHandle);
            catch ME
                try
                    fclose(obj.FileHandle);
                catch
                    fprintf('[ProfileDatastore/write] Couldnt close file handle during catching error from writing to ProfileDatastore.\n');
                end
                fprintf('[ProfileDatastore/write] (Before rethrow) Error occurred when writing to ProfileDatastore: %s\n', getReport(ME));
                rethrow(ME);
            end
        end

        % Define the reset method
        function reset(obj, varargin)
            % norewind=false, noremap=false
            % Reset to the start of the data
            % reset(myds.FileSet);
            % myds.CurrentFileIndex = 1;
            [hf,io,oldPos] = hasfile(obj);
            if (hf && io)
                fclose(obj.FileHandle);
                %fseek(obj.FileHandle, 0, 1);
                %obj.FileSize = double(max(0, ftell(obj.FileHandle)));
                %obj.NumDatapoints = fix(double(obj.FileSize) / double(obj.BytesPerDatapoint));
                %frewind(obj.FileHandle); %fseek(myds.FileHandle, 0, -1);
            end
            
            obj.FileHandle = fopen(obj.FilePath, "a+", "n");
            
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
                obj.FileSize = double(max(0, ftell(obj.FileHandle))); % obj.BytesPerUnit);
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
                % 2 or 3 args (so one or more varargin)
                if obj.CanWrite
                    if varargin{1} && oldPos % norewind (==> restore old pos)
                        fseek(obj.FileHandle, oldPos, -1);
                    else 
                        % rewind to beginning of file
                        frewind(obj.FileHandle);
                        obj.CurrentRelativeIndex = 1;
                    end
                end
                if (nargin==3 && varargin{2}) 
                    %~(nargin==3 && varargin{2}) % noremap = true
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
                    'Format', ... % {obj.MemMap.Format{1} [double(obj.ReadDim(1)*obj.ReadDim(2)) max(1,double(obj.NumDatapoints))] obj.MemMap.Format{3}}, ...
                    {obj.DatatypeName fliplr(double([double(obj.NumChannelsVar) obj.UnitsPerChannelDatapoint])) obj.MemMap.Format{3}}, ...
                    'Repeat', max(1,obj.NumDatapoints), ...%max(1,obj.NumDatapoints), ...
                    'Offset', obj.MemMap.Offset);
                chMemMapFormat = repmat({obj.DatatypeName, [1 obj.UnitsPerChannelDatapoint]}, obj.NumChannelsVar, 1);
                chMemMapFormat(:, 3) = compose('Ch%u', 1:obj.NumChannelsVar);
                obj.ChMemMap = memmapfile(obj.FilePath, ...
                    'Format', chMemMapFormat, 'Repeat', max(1,obj.NumDatapoints), ...
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
                    'Format', ... % {obj.MemMap.Format{1} [double(obj.ReadDim(1)*obj.ReadDim(2)) max(1,double(obj.NumDatapoints))] obj.MemMap.Format{3}}, ...
                    {obj.DatatypeName fliplr(double([double(obj.NumChannelsVar) obj.UnitsPerChannelDatapoint])) obj.MemMap.Format{3}}, ...
                    'Repeat', max(1,obj.NumDatapoints), ... %obj.MemMap.Repeat, ...
                    'Offset', obj.MemMap.Offset, 'Writable', false);
                chMemMapFormat = repmat({obj.DatatypeName, [1 obj.UnitsPerChannelDatapoint]}, obj.NumChannelsVar, 1);
                chMemMapFormat(:, 3) = compose('Ch%u', 1:obj.NumChannelsVar);
                obj.ChMemMap = memmapfile(obj.ChMemMap.Filename, ...
                    'Format', chMemMapFormat, 'Repeat', max(1, double(obj.NumDatapoints)), ... %obj.ChMemMap.Repeat, ...
                    'Offset', obj.ChMemMap.Offset, 'Writable', false);
            end
        end

        function subds = partition(obj, n, varargin)
            if nargin > 2
                ii = varargin{1};
            elseif obj.NumDatapoints
                ii = n;
                % n = obj.NumChannelsVar;
                n = obj.NumDatapoints;
            else
                error('[ProfileDatastore/partition] Cannot partition empty datastore (NumDatapoints=0).\n');
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
                    rep = floor(size(obj.MemMap.Data.AllChannels, 2) / ... % TODO
                        obj.NumChannelsVar) + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = numel(obj.MemMap.Data);
                    subds.NumDatapoints = rep;
                end
            else
                rep = floor(size(obj.MemMap.Data, 2) / ...
                    obj.NumChannelsVar) + 1 - ii;
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
                        obj.NumChannelsVar) + 1 - ii;
                    subds.NumDatapoints = rep;
                else
                    rep = numel(obj.ChMemMap.Data);
                    subds.NumDatapoints = rep;
                end
            else
                rep = floor(size(obj.ChMemMap.Data, 1) / ...
                    obj.NumChannelsVar) + 1 - ii;
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

        function FH = ffopen(obj, varargin)
            FH = fopen(varargin{:});
            if(nargin>2)
                obj.fmode = varargin{2};
            end
        end

        function FH = ffclose(obj, varargin)
            FH = fclose(varargin{:});

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
            fprintf('[ProfileDatastore/postset_SplitSize]\n');
            % disp(src); disp(ev);
            if (src.Name(1)~='N') && (src.Name([1 9 16])=="BCD") % BytesPerChannelDatapoint
                obj.BytesPerChannelDatapointVar = ev.Value * obj.BytesPerUnit;
                obj.BytesPerDatapoint = obj.BytesPerChannelDatapoint * double(obj.NumChannelsVar);
                obj.SplitSize = obj.BytesPerDatapoint;
                obj.ReadDim = [double(obj.NumChannelsVar) max(1,double(obj.BytesPerChannelDatapointVar))];
                reset(obj);
            else % BytesPerUnit or NumChannels or...?
                obj.BytesPerChannelDatapoint = double(obj.UnitsPerChannelDatapointVar) ...
                    * double(obj.BytesPerUnitVar);
                obj.BytesPerDatapoint = double(obj.NumChannelsVar)*obj.BytesPerChannelDatapoint;
                if src.Name=="BytesPerUnit" % BytesPerUnit
                    if obj.BytesPerUnitVar <= 1
                        obj.DatatypeName = 'uint8';
                    elseif ev.Value <= 2
                        obj.DatatypeName = 'uint16';
                    elseif ev.Value <= 4
                        obj.DatatypeName = 'single'; %'uint32';
                    elseif ev.Value <= 8
                        obj.DatatypeName = 'uint64';
                    else
                        obj.DatatypeName = 'double';
                    end
                % else % Units per Channel Datapoint
                %     obj.ReadDim(2) = max(1,double(obj.BytesPerChannelDatapoint));
                end
                obj.SplitSize = obj.BytesPerDatapoint;
                obj.ReadDim = [double(obj.NumChannelsVar) max(1,double(obj.BytesPerChannelDatapoint))];
                reset(obj);
            end
            % obj.BytesPerUnit = ceil(bitsPerUnit/8);
            %              % obj.UnitsPerChannelDatapoint = unitsPerChannelDatapoint;
            %              obj.BytesPerChannelDatapoint = obj.BytesPerUnit*obj.UnitsPerChannelDatapoint;
%              obj.BytesPerDatapoint = obj.BytesPerChannelDatapoint*double(obj.NumChannelsVar);
%              obj.SplitSize = obj.BytesPerDatapoint;
%              obj.ReadDim = [double(obj.NumChannelsVar) double(obj.UnitsPerChannelDatapoint)];
             % obj.OutputDatatypeName = outputClass;
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
                offset = double(indexRange(1) - 1)*ds.BytesPerDatapoint/ds.BytesPerUnitVar;
                n = double(max(1,diff(indexRange)+1));
            else
                indexRange = [];
                %if min(indices)<=1
                %    offset = 0;
                %else
                %    offset = max(0,datapointIdxToBytePosition(ds, min(indices)-1));
                offset = double(min(indices) - 1)*ds.BytesPerDatapoint/ds.BytesPerUnitVar;
                %end
                n = double(max(1,range(indices)+1));
            end

            subds = sbsense.ProfileDatastore(ds.FilePath, ds.NumChannelsVar, ...
                ds.UnitsPerChannelDatapointVar, 8*ds.BytesPerUnitVar, ds.OutputDatatypeName, ...
                "CanWrite", false, 'IndexRange', indexRange, 'Indices', indices, ...
                'MemMap', memmapfile(ds.FilePath, 'Format', ...
                {ds.MemMap.Format{1} double([double(obj.NumChannelsVar) double(obj.BytesPerChannelDatapoint)]), ds.MemMap.Format{3}}, ...
                ... % {ds.MemMap.Format{1} [double(ds.ReadDim(1)*ds.ReadDim(2)) n] ds.MemMap.Format{3}}, ...
                'Offset', offset, 'Writable', false, 'Repeat', n), ...
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


% size([dat.Ch1])
% ans =
%      1       15360
% size({dat.Ch1})
% ans =
%      1    12