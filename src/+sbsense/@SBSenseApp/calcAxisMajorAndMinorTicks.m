function [minTicks,majTicks,majLabels] = calcAxisMajorAndMinorTicks(modeIndex, zoomModeOn, resUnit, lims, varargin)
    if modeIndex ~= 1
        resUnit = seconds(resUnit);
    end
    minTicks = colonspace(lims(1),resUnit,lims(2));
    if ((nargin > 4) && varargin{1})
        [majUnit, majFormat, sfac] = chooseMajorResUnit(modeIndex, resUnit);
        if modeIndex ~= 1
            majUnit = seconds(majUnit);
        end
        majTicks = colonspace(lims(1), majUnit, lims(2));
        if sfac ~= 1
            majLabels = sfac\majTicks;
        else
            majLabels = majTicks;
        end
        majLabels = compose(majFormat, majLabels);
    else
        majTicks = []; majLabels = '';
    end
end