classdef Analyzer < handle & matlab.mixin.SetGetExactNames
properties(GetAccess=public,SetAccess=private,Transient)
    MTQueue parallel.pool.PollableDataQueue;
    HCQueue parallel.pool.PollableDataQueue;
    APQueue parallel.pool.PollableDataQueue = parallel.pool.PollableDataQueue(); % TODO
    IvlQueue parallel.pool.PollableDataQueue;
    HCQFuture parallel.Future;
    APQ1Future parallel.Future;

    % APQueue parallel.pool.DataQueue;
    ResQueue parallel.pool.DataQueue;
    FinishedQueue parallel.pool.PollableDataQueue;

    APQueue2 parallel.pool.PollableDataQueue;
    APTimer timer;
% end
% properties(SetAccess=private,GetAccess=public,Transient)
    % HCQueue parallel.pool.DataQueue;
    % HCQueue2 parallel.pool.PollableDataQueue;
    % BatchMask (1,10) logical;
    % BatchIndices (1,10) uint64;
    % BatchFrames (:,:,10) uint8;
    HCQueueFileData;
    HCQueueFileMap;
    HCQueueFilePath = 'SBSense_temp.bin';
    HCQueueFile;
    % lastReadHCMapSlot uint16;
    % nextHCMapSlot uint16;
    % nextBatchSlot uint8;
    % thisBatchFirstIndex uint64;
    % thisBatchLastIndex uint64;
    AnalysisParams; %sbsense.AnalysisParameters;
    % lfit sbsense.LorentzFitter;
    SignalFcn function_handle;
end

properties(Access=public,Transient)
    AnalysisFutures parallel.Future;
end

properties(Access=public,Transient,NonCopyable)
    LastParams = double.empty();
end

properties(GetAccess=public,SetAccess=protected,Transient,NonCopyable)
    ConstObj parallel.pool.Constant;
end

properties(GetAccess=public,SetAccess=public)
    fph;
    LogFile = [];
end

properties(GetAccess=public,SetAccess=private)
    PSBWidth (1,1) uint16;
    ChHorzIdxs (1,:) uint16;
end

properties(SetAccess=public,SetObservable,AbortSet)
    PSBL (1,1) uint16;
    PSBR (1,1) uint16;
end

properties(Dependent,Access=public)
    ShouldStopAPTimer;
end

