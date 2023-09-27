function [vobj, vsrc,TF] = recreateVideoInput(vobj)


% vobj.DeviceID (int?) -- ex. 1
% vobj.Name (char vector) -- ex. 'MJPG_1280x720-winvideo-1'
% vobj.VideoFormat (char vector) -- ex. 'MJPG_1280x720'
% vobj.VideoResolution (int row vector) -- ex. [1280 720] = [<# col> <# row>]
% vobj.ROIPosition (int row vector) -- ex. [0 0 1280 720]

% Remember vobj.EventLog, vobj.DiskLogger, vobj.DiskLoggerFrameCount

% vinfo (struct):
%   AdaptorName (char vector) -- ex. 'winvideo'
%   DeviceName (char vector) -- ex. 'Integrated Camera', 'USB Camera'
%   MaxHeight (int) -- ex. 720
%   MaxWidth (int) -- ex. 1280
%   NativeDataType (char vector) -- ex. 'uint8'
%   TotalSources (int) -- ex. 1
%   VendorDriverDescription (char vector) -- ex. 'Windows WDM Compatible Driver'
%   VendorDriverVersion (char vector) -- ex. 'DirectX 9.0'

% ainfo (struct):
%   AdaptorDllName (char vector): path to DLL
%                                 ex: 'C:\ProgramData\MATLAB\SupportPackages\R2022b\toolbox\imaq\supportpackages\genericvideo\adaptor\win64\mwwinvideoimaq.dll'
%   AdaptorDllVersion (char vector) -- ex: '6.7 (R2022b)'
%   AdaptorName (char vector) -- ex. 'winvideo'
%   DeviceIDs (cell row vector) -- ex. {[1] [2]}
%   DeviceInfo (struct row vector) -- ex. [1x2 struct]

% DeviceInfo struct:
%   DefaultFormat (char vector) -- ex. 'MJPG_1280x720'
%   DeviceFileSupported (int?) -- ex. 0
%   DeviceName (char vector) -- ex. 'Integrated Camera', 'USB Camera'
%   DeviceID (int?) -- ex. 1
%   VideoInputConstructor (char vector) -- ex. 'videoinput('winvideo', 1)'
%   VideoDeviceConstructor (char vector) -- ex. 'imaq.VideoDevice('winvideo', 1)'
%   SupportedFormats (cell row vector of char vectors) -- ex. {1x18 cell}

% imaq.VideoDevice(<adaptor name>, <device id>) object members:
%   Device (char vector) -- ex. 'Integrated Camera (winvideo-1)'
%   VideoFormat (char vector) -- ex. 'MJPG_1280x720'
%   ROI (int row vector) -- ex. [1 1 1280 720]
%   ReturnedColorSpace (char vector) -- ex. 'rgb'
%   ReturnedDataType (char vector) -- ex. 'single'
%   ReadAllFrames ('on' or 'off') -- ex. 'off'
%   HardwareTriggering ('on' or 'off') -- ex. 'off'
%   DeviceProperties (imaq.internal.DeviceProperties vector) -- ex. [1×1 imaq.internal.DeviceProperties]
%   DeviceFile -- ex. 0x0 char array
%   TriggerConfiguration (char vector) -- ex. 'none/none'
%   step() method
%   clone() method
%   ... and other methods (call methods(vdev))

% Example of imaq.internal.DeviceProperties object properties (console representation) -- differs per device:
%     Device Properties:
%         SourceName: 'input1'
%         BacklightCompensation: 'on'
%         Brightness: 128
%         ColorEnable: 'on'
%         Contrast: 32
%         Exposure: -6
%         ExposureMode: 'auto'
%         FrameRate: '30.0000'
%         Gamma: 120
%         HorizontalFlip: 'off'
%         Hue: 0
%         Pan: 0
%         Roll: 0
%         Saturation: 64
%         Sharpness: 3
%         Tilt: 0
%         VerticalFlip: 'off'
%         WhiteBalance: 4600
%         WhiteBalanceMode: 'auto'
%         Zoom: 100

% Example of console representation of vsrc:
% vsrc = 
%    Display Summary for Video Source Object:
%       General Settings:
%         Parent = [1x1 videoinput]
%         Selected = on
%         SourceName = input1
%         Tag = [0x0 string]
%         Type = videosource
%
%       Device Specific Properties:
%         BacklightCompensation = on
%         Brightness = 128
%         ColorEnable = on
%         Contrast = 32
%         Exposure = -6
%         ExposureMode = auto
%         FrameRate = 30.0000
%         Gamma = 120
%         HorizontalFlip = off
%         Hue = 0
%         Pan = 0
%         Roll = 0
%         Saturation = 64
%         Sharpness = 3
%         Tilt = 0
%         VerticalFlip = off
%         WhiteBalance = 4600
%         WhiteBalanceMode = auto
%         Zoom = 100

% return value of imaqhwinfo() (without args): struct with fields:
%   InstalledAdaptors: {'winvideo'}
%   MATLABVersion: '9.13 (R2022b)'
%   ToolboxName: 'Image Acquisition Toolbox'
%   ToolboxVersion: '6.7 (R2022b)'

if isscalar(vobj) && isa(vobj, 'videoinput') && isvalid(vobj)
    vinfo = imaqhwinfo(vobj);
    vsrc = getselectedsource(vobj);
    %if isempty(varargin) || ~mod(length(varargin),2)
    adaptorName = vinfo.AdaptorName;
    %else
    %    adaptorName = "winvideo";
    %end
    deviceID    = vobj.DeviceID;
    vfullname = vobj.Name;
    devname = vinfo.DeviceName;
    srcname = vsrc.SourceName; % OR: getselectedsource(vobj) or vobj.SelectedSourceName??
    try
        stop(vobj); 
        wait(vobj, 15, 'running'); % TODO: Wait timeout, ask to keep waiting
        wait(vobj, 15, 'logging');
    catch
    end
    try
        delete(vobj);
    catch
    end
else
    fprintf('Cannot recreate device because no valid device was supplied as argument!\n'); % TODO
    TF = false; % CANNOT RECREATE
    return;
    % deviceID = 1; % TODO: What to do??
    % if isempty(varargin) || ~mod(length(varargin), 2)
    %     adaptorName = 'winvideo';
    % else
    %     adaptorName = varargin{1};
    %     varargin(1) = [];
    % end
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
% adaptorName = aName; %vinfo.AdaptorName; %imaqhwinfo(vobj).AdaptorName;
%catch ME
%    %display(imaqhwinfo(vobj));
%    %display(imaqhwinfo(vobj).AdaptorName);
%    display(vsrc);
%    display(vinfo);
%    display(vinfo.AdaptorName);
%    rethrow(ME);
%end


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

    imaqreset();
    imaqmex('feature','-limitPhysicalMemoryUsage',false);
    disp(varargin);

    ainfo = imaqhwinfo(adaptorName);
    deviceID = findDeviceID();

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
    fprintf('Error occurred while recreating videoinput object: (%s) %s', ...
        ME.identifier, ME.message);
    fprintf('Error report: %s\n', getReport(ME));
    TF = false; vobj = []; vsrc = [];
end


function devID = findDeviceID() % TODO: try to use previous device ID first...?
    devnames = {ainfo.DeviceInfo.DeviceName};
    msk = strcmp(devnames, devname);
    if(~any(msk))
        error("Previous device appears to be no longer connected to the computer, or is no longer visible to MATLAB");
    elseif sum(msk, 'all') > 1 % TODO: What to do if there are multiple matches? (ask user to select from list?)
        msk = find(msk, 1);
    end
    devID = ainfo.DeviceIDs{msk};
end
end