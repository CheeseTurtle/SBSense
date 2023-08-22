function onAcquisitionTimer(tobj, event)
    if tobj.TasksExecuted < 2
        fprintf('Triggers executed: %d\n', vobj.TriggersExecuted);
        fprintf('Initial trigger time: %s\n', ...
            formattedDisplayText(datetime(tobj.StartDateTime)));
        send(tobj.UserData.resQueue, datetime(tobj.StartDateTime));
    end
    
    [frames, ~, metadata] = getdata(tobj.UserData); % TODO?
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
end