methods

    function set.ShouldStopAPTimer(obj,val)
        obj.APTimer.UserData = val;
    end
    function val = get.ShouldStopAPTimer(obj)
        val = isa(obj.APTimer, 'timer') && isvalid(obj.APTimer) && obj.APTimer.UserData;
    end

    function obj = Analyzer(resQueue, signalFcn, paramsObjHandle)
        obj.ResQueue = resQueue;
        obj.SignalFcn = signalFcn;
        % obj.lfit = sbsense.LorentzFitter(); % TODO: Args
        obj.AnalysisParams = paramsObjHandle;

        % obj.APQueue = parallel.pool.DataQueue();
        % % afterEach(obj.APQueue, @obj.APFcn);
        % afterEach(obj.APQueue, @(x) send(obj.APQueue2, x));
        % obj.HCQueue = parallel.pool.DataQueue();
        % afterEach(obj.HCQueue, @obj.HCFcn);
        obj.FinishedQueue = parallel.pool.PollableDataQueue();
        addlistener(obj, {'PSBL', 'PSBR'}, 'PostSet', @obj.postset_psb);
    end

    % (BGimg), (NumChs)
    function initialize(obj, dpIdx0, resQueue, varargin) % varargin: BGimg, numChannels, analysisScale
        fprintf('[Analyzer:initialize]\n');
        
        obj.ResQueue = resQueue;
        obj.APTimer = timer('BusyMode', 'drop', 'ExecutionMode', 'fixedSpacing', 'Period', 0.050, ...
            'TimerFcn', @(tobj,~) pollAPQueue2(obj,tobj), 'ErrorFcn', {@obj.onAPTimerError}, ...
            ... %'StopFcn', @(~,~) cancel([obj.HCQFuture, obj.APQ1Future]), ...
             'Name', 'AnalysisQueueTimer');
        obj.APQueue2 = parallel.pool.PollableDataQueue();
        initialize(obj.AnalysisParams, dpIdx0, varargin{:});
    end

    function onAPTimerError(~, tobj, ev) % ev.Type is 'ErrorFcn'
        fprintf('APTimer encountered an error:'); display(ev.Data);
        tobj.UserData = true;
        try
            stop(tobj); % TODO: Also stop recording??
        catch
            fprintf('Error occurred while stopping tobj in onAPTimerError function.\n');
        end
    end

    function stopPollerFutures(obj)
        if ~isempty(obj.HCQFuture) && isa(obj.HCQFuture, 'parallel.Future')
            try
                cancel(obj.HCQFuture);
            catch
            end
            % obj.HCQFuture = parallel.Future.empty();
        end
        if ~isempty(obj.APQ1Future) && isa(obj.APQ1Future, 'parallel.Future')
            try
                cancel(obj.APQ1Future);
            catch
            end
            % obj.APQ1Future = parallel.Future.empty();
        end
    end

    function prepareReanalysis(obj, varargin)
        obj.LastParams = [];
        obj.APTimer.UserData = false;
        prepareReanalysis(obj.AnalysisParams, varargin{:});
    end

    function TF = pollAPQueue2(obj,varargin)
        if nargin > 1
            tobj = varargin{1};
            if isequal(tobj.UserData, true)
                if tobj.Running(2)=='n'
                    fprintf('[pollAPqueue] #### APTimer UserData is true (APTimer should stop) #### \n');
                    stop(tobj);
                end
                fprintf('[pollAPqueue] #### APTimer UserData is true (but timer is already stopped) #### \n');
                return;
            end
        else
            tobj = [];
        end
        [APdata,TF] = poll(obj.APQueue2,0); % TODO: poll timeout?
        % disp({APdata,TF});
        if TF
            if ~isempty(tobj) && (tobj.Running=="on")
                fprintf('[pollAPqueue] (stopping running APTimer before analysis) \n');
                stop(tobj);
            end
            % APfcn(obj, APdata);
            sbsense.improc.analyzeHCsParallel(obj, obj.AnalysisParams, ...
                [obj.PSBL obj.PSBR], ...
                APdata{:}, obj.LastParams);
        % elseif tobj.ExecutionMode~="singleShot"
        %     fprintf('[pollAPqueue] Not restarting APTimer since its ExecutionMode is not singleShot.\n');
        % elseif isequal(tobj.UserData, true)
        %     fprintf('[pollAPqueue] Not restarting APTimer since its UserData is true.\n');
        % elseif tobj.Running=="on"
        %     fprintf('[pollAPqueue] Not restarting APTimer since it is mysteriously already running.\n');
        % else
        % %elseif ~isequal(tobj.UserData,true) && (tobj.Running(2)=='f') && (tobj.ExecutionMode(1)=="singleShot")% singleShot, not fixed<...>
        %     fprintf('[pollAPqueue] (re-starting stopped APTimer since poll failed) \n');
        %     start(tobj);
        % %else
        % %    fprintf('[pollAPqueue] Not restarting tobj since conditions are not met.\n');
        end
    end

    % (analysisScale)
    function prepare(obj,dpIdx0,resQueue,fph,varargin)
        fprintf('[Analyzer:prepare]\n');
        if ~isempty(obj.HCQueueFile)
            try
                fclose(obj.HCQueueFile);
            catch
            end
        end
        if isobject(obj.HCQueueFileMap)
            % clearvars obj.HCQueueFileMap;
            obj.HCQueueFileMap = [];
        end
        obj.HCQueueFile = fopen(obj.HCQueueFilePath, 'w'); %'w+');
        % TODO: Handle fopen errors/failure
        %obj.BatchMask = false(1,10);
        % obj.BatchFrames = zeros([size(obj.AnalysisParams.RefImg) 10]);
        % obj.NextBatchSlot = 1;
        % obj.thisBatchFirstIndex = obj.dpIdx0;
        % obj.thisBatchLastIndex = obj.dpIdx0 + 9;
        % obj.nextHCMapSlot = 1;
        % obj.lastReadHCMapSlot = 0;
        % Each HC group is N*L*W*8 bits = N*L*W bytes, where N = # frames per HC
        % A two-element datetime array is 32 bytes = 256 bits.
        % If precision is 'ubit64' or 'bit64' or 'uint64' or 'int64' or 'real*8'
        % and skip is 64, then each element in the written array will take up 128 bits.
        % >> 128 bits per written value
        % >> 32 + N*L*W*8 bits per stored HC group
        %    ==> 1024*(32+N*L*W*8) bits needed total
        % ==> ceil(1024*(32+N*L*W*8) / 128) written values needed
        % numberOfValuesToWrite = ceil(1024/128 * (32+prod([fph size(obj.AnalysisParams.RefImg)])));
        % fwrite(obj.HCQueueFile, zeros(1, numberOfValuesToWrite, 'uint8'), 'ubit64', 'Skip', 64);
        % fclose(obj.HCQueueFile); % TODO: Try/catch??
        % obj.HCQueueFile = [];
        % obj.HCQueueFileMap = memmapfile(obj.HCQueueFilePath, ...
        %     'Format', {'datetime', [1 2], 'timeRange' ; ...
        %     'uint8', [prod(size(obj.AnalysisParams.RefImage)) fph], 'frames'}, ...
        %     'Repeat', 1024, 'Writable', true);

        % Each HC group is 64 + 64 + 16*L*W bits = 16 + 2*L*W bytes
        try
            % numberOfValuesToWritePerGroup = 2*prod(size(obj.AnalysisParams.RefImg));
            zs = zeros(size(obj.AnalysisParams.RefImg), 'single');
            for groupNo=1:60
                fwrite(obj.HCQueueFile, zeros(1, 16, 'uint8'), 'uint8');
                fwrite(obj.HCQueueFile, zs, 'single');
            end
            fclose(obj.HCQueueFile);
        catch HCQFError % TODO: Abort setup on error
            try
                close(obj.HCQueueFile); 
            catch
            end
            rethrow(HCQFError);
        end
        obj.HCQueueFileMap = memmapfile(obj.HCQueueFilePath, ...
            'Format', { ...
                'uint64', [1 1], 'DatapointIndex' ; ... % Relative datapoint index !! (??)
                'double', [1 1], 'RelTimeSecs' ; ...
                'single', size(obj.AnalysisParams.RefImg), 'HalfCompositeImage' ...
            }, ...
            'Writable', true, 'Offset', 0, 'Repeat', 60 ...
        );
        obj.HCQueueFileData = obj.HCQueueFileMap.Data;
        obj.LogFile = fopen("SBSense_log.txt", "a"); % TODO: Try/catch???
        obj.ResQueue = resQueue;
        obj.fph = fph;
        obj.LastParams = [];

        stopPollerFutures(obj);
        disp({obj.HCQueue, isvalid(obj.HCQueue), obj.HCQueue.QueueLength});
        if ~isempty(obj.HCQueue) && isa(obj.HCQueue, 'parallel.pool.PollableDataQueue') % TODO: Name of prop??
            delete(obj.HCQueue);
        %     obj.HCQueue = parallel.pool.DataQueue();
        %     afterEach(obj.HCQueue, @obj.HCFcn0);
        end
        % if isa(obj.HCQueue2, 'parallel.pool.PollableDataQueue') && ...
        %     (~isvalid(obj.HCQueue2) || obj.HCQueue2.QueueLength) % TODO: Name of prop??
        %     delete(obj.HCQueue2);
        %     obj.HCQueue = parallel.pool.PollableDataQueue();
        %     afterEach(obj.HCQueue, @obj.HCFcn);
        % end
        if ~isempty(obj.MTQueue) && isa(obj.MTQueue, 'parallel.pool.PollableDataQueue') %  ...
                % (~isvalid(obj.MTQueue) || obj.MTQueue.QueueLength) % TODO: Name of prop??
                delete(obj.MTQueue);
        end
        if ~isempty(obj.IvlQueue) && isa(obj.IvlQueue, 'parallel.pool.PollableDataQueue') % && ...
            % (~isvalid(obj.IvlQueue) || obj.IvlQueue.QueueLength) % TODO: Name of prop??
            delete(obj.IvlQueue);
        end
        obj.MTQueue = parallel.pool.PollableDataQueue();
        obj.HCQFuture = parfeval(backgroundPool, @obj.pollHCQ, 0, obj.fph, obj.MTQueue);
        [queues, TF] = poll(obj.MTQueue, 30);
        assert(TF);
        obj.HCQueue = queues(1);
        obj.IvlQueue = queues(2);
        obj.APQ1Future = parfeval(backgroundPool, @obj.pollAPQ1, 0, ...
            obj.HCQueueFileData, obj.IvlQueue, obj.APQueue2, obj.FinishedQueue);
        if isempty(obj.APQueue2)
            obj.APQueue2 = parallel.pool.PollableDataQueue();
        else
            try
                TF = true;
                while TF && obj.APQueue2.QueueLength
                    [~,TF] = poll(obj.APQueue2);
                end
            catch ME
                fprintf('Error occurred while emptying FinishedQueue: %s\n', getReport(ME));
                if isa(obj.APQueue2, 'parallel.pool.PollableDataQueue')
                    delete(obj.APQueue2);
                end
                obj.APQueue2 = parallel.pool.PollableDataQueue();
            end
        end
