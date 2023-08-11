% varargin: minChanged, maxChanged, majInfo
%        OR assumeChanged(, oldMajInfo or `false' for no majtick calc/gen)

function [minTicks, showMinTicks, minTicksChanged, majTicksChanged, majTicks, majLabels, majTickInfo] = generateTicks( ...
    timeZero, axisModeIndex, zoomModeOn, pixelWidth, lims, resUnit, assumeChanged, varargin)
if ~isscalar(resUnit)
    resUnit = resUnit{axisModeIndex, 1};
end

fprintf('[generateTicks] >>> ARGS: ami/zm/ac=%d/%d/%d, pixelWd=%g, lims=%g, RU=%s, varargin=%s\n', ...
    axisModeIndex, zoomModeOn, assumeChanged, pixelWidth, fdt(lims), fdt(resUnit), fdt(varargin));

if (nargin<10)
    % assumeChanged(, oldMajInfo or `false' for no majtick calc/gen)
    [showMinTicks, minTicksChanged, majTickInfo, majTicksChanged, isRuler, timeMode, genMajInfo, ~] = ... % unused: domWidth
        generateTickInfo(axisModeIndex, zoomModeOn, pixelWidth, lims, resUnit, assumeChanged, varargin{:});
    genMajTicks = genMajInfo && majTicksChanged;
    % fprintf('[generateTicks] isRuler: %d, zoomModeOn: %d, minTicksChanged: %d, showMinTicks: %d, majTicksChanged: %d\n', ...
    %    uint8(isRuler), uint8(isequal(true,zoomModeOn)), uint8(minTicksChanged), uint8(showMinTicks), uint8(majTicksChanged));
else
    % (minChanged, majChanged(, majInfo))
    timeMode = bitget(axisModeIndex, 2);
    isRuler = isempty(zoomModeOn);
    domWidth = lims(2) - lims(1);
    if timeMode && isRuler
        domWidth = seconds(domWidth); % duration to numeric
    end

    if isRuler
        showMinTicks = (500 >= ceil(domWidth/resUnit)) && ...
            resUnit >= 10*domWidth/pixelWidth;
    else % (is slider)
        showMinTicks = (200 >= ceil(domWidth/resUnit)) && ...
            resUnit >= 6*domWidth/pixelWidth;
    end
    if nargin==6
        minTicksChanged = true;
        majTicksChanged = true;
        genMajTicks = true;
        majTickInfo = struct.empty();
    else
        minTicksChanged = varargin{1};
        genMajTicks = (nargin > 7) && varargin{2};
        if genMajTicks
            majTickInfo = varargin{3};
        end
    end
end

if ~(minTicksChanged || majTicksChanged)
    fprintf('[generateTicks] Neither minTicks nor majTicks changed.\n');
    if nargout
        minTicks=[];
        showMinTicks = logical.empty();
        majTicks = [];
        majTickInfo = struct.empty();
        majLabels = '';
    end
    fprintf('[generateTicks] <<< NC/JC=%s/%s, showMinTicks=[], minTicks=majTicks=[], majTickInfo=[], majLabels=''''\n', ...
        fdt(logical(minTicksChanged)), fdt(logical(majTicksChanged)));
    return;
end

% GENERATE MINOR TICKS
if timeMode % (TIME MODE)
    resUnit = seconds(resUnit);
    if ~isRuler
        lims = seconds(lims);
    end
    minTicks = timecolonspace1([0.08, 0.6], lims(1), resUnit, lims(2));
else % (INDEX MODE)
    if isRuler
        resUnit = uint64(resUnit);
    else
        lims = double(lims);
    end
    minTicks = colonspace1([0.05, 0.51], lims(1), resUnit, lims(2));
    % if ~genMajTicks
    %     return;
    % end
end

% majTickInfo: {majUnit,div,pFmt,zFmt,bFmt}
if ~genMajTicks
    fprintf('[generateTicks] Not generating major ticks.\n');
    if ~isRuler && timeMode
      minTicks = seconds(minTicks); % minTicks is always a duration
      % minTicks.Format = 's';
    end
    majTicks = [];
    majLabels = '';
    majTickInfo = struct.empty();
    fprintf('[generateTicks] <<< NC/JC=%s/%s, showMinTicks=%s, minTicks#=%gx(%s), majTicks=[], majTickInfo=[], majLabels=''''\n', ...
        fdt(logical(minTicksChanged)), fdt(logical(majTicksChanged)), ...
        fdt(showMinTicks), numel(minTicks), fdt(mean(diff(minTicks))));
    % minTicks, showMinTicks, minTicksChanged, majTicksChanged, majTicks, majLabels, majTickInfo
    return;
end

if timeMode % (TIME MODE)
    % if (isRuler || zoomModeOn) && ~bitget(axisModeIndex,1) % absolute time
    if ~isRuler && ~zoomModeOn && ~bitget(axisModeIndex,1) % absolute time, but need to convert lims to time
        lims = lims + timeZero; % convert duration to datetime
    end
    if isempty(majTickInfo) || isnan(majTickInfo{1})
        majTicks = lims; % datetime if ruler; duration if slider and zoom mode off
        majLabels = strings(1,2);
    else
        majTicks = timecolonspace1([0.05, 0.51], lims(1), seconds(majTickInfo{1}), lims(2));
        if isRuler
            majLabels = strings(1,2);
        else
            majLabels = strings(1, size(majTicks,2));
            lims = majTicks([1 end]);
        end
    end
    div = majTickInfo{2};
    %        | RULER |   SLIDER   |
    %        |       | PAN   ZOOM |
    %        |====================|
    %   NaN  |  s3   | s3     s4  |
    %     0  |  c3   | c3     c4  | (need to convert to numeric)
    %   num  |  s3   | s3     c4* |
    if isnan(div) % Use pan/zoom fmt as normal, but both formats use string(...)
        if ~isequal(size(lims), [1 2])
            fprintf('[generateTicks] Size of lims ~= [1 2]!! Lims: %s\n', fdt(lims));
        end
        majLabels([1 end]) = string(lims, majTickInfo{3 + ((axisModeIndex==3) || (~isRuler && zoomModeOn))});
    elseif ~(div) % Use pan/zoom fmt as normal, but both fmts use compose(...)
        if all(isduration(lims))
            lims1 = seconds(lims);
        elseif all(isdatetime(lims))
            lims1 = seconds(lims - timeZero);
        else
            lims1 = lims;
        end
        majLabels([1 end]) = compose(majTickInfo{3+((axisModeIndex==3) || (~isRuler && zoomModeOn))}, seconds(lims1));
    elseif ~isRuler && zoomModeOn % slider + zoom mode ==> use zoom format
        if all(isduration(lims))
            lims1 = seconds(lims);
        elseif all(isdatetime(lims))
            lims1 = seconds(lims - timeZero);
        else
            lims1 = lims;
        end
        majLabels([1 end]) = compose(majTickInfo{4}, lims1);
    elseif startsWith(majTickInfo{3 + ((~isRuler && zoomModeOn) ||(axisModeIndex==3))}, '%')%(axisModeIndex==3) || (~isRuler && zoomModeOn) % ????
        if all(isduration(lims))
            lims1 = seconds(lims);
        elseif all(isdatetime(lims))
            lims1 = seconds(lims - timeZero);
        else
            lims1 = lims;
        end
        majLabels([1 end]) = compose(majTickInfo{3 + ((~isRuler && zoomModeOn) ||(axisModeIndex==3))}, lims1);
    else % axis, or slider + pan mode ==> use pan format (NO divisor)
        majLabels([1 end]) = string(lims, majTickInfo{3 + ((~isRuler && zoomModeOn) || (axisModeIndex==3))});
    end
else % (INDEX MODE)
    % NOTE: It is assumed that there is NO divisor factor in index mode
    lims = uint64(lims);
    if isempty(majTickInfo) || isnan(majTickInfo{1})
        majTicks = lims; % uint64 if ruler, double if slider
        majLabels = compose(majTickInfo{4}, lims);
    else
        if isRuler % (RULER)
            majResUnit = uint64(majTickInfo{1});
        else % (SLIDER)
            majResUnit = fix(majTickInfo{1});
        end
        majTicks = colonspace1([0.05 0.51], lims(1), majResUnit, lims(2));
        if isRuler
            if all(isduration(lims))
                lims1 = seconds(lims);
            elseif all(isdatetime(lims))
                lims1 = seconds(lims - timeZero);
            else
                lims1 = lims;
            end
            majLabels = compose(majTickInfo{4}, lims1);
        else
            majLabels = strings(1,size(majTicks,2));
            majLabels([1 end]) = compose(majTickInfo{4}, majTicks([1 end]));
        end
    end
end

if ~isRuler && timeMode % (SLIDER)
    if ~isnumeric(minTicks)
        if isduration(minTicks)
            minTicks = max(seconds(minTicks), 0); % convert from duration to numeric
        else
            minTicks = max(seconds(minTicks-timeZero), 0);
        end
    end
    if ~isnumeric(majTicks)
        if isdatetime(majTicks) % ~bitget(axisModeIndex,1) % absolute time
            majTicks = max(seconds(majTicks-timeZero), 0);  % convert datetime to numeric
        else
            majTicks = max(seconds(majTicks), 0); % convert duration to numeric
        end
    end
end

fprintf('[generateTicks] <<< showMinTicks=%s, minTicks#=%gx(%s), majTicks#=%gx(%s),\n', ...
    fdt(showMinTicks), numel(minTicks), fdt(mean(diff(minTicks))), ...
    fdt(numel(majTicks)), fdt(mean(diff(majTicks))));
if isempty(majLabels)
    majLabStr = '''''';
elseif ischar(majLabels) || isscalar(majLabels)
    majLabStr = sprintf('[%s]', majLabels);
elseif iscell(majLabels)
    majLabStr = sprintf('{%s (...) %s}', fdt(majLabels{1}), fdt(majLabels{end}));
elseif isstring(majLabels)
    majLabStr = sprintf('["%s" (...) "%s"]', majLabels(1), majLabels(end));
else
    majLabStr = sprintf('[%s (...) %s]', fdt(majLabels(1)), fdt(majLabels(end)));
end
fprintf('[generateTicks]     majLabels (%g) = %s,\n', ...
    numel(majLabels), majLabStr);
fprintf('[generateTicks]     majTickInfo = {%s}\n', ...
    strjoin(cellfun(@fdt, majTickInfo)));


if minTicksChanged && isempty(minTicks)
    error('[generateMinTicks] Unexpectedly empty minTicks!\n');
end
end