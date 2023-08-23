function onAcquisitionTimer(tobj, event)
    if tobj.TasksExecuted < 2
        fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
        fprintf('Initial trigger time: %s\n', ...
            formattedDisplayText(datetime(tobj.StartDateTime)));
        send(tobj.UserData.resQueue, datetime(tobj.StartDateTime));
    end
    
    [frames, ~, metadata] = getdata(tobj.UserData); % TODO: TRY/CATCH
    try
        flushdata(tobj.UserData);
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