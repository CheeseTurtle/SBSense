function [devnames, devinfos] = getAvailableInputDevices()
adaptorNames = string(imaqhwinfo().InstalledAdaptors);
if isempty(adaptorNames)
    devnames = {};
    devinfos = {};
else
    numAdaptors = length(adaptorNames);
    if numAdaptors > 1
        ais = arrayfun(@(name) imaqhwinfo(name), adaptorNames, ...
            "UniformOutput", true);
        ids = ais.DeviceIDs;
        ids = cell2mat([ids{:}]);
    else
        ais = imaqhwinfo(adaptorNames);
        ids = cell2mat(ais.DeviceIDs);
    end
    numDevices = length(ids);
    devnames = cell(1,numDevices);%strings(1,numDevices);
    devinfos = devnames; %struct.empty(0,numDevices);
    i = 1;
    for adapnum = 1:numAdaptors
        ai = ais(adapnum);
        for devinfo=ai.DeviceInfo
            devinfo.("AdaptorName") = adaptorNames(adapnum);
            devinfos{i} = devinfo;
            devnames{i} = devinfo.DeviceName;
            i = i+1;
        end
    end
end
end