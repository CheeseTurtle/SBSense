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
    if vobj.TriggersExecuted < 2
        fprintf('Triggers executed, Trigger index: %d, %d\n', ...
            vobj.TriggersExecuted, event.Data.TriggerIndex);
        fprintf('Initial trigger time, AbsTime: %s, %s\n', ...
            string(datetime(vobj.InitialTriggerTime), 'HH:mm:ss.SSSS'), ...
            string(datetime(event.Data.AbsTime), 'HH:mm:ss.SSSS'));
        if event.Type == "Timer"
            fprintf('Triggers executed: %d\n', ...
                vobj.TriggersExecuted);
            datapointIndex = vobj.TriggersExecuted - 1;
        else
            fprintf('Triggers executed, Trigger index: %d, %d\n', ...
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
        % end
    else
        datapointIndex = event.Data.TriggerIndex - 1;
    end
    try
        [frames, ~, metadata] = getdata(vobj);
    catch ME1
        if strcmp(ME1.identifier, "imaq:getdata:timeout")
            return;
        else
            fprintf('[onAcquisitionTrigger] Error "%s" occurred when calling getdata(vobj): %s\n', ...
                ME1.identifier, getReport(ME1));
            rethrow(ME1);
        end
    end
    HCtimeRange = [ datetime(metadata(1).AbsTime), ...
        datetime(metadata(end).AbsTime) ];
    
    if(vobj.NumberOfBands > 1)
        frames = frames(:,:,1,:);
        frames = squeeze(frames);
    elseif(ndims(frames) > 3)
        frames = squeeze(frames);
    end
    send(getfield(vobj.UserData, 'HCQueue'),...
        {datapointIndex, HCtimeRange, frames});
end