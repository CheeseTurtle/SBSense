classdef Analyzer < handle & matlab.mixin.SetGetExactNames
properties(GetAccess=public,SetAccess=private,Transient)
    APQueue parallel.pool.DataQueue;
    ResQueue parallel.pool.DataQueue;
    FinishedQueue parallel.pool.PollableDataQueue;

    APQueue2 parallel.pool.PollableDataQueue;
    APTimer timer;
% end
% properties(SetAccess=private,GetAccess=public,Transient)
    HCQueue parallel.pool.DataQueue;
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

        obj.APQueue = parallel.pool.DataQueue();
        % afterEach(obj.APQueue, @obj.APFcn);
        afterEach(obj.APQueue, @(x) send(obj.APQueue2, x));
        obj.HCQueue = parallel.pool.DataQueue();
        afterEach(obj.HCQueue, @obj.HCFcn);
        obj.FinishedQueue = parallel.pool.PollableDataQueue();

        addlistener(obj, {'PSBL', 'PSBR'}, 'PostSet', @obj.postset_psb);
    end

    % (BGimg), (NumChs)
    function initialize(obj, dpIdx0, resQueue, varargin) % varargin: BGimg, numChannels, analysisScale
        fprintf('[Analyzer:initialize]\n');
        obj.ResQueue = resQueue;
        obj.APTimer = timer('BusyMode', 'drop', 'ExecutionMode', 'fixedSpacing', 'Period', 0.050, ...
            'TimerFcn', @(tobj,~) pollAPQueue(obj,tobj), 'ErrorFcn', {@obj.onAPTimerError}, 'Name', 'AnalysisQueueTimer');
        obj.APQueue2 = parallel.pool.PollableDataQueue();
        initialize(obj.AnalysisParams, dpIdx0, varargin{:});
    end

    function onAPTimerError(~, tobj, ev) % ev.Type is 'ErrorFcn'
        fprintf('APTimer encountered an error:'); display(ev.Data);
        tobj.UserData = true;
        stop(tobj); % TODO: Also stop recording??
    end

    function prepareReanalysis(obj, varargin)
        obj.LastParams = [];
        obj.APTimer.UserData = false;
        prepareReanalysis(obj.AnalysisParams, varargin{:});
    end

    function TF = pollAPQueue(obj,varargin)
        if nargin > 1
            tobj = varargin{1};
            if isequal(tobj.UserData, true)
                if tobj.Running(2)=='n'
                    fprintf('[pollAPqueue] #### APTimer UserData is true (APTimer should stop) #### \n');
                    stop(tobj);
                end
                return;
            end
        else
            tobj = [];
        end
        [APdata,TF] = poll(obj.APQueue2); % TODO: poll timeout?
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
        obj.LogFile = fopen("SBSense_log.txt", "a");
        obj.ResQueue = resQueue;
        obj.fph = fph;
        obj.LastParams = [];
        if isa(obj.HCQueue, 'parallel.pool.DataQueue') && ...
            (~isvalid(obj.HCQueue) || obj.HCQueue.QueueLength) % TODO: Name of prop??
            delete(obj.HCQueue);
            obj.HCQueue = parallel.pool.DataQueue();
            afterEach(obj.HCQueue, @obj.HCFcn);
        end
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
        if isa(obj.APQueue, 'parallel.pool.DataQueue') && ...
            (~isvalid(obj.APQueue) || obj.APQueue.QueueLength) % TODO: Name of prop??
            delete(obj.APQueue);
            obj.APQueue = parallel.pool.DataQueue();
            % afterEach(obj.APQueue, @obj.APFcn);
            afterEach(obj.APQueue, @(x) send(obj.APQueue2, x));
            % afterEach(obj.APQueue, @(APdata) obj.APQueueFcn(APdata));
        end
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
    function HCFcn(obj, HCdata)
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