%         if ~isempty(obj.APQueue) && isa(obj.APQueue, 'parallel.pool.DataQueue') && ...
%             (~isvalid(obj.APQueue) || obj.APQueue.QueueLength) % TODO: Name of prop??
%             delete(obj.APQueue);
%             obj.APQueue = parallel.pool.DataQueue();
%             % afterEach(obj.APQueue, @obj.APFcn);
%             afterEach(obj.APQueue, @(x) send(obj.APQueue2, x));
%             % afterEach(obj.APQueue, @(APdata) obj.APQueueFcn(APdata));
%         end
        if isa(obj.FinishedQueue, 'parallel.pool.DataQueue') && ...
            (~isvalid(obj.FinishedQueue) || obj.FinishedQueue.QueueLength) % TODO: Name of prop??
            delete(obj.FinishedQueue);
            obj.FinishedQueue = parallel.pool.PollableDataQueue();
        end

        prepare(obj.AnalysisParams, dpIdx0, varargin{:});

        obj.ConstObj = parallel.pool.Constant(obj.AnalysisParams);

        obj.ShouldStopAPTimer = false;
    end
end

methods(Access=protected)
    function pollHCQ(~,fph,mtQueue)
        hcQueue = parallel.pool.PollableDataQueue();
        ivlQueue = parallel.pool.PollableDataQueue();
        send(mtQueue, [hcQueue, ivlQueue]);
        ivls = [0,0,0,0];
        lastDT = datetime('now');
        lastMeanAPIvl = 0;
        [apQueue, TF] = poll(ivlQueue, 15);
        assert(TF);
        % prevHCimg = [];
        % prevHCtimeRange = [];
        fprintf('pollHCQ: Entering while loop.\n');
        while true
            [HCData, TF] = poll(hcQueue, 15);
            fprintf('pollHCQ: HCData TF: %d.\n', TF);
            if TF
                thisDT = datetime('now');
                ivl = seconds(thisDT-lastDT);
                ivls = [mean([ivls([2 3 4]) ivl]) ivls([3 4]) ivl];
                ivls([2 3]) = ivls([3 4]);
                lastDT = thisDT;
                if apQueue.QueueLength > 4
                    continue;
                elseif apQueue.QueueLength > 1
                    meanIvl = 0;
                    maxIvls = ivlQueue.QueueLength;
                    if maxIvls > 0
                        TF = true;
                        while TF && (maxIvls > 2)
                            [~, TF] = poll(ivlQueue);
                            maxIvls = maxIvls - 1;
                        end
                        n = 0;
                        while TF && (maxIvls > 0)
                            [ivl1, TF] = poll(ivlQueue);
                            if ~isempty(ivl1)
                                n = n + 1;
                                meanIvl = meanIvl + ivl1;
                            end
                        end
                        if n > 0
                            lastMeanAPIvl = meanIvl / n;
                            if lastMeanAPIvl > 2*ivls(1)
                                continue;
                            end
                        end
                    end
                elseif lastMeanAPIvl > 2*ivls(1)
                    continue;
                end
                % Not dropped
                % HCdata: {datapointIndex, HCtimeRange, frames}
                [datapointIndex, timeRange, frames] = HCData{:};
                if iscell(frames)
                    frames = cat(3, frames{:});
                end
                HC = (sbsense.improc.makeHalfComposite(fix(2\fph),frames));
                if(datapointIndex)% && ~isempty(prevHCimg))
                    % datapointTimePos = mean([prevHCtimeRange(1) timeRange(2)]);
                    % send(obj.FinishedQueue, datapointIndex);
                    fprintf('pollHCQ: Sending to apQueue.\n');
                    send(apQueue, ...
                        {datapointIndex, timeRange, HC});
                    fprintf('pollHCQ: Sent to apQueue.\n');
                        % {false, datapointIndex, datapointTimePos, prevHCimg, HC});
                    % APdata: {isReanalysis, index, timePos, HC1, HC2}
                end
                % prevHCtimeRange = timeRange;
                % prevHCimg = HC;
            end
        end
    end

    function pollAPQ1(~, hcQueueFileData, ivlQueue, apQueue2, finishedQueue)
        takenSpotsQueue = parallel.pool.PollableDataQueue();
        availableSpotsQueue = parallel.pool.PollableDataQueue();
        for i=1:60
            send(availableSpotsQueue, i);
        end
        apQueue = parallel.pool.PollableDataQueue(); % AP queue 1
        send(ivlQueue, apQueue);
        prevHCimg = [];
        prevHCtimeRange = [];
        fprintf('pollAPQ1: Starting while loop.\n');
        while true
            [APData, pollSuccess] = poll(apQueue, 15);
            fprintf('pollAPQ1: APData pollSuccess: %d\n', pollSuccess);
            [readSpot, queueNotEmpty] = poll(takenSpotsQueue, 0);
            if pollSuccess && (queueNotEmpty || (apQueue2.QueueLength > 8))
                [writeSpot, TF] = poll(availableSpotsQueue);
                if ~TF
                    continue; % Drop frame
                end
                send(takenSpotsQueue,writeSpot);
                hcQueueFileData(writeSpot).DatapointIndex = APData{1};
                hcQueueFileData(writeSpot).RelTimeSecs = posixtime(APData{2});
                hcQueueFileData(writeSpot).HalfCompositeImage = APData{3};
                % TODO: Ensure data is not lost!
            elseif isempty(APData)
                continue;
            end
            if queueNotEmpty
                dpIdx = hcQueueFileData(readSpot).DatapointIndex;
                if dpIdx == 0
                    % TODO
                    continue;
                else
                    relTimeSecs = datetime(hcQueueFileData(readSpot).RelTimeSecs, 'ConvertFrom', 'posixtime');
                    hcImg = hcQueueFileData(readSpot).HalfCompositeImage;
                    APData = {dpIdx, relTimeSecs, hcImg};
                end
                % APdata: {isReanalysis, index, timePos, HC1, HC2}
                % APData= {false, dpIdx, datetime(relTimeSecs, ,'ConvertFrom', 'posixtime'), hcData};
            elseif ~pollSuccess
                continue;
            end
            if APData{1} && ~isempty(prevHCimg)
                datapointTimePos = mean([prevHCtimeRange(1) APData{2}(2)]);
                send(finishedQueue, APData{1});
                fprintf('pollAPQ1: Sending to APQueue2.\n');
                send(apQueue2, {false, APData{1}, datapointTimePos, ...
                    prevHCimg, APData{3}});
                fprintf('pollAPQ1: Sent to APQueue2.\n');
            end
            prevHCtimeRange = APData{2};
            prevHCimg = APData{3};
        end
    end

    function HCFcn0(obj, HCData)
        
    end

    function HCFcn(obj, HCdata)
    end

    function HCFcn1(obj, HCdata)
        persistent prevHCimg prevHCtimeRange;
        % HCdata: {datapointIndex, HCtimeRange, frames}
        [datapointIndex, timeRange, frames] = HCdata{:};
        if iscell(frames)
            frames = cat(3, frames{:});
        end
        HC = (sbsense.improc.makeHalfComposite(fix(2\obj.fph),frames));
        if(datapointIndex && ~isempty(prevHCimg))
            datapointTimePos = mean([prevHCtimeRange(1) timeRange(2)]);
            % fprintf('[HCFcn] (Index: %d) Previous range: [%s %s]\n', ...
            %     datapointIndex, ...
            %     string(prevHCtimeRange(1), 'HH:mm:ss.SSSS'), ...
            %     string(prevHCtimeRange(2), 'HH:mm:ss.SSSS'));
            % fprintf('[HCFcn] (Index: %d) Received range: [%s %s]\n', ...
            %     datapointIndex, ...
            %     string(timeRange(1), 'HH:mm:ss.SSSS'), ...
            %     string(timeRange(2), 'HH:mm:ss.SSSS'));
            % fprintf('[HCFcn] Mean of %s and %s = %s\n', ...
            %     string(prevHCtimeRange(1), 'HH:mm:ss.SSSS'), ...
            %     string(timeRange(2), 'HH:mm:ss.SSSS'), ...
            %     string(datapointTimePos, 'HH:mm:sss.SSSS'));
            %     %prevHCtimeRange(1) + ...
            %     %0.5*(timeRange(2) - prevHCtimeRange(1));
            send(obj.FinishedQueue, datapointIndex);
            send(obj.APQueue, ...
                {false, datapointIndex, datapointTimePos, prevHCimg, HC});
            % APdata: {isReanalysis, index, timePos, HC1, HC2}
        end
        prevHCtimeRange = timeRange;
        prevHCimg = HC;
    end

    function APFcn(obj, APdata)
        % fprintf('Received APdata: %s', formattedDisplayText(APdata));
        if ~APdata{1} % isReanalysis 
            sbsense.improc.analyzeHCsParallel(obj, obj.AnalysisParams, ...
                [obj.PSBL obj.PSBR], ...
                APdata{:}, obj.LastParams);
            return;
        end
        try
            res = sbsense.improc.analyzeHCsParallel(obj, obj.AnalysisParams, ...
                [obj.PSBL obj.PSBR], ...
                APdata{:}, obj.LastParams); % APdata: {isReanalysis, index, timePos, HC1, HC2})
        catch ME
            fprintf('[APFcn] Error "%s" occurred while calling analyzeHCsParallel: %s\n', ...
                ME.identifier, getReport(ME));
            res = ME;
        end

        
        % display(res);
        if isstruct(res) && isfield(res, 'SuccessCode') && res.SuccessCode && isfield(res, 'EstParams')
            obj.LastParams = res.EstParams;
        end
        send(obj.ResQueue, res);
        
        % % TODO: Rework this to eliminate redundant arguments
        % futs = sbsense.improc.analyzeHCsParallel(obj, obj.AnalysisParams, ...
        %     [obj.PSBL obj.PSBR], APdata{:});
    end

    function postset_psb(obj, ~, ~)
        obj.PSBWidth = obj.PSBR - obj.PSBL - 1;
        obj.ChHorzIdxs = obj.PSBL:obj.PSBR;
    end
end

methods(Access=private)
    function clearFuture(obj, fut)
        try
            % if ~obj.FinishedQueue.QueueLength
            %     fprintf('[clearFuture] FinishedQueue is unexpectedly empty!\n');
            % else
            %     poll(obj.FinishedQueue);
            % end
            
            if ~isempty(fut.Error)
                if (fut.Error.identifier ~= "parallel:fevalqueue:ExecutionCancelled")
                    fprintf('[APFcn>clearFuture] fut.Error "%s": %s\n', ...
                        fut.Error.identifier, getReport(fut.Error));
                        %celldisp(fut.Error.stack);
                end
                return;
            elseif isempty(fut.OutputArguments)
                fprintf('[APFcn>clearFuture] OutputArguments is unexpectedly empty!\n');
                return;
            elseif ~isempty(fut.OutputArguments{1})
                if isstruct(fut.OutputArguments{1})
                    send(obj.ResQueue, fut.OutputArguments{1});
                elseif isa(fut.OutputArguments{1}, 'MException')
                    fprintf('[APFcn>clearFuture] res=error "%s": %s\n', ...
                        fut.OutputArguments{1}.identifier, ...
                        getReport(fut.OutputArguments{1}));
                end
            end
            % obj.AnalysisFutures(obj.AnalysisFutures==fut) = [];
        catch ME
            fprintf('[clearFuture] Error "%s": %s\n', ...
                ME.identifier, getReport(ME));
            % display(fut.Error);
            % obj.AnalysisFutures(obj.AnalysisFutures==fut) = [];
            % rethrow(ME);
        end
        obj.AnalysisFutures(obj.AnalysisFutures==fut) = [];
    end
end

methods
    function set.LastParams(obj, value)
        if isempty(value) || anynan(value) || ~allfinite(value)
            obj.LastParams = double.empty();
        else
            obj.LastParams = value;
        end
    end
end
end