function resUnit = restrictResUnit(axisModeIndex,isRuler,resTicks,lims,resUnit, varargin)
% timeMode = bitget(axisModeIndex,2);
% absMode =  ~bitget(axisModeIndex,1);
if ~isscalar(resUnit)
    resUnit = resUnit{axisModeIndex, 1};
end

resUnit0 = resUnit;

domSpan = diff(lims);

fprintf('[restrictResUnit] >>> ARGS: ami/isRuler=%d/%d, lims=[%g], resUnit=%s, varargin=%s\n', ...
    axisModeIndex, isRuler, fdt(lims), fdt(resUnit), fdt(varargin));
fprintf('[restrictResUnit]     domSpan: %s\n', fdt(domSpan));

if isnumeric(domSpan) % uint64
    domSpan = double(domSpan);
else % duration
    domSpan = seconds(domSpan);
end

if isRuler % is axis
    maxN = 1024; %2048;
    axisDomSpan = domSpan;
else % is slider
    maxN = 512; %1024;
    if bitget(axisModeIndex, 2)
        axisDomSpan = seconds(diff(varargin{1}));
    else
        axisDomSpan = double(diff(varargin{1}));
    end
end


if (nargin>(5 + ~isRuler))
    if bitget(axisModeIndex, 2) % Abs or rel time
        maxMaxUnit = seconds(varargin{end});
    else % Index mode
        maxMaxUnit = double(varargin{end});
    end
    if 0.8*maxMaxUnit <= resUnit
        maxMaxUnit = 4\(maxMaxUnit + min(maxMaxUnit, axisDomSpan));
        if maxMaxUnit <= resTicks(1)
            resUnit = resTicks(1);
        else
            resUnit = interp1(resTicks, maxMaxUnit, 'nearest', 'extrap');
        end
    end
end

% maxN = pwd/minP = dwd/minUnit
if (fix(domSpan/resUnit)>1) && (ceil(domSpan/resUnit)<=maxN)
    fprintf('[restrictResUnit] <<< [%s] --> (no change)\n', ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline));
    return; % No change in res unit
end

% maxN = 2048;
% minN = 1;

ns = domSpan ./ resTicks;

msk = ns <= maxN; %  ceil(ns) <= maxN;
if any(msk)
    ns = ns(msk);
    resTicks = resTicks(msk);
else % Assumes resTicks is not empty
    resUnit = resTicks(end);
    fprintf('[restrictResUnit] <<< (all resTicks\domSpan > maxN %g) [%s] --> [%s]\n', ...
        maxN, ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline), ...
        erase(strrep(strip(formattedDisplayText(resUnit)), '  ', ' '), newline));
    fmt = format("shortG"); disp(vertcat(resTicks, ns)); format(fmt);
    return;
end

fprintf('[restrictResUnit]     (maxN: %g, RU0: %s) [resTicks; ns]:\n', maxN, ...
    erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline));
% disp({size(resTicks), size(ns)});
fmt = format("shortG"); disp(vertcat(resTicks, ns)); format(fmt);

ns = fix(ns);
msk = ns > 0;
if any(msk)
    fprintf('[restrictResUnit]     At least 1 option has n>0. Remaining [ticks ; ns]:\n');
    ns = ns(msk);
    resTicks = resTicks(msk);
    fmt = format("shortG"); disp(vertcat(resTicks, ns)); format(fmt);
    msk = ns > 1;
    if any(msk)
        fprintf('[restrictResUnit]     (RU0: %s, RU: %s) At least 1 option has n>1. Remaining [ticks ; ns]:\n', ...
            erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline), ...
            erase(strrep(strip(formattedDisplayText(resUnit)), '  ', ' '), newline));
        % ns = ns(msk);
        resTicks = resTicks(msk);
        fmt = format("shortG"); disp(vertcat(resTicks, ns(msk))); format(fmt);
    else
        fprintf('[restrictResUnit]     (RU0: %s, RU: %s) No options have n>1.\n', ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline), ...
        erase(strrep(strip(formattedDisplayText(resUnit)), '  ', ' '), newline));
    end
else
    fprintf('[restrictResUnit]     (RU0: %s, RU: %s) No options have n>0.\n', ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline), ...
            erase(strrep(strip(formattedDisplayText(resUnit)), '  ', ' '), newline));
%    resUnit = resTicks(1);
%    return;
end

if resUnit >= resTicks(end)
    resUnit = resTicks(end);
elseif resUnit <= resTicks(1)
    resUnit = resTicks(1);
else
    resUnit = resTicks(end); %resTicks(ceil(length(resTicks)/2));
end    

if isequal(resUnit, resUnit0)
    fprintf('[restrictResUnit] <<< [%s] --> (no change)\n', ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline));
else
    fprintf('[restrictResUnit] <<< [%s] --> [%s]\n', ...
        erase(strrep(strip(formattedDisplayText(resUnit0)), '  ', ' '), newline), ...
        erase(strrep(strip(formattedDisplayText(resUnit)), '  ', ' '), newline));
end
end