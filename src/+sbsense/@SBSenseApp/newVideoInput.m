function [vobj, vsrc,TF] = newVideoInput(vformat, vobj, vsrc, varargin)
%arguments(Input)
%    vformat; vobj; vsrc = getselectedsource(vobj); vinfo = imaqhwinfo(vobj);
%end
%arguments(Input,Repeating)
%    varargin;
%end
%if ~isstruct(vinfo)
%    vals = {vinfo, vsrc};
%    clear vinfo vsrc;
%    [vsrc, vinfo] = vals{:};
%end

%try
if isempty(varargin) || ~mod(length(varargin), 2)
    aName = 'winvideo';
else
    aName = varargin{1};
    varargin(1) = [];
end


%if isstruct(vsrc)
%    vsrc_propnames = fieldnames(vsrc);
%    vsrc_propvals = cellfun(@(x) vsrc.(x), vsrc_propnames, ...
%        'UniformOutput', false);
%else
props = propinfo(vsrc);
msk = cellfun(@(x) x.ReadOnly~="always", struct2cell(props));
vsrc_propnames = fieldnames(props);
vsrc_propnames = vsrc_propnames(msk);
vsrc_propnames = vsrc_propnames(cellfun(@(name) ~strcmp(name, 'FrameRate'), vsrc_propnames));
vsrc_propvals  = cellfun(@(x) get(vsrc,x), vsrc_propnames, ...
    'UniformOutput', false);
%end
vsrc_propargs = reshape(horzcat(vsrc_propnames, ...
    vsrc_propvals)', 1, []);

%props = propinfo(vobj);
%msk = cellfun(@(x) x.ReadOnly~="always", struct2cell(props));
%vobj_propnames = fieldnames(props);
%vobj_propnames = vobj_propnames(msk);
%vobj_propnames = setdiff(vobj_propnames, ...
%    {'SelectedSourceName', 'ROIPosition', })
%vobj_propnames = {'Timeout', 'Tag'
%vobj_propvals  = cellfun(@(x) get(vobj,x), vobj_propnames, ...
%    'UniformOutput', false);
%vobj_propargs = reshape(horzcat(vobj_propnames, ...
%    vobj_propvals)', 1, []);

%try
adaptorName = aName; %vinfo.AdaptorName; %imaqhwinfo(vobj).AdaptorName;
%catch ME
%    %display(imaqhwinfo(vobj));
%    %display(imaqhwinfo(vobj).AdaptorName);
%    display(vsrc);
%    display(vinfo);
%    display(vinfo.AdaptorName);
%    rethrow(ME);
%end
if isscalar(vobj) && isa(vobj, 'videoinput') && isvalid(vobj)
    stop(vobj); 
    wait(vobj, 15, 'running'); % TODO: Wait timeout, ask to keep waiting
    wait(vobj, 15, 'logging');
    deviceID    = vobj.DeviceID;
    delete(vobj);
else
    deviceID = 1;
end
% [deviceID,startFcn,stopFcn,timerFcn,trigFcn, acqFcn, ...
%    timerPeriod, fptrig, fpacq, fpacqfun, trigrep, timeout, ...
%    logmode]
%vobj_propnames = {'StartFcn', 'StopFcn', 'TimerFcn', 'TriggerFcn', ...
%    'FramesAcquiredFcn', 'FrameGrabInterval', 'FramesAcquiredFcnCount', ...
%    'FramesPerTrigger', 'TriggerRepeat', 'TimerPeriod'};
% Doesn't include TriggerFrameDelay or UserData
%vobj_propvals = get(vobj, vobj_propnames);
%vobj_propargs = reshape(vertcat(vobj_propnames,vobj_propvals),1,[]);
try
%     disp(class(vformat));
%     display(vformat);
%     vformat = cellstr(vformat);
%     vformat = vformat{1};
disp(varargin);
    vobj = videoinput(adaptorName, deviceID, vformat, ...
        ...%vobj_propargs{:}, ...
        varargin{:});
    vsrc = getselectedsource(vobj);
    set(vsrc, vsrc_propargs{:});
    if logical(vobj.FramesAcquiredFcnCount)
        triggerconfig(vobj, "immediate");
    else
        triggerconfig(vobj, "manual");
    end
    %triggerconfig(vobj, "immediate");

    % triggerconfig(vobj, 'manual');
    TF = true;
catch ME % TODO
    fprintf('Error occurred while creating new videoinput object: (%s) %s', ...
        ME.identifier, ME.message);
    fprintf('Error report: %s\n', getReport(ME));
    TF = false; vobj = []; vsrc = [];
end
end