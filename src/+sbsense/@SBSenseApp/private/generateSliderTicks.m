function [minTicks,majTicks,majLabels] = generateSliderTicks(timeZero, axisModeIndex, zoomModeOn, sliderLims, minUnit, majUnitInfo)
    %genMinTick = ~isempty(minUnit); %nargin>4;
    timeMode = bitget(axisModeIndex,2); % axisModeIndex ~= 1

    % If NUMERIC, slider lims are always just in terms of NUM. DATAPOINTS
    % If ABS. TIME and PAN MODE, slider lims are in terms of SECS SINCE TIMEZERO
    %     and should be labeled at (maj) intervals RELATIVE TO THE HOUR (and always include beg/end?)
    % If ABS TIME and and ZOOM MODE, or REL TIME and either mode, slider lims are in terms of NUM. SECONDS
    %     and should be labeled at (maj) intervals relative to zero, using TIME FORMAT --unless sfac is not 1.
    % ==> ORDER OF CONDITIONS: If (numeric or sfac~=1), elseif (pan mode and abs time), else ...

    if ~timeMode
        minTicks = sbsense.utils.colonspace1([0.05, 0.5], sliderLims(1),double(minUnit),sliderLims(2));    
        if isempty(majUnitInfo)
            return;
        end
        majTicks = sbsense.utils.colonspace1([0.15 0.65], sliderLims(1),majUnitInfo{1},sliderLims(2));
        if length(majTicks) > 4
            ivl = ceil(4\length(majTicks));
            idxs = sbsense.utils.colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = compose(majUnitInfo{4}, (majUnitInfo{2})\majTicks);
    elseif ~zoomModeOn && ~bitand(axisModeIndex,1) % Absolute time + pan mode
        sliderLims = seconds(sliderLims); % Convert from numeric to duration
        minTicks = seconds(sbsense.utils.timecolonspace1([0.05, 0.5], sliderLims(1),seconds(minUnit),sliderLims(2)));
        if isempty(majUnitInfo)
            return;
        end
        majTicks = sbsense.utils.timecolonspace1([0.15 0.65], sliderLims(1),seconds(majUnitInfo{1}),sliderLims(2));
        if length(majTicks) > 4
            ivl = ceil(4\length(majTicks));
            idxs = sbsense.utils.colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = string(majTicks+timeZero, majUnitInfo{3});
        majTicks = seconds(majTicks); % Convert from duration to numeric
   elseif iscell(majUnitInfo) && ~isnan(majUnitInfo{2}) && startsWith(majUnitInfo{4},'%') % && zoomModeOn
        minTicks = sbsense.utils.colonspace1([0.05, 0.5], sliderLims(1),double(minUnit),sliderLims(2));
        if isempty(majUnitInfo)
            return;
        end
        majTicks = sbsense.utils.colonspace1([0.15 0.65], sliderLims(1),majUnitInfo{1},sliderLims(2));
        if length(majTicks) > 4
            ivl = ceil(4\length(majTicks));
            idxs = sbsense.utils.colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = compose(majUnitInfo{4}, majTicks/(majUnitInfo{2}));
    else % abs time + zoom mode, or rel time + pan/zoom
        sliderLims = seconds(sliderLims);
        minTicks = seconds(sbsense.utils.timecolonspace1([0.05, 0.5], sliderLims(1),seconds(minUnit),sliderLims(2)));
        if isempty(majUnitInfo)
            return;
        end
        majTicks = sbsense.utils.timecolonspace1([0.15 0.65], sliderLims(1),seconds(majUnitInfo{1}),sliderLims(2));
        if length(majTicks) > 4
            ivl = ceil(4\length(majTicks));
            idxs = sbsense.utils.colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = string(majTicks, majUnitInfo{3+zoomModeOn});
        majTicks = seconds(majTicks); % Convert from duration to numeric
    end
end