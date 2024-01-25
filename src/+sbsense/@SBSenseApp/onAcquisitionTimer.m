function onAcquisitionTimer(tobj, event)
    persistent fail;
    if tobj.TasksExecuted < 2
        fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
        fprintf('Initial trigger time: %s\n', ...
            formattedDisplayText(datetime(tobj.StartDateTime)));
        send(tobj.UserData.resQueue, datetime(tobj.StartDateTime));
    end
    
    try
        [frames, ~, metadata] = getdata(tobj.UserData);
    catch ME1
        if strcmp(ME1.identifier, "imaq:getdata:timeout")
            try
                % Must attempt restart!
                start(tobj.UserData);
            catch ME
                fprintf('[onAcquisitionTimer] Could not restart vobj after timeout due to error "%s": %s\n', ...
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
            fprintf('[onAcquisitionTrigger] Non-timeout error "%s" occurred when calling getdata(vobj): %s\n', ...
                ME1.identifier, getReport(ME1));
            rethrow(ME1);
        end
    end
    try
        % flushdata(tobj.UserData, 'triggers');
        fprintf('[onAcquisitionTimer] Flushed data.\n');
    catch ME1
        fprintf(['[onAcquisitionTimer] Unable to flushdata due to error "%s": %s\n', ME1.identifier, getReport(ME1)]);
    end
    HCtimeRange = [datetime(metadata(1).AbsTime), ...
        datetime(metadata(end).AbsTime) ];
    
    if(vobj.NumberOfBands > 1)
        frames = frames(:,:,1,:);
        frames = squeeze(frames);
    elseif(ndims(frames) > 3)
        frames = squeeze(frames);
    end
    send(vobj.UserData.HCqueue,...
        {event.Data.TriggerIndex-1, HCtimeRange, frames});
    clearvars frames;
end