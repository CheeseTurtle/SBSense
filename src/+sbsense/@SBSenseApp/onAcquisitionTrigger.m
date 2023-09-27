function onAcquisitionTrigger(vobj, event)
    % if vobj.TriggerType=="manual" % usingTimer is true
    %     datapointIndex = 
    %     if vobj.TriggersExecuted < 2
    %         fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
    %         fprintf('Initial trigger time: %s\n', ...
    %             string(datetime(vobj.InitialTriggerTime), 'HH:mm:ss.SSSS'));
    %         send(vobj.UserData.resQueue, datetime(vobj.InitialTriggerTime));
    %         return;
    %     end
    % else % usingTimer is false
    %     if vobj.TriggersExecuted < 2
    %         fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
    %         fprintf('Initial trigger time: %s\n', ...
    %             string(datetime(vobj.InitialTriggerTime), 'HH:mm:ss.SSSS'));
    %         send(vobj.UserData.resQueue, datetime(vobj.InitialTriggerTime));
    %         return;
    %     end
    % end
    persistent fail;
    if ~isrunning(vobj)
        fprintf('vobj not running. Exiting.\n');
        flushdata(vobj);
        return;
    end
    if vobj.TriggersExecuted < 2
        fprintf('vobj triggers executed, Trigger index: %d, %d\n', ...
            vobj.TriggersExecuted, event.Data.TriggerIndex);
        fprintf('Initial trigger time, AbsTime: %s, %s\n', ...
            string(datetime(vobj.InitialTriggerTime), "HH:mm:ss.SSSS"), ...
            string(datetime(event.Data.AbsTime), "HH:mm:ss.SSSS"));
        if event.Type == "Timer"
            fprintf('Timer event executed. vobj.TriggersExecuted: %d\n', ...
                vobj.TriggersExecuted);
            datapointIndex = vobj.TriggersExecuted - 1;
        else
            fprintf('Non-timer event executed. vobj.TriggersExecuted, event.Data.TriggerIndex: %d, %d\n', ...
                vobj.TriggersExecuted, event.Data.TriggerIndex);
            fprintf('Initial trigger time, AbsTime: %s, %s\n', ...
                string(datetime(vobj.InitialTriggerTime), 'HH:mm:ss.SSSS'), ...
                string(datetime(event.Data.AbsTime), 'HH:mm:ss.SSSS'));
            datapointIndex = event.Data.TriggerIndex - 1;
            % AbsTime: [2023 3 7 8 43 58.6962]
            % FrameNumber: 0
            % RelativeFrame: 0
            % TriggerIndex: 1
        end
%         sentTime = false;
%         for i=1:6
%             intlTrigTime = vobj.InitialTriggerTime;
%             if isvector(intlTrigTime) && (event.Data.AbsTime(i) < intlTrigTime(i))
%                 send(vobj.UserData.resQueue, datetime(event.Data.AbsTime));
%                 i = 0;
%                 break;
%             end
%         end
%         if i
            send(getfield(vobj.UserData,'resQueue'), datetime(vobj.InitialTriggerTime));
            fprintf('Datapoint index (initial HC): %d\n', datapointIndex);
        % end
    elseif event.Type=="Timer"
        datapointIndex = vobj.TriggersExecuted - 1;
        str = sprintf('(Timer event @ %s) Datapoint index = vobj.TriggersExecuted-1 = %g\n', ...
            string(datetime(event.Data.AbsTime), 'HH:mm:ss.SSSS'), datapointIndex);
        fprintf('%s', str);
        display(event.Data);
    else
        datapointIndex = event.Data.TriggerIndex - 1;
        str = fprintf('(Non-timer event %s) Datapoint index = event.Data.TriggerIndex-1 = %g (vobj.TriggersExecuted: %g)\n', ...
            string(datetime(event.Data.AbsTime), 'HH:mm:ss.SSSS'), datapointIndex, vobj.TriggersExecuted);
        fprintf('%s', str);
    end
    
    try
        [frames, ~, metadata] = getdata(vobj);
    catch ME1
        if strcmp(ME1.identifier, "imaq:getdata:timeout")
            try
                start(vobj);
            catch ME
                fprintf('[onAcquisitionTrigger] Could not restart vobj after timeout due to error "%s": %s\n',
                    ME.identifier, getReport(ME));
            end
            if(isempty(fail))
                fail = 1;
            elseif(fail > 5)
                fail = []; % TODO: Yes? No?
                rethrow(ME1);
            else
                fail = fail + 1;
            end
            return;
        else
            fprintf('[onAcquisitionTrigger] Error "%s" occurred when calling getdata(vobj): %s\n', ...
                ME1.identifier, getReport(ME1));
            rethrow(ME1);
        end
    end
    try
        % flushdata(vobj,'triggers');
        fprintf('[onAcquisitionTrigger] Flushed data.\n');
    catch ME1
        fprintf(['[onAcquisitionTrigger] Unable to flushdata due to error "%s": %s\n', ME1.identifier, getReport(ME1)]);
    end
    HCtimeRange = [ datetime(metadata(1).AbsTime), ...
        datetime(metadata(end).AbsTime) ];
    
    if(vobj.NumberOfBands > 1)
        frames = frames(:,:,1,:);
        frames = squeeze(frames);
    elseif(ndims(frames) > 3)
        frames = squeeze(frames);
    end
    if isempty(frames)
        val = false;
    else
        val = any(any(frames));
    end
    str = string(datetime(event.Data.AbsTime), "HH:mm:ss.SSSS");
    % disp({datapointIndex,logical(val), str});
    str = sprintf('[onAcquisitionTrigger] (%g, ev @ %s) Sending HCData to HCQueue (any(frames)=%d):\n',...
        datapointIndex, strtrim(formattedDisplayText(str, 'SuppressMarkup', true)), logical(val));
    fprintf('%s', str);
    % disp({uint64(datapointIndex), HCtimeRange, frames});
    send(getfield(vobj.UserData, 'HCQueue'),...
        {uint64(datapointIndex), HCtimeRange, frames});
    clearvars frames;
end