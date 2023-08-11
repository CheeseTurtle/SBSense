function [dom, idxs] = convertDomain(timeZero, dataTable, lims, oldModeIndex, newModeIndex, varargin)
%fromNum = isa(ruler, 'matlab.graphics.axis.decorator.NumericRuler');
fromNum = (oldModeIndex==1);
toNum = (newModeIndex==1);
if ~istable(dataTable)
    dataTable = dataTable{2};
end
if fromNum
    lims = max(lims, 1);
    if toNum
        %dom = ruler.Limits;
        dom = lims;
        dom(1) = max(1, dom(1));
        dom(2) = max(dom(1)+1, dom(2));
        if anymissing(dom)
            % TODO
            fprintf('##### [convertDomain] WARNING: MISSING INDEX! ####\n');
        end
        idxs = dom(1):dom(2); %lims(1):lims(2);
        %idxs = ruler.Limits(1):ruler.Limits(2);
        return;
    end
    fromAbs = false;
else
    %fromAbs = isa(ruler, 'matlab.graphics.axis.decorator.DatetimeRuler');
    fromAbs = (oldModeIndex==2);
end
toAbs = (newModeIndex==2);
fprintf('[convertDomain] fromNum: %d, toNum: %d; fromAbs: %d, toAbs: %d\n', ...
    logical(fromNum), logical(toNum), logical(fromAbs), logical(toAbs));
% display(lims);
maxRelTimeIdx = find(~isnan(dataTable.Index), 1, 'last');
if fromNum % from index
    if ~maxRelTimeIdx
        rightmostPos = 1;
    else
        rightmostPos = dataTable.Index(maxRelTimeIdx);
    end
    if lims(1) >= rightmostPos + fix(4\diff(lims))
        lims = lims - (lims(1) - rightmostPos);
    end
    dom = dataTable.RelTime([lims(1) min(size(dataTable,1), lims(2))]);
    if anymissing(dom)
        % TODO
        fprintf('##### [convertDomain] WARNING: MISSING RELTIME! ####\n');
    end
    % display(dom);
    if toAbs
        dom = dom + timeZero;
        %else % neither toNum nor toAbs --> to relative
    end
else % from time (abs or rel)
    if ~logical(maxRelTimeIdx)
        maxRelTime = seconds(1);
    else
        maxRelTime = dataTable.RelTime(maxRelTimeIdx);
    end
    if fromAbs
        rightmostPos = timeZero + maxRelTime;
    else
        rightmostPos = maxRelTime;
    end
    if lims(1) >= (rightmostPos +  0.25*diff(lims))
        dx = lims(1) - rightmostPos;
        lims = lims - dx;
    end
    if toNum
        if fromNum
            dom = lims;
        elseif fromAbs
            dom = lims - timeZero;
        else
            dom = lims;
        end
        trng = timerange(dom(1), dom(2), 'closed');
        idxs = dataTable.Index(trng);
        if isempty(idxs)
            %if isempty(dataTable)
            %    dom = double([1 5]);
            %    idxs = [];
            %else
            dom = dataTable.Index([1 end]);
            idxs = dom;
            %end
        else
            dom = idxs([1 end]);
        end
        if anymissing(dom)
            % TODO
            fprintf('##### [convertDomain] WARNING: MISSING INDEX/INDICES! ####\n');
        end
        dom(1) = max(1, dom(1));
        dom(2) = max(dom(1)+1, dom(2));
    elseif toAbs==fromAbs % abs->abs or rel->rel
        dom = lims;
        if anymissing(dom)
            % TODO
            fprintf('##### [convertDomain] WARNING: MISSING! ####\n');
        end
        if fromAbs
            dom1 = dom - timeZero;
        else
            dom1 = dom;
        end
        trng = timerange(dom1(1), dom1(2), 'closed');
        idxs = dataTable.Index(trng);
        if isempty(idxs)
            idxs = dataTable.Index([1 end]);
            dom = dataTable.RelTime([1 end]) + timeZero;
        end
    elseif toAbs % from relative, toAbs
        dom = lims;
        if anymissing(dom)
            % TODO
            fprintf('##### [convertDomain] WARNING: MISSING! ####\n');
        end
        trng = timerange(dom(1), dom(2), 'closed');
        idxs = dataTable.Index(trng);
        dom = dom + timeZero;
    else % fromAbs, to relative
        dom = lims - timeZero;
        if anymissing(dom)
            % TODO
            fprintf('##### [convertDomain] WARNING: MISSING! ####\n');
        end
        trng = timerange(dom(1), dom(2), 'closed');
        idxs = dataTable.Index(trng);
    end
end

if nargin > 5
    rightmostPos = varargin{1};
    if dom(2) > rightmostPos
        dom(2) = rightmostPos;
    end
    if dom(1) >= dom(2)
        if bitget(newModeIndex, 2)
            if bitget(newModeIndex, 1)
                dom(1) = seconds(0);
            else
                dom(1) = app.TimeZero; % TODO: Handle NaN??
            end
        else
            dom(1) = 1;
        end
        if dom(1) >= dom(2)
            dom(2) = dom(2) + varargin{2};
        end
    end
end
end