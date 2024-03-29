function [showMinTicks, minTicksChanged, majTickInfo, majTicksChanged, isRuler, timeMode, genMajInfo, domWidth] = generateTickInfo( ...
    axisModeIndex, zoomModeOn, pixelWidth, lims, resUnit, assumechanged, varargin)
persistent oldLims oldResUnit oldWidth oldDomWidth oldMajUnit oldMajInfo oldShowMinTicks;
if ~isscalar(resUnit)
    resUnit = resUnit{axisModeIndex, 1};
end

% fprintf('[generateTickInfo] >>> ARGS: ami/zm/achg=%d/%d/%d, pW=%g, lims=%s, varargin=%s\n', ...
%     axisModeIndex, zoomModeOn, assumechanged, pixelWidth, sbsense.utils.fdt(lims), sbsense.utils.fdt(varargin));

timeMode = bitget(axisModeIndex, 2);
isRuler = isempty(zoomModeOn);
idx = uint8(isRuler) + 1;
domWidth = lims(2) - lims(1);
% genMajInfo = ~isequal(varargin,{false});
if timeMode
    if isRuler
        domWidth = seconds(domWidth); % duration to numeric
    end
    if ~isnumeric(resUnit)
        resUnit1= seconds(resUnit);
    else
        resUnit1 = resUnit;
    end
else
    resUnit1 = resUnit;
end

if isempty(oldMajUnit)
    oldResUnit = {NaN, NaN};
    oldMajUnit = NaN(1,2,'double');
    oldWidth = oldMajUnit;
    oldDomWidth = {NaN, NaN};
    oldLims = {oldMajUnit ; oldMajUnit};
    oldMajInfo = {struct.empty(), struct.empty()};
    % if genMajInfo && (nargin~=6)
    %     oldMajInfo{idx} = varargin{1};
    % end
    oldShowMinTicks = true(1,2);
    limsSame = false;
    domWidthSame = false;
else
    % if nargin~=6
    %     oldMajInfo{idx} = varargin{1};
    % end
    limsSame = isequal(lims, oldLims{idx});
    domWidthSame = isequal(domWidth, oldDomWidth{idx});
end

if isequal(varargin, {false})
    genMajInfo = false;
else
    genMajInfo = ~domWidthSame;
end

if ~assumechanged && limsSame && isequal(resUnit,oldResUnit{idx})
    %minTicksChanged = false;
    if oldWidth(idx) == pixelWidth
        showMinTicks = oldShowMinTicks(idx); %logical.empty();
        minTicksChanged = false;
    else
        minTicksChanged = true;
        showMinTicks = true; % ???
    end
else % changed
    minTicksChanged = true;
    showMinTicks = true; % ???
end

% fprintf('[generateTickInfo] <<< assumeChanged:%d, limsSame:%d, domWdSame:%d, minTicksChanged:%d\n', ...
%     assumechanged, limsSame, domWidthSame, minTicksChanged);

if ~isempty(showMinTicks)
    if isRuler
        try
            showMinTicks = (1024 >= ceil(domWidth/resUnit1)) && ...
                (resUnit1 >= 4*domWidth/pixelWidth);
        catch ME
            % keyboard;
            display(resUnit);
            display(resUnit1);
            rethrow(ME);
        end
        % %fprintf('[generateTickInfo] (%d) showMinTicks = (%d && %d) = (1024>=%0.4g)&&(%0.4g>=%0.4g)\n', ...
        % %    isRuler, (1024 >= ceil(domWidth/resUnit)), (resUnit >= 4*domWidth/pixelWidth), ...
        % %    ceil(domWidth/resUnit), resUnit, 4*domWidth/pixelWidth);
    else % (is slider)
        showMinTicks = (512 >= ceil(domWidth/resUnit1)) && ...
            (resUnit1 >= 3.75*domWidth/pixelWidth);
        % %fprintf('[generateTickInfo] (%d) showMinTicks = (%d && %d) = (512>=%0.4g)&&(%0.4g>=%0.4g)\n', ...
        % %    isRuler, (512 >= ceil(domWidth/resUnit)), (resUnit >= 3.75*domWidth/pixelWidth), ...
        % %    ceil(domWidth/resUnit), resUnit, 3.75*domWidth/pixelWidth);
    end
end

if ~genMajInfo || (~assumechanged && limsSame && (pixelWidth == oldWidth(idx)) ...
        && (oldMajUnit(idx) >= resUnit))
    majTicksChanged = false;
    if genMajInfo && (nargin~=6)
        majTickInfo = varargin{1};
    else
        majTickInfo = oldMajInfo{idx}; %struct.empty();
    end
elseif genMajInfo % changed
    majTicksChanged = true;
    if isRuler
        [majUnit,div,pFmt,zFmt,bFmt] = getMajIntervalForWidth(timeMode, ...
            resUnit, pixelWidth, domWidth, 10, 1000); % 1024);
    else
        [majUnit,div,pFmt,zFmt,bFmt] = getMajIntervalForWidth(timeMode, ...
            resUnit, pixelWidth, domWidth, 10, 300); %500);
    end
    majTickInfo = {majUnit,div,pFmt,zFmt,bFmt};
else
    majTicksChanged = false;
    % majTickInfo = {};
end

% fprintf('[generateTickInfo] <<< minTicksChanged:%d, genMajInfo:%d, majTicksChanged:%d, majTickInfo: %s\n', ...
%     minTicksChanged, genMajInfo,majTicksChanged, sbsense.utils.fdt(majTickInfo));

oldLims{idx} = lims;
oldResUnit{idx} = resUnit;
oldWidth(idx) = pixelWidth;
oldShowMinTicks(idx) = showMinTicks;
if genMajInfo && ~isempty(majTickInfo)
    % fprintf('[generateTickInfo] Old/new domWidth (%d): %s\n', ...
    %     idx, strrep(strip(formattedDisplayText({oldDomWidth{idx}, domWidth})), '  ', ' '));
    oldDomWidth{idx} = domWidth;
    oldMajInfo{idx} = majTickInfo;
    oldMajUnit(idx) = majTickInfo{1};
end
end

% maxN = pwd/minP = dwd/minUnit
function [majIvl, div, pFmt, zFmt, bFmt] = getMajIntervalForWidth(timeMode, minUnit, pwd, dwd, minP, maxN) % All parameters NUMERIC
% fprintf('[getMajIvlForWd] >>> ARGS: timeMode=%d, minUnit=%g, pwd=%g, dwd=%g, minP=%g, maxN=%d\n', ...
%     timeMode, minUnit, pwd, dwd, minP, maxN);
if timeMode % Time mode
    if minUnit < 1
        div = NaN; % both zoom and pan use string
        pFmt = 'mm:ss.SSS';
        zFmt = 'mm:ss.SSS';
        bFmt = 'MM/dd HH:mm:ss.SSS';
        ivls = [0.001 0.002 0.005 0.010 0.025 0.050 ...
            0.1 0.2 0.25 0.5 1 1.5 2 5 10 15 20 30];
    elseif minUnit < 60
        div = NaN; % both zoom and pan use string
        pFmt = 'HH:mm:ss';
        zFmt = 'mm:ss';
        bFmt = 'MM/dd HH:mm:ss';
        if minUnit < 10
            ivls = [0.1 0.2 0.25 0.5 1 2.5 5 10 15 20 30];
        else
            ivls = [0.5 1 2 2.5 5 10 15 20 30 60 120];
        end
    elseif minUnit < 3600
        div = 60.0; % Minutes; pan uses string, zoom uses compose
        pFmt = 'HH:mm';
        zFmt = '%g';
        bFmt = 'MM/dd hh:mm';
        if minUnit < 180
            ivls = [1 5 10 15 20 30 60 90 120];
        else
            ivls = [10 15 30 60 90 120 180 300 600 900 1200 1800];
        end
    else % minUnit is 1hr or larger
        div = 3600.0; % Hours; pan uses string, zoom uses compose
        pFmt = 'hhaa';
        zFmt = '%g';
        bFmt = 'MM/dd hh:mm';
        ivls = double.empty();
    end
else % Index mode
    div = 0; % both zoom and pan use compose
    pFmt = '%g'; zFmt = '%g';
    bFmt = 'MM/dd HH:mm:ss.SSS';
    if minUnit < 15
        ivls = uint64([1 2 5 10]);
    elseif minUnit < 50
        ivls = [1 5 10 15 20 25];
    elseif minUnit < 500
        ivls = [5 10 25 50 100 200];
    elseif minUnit < 1000
        ivls = [25 50 100 200 250 500];
    else
        ivls = double.empty();
    end
end
ivls(ivls>dwd) = [];
if isempty(ivls)
    majIvl = NaN;
else
    ivls(ivls<=minUnit) = [];
    msk2 = rem(ivls,minUnit)==0;
    if any(msk2)
        ivls = ivls(msk2);
    else
        ivls = minUnit * [2 4 5 10];
        ivls(ivls>dwd) = [];
    end
    % maxN_bypixelwidth = ceil(pwd/minP) = ceil(dwd/minMinUnit)
    minMinUnit = dwd*minP/pwd;
    if isempty(ivls)
        if minUnit >= minMinUnit
            majIvl = minUnit;
        else
            majIvl = NaN;
        end
    elseif isscalar(ivls)
        if (ivls < minMinUnit) || (ivls < ceil(dwd/maxN))
            majIvl = NaN;
        else
            majIvl = ivls;
        end
    else
        msk = ivls >= minMinUnit;
        if any(msk)
            ivls = ivls(msk);
            minWj = ceil(dwd/maxN);
            msk = ivls >= minWj;
            if any(msk)
                len = sum(msk, 'all', 'native');
                ivls = ivls(msk);
                majIvl = ivls(ceil(2\len)); %ivls(idivide(len, 2, 'ceil')); %ceil(0.5*len));
            else
                majIvl = ivls(end);
            end
        else
            majIvl = NaN;
        end

        %for majIvl = ivls
        %    if majIvl >= minWj
        %        break;
        %    end
        %end
    end
end

% fprintf('[getMajIvlForWd] <<< majIvl = %g\n', majIvl);
end

