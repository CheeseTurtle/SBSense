function [minTicks,majTicks,majLabels] = generateRulerTicks(timeZero, axisModeIndex, ~, rulerLims, minUnit, majUnitInfo)
    % genMinTick = ~isempty(minUnit); % nargin>4;
    numericMode = ~bitget(axisModeIndex,2); % axisModeIndex == 1
    
    % if timeMode % && (majUnitInfo{2}==NaN)
    %     minUnit = seconds(minUnit);
    %     majUnit = seconds(majUnitInfo{1});
    % else
    %     majUnit = majUnitInfo{1};
    % end
        

    if numericMode
        minTicks = colonspace1([0.01, 0.5], rulerLims(1),uint64(minUnit),rulerLims(2));
        if isempty(majUnitInfo)
            return;
        end
        majTicks = colonspace1([0.1 0.5], rulerLims(1),uint64(majUnitInfo{1}),rulerLims(2));
        if length(majTicks) > 10
            ivl = ceil(10\length(majTicks));
            idxs = colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = compose(majUnitInfo{3}, majTicks);
    elseif iscell(majUnitInfo) && ~isnan(majUnitInfo{2}) && startsWith(majUnitInfo{4},'%')
        minTicks = timecolonspace1([0.01, 0.5], rulerLims(1),seconds(minUnit),rulerLims(2));
        if isempty(majUnitInfo)
            return;
        end
%         if ~bitget(axisModeIndex,1) % absolute time
%             soh = dateshift(rulerLims(1), 'start', 'hour');
%             rulerLims = rulerLims - soh; % datetime to duration
%         else
%             soh = seconds(0);
%         end
        majTicks = timecolonspace1([0.1 0.5], rulerLims(1),seconds(majUnitInfo{1}),rulerLims(2));
        if length(majTicks) > 10
            ivl = ceil(10\length(majTicks));
            idxs = colonspace(1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        if ~bitget(axisModeIndex,1) % absolute time
            majLabels = seconds(majTicks - timeZero); % datetime to duration
        else
            majLabels = seconds(majTicks);
        end
        majLabels = compose(majUnitInfo{4}, majLabels);
    else % Time mode (absolute or relative)
        minUnit = seconds(minUnit);
        if ~isempty(majUnitInfo)
            majUnit = seconds(majUnitInfo{1});
        end
        if bitand(axisModeIndex,1) % Relative time
            minTicks = colonspace1([0.01, 0.5], rulerLims(1),minUnit,rulerLims(2));
            if isempty(majUnitInfo)
                return;
            end
            majTicks = colonspace1([0.1 0.5], rulerLims(1),majUnit,rulerLims(2));
        else % Absolute time
            minTicks = timecolonspace1([0.01, 0.5], rulerLims(1),minUnit,rulerLims(2));
            if isempty(majUnitInfo)
                return;
            end
            majTicks = timecolonspace1([0.1 0.5], rulerLims(1),majUnit,rulerLims(2));
        end
        if length(majTicks) > 10
            ivl = ceil(10\length(majTicks));
            idxs = colonspace1([0.08 0.5], 1,ivl,length(majTicks));
            majTicks = majTicks(idxs);
        end
        majLabels = string(majTicks, majUnitInfo{3});
    end
end