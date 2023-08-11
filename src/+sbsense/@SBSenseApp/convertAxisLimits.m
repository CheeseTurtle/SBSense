function [dom, idxs] = convertAxisLimits(timeZero, dataTable, lims, oldModeIndex, newModeIndex, rightmostPos, minDomWd)
if bitget(newModeIndex, 2)
    toTimeMode = true;
    toAbsMode = ~bitget(newModeIndex, 1);
    varName = "RelTime";
else
    toTimeMode = false;
    toAbsMode = false;
    varName = "Index";
end

if isempty(dataTable) || isempty(dataTable{1}) || isempty(dataTable{2}) || (newModeIndex==2 && rightmostPos<=timeZero) || (~isdatetime(rightmostPos) && (rightmostPos<=0))
    switch newModeIndex
        case 1
            dom = [1 minDomWd];
        case 2
            dom = [timeZero timeZero+minDomwd];
        otherwise
            dom = [ seconds(0) minDomWd ];
    end
    idxs = [1 1]; % ??
    fprintf('[convertAxisLimits] NOTE: zero rightmostPos or empty table!\n');
    return;
end

if bitget(oldModeIndex, 2) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% From time mode
    % fromTimeMode = true;
    fromAbsMode = ~bitget(oldModeIndex, 1);
    if fromAbsMode
        lims = lims - timeZero;
    end
    trng = timerange(lims(1), lims(2), 'closed');
    times = dataTable{2}.RelTime(trng);
    if isempty(times)
        % dom = dataTable{2}.(varName)([1 end]);
        dom = dataTable{1}{[1 end], varName};
        idxs = dataTable{2}{[1 end], 'Index'};
        if ~isempty(dom)
            dom = dom([1 end]);
        end
    else
        dom = times([1 end])';
        idxs = dataTable{2}{dom, 'Index'};
    end
    if toAbsMode
        dom = dom + timeZero;
    elseif ~toTimeMode
        dom = idxs;
    end
else %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% From index mode
    % fromTimeMode = false;
    % fromAbsMode = false;
    lims = min(lims, size(dataTable{1},1));
    if lims(1)>=lims(2)
        lims(1) = 1;
    end
    if lims(1)>=lims(2)
        dom = [];
    else
        try
            dom = dataTable{1}{lims, varName};
            if toTimeMode
                idxs = lims;
                if toAbsMode
                    dom = dom + timeZero;
                end
            else
                idxs = dom;
            end
        catch ME
            fprintf('[convertAxes] Error occurred while converting from index mode to non-index mode: %s\n', ...
                getReport(ME));
            dom = [];
        end
    end
end

if isempty(dom) || isscalar(dom) || (dom(1) >= dom(2))
    switch newModeIndex
        case 1
            dom = [1 minDomWd];
            idxs = dom; % ??
        case 2
            dom = [timeZero timeZero+minDomWd];
            dom.Format = 'MM/dd HH:mm:ss.SSSS';
            idxs = [1 5];
        otherwise
            dom = [ seconds(0) minDomWd ];
            dom.Format = 's';
            idxs = [1 5];
    end
    fprintf('[convertAxisLimits] dom empty!\n');
    return;
end

if dom(2) > rightmostPos
    dom(2) = rightmostPos;
end
if dom(1) >= dom(2)
    if bitget(newModeIndex, 2) % time mode
        if bitget(newModeIndex, 1) % relative
            dom(1) = seconds(0);
            dom.Format = 's';
        else % absolute
            dom(1) = timeZero; % TODO: Handle NaN??
            dom.Format = 'MM/dd HH:mm:ss.SSSS';
        end
    else % index mode
        dom(1) = 1;
    end
    if dom(1) >= dom(2)
        dom(2) = dom(1) + minDomWd;
    end
elseif newModeIndex==2
    dom.Format = 'MM/dd HH:mm:ss.SSSS';
elseif newModeIndex==3
    dom.Format = 's';
end

% fprintf('[convertAxisLimits] Success!\n');

end