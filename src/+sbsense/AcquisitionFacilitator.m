classdef AcquisitionFacilitator < matlab.mixin.SetGetExactNames %handle
    properties(SetAccess=public,SetObservable)
        frameDimensions;
        analysisScale;
    end
    properties(SetAccess=protected)
        % analysisRescale = 2.0;
    end

    properties(SetAccess=public)%,SetObservable,GetAccess=public)
        fps0;
        tpf0;
        fpp0;
        fps;
        tpf;
        tpfRatio;
        fph;
        fpp;
        tpp;
        tph;
        numPoints;
        numFitPoints;
        numIntensityProfilePoints;

        logFileName;

        % futs;

        plotData;
        composites;
        intensityProfiles;
        timePositions;

        startTime = NaN;
        stopTime = NaN;

        readTimer;

        timeZero = NaT;

        BGimg = [];
        BGimg0 = [];
        BGimgScaled = [];

        dpIdx0 = 0;
    end

    properties(Access=private,SetObservable,AbortSet=true)

    end

    properties(Transient)
        finishedQueue;
        HCqqueue; HCqueue = [];
        HCFrameQqueue; HCFrameQueue = [];
        APqqueue; APqueue = [];
        prevHCimg = []; prevHCtimeInterval = [];
        resQueue = [];

        bgPool1; bgPool2;

        APqueueFcnInternalFcn = [];

        lfit;

        vobj;
        vsrc;
        vdev;
    end

    properties(Access=public)
        NumChannels;
        ScaledChannelDivPositions (1,:) uint16;
        ScaledChannelVertIdxs (1,:) cell;
        ChannelHeights (1,:) uint16;
        CropRectangle images.spatialref.Rectangle;
       
        PeakSearchBoundsDefault (1,2) uint16;
        CurrentPeakSearchBounds (1,2) uint16;

        SourceFilePath (1,1); % {mustBeFile};
        vreader;
        readFromFile (1,1) logical = false;
    end

    properties(Dependent,SetAccess=public,SetObservable)
        FrameYBounds(1,2) uint16;
        FrameYBoundL (1,1) uint16;
        FrameYBoundR (1,1) uint16;
    end

    properties(Access=private, Transient)
        propListener event.proplistener;
    end

    properties(SetAccess=private,GetAccess=public)
        OrigDim (1,2);
        ScaledDim (1,2);
        ChannelHorizIdxs;
        ChannelVertIdxs;
    end

    methods
        function self = AcquisitionFacilitator( ...
                numChannels, opts)
            arguments(Input)
                numChannels (1,1) uint8;
                opts.NumDatapoints (1,1) {mustBePositive} = Inf;
                opts.TimePerFrame (1,1) {mustBePositive,mustBeInRange(opts.TimePerFrame,0.0333333333333,3600)} = 1/6;
                opts.FramesPerDatapoint (1,1) {mustBePositive,mustBeInteger} = 8;
                opts.NumFitPoints (1,1) {mustBePositive,mustBeInteger} = 200;
                opts.AnalysisScale (1,1) {mustBePositive} = 0.5;
                opts.SmoothingLevel (1,1) {mustBeInteger,mustBeInRange(opts.SmoothingLevel, -1,7)} = -1;
                opts.LogFileName {mustBeNonzeroLengthText} = "threadtest_log.txt";
                opts.APqueue = []; 
                opts.HCqueue = [];
                opts.APqueueFcnInternal = [];
                opts.ResultQueue = [];
            end
            if(~isa(self.bgPool1, 'parallel.BackgroundPool'))
                self.bgPool1 = backgroundPool();
            end
            if(~isa(self.bgPool2, 'parallel.BackgroundPool'))
                self.bgPool2 = backgroundPool();
            end
            if(isa(self.propListener,'event.listener'))
                delete(self.propListener);
            end

            self.tpf = opts.TimePerFrame;
            self.fpp = opts.FramesPerDatapoint;
            self.numPoints = opts.NumDatapoints;
            self.fph = 0.5*opts.FramesPerDatapoint;
            self.logFileName = opts.LogFileName;

            fprintf('Getting video objects.\n');
            adaptorNames = imaqhwinfo().InstalledAdaptors;
            devIdx = 0;
            for i=1:length(adaptorNames)
                adaptorName = adaptorNames{i};
                devInfos = imaqhwinfo(adaptorName).DeviceInfo;
                devNames = {devInfos(:).DeviceName};
                idx = find(strcmp(devNames,'USB Camera'), 1);
                if(~isempty(idx))
                    devIdx = idx;
                    break;
                end
            end
            if(devIdx == 0)
                fprintf('Could not find device matching name "USB Camera". Using default camera instead.\n');
                devIdx = 1;
            else
                fprintf('Found webcam with name "USB Camera".\n');
            end
            self.vobj = videoinput(adaptorName, devIdx);
            self.vdev = imaq.VideoDevice(adaptorName, devIdx);
            self.vsrc = getselectedsource(self.vobj);

            self.fps0 = 30.0;

            self.fps = inv(self.tpf);
            self.tpf0 = inv(self.fps0);
            self.tpfRatio = self.fps0 * self.tpf;

            if(fix(self.tpfRatio) ~= self.tpfRatio)
                self.tpfRatio = max(1, floor(self.tpfRatio));
            end

            self.fpp0 = self.tpfRatio * self.fpp;
            self.tph = (self.tpf0 * self.tpfRatio)*self.fph;
            self.tpp =  2 * self.tph;

            if(isempty(opts.APqueueFcnInternal))
                self.APqueueFcnInternalFcn = @AcquisitionFacilitator.APqueueFcnInternal;
            else
                self.APqueueFcnInternalFcn  =  opts.APqueueFcnInternal;
            end

            self.resQueue = opts.ResultQueue;
            self.finishedQueue = parallel.pool.PollableDataQueue();

            if(isempty(opts.HCqueue))
                self.HCqueue = makeHCqueue(self);
            else
                self.HCqueue = opts.HCqueue;
            end
            if(isempty(opts.APqueue))
                self.APqueue = makeAPqueue(self);
            else
                self.APqueue = opts.APqueue;
            end

            self.NumChannels = numChannels;
            
            % Very important to replace
            configureVideoInput(self);

            self.PeakSearchBoundsDefault = [1 self.frameDimensions(2)];
            self.CurrentPeakSearchBounds = ...
                self.PeakSearchBoundsDefault;
            
            self.analysisScale = opts.AnalysisScale;
            % self.analysisRescale = 1/self.analysisScale;
            
            %self.ScaledDim = [ self.frameDimensions(1), ...
            %    ceil((self.frameDimensions(2)-1)*self.analysisScale)+1 ];
            self.CropRectangle = images.spatialref.Rectangle(...
                self.PeakSearchBoundsDefault, ...
                [1 self.frameDimensions(1)]);
            self.OrigDim(1,1:2) = self.frameDimensions;
            fprintf('frameDimensions: %s', formattedDisplayText(self.frameDimensions));
            fprintf('origDim: %s', formattedDisplayText(self.OrigDim));
            self.ScaledDim(1,1:2) = self.frameDimensions;
            self.ScaledDim(1,1) = ceil((self.OrigDim(1,1)-1)*self.analysisScale)+1;
            fprintf('Set scaled dim (length: %d): %s', ...
                numel(self.ScaledDim), formattedDisplayText(self.ScaledDim));

            % self.timeZero = datetime();

            initialSize = min(opts.NumDatapoints, 64);
            self.plotData = zeros(initialSize, 6);

            self.analysisScale = opts.AnalysisScale;
            % self.analysisRescale = opts.AnalysisScale\1;

            self.numIntensityProfilePoints = self.OrigDim(2);
            initialSize = min(opts.NumDatapoints, 512);
            self.plotData = zeros(initialSize, 6);
            self.composites = zeros(self.OrigDim(1), initialSize);
            self.intensityProfiles = zeros(initialSize, self.numIntensityProfilePoints);

            self.numFitPoints = opts.NumFitPoints;
          
            % self.lfit = LorentzFitter('NumSamplePoints', self.numIntensityProfilePoints, ...
            %     'NumFitPoints', opts.NumFitPoints, ...
            %     'SmoothingLevel', opts.SmoothingLevel, ...
            %     'DoSecondPass', 1);

            self.propListener = addlistener(self, {'analysisScale', 'FrameYBounds', 'FrameYBoundL', 'FrameYBoundR'}, 'PostSet', @self.postset_framesize);
        end

        function stop(self)
            if(isa(self.vobj, 'videoinput') && (self.vobj.Running=="on"))
                stop(self.vobj);
            end
            try
                if isa(self.vdev, 'imaq.VideoDevice') && isvalid(self.vdev)
                    release(self.vdev);
                end
            catch ME
                fprintf('Error occurred while releasing video device:\n%s', ...
                    getReport(ME));
            end
        end

        function initialize(self, numchannels, analysisScale, divPositions)
            self.NumChannels = numchannels;
            self.analysisScale = analysisScale;

            self.dpIdx0 = 0;

            self.ChannelHorizIdxs = (self.CropRectangle.XLimits(1)+1) ...
                : (self.CropRectangle.XLimits(2)-1);

            fprintf('divPositions: %s', formattedDisplayText(divPositions));
            fprintf('divPositions diff: %s', formattedDisplayText(diff(divPositions)));

            fprintf('%s\n%s\n%s\n%s', formattedDisplayText(divPositions-self.CropRectangle.YLimits(1)-1), ...
                formattedDisplayText(analysisScale*(divPositions-self.CropRectangle.YLimits(1)-1)), ...
                formattedDisplayText(ceil(analysisScale*(divPositions-self.CropRectangle.YLimits(1)-1))), ...
                formattedDisplayText(ceil(analysisScale*(divPositions-self.CropRectangle.YLimits(1)-1))+1));
            self.ScaledChannelDivPositions = ...
                uint16(ceil(analysisScale*(divPositions-self.CropRectangle.YLimits(1)))+1);
            self.ScaledChannelDivPositions(1) = 0;
            fprintf('Scaled div positions: %s', formattedDisplayText(self.ScaledChannelDivPositions));

            
            self.ScaledChannelVertIdxs = cell(1,numchannels);
            %self.ScaledChannelVertIdxs{1} = ...
            %        self.ScaledChannelDivPositions(1) ...
            %        : self.ScaledChannelDivPositions(2)-1;
            for i=1:numchannels%i=2:numchannels-1
                fprintf('Channel %d: From %0.4g to %0.4g = %0.4g\n', ...
                    i, self.ScaledChannelDivPositions(i)+1, ...
                    self.ScaledChannelDivPositions(i+1)-1, ...
                    (self.ScaledChannelDivPositions(i+1)-1) ...
                    - (self.ScaledChannelDivPositions(i)+1) ...
                    );
                self.ScaledChannelVertIdxs{i} = ...
                    self.ScaledChannelDivPositions(i)+1 ...
                    : self.ScaledChannelDivPositions(i+1)-1;
            end
            %self.ScaledChannelVertIdxs{numchannels} = ...
            %        self.ScaledChannelDivPositions(numchannels)+1 ...
            %        : self.ScaledChannelDivPositions(numchannels+1);

            self.BGimgScaled = imresize(imcrop(self.BGimg, ...
                self.CropRectangle), self.ScaledDim, "lanczos3");
            
            initialSize = min(self.numPoints, 512);

            self.composites = zeros([self.OrigDim initialSize]);

            % self.intensityProfiles = zeros(initialSize, self.numIntensityProfilePoints);
            self.timePositions = NaT(1,initialSize);
        end

        %function value = get.numChannels(self)
        %    %if(isempty(self.channels))
        %        value = size(self.channelInfo, 1);
        %    %else
        %    %    value = length(self.channels);
        %    %end
        %
        %end

        function set.FrameYBounds(self, value)
            self.CropRectangle = images.spatialref.Rectangle(...
                self.PeakSearchBoundsDefault, value);
            ht = value(2) - value(1) + 1;
            self.OrigDim(1,1) = ht;
            self.ScaledDim(1,1) = ceil((ht-1)*self.analysisScale)+1;
        end

        function set.FrameYBoundL(self, value)
            rb = self.CropRectangle.YLimits(2);
            self.CropRectangle = images.spatialref.Rectangle(...
                self.PeakSearchBoundsDefault, [ ...
                value rb]);
            ht = rb - value + 1;
            self.OrigDim(1,1) = ht;
            self.ScaledDim(1,1) = ceil((ht-1)*self.analysisScale)+1;
        end

        function set.FrameYBoundR(self, value)
            lb = self.CropRectangle.YLimits(1);
            self.CropRectangle = images.spatialref.Rectangle(...
                self.PeakSearchBoundsDefault, [ ...
                lb value ]);
            ht = value - lb + 1;
            self.OrigDim(1) = ht;
            self.ScaledDim(1,1) = ceil((ht-1)*self.analysisScale)+1;
        end
        
        function value = get.FrameYBounds(self)
            value = self.CropRectangle.YLimits; % TODO
        end

        function value = get.FrameYBoundL(self)
            value = self.CropRectangle.YLimits(1);
        end

        function value = get.FrameYBoundR(self)
            value = self.CropRectangle.YLimits(2);
        end

        function delete(self)
            try
                delete(self.propListener);
                %delete(self.bgPool1);
                %delete(self.bgPool2);
                %if isa(self.vobj, 'videoinput') %&& isvalid(self.vobj)
                %    delete(self.vobj);
                %end
                %if isa(self.vsrc, 'videosource') %&& isvalid(self.vsrc)
                %    delete(self.vsrc);
                %end
            catch ERR
                fprintf(2, ERR.message);
                celldisp(struct2cell(ERR.stack));
                celldisp(ERR.cause);
            end
        end

        function [objConfig, BGimg, BGimgScaled, vsrcConfig, vobjConfig, plotData, timePositions, composites] ...
                = saveState(self, filename)
            arguments(Input)
                self AcquisitionFacilitator;
                filename = [];
            end

            BGimg = self.BGimg;
            BGimgScaled = self.BGimgScaled;
            plotData = self.plotData;
            timePositions = self.timePositions;
            composites = self.composites;

            objConfig = struct('fps0', self.fps0, 'fps', self.fps, ...
                'fpp0', self.fpp, 'tpf', self.tpf, 'tpfRatio', self.tpfRatio, 'fph', self.fph, ...
                'fpp', self.fpp, 'tpp', self.tpp, 'tph', self.tph, 'numPoints', self.numPoints, ...
                'numFitPoints', self.numFitPoints, 'numIntensityProfilePoints', self.numIntensityProfilePoints, ...
                'frameDimensions', self.frameDimensions, 'timeZero', self.timeZero, ...
                'startTime', self.startTime, 'stopTime', self.stopTime, 'analysisScale', self.analysisScale, ...
                'logFileName', self.logFileName);
            %vsrcNames = {'BacklightCompensation', 'Brightness', 'Contrast', 'Exposure', ...
            %    'ExposureMode', 'Focus' , 'FocusMode', 'Gain', 'Hue', 'HueMode', ...
            %    'Iris', 'IrisMode', 'Saturation', 'Sharpness', ...
            %    'WhiteBalance', 'Gamma', 'WhiteBalanceMode'};
            %vsrcVals  = get(self.vsrc, vsrcNames);
            % disp(vsrcNames);
            %disp(vsrcVals);
            %vsrcConfig = cell2struct(vsrcVals, vsrcNames, 2);
            vsrcConfig = [];

            propNames = fieldnames(propinfo(self.vobj))';
            propNames(propNames=="UserData") = [];
            propInfos = propinfo(self.vobj, propNames);
            propMask = cell2mat(cellfun(@(x) ~contains(x.ReadOnly,'always'), propInfos, 'UniformOutput', false));
            %propMask  = cell2mat(propInfos(~contains(propInfos, 'always')));
            %disp(size(propMask));
            %disp(size(propInfos));
            propNames = propNames(propMask);
            propVals  = get(self.vobj, propNames);
            vobjConfig = cell2struct(propVals, propNames, 2);
            if(~isempty(filename))
                save(filename,"objConfig", "vsrcConfig", "vobjConfig", ...
                    "BGimg", "BGimgScaled", "plotData", "timePositions", "composites", "-mat", "-v7.3");
            end
        end

        function loadStateFromFile(self,filename)
            arguments(Input)
                self AcquisitionFacilitator;
                filename {mustBeFile};
            end
            varNames = {'objConfig', 'vsrcConfig', 'vobjConfig', ...
                'BGimg', 'BGimgScaled', 'plotData', 'timePositions', 'composites'};
            propStruct = load(filename,varNames{:},'-mat');
            propNames = fieldnames(propStruct);
            propVals = struct2cell(propStruct);
            propCell = vertcat(propNames', propVals');
            propCell = reshape(propCell, 1, []);
            %disp(propCell);
            try
                loadState(self, propCell{:});
            catch
            end
        end

        function loadState(self, opts)
            arguments(Input)
                self AcquisitionFacilitator;
                opts.img = [];
                opts.BGimg = [];
                opts.BGimgScaled = [];
                opts.objConfig = [];
                opts.vsrcConfig = [];
                opts.vobjConfig = [];
                opts.plotData = [];
                opts.timePositions = [];
                opts.composites = [];
            end
            if(~isempty(opts.img))
                self.BGimg = opts.img;
            end

            if(~isempty(opts.plotData))
                self.plotData = opts.plotData;
            end
            if(~isempty(opts.composites))
                self.composites = opts.composites;
            end
            if(~isempty(opts.timePositions))
                self.timePositions = opts.timePositions;
            end

            if(~isempty(opts.objConfig))
                propVals = struct2cell(opts.objConfig);
                propNames = fieldnames(opts.objConfig);
                %disp(size(propCell));
                %propNames = propCell{:,1};
                %propVals  = propCell{:,2};
                [~] = set(self, propNames', propVals'); % TODO: Unnecessary?
            end
            if(~isempty(opts.BGimg))
                % TODO: crop rectangle
                self.BGimg = opts.BGimg;
                if(isempty(opts.BGimgScaled))
                    % TODO: Crop
                    self.BGimgScaled = imresize(opts.BGimg, ...
                        self.ScaledDim, "lanczos3");
                end
                %elseif(~isempty(opts.BGimgScaled))
                %    self.BGimgScaled = opts.BGimgScaled;
                %    self.BGimg = imresize(opts.BGimgScaled, ...
                %        self.analysisRescale, "lanczos3");
            end

            if(~isempty(opts.vsrcConfig))
                propVals = struct2cell(opts.vsrcConfig);
                propNames = fieldnames(opts.vsrcConfig);
                %propNames = propCell{:,1};
                %propVals  = propCell{:,2};
                [~] = set(self.vsrc, propNames', propVals'); % TODO: Unnecessary?
            end
            if(~isempty(opts.vobjConfig))
                propVals = struct2cell(opts.vobjConfig);
                propNames = fieldnames(opts.vobjConfig);
                %propNames = propCell{:,1};
                %propVals  = propCell{:,2};
                %disp(size(propNames'));
                %disp(size(propVals'));
                %disp(propNames);
                %disp(propVals);
                for i=1:min(length(propNames),length(propVals))
                    if(any(isa(propVals{i}, 'function_handle')) || any(ishandle(propVals{i})))
                        continue;
                    elseif(isequal(get(self.vobj, propNames{i}), propVals{i}))
                        continue;
                    elseif(any(string(propNames{i}) ...
                            == {'DiskLogger','SelectedSourceName','LoggingMode', ...
                            'Name', 'PreviewFullBitDepth', 'ReturnedColorSpace', ...
                            'LoggingMode','StopFcn','StartFcn','TriggerFcn', ...
                            'TimerFcn', 'FramesAcquiredFcn','UserData'}))
                        continue;
                    elseif(propinfo(self.vobj,propNames{i}).ReadOnly ~= "always")
                        %fprintf('%s %s', propNames{i}, formattedDisplayText(propVals{i}));
                        [~] = set(self.vobj, propNames{i}, propVals{i});
                    end
                end
                self.vobj.UserData = struct(....
                    'maxTriggers', self.numPoints+1, ...
                    'prevHCimg', [], ...
                    'prevHCtimeRange', [], ...
                    'currHCimg', [], ...
                    'currHCtimeRange', [], ...
                    'HCqueue', self.HCqueue, ...
                    'resQueue', self.resQueue ...
                    );
                % [~] = set(self.vobj, propNames', propVals'); % TODO: Unnecessary?
            end
        end

        function BGimg = takeBG(self)
            configureVideoSource(self, false); % Ensure non-adjusted values are correct
            try
            self.vsrc.Brightness = -64;
            self.vsrc.Saturation = 60;
            self.vsrc.Gamma = 72;
            %self.vsrc.Exposure = -8;
            self.vsrc.Contrast = 30;
            self.vsrc.Hue = 0;
            self.vsrc.WhiteBalance = 6500;
            self.vsrc.Gain = 0;
            catch
            end

            self.BGimg0 = getsnapshot(self.vobj);
            self.BGimg  = self.BGimg0(:,:,1);
            self.BGimg  = im2double(self.BGimg);
            montage({self.BGimg0, self.BGimg});
            BGimg = self.BGimg;
            fprintf('Crop Rectangle X Lims: [%0.4g %0.4g]\n', ...
                self.CropRectangle.XLimits(1), self.CropRectangle.XLimits(2));
            fprintf('Crop Rectangle Y Lims: [%0.4g %0.4g]\n', ...
                self.CropRectangle.YLimits(1), self.CropRectangle.YLimits(2));
            fprintf('Scaled dim: [ %0.4g %0.4g ]\n', self.ScaledDim(1), self.ScaledDim(2));
            self.BGimgScaled = imresize(imcrop(BGimg, self.CropRectangle), ...
                self.ScaledDim, "lanczos3");
        end

        function start(self)
            if(self.readFromFile || (self.vobj.Running == "off"))
                f = fopen(self.logFileName, "w");
                fclose(f);

                self.prevHCimg = [];
                self.prevHCtimeInterval = [];

                if ismissing(self.timeZero)
                    self.timeZero = datetime('now');
                else
                    [tf, ~] = AcquisitionFacilitator.waitForQueueToEmpty( ...
                        self.bgPool2, self.finishedQueue, 10, true);
                    if(~tf)
                        fprintf('Warning: Finished queue is not empty (%d)... The program may not behave as expected.\n', ...
                            self.finishedQueue.QueueLength);
                        delete(self.finishedQueue);
                        self.finishedQueue = parallel.pool.PollableDataQueue();
                    end
                end
                if self.readFromFile
                    self.timeZero = datetime('now');
                    self.startTime = self.timeZero;
                    send(self.resQueue, self.timeZero);
                    startread(self);
                else
                    start(self.vobj);
                end
            else
                fprintf('Could not start frame acquisition because the video input object is already running.\n');
            end
        end

        function startread(self)
            try
                self.vreader = VideoReader(self.SourceFilePath);
            catch ME
                fprintf('Cannot read from file "%s" due to error: %s\n', ...
                    value, getReport(ME));
                return;
            end
            tms = timerfindall("Tag", "SBsense_vread");
            for tm = tms
                if isa(tm, 'timer') && (tm.Running(2)=='n')
                    stop(tm);
                end
                delete(tm);
            end
            self.readTimer = timer("BusyMode", "queue", ...
                "ExecutionMode", "fixedRate", ...
                "Name", "SB File Read Timer", "ObjectVisibility", "off", ...
                "StartDelay", 0, "Period", 1, "TasksToExecute", ...% self.tpf, "TasksToExecute", ...
                Inf, "Tag", "SBsense_vread", ...
                ...%self.vreader.NumFrames, "Tag", "SBsense_vread", ...
                "TimerFcn", {@AcquisitionFacilitator.readNextFrame, self.APqueue}, ...
                "StopFcn", { @AcquisitionFacilitator.stopReadingFrames, self.APqueue }, ...
                "UserData", struct('PrevHC', [], 'vreader', self.vreader));
            start(self.readTimer);
        end

        % data = {triggerIndex, timeRange, frames}
        function HCqueueFcn(self, HCdata)
%             if isequal(HCdata, true)
%                 send(self.APqueue, true);
%                 return;
%             end
            % TODO: Use persistent vars instead of UserData?
            triggerIndex = HCdata{1};
            timeRange = HCdata{2};
            frames = HCdata{3};
            ud = self.vobj.UserData;
            HC = im2double(AcquisitionFacilitator.makeHalfComposite(0.5*self.fph,frames));
            prevHC = ud.prevHCimg;
            if((triggerIndex > 1) && ~isempty(ud.prevHCtimeRange))
                datapointTimePos = ...
                    ud.prevHCtimeRange(1) + ...
                    0.5*(timeRange(2) - ud.prevHCtimeRange(1));
                datapointIndex = triggerIndex - 1;
                send(self.finishedQueue, datapointIndex);
                send(self.APqueue, ...
                    {false, datapointIndex, datapointTimePos, prevHC, HC});
                % APdata: {isReanalysis, index, timePos, HC1, HC2}
            end
            ud.prevHCtimeRange = timeRange;
            ud.prevHCimg = HC;
            self.vobj.UserData = ud;
        end

        function reanalyze(self, opts)
            arguments(Input)
                self AcquisitionFacilitator;
                opts.ClearLog logical = false;
            end
            if(opts.ClearLog)
                try
                    f = fopen(self.logFileName, "w");
                    fclose(f);
                catch ME
                    fprintf('Error occurred while trying to clear logfile (%s): %s', ...
                        ME.identifier, ME.message);
                end
            end
            N = min(size(self.plotData,1), size(self.composites,3));
            N = min(N, length(self.timePositions));

            for datapointIndex=1:N
                send(self.finishedQueue, datapointIndex);
                if(iscell(self.timePositions))
                    timePos = self.timePositions{datapointIndex};
                else
                    timePos = self.timePositions(datapointIndex);
                end
                send(self.APqueue, ...
                    {true, datapointIndex, timePos, ...
                    self.composites(:,:,datapointIndex), []});
            end
            %AcquisitionFacilitator.makePlots1(self.vobj,self,true);
        end

        function toResQueueFcn(self, res)
            fprintf('[toResQueueFcn] Sending res (length: %d) to queue.\n', length(res));
            %fprintf('res (%d): %s', length(res), ...
            %    formattedDisplayText(res));
            %if (length(varargin)==1) && iscell(varargin{1})
            %    varargin = varargin{1};
            %end
            send(self.resQueue, res);
        end

        % APdata: {isReanalysis, index, timePos, HC1, HC2}
        function APqueueFcn(self, APdata)
            fprintf('Received APdata: %s', formattedDisplayText(APdata));
            if isequal(APdata, true)
                send(self.resQueue, true);
                return;
            end
            fut = parfeval(self.bgPool1, ...
                @AcquisitionFacilitator.APqueueFcnInternal, 1, ... % 1 = num out
                self.dpIdx0, self.logFileName, self.BGimgScaled, ...
                self.NumChannels, self.CropRectangle, ...
                self.CurrentPeakSearchBounds, ...
                self.ChannelHorizIdxs, self.ScaledChannelVertIdxs, ...
                self.lfit, self.OrigDim, ...
                ...% self.numIntensityProfilePoints, ...
                self.ScaledDim, ...
                APdata{:});
            % APdata: {isReanalysis, datapointIndex, timePos, HC1, HC2}
            %             if(isempty(self.futs))
            %                 self.futs = fut;
            %             else
            %                 self.futs(end+1) = fut;
            %             end
            % TODO: Rewrite update function(s)
            if(APdata{1}) % Is it a reanalysis?
                % fut2 = afterEach(fut, self.updateDataReanalysisFcn, 0, "PassFuture", false); %#ok<NASGU>
            else
                fut2 = afterEach(fut, @self.toResQueueFcn, 0, ...
                    "PassFuture", false); %#ok<NASGU>
                % fut2 = afterEach(fut, self.updateDataFcn, 0, "PassFuture", false); %#ok<NASGU>
            end
            %                         wait(fut);
            %                         wait(fut2);
            %                         if(~isempty(fut.Error))
            %                             fprintf('fut.Error: ');
            %                             disp(fut.Error);
            %                             if(iscell(fut.Error))
            %                                 fprintf('Cell iteration: ');
            %                                 for i=1:length(fut.Error)
            %                                     err = fut.Error{i};
            %                                     disp(err.remotecause);
            %                                     disp(err.stack);
            %                                 end
            %                             elseif(~isscalar(fut.Error))
            %                                 fprintf('Array iteration: ');
            %                                 for i=1:length(fut.Error)
            %                                     err = fut.Error(i,1);
            %                                     disp(err.remotecause);
            %                                     disp(err.stack);
            %                                 end
            %                             else
            %                                 err = fut.Error;
            %                                 fprintf('RC: ');
            %                                 disp(err.remotecause{1});
            %                                 fprintf('Stack: ');
            %                                 for g = err.stack
            %                                     disp(struct2cell(g));
            %                                 end
            %                             end
            %                         end
            %                         %if(~isempty(fut2.Error))
            %                         %    fprintf('fut2.Error: ');
            %                         %    err = fut2.Error{1};
            %                         %    disp(err);
            %                         %    disp(err.cause{1});
            %                         %    disp(err.remotecause{1});
            %                         %end
            %                         %afterEach(fut, @(x) updateData(self, x), 0, ...
            %                         %    PassFuture=true);
            %                         %afterEach(fut, @AcquisitionFacilitator.testFcn, 0, ...
            %                         %    PassFuture=true);% @(x) updateData(self, x));
        end
    end

    methods(Access=protected)
        function q = makeHCqueue(self)
            q = parallel.pool.DataQueue();
            afterEach(q, @(x) self.HCqueueFcn(x));
        end
        function q = makeAPqueue(self)
            q = parallel.pool.DataQueue();
            afterEach(q, @(x) self.APqueueFcn(x));
        end
    end

    methods(Access=protected)
        function postset_framesize(self, src, eventData)
            arguments(Input)
                self AcquisitionFacilitator;
                src meta.property;
                eventData event.EventData; %#ok<INUSA>
            end
            switch src.Name
                case "FrameYBoundL"
                    self.OrigDim(1) = ...
                        self.CropRectangle.YLimits(2) ...
                        - self.CropRectangle.YLimits(1) ...
                        + 1;
                case "FrameYBoundR"
                    self.OrigDim(1) = ...
                        self.CropRectangle.YLimits(2) ...
                        - self.CropRectangle.YLimits(1) ...
                        + 1;
                case "FrameYBounds"
                    self.OrigDim(1) = ...
                        self.CropRectangle.YLimits(2) ...
                        - self.CropRectangle.YLimits(1) ...
                        + 1;
                    % TODO: Double-check
                case "analysisScale"
                    %obj = eventData.AffectedObject;
                    % self.analysisRescale = self.analysisScale\1;
            end
            if self.analysisScale == 1
                self.ScaledDim(1,1) = self.OrigDim(1);
            else
                self.ScaledDim(1,1) = ceil((self.OrigDim(1)-1)*self.analysisScale)+1;
            end
            fprintf('Set scaled dim (length: %d): %s', ...
                numel(self.ScaledDim), formattedDisplayText(self.ScaledDim));
        end
    end

    methods(Access=protected,Static)
        function [ret,ERR] = waitForQueueToEmpty(bgPool, Q, ...
                timeout, pollQueue)
            arguments(Input)
                bgPool {mustBeA(bgPool, 'parallel.BackgroundPool')};
                Q {mustBeA(Q, 'parallel.pool.PollableDataQueue')};
                timeout {mustBeNonnegative, mustBeNumeric, mustBeReal} = Inf;
                pollQueue {mustBeNumericOrLogical} = false;
            end
            try
                if(Q.QueueLength)
                    fut = parfeval(bgPool, ...
                        @AcquisitionFacilitator.waitForQueueToEmptyInner, ...
                        2, Q, pollQueue);
                    if(~isfinite(timeout))
                        wait(fut);
                        [ret, ERR] = fetchNext(fut);
                    elseif(timeout)
                        % wait(fut, timeout);
                        [ret, ERR] = fetchNext(fut, timeout);
                    else % zero timeout specified. not sure what the point would be though
                        ret = true;
                        ERR = [];
                    end
                else
                    ret = true;
                    ERR = [];
                end
            catch ERR
                ret = false;
            end
        end

        function [ret,ERR] = waitForQueueToEmptyInner(Q, pollQueue)
            try
                while Q.QueueLength
                    if(pollQueue)
                        poll(Q, 1);
                    end
                end
                ret = true;
                ERR = [];
            catch ERR
                ret = false;
            end
        end
    end

    methods(Access=public, Static)
        function stopReadingFrames(~,~,APqueue)
            send(APqueue, true);
            % delete(tobj);
        end

        function readNextFrame(tobj, event, APqueue)
            arguments(Input)
                tobj timer;
                event;
                APqueue
            end
            ud = tobj.UserData;
            if hasFrame(ud.vreader)
                fprintf('Reading frame no. %d\n', tobj.TasksExecuted);
                HC = readFrame(ud.vreader);
                HC = im2double(HC);
                fprintf('HC class, min, max: %s, %0.4g, %0.4g\n', ...
                class(HC), min(HC,[],"all","omitnan"), max(HC,[],"all", "omitnan"));
                triggerIndex = tobj.TasksExecuted;
                % {false, datapointIndex, datapointTimePos, prevHC, HC}
                if (triggerIndex > 1) && ~isempty(ud.PrevHC)
                    send(APqueue,...
                        {false, triggerIndex-1, datetime(event.Data.time), ud.PrevHC, HC});
                end
                ud.PrevHC = HC;
                tobj.UserData = ud;
            else
                fprintf('On tick no. %d, there were no frames left.\n', ...
                    tobj.TasksExecuted);
                stop(tobj);
            end
        end

        function HC = makeHalfComposite(fphh,frames)
            if(fphh < 1)
                HC = im2double(frames);
                return;
            elseif(fphh == 1)
                A = im2double(frames(:,:,1));
                B = im2double(frames(:,:,2));
            else
                iA2 = fphh;
                iB1 = iA2 + 1;

                A0 = im2double(frames(:,:,iA2));
                B0 = im2double(frames(:,:,iB1));
                A = A0;
                B = B0;
                iA1 = iA2 - 1;
                iB2 = iB1 + 1;

                while (iA1 >= 1)
                    A = AcquisitionFacilitator.makeComposite(im2double(frames(:,:,iA1)), A);
                    B = AcquisitionFacilitator.makeComposite(B, im2double(frames(:,:,iB2)));
                    iA1 = iA1 - 1;
                    iB2 = iB2 + 1;
                end
            end
            HC = AcquisitionFacilitator.makeComposite(A,B);
        end

        function res = APqueueFcnInternal(dpIdx0, logFileName, Y0s, ...
                numChannels, cropRectangle, peakSearchBounds, ...
                channelHorizIdxs, scaledChannelVertIdxs, lfit, origDims, ...
                scaledDim, isReanalysis, datapointIndex, timePos, HC1, HC2)
            arguments(Input)
                dpIdx0;
                logFileName;
                Y0s;
                numChannels;
                cropRectangle;
                peakSearchBounds;
                channelHorizIdxs;
                scaledChannelVertIdxs;
                lfit;
                origDims;
                scaledDim;
                isReanalysis;
                datapointIndex;
                timePos;
                HC1;
                HC2 = [];
            end
            f = fopen(logFileName, "a");
            fprintf(f, 'Internal args (%d):', nargin);
            fprintf(f, 'timePos: %s\n', erase(formattedDisplayText(timePos, 'SuppressMarkup',true), newline));
            try
                if(isReanalysis)
                    Y1 = HC1;
                else
                    Y1 = AcquisitionFacilitator.makeFullComposite(HC1, HC2);
                end

                fprintf(f, 'Y0s class & size: %s, %s\n', ...
                    class(Y0s), ...
                    erase(formattedDisplayText(size(Y0s)), newline));

                Y1s = imcrop(Y1, cropRectangle);
                if(~isempty(scaledDim))
                    fprintf(f, 'Y1 class & size before resize: %s, %s', ...
                        class(Y1), ...
                        formattedDisplayText(size(Y1)));
                    fprintf(f, 'Scaled dim: [ %0.4g %0.4g ]\n', scaledDim(1), scaledDim(2));
                    Y1s = imresize(Y1s, scaledDim, "lanczos3");
                end

                numIntensityProfilePoints = floor(0.5*(size(Y1, 2)-1));
                % numFitPoints = min(225, numIntensityProfilePoints);
                fprintf(f, 'Y1s class & size: %s, %s', ...
                    class(Y1s), ...
                    formattedDisplayText(size(Y1s)));

                [Yc, peakData, estimatedLaserIntensity, ...
                    p1s, intprofs, fitprofs, cfitBoundses, ...
                    successCode] ... % Unused: Yr
                    = AcquisitionFacilitator.analyzeComposite1(Y0s,Y1s,lfit, ...
                    numIntensityProfilePoints, origDims, numChannels,...
                    channelHorizIdxs,scaledChannelVertIdxs, ...
                    cropRectangle, peakSearchBounds, f);

                %res = {datapointIndex, timePos, peakSearchBounds, ...
                %    Y1, estimatedLaserIntensity, peakData, intprofs, p1s ...
                %    }; % TODO: Also send back Yc?
                res = struct('DatapointIndex', datapointIndex+dpIdx0, ...
                    'RelativeDatapointIndex', datapointIndex, ...
                    'AbsTimePos', timePos, 'PeakSearchBounds', ...
                    peakSearchBounds, 'ELI', estimatedLaserIntensity, ...
                    'SuccessCode', successCode, 'PeakData', peakData, ...
                    'IntensityProfiles', intprofs, 'EstParams', p1s, ...
                    'CurveFitBounds', cfitBoundses, ...
                    'FitProfiles', fitprofs, ...
                    'CompositeImage', Y1, 'ScaledComposite', Yc);
                fprintf(f,'\tMade res:\n');
                fprintf(f,'\t%s\n', formattedDisplayText(res, 'SuppressMarkup', true));
            catch ERR
                fprintf(f, '< ERR: %s > ', formattedDisplayText(ERR, 'SuppressMarkup',true));
                fprintf(f, '< ERR.message: %s > ', formattedDisplayText(ERR.message, 'SuppressMarkup', true));
                try
                    %stk = ERR.stack;
                    %fprintf(f, '< Cause: %s >\n', formattedDisplayText(ERR.cause));
                    %fprintf(f, '< Stack: %s >\n', formattedDisplayText(struct2cell(ERR.stk)));
                    fprintf(f, '< Report: %s >\n', getReport(ERR,'extended','hyperlinks','off'));
                    %fprintf(f, '<< file: %s; name: %s; line: %d >>\n', ...
                    %    stk.file, ...
                    %    stk.name, stk.line);
                catch ERR2
                    fprintf(f,'Error occurred while writing error stack to file: %s', ...
                        formattedDisplayText(ERR2, 'SuppressMarkup', true));
                end
                fclose(f);
                %rethrow(ERR);
                res = {datapointIndex, timePos, [], ...
                    NaN, NaN(1,2,numChannels), ...
                    sbsense.helpers.makeIPcellrow(cropRectangle), ... % TODO: Store blank template row in props
                    NaN(1, numIntensityProfilePoints, numChannels), [NaN NaN NaN]};
                %res = {isReanalysis, false, datapointIndex, timePos, ...
                %    [], [], [], [], []};
            end
            fclose(f);
        end

        function FC = makeFullComposite(A,B)
            A = im2double(A);
            B = im2double(B);
            % FC = im2double(imfuse(A, B, 'blend'));
            FC = imlincomb(0.5, A, 0.5, B, 'double');
        end

        function C = makeComposite(A,B)
            A = im2double(A);
            B = im2double(B);
            C = imlincomb(0.5, immultiply(A,B), 0.5, imlincomb(0.5, A, 0.5, B, 'double'), 'double');
        end

        function videoStartFcn(vobj, ~)
            % Do stuff...
            %trigger(vobj);
            ud = vobj.UserData;
            ud.prevHCimg = [];
            ud.prevHCtimeRange = [];
            vobj.UserData = ud;
            flushdata(vobj);
        end

        % A timer event occurs when the time period specified by the TimerPeriod property expires.
        % The toolbox measures time relative to when the object is started with the start function.
        % Timer events stop being generated when the image acquisition object stops running.
        % The Running property indicates that the object is ready to acquire data, while the Logging property indicates that the object is acquiring data.
        % When Running is "off", you cannot acquire image data. However, you can acquire one image frame with the getsnapshot function.
        function videoTimerFcn(vobj, event) % event structure has AbsTime
            ud = vobj.UserData;
            if(vobj.TriggersExecuted > ud.maxTriggers )
                fprintf('%16s TimerFcn: Stopping video input\n', ...
                    datetime(event.Data.AbsTime));
                if(~isempty(vobj))
                    stop(vobj);
                end
            else
                fprintf('%16s Timer went off, but not finished capturing frames (%d < %d).\n', ...
                    datetime(event.Data.AbsTime), ...
                    vobj.TriggersExecuted, ud.maxTriggers);
            end
        end

        % self.vobj.FramesAcquired: # frames extracted from memory buffer
        % When you issue a start command, the video input object resets the value of the FramesAcquired property to 0 (zero) and flushes the buffer.
        % FramesAvailable — Number of frames available in memory buffer
        function videoFramesAcquiredFcn(vobj,event)
            ud = vobj.UserData;
            if vobj.TriggersExecuted < 2
                fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
                fprintf('Initial trigger time: %s\n', ...
                    formattedDisplayText(datetime(vobj.InitialTriggerTime)));
                send(ud.resQueue, datetime(vobj.InitialTriggerTime));
            end

            [frames, ~, metadata] = getdata(vobj);
            HCtimeRange = [datetime(metadata(1).AbsTime), ...
                datetime(metadata(end).AbsTime) ];
            
            if(vobj.NumberOfBands > 1)
                frames = frames(:,:,1,:);
                frames = squeeze(frames);
            elseif(ndims(frames) > 3)
                frames = squeeze(frames);
            end
            send(ud.HCqueue,...
                {event.Data.TriggerIndex, HCtimeRange, frames});
        end

        % InitialTriggerTime: Absolute time of the first trigger, returned as a MATLAB clock vector.
        % For all trigger types, InitialTriggerTime records the time when the Logging property is set to "on".
        % To find the time when a subsequent trigger executed, view the Data.AbsTime field of the EventLog property for the particular trigger.
        function videoTriggerFcn(vobj,event,~)
            ud = vobj.UserData;
            if(( event.Data.TriggerIndex > ud.maxTriggers) ... %2*tobj.numPoints) ...
                    || (vobj.TriggersExecuted > ud.maxTriggers) ) % 2*tobj.numPoints) )
                stop(vobj);
            else
                fprintf('(%d) TriggersExecuted: %d =< %d\n', ...
                    event.Data.TriggerIndex, vobj.TriggersExecuted, ...
                    ud.maxTriggers);
            end
        end

        function videoStopFcn(vobj,event,tobj)
            fprintf('%16s videoStopFcn: Trigger index is %d, TriggersExecuted is %d\n', ...
                datetime(event.Data.AbsTime),  event.Data.TriggerIndex, ...
                vobj.TriggersExecuted);
            tobj.startTime = datetime(vobj.InitialTriggerTime);
            tobj.stopTime  = datetime(event.Data.AbsTime);
            [tf, ERR] = AcquisitionFacilitator.waitForQueueToEmpty( ...
                tobj.bgPool2, tobj.finishedQueue, 30);
            if(~tf)
                fprintf('Warning: Queue still has nonzero length %d after 30-second timeout period. Processing may be incomplete and some datapoints may be missing.\n', ...
                    tobj.finishedQueue.QueueLength);
                if ~isempty(ERR)
                    fprintf('Error report: %s', getReport(ERR));
                end
                %fprintf('ERR: %s', formattedDisplayText(ERR, 'SuppressMarkup', true));
                %fprintf('File: %s\n',ERR.stack.file);
                %fprintf('Name: %s\n', ERR.stack.name);
                %fprintf('Line: %d\n', ERR.stack.line);
                %fprintf('Cause: %s', getReport(ERR.cause));
            end
            %numCompositesCollected = size(tobj.composites, 3);
            %numTimePositionsCollected = length(tobj.timePositions);
            if(isempty(tobj.timePositions) && ~isempty(tobj.composites))
                fprintf('[vobj.stop] Warning: tobj.timePositions is empty! Retrospectively generating times.\n');
                st = datetime(vobj.InitialTriggerTime);
                en = datetime(event.Data.AbsTime);
                N = size(tobj.composites, 3); % max(size(tobj.composites, 3), size(tobj.plotData,1));
                rng = seconds(en - st);
                stp = rng / (N - 1);
                tobj.timePositions = st + stp.*(0:N);
            end
            ud = vobj.UserData;
            if isfield(ud, 'maxTriggers') && isfinite(ud.maxTriggers)
                numdp = max(0,(vobj.TriggersExecuted-2));
            else
                numdp = max(0,(vobj.TriggersExecuted-1));
            end
            % send(tobj.resQueue, tobj.startTime);
            fprintf('[videoStopFcn] Number of datapoints added: %d\n', ...
                numdp);
            %send(tobj.resQueue, numdp);
            send(tobj.resQueue, true);
            tobj.dpIdx0 = tobj.dpIdx0 + numdp;
        end
    end

    methods(Access=protected, Static)
        function [Yc,peakData,estimatedLaserIntensity, ...
                p1s, intprofs, fitprofs, cfitBoundses, ...
                successCode, Yr] = analyzeComposite1(Y0,Y1,lfit, ... % numFitPoints,...
                numHalfIPpoints, ...
                origDims,numChannels,~,channelVertIdxs, ...
                ~, peakSearchBounds, f) %#ok<INUSD> 

            %fprintf(f,'[analyzeComposite1] bounds: %s', formattedDisplayText(bounds));
            fprintf(f,'[analyzeComposite1] Size of Y0: %s', formattedDisplayText(size(Y0)));
            fprintf(f,'[analyzeComposite1] Size of Y1: %s', formattedDisplayText(size(Y1)));
            fprintf(f,'[analyzeComposite1] numChannels: %d\n', numChannels);

            % TODO: Fallback masks / guide parameters based on whole image
            %       -- use during individual channel analysis
            [estimatedLaserIntensity, successTF, Yc, Yr] ...%, sampMask, sampMask0, roiMask] ...
                = sbestimatelaserintensity(Y0, Y1, peakSearchBounds, f);
            
            peakData = NaN(2,numChannels); p1s = NaN(3,numChannels);
            
            numIPpoints = origDims(2); %2*numHalfIPpoints + 1;
            intprofs = NaN(numIPpoints, numChannels);
            fitprofs = NaN(numIPpoints, numChannels);
            cfitBoundses = NaN(2, numChannels);
            if ~successTF
                return;
            end
            %horizIdxs0 = 1:origDims(2);
            successTF2 = true;
            fitXs = 1:numIPpoints; % TODO: Subset?
            for chNum=1:numChannels
                Y0c = Y0(channelVertIdxs{chNum}, :);
                Y1c = Y1(channelVertIdxs{chNum}, :);
                Ycc = Yc(channelVertIdxs{chNum}, :);
                % TODO: Try/catch??? -- be sure to fill cell with NaNs
                [channelPeakData, channelIP, p1, successTF2a, cfitBounds] ... % sampMask, sampMask0, roiMask] ...
                    = sbestimatepeakloc(Y0c,Y1c,Ycc,lfit, ...
                    origDims, peakSearchBounds, f); %...
                    %numHalfIPpoints, numIPpoints, f);
                if successTF2a
                    peakData(:,chNum) = channelPeakData; %'; % Unnecessary?
                    p1s(:,chNum) = p1;%'; % Unnecessary?
                    intprofs(:,chNum) = channelIP;
                    fitprofs(:,chNum) = lorentz(p1, fitXs); % TODO: Don't recalculate for each?
                    cfitBoundses(:,chNum) = cfitBounds;
                    fprintf(f, 'Size of intprofs(:,chNum): %s', formattedDisplayText(size(intprofs(:,chNum))));
                    fprintf(f, 'Size of channelIP: %s', formattedDisplayText(size(channelIP)));
                elseif successTF2
                    successTF2 = false;
                end
            end
            successCode = successTF + successTF2; %uint8(successTF + successTF2);
        end
    end

    methods(Access=private)
        function configureVideoSource(self,resetexposure)
            arguments(Input)
                self AcquisitionFacilitator;
                resetexposure logical = true;
            end
            stop(self.vobj);
            closepreview(self.vobj);
            %disp(self.vobj);
            %disp(self.vsrc);
            self.vdev.ReturnedDataType = 'double'; % default: single
            % self.vdev.ReadAllFrames = 'on'; % default: off
            %disp(self.vdev.DeviceProperties);
            %disp(propinfo(self.vobj));
            %disp(propinfo(self.vobj.Source));
            %disp(propinfo(self.vsrc));
            %disp(self.vsrc.Selected);
            try
                self.vsrc.BacklightCompensation = "off";
                self.vsrc.IrisMode = "manual";
                self.vsrc.Iris = 0; % This is the only allowable value for our cam
                self.vsrc.Roll = 0; % Todo: Why does Roll=3 not work?
                %self.vsrc.Pan = 0;
                %self.vsrc.Tilt = 0;
                %self.vsrc.HorizontalFlip = "on";
                %self.vsrc.VerticalFlip = "on";
                % self.vsrc.Zoom = 100; % TODO: Zoom value?
                %self.vsrc.ColorEnable = "on";
            catch
            end

            try
                self.vsrc.Sharpness = 0;
                %self.vsrc.HueMode = "manual";
                self.vsrc.Hue = 40;
                self.vsrc.WhiteBalanceMode = "manual";
                self.vsrc.WhiteBalance = 2800;
                %self.vsrc.Saturation = 128;
            catch
            end
            %self.vsrc.FocusMode = "manual"; % TODO: Setup focus
            %self.vsrc.Focus = 1;

            try
            self.vsrc.Brightness = -64; % TODO: Brightness value?
            self.vsrc.Contrast = 64;
            catch
            end

            try
            self.vsrc.Gamma = 72; %400; %286; % TODO: Auto gamma adjustment
            catch
            end

            try
            self.vsrc.ExposureMode = "manual"; % Very important!
            catch
            end
            
            try
            self.vsrc.Brightness = -64;
            self.vsrc.Saturation = 60;
            self.vsrc.Gamma = 72;
            self.vsrc.Contrast = 30;
            self.vsrc.Hue = 0;
            catch
            end


            try
            self.vsrc.WhiteBalance = 6500;
            catch
            end
            
            if resetexposure
                try
                    self.vsrc.Exposure = -8;
                    self.vsrc.Gain = 0;
                catch
                end
            end
        end
        function configureVideoInput(self)
            fprintf('Configuring video input.\n');

            self.vdev.ReturnedColorSpace = 'RGB'; % default: YCbCr
            self.vobj.ReturnedColorSpace = 'RGB';

            configureVideoSource(self);

            try
            self.vsrc.Gain = 0;
            self.vsrc.Brightness = 0;
            self.vsrc.Exposure = -4;
            catch
            end

            fprintf('Setting frame vars.\n');
            self.vobj.FrameGrabInterval = self.tpfRatio;
            self.vobj.FramesAcquiredFcnCount = self.fph;
            self.vobj.ReturnedColorSpace = "rgb";

            fprintf('Setting timer vars.\n');
            %self.vobj.TimerPeriod = 1.25*self.tpp*self.numPoints;
            self.vobj.TimerPeriod = 120; % 2*self.tpp*self.numPoints; % 60
            self.vobj.TimerFcn = @self.videoTimerFcn;

            fprintf('Setting misc vars.\n');
            self.vobj.Timeout = 15; % 180;
            %self.vobj.Logging = "on";
            self.vobj.LoggingMode = "memory";

            fprintf('Setting fcn vars.\n');
            self.vobj.StartFcn = @self.videoStartFcn;
            self.vobj.FramesAcquiredFcn = ...
                @self.videoFramesAcquiredFcn;
            self.vobj.StopFcn = {@self.videoStopFcn, self};
            % self.vobj.ErrorFcn = @imaqcallback;

            fprintf('Setting trigger vars.\n');
            self.vobj.TriggerFcn = {@self.videoTriggerFcn, self};
            triggerconfig(self.vobj, 'immediate');
            self.vobj.FramesPerTrigger = self.fph;
            self.vobj.TriggerFrameDelay = 0;%self.fph;
            %self.vobj.TriggerFrameDelay = ...
            %    fixDiv(mod(self.fps0,self.fps), 2);
            self.vobj.TriggerRepeat = self.numPoints * 2; % Inf;

            vr = flip(self.vobj.VideoResolution);
            self.vobj.ROIPosition = ...
                [0 0 vr(2) vr(1)];
            self.frameDimensions = vr; %flip(vr, 2); %[max(vr) min(vr)];


            fprintf('Setting user data.\n');
            self.vobj.UserData = struct(...
                'maxTriggers', self.numPoints+1, ...
                'prevHCimg', [], ...
                'prevHCtimeRange', [], ...
                'currHCimg', [], ...
                'currHCtimeRange', [], ...
                'HCqueue', self.HCqueue,...%, ...
                'resQueue', self.resQueue ...
                );
            fprintf('Done configuring video input.\n');
        end
    end
end