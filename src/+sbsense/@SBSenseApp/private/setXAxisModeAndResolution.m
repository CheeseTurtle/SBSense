function futs = setXAxisModeAndResolution(app, resUnit, varargin)
    fprintf('[setXAxisModeAndResolution] Called (nargin: %d)!\n', nargin);
    if nargin > 2
        app.XAxisModeIndex = varargin{1};
        oldMI = varargin{2};
        ruler = varargin{3};
        forceSetMajorTicks = (nargin < 4) || varargin{4};
    else
        oldMI = app.XAxisModeIndex;
        ruler = app.HgtAxes.XAxis;
        forceSetMajorTicks = false;
    end
    fprintf('[setXAxisModeAndResolution] Ruler: %s', formattedDisplayText(ruler));
    oldLims = ruler.Limits;
    switch app.XAxisModeIndex
        case 2
            rulers = app.TRulers;
        case 3
            rulers = app.DRulers;
        otherwise
            rulers = app.NRulers;
    end

    if isempty(resUnit)
        resUnit = pow2(app.XResKnob.Value); %app.ResTable{app.XAxisModeIndex, 1}; % TODO: Already have stored the previous value (for old mode) in the table
    end

    
    midx = app.XAxisModeIndex; tz = app.TimeZero; dt = app.DataTable;
    if nargin > 2
        fprintf('[setXAxisModeAndResolution] Launching parfeval 1a (fut00).\n');
        fut00 = parfeval(backgroundPool, @sbsense.SBSenseApp.convertDomain, 1, ...
            tz, dt, ruler.Limits, oldMI, midx);
        fprintf('[setXAxisModeAndResolution] Launching parfeval 1b (fut0).\n');
        fut0 = afterEach(fut00, @(x) parfeval(backgroundPool, ...
            @sbsense.SBSenseApp.quantizeDomain, 1, x), 1);
    else
        fprintf('[setXAxisModeAndResolution] Launching first parfeval (fut0).\n');
        fut0 = parfeval(backgroundPool, @sbsense.SBSenseApp.quantizeDomain, ...
            1, oldLims);
    end

    fprintf('[setXAxisModeAndResolution] Launching second parfeval (fut1).\n');
    % Nav slider lims, min tick values, maj tick values, and maj labels, new pos
    znm = app.XNavZoomMode; lir = app.LargestIndexReceived;
    %oru = pow2(app.XResSlider.Value);
    fut1 = afterEach(fut0, @(alims) parfeval(backgroundPool, ...
        @sbsense.SBSenseApp.axisLims2NavSliLims, 5, ...
        znm, midx, tz, dt([1 lir], ["RelTime" "Index"]), ...
        resUnit, alims), 5, 'PassFuture', false);
    
        % TODO: Also new auto-Ys (with index list from fut0!)
    
    fprintf('[setXAxisModeAndResolution] Launching third parfeval (fut2).\n');
        % Axis minor ticks, major ticks, and major tick labels
    fut2 = afterEach(fut0, @(alims) sbsense.SBSenseApp.calcAxisMajorAndMinorTicks( ...
        midx, tz, resUnit, alims, forceSetMajorTicks), 3);
    fprintf('[setXAxisModeAndResolution] Launched third parfeval.\n');
    nsli = app.XNavSlider;
    futs = [ fut1 ; fut2 ;
        afterEach(fut2, @(a,b,c) setAxisProps(rulers, a,b,c), 0) ...
        ; afterEach(fut1, @(varargin) setNavSliProps(nsli, varargin{:}), 0) ]';
    fprintf('[setXAxisModeAndResolution] Returning futs:\n');
    display(futs);
end

function setAxisProps(rulers, minorTicks, majTicks, majLabels)
    set(rulers, 'MinorTickValues', minorTicks, 'TickValues', majTicks, 'TickLabels', majLabels);
end

function setNavSliProps(sli, lims, minorTicks, majTicks, majLabels, val)
    set(sli, 'Limits', lims, 'MinorTickValues', minorTicks, ...
        'MajorTickValues', majTicks, 'MajorTickLabels', majLabels, 'Value', val);
end

function [lims, minTicks, majTicks, majLabels, pos] = axisLims2NavSliLims(...
    zoomMode, modeIndex, timeZero, dataRows, resUnit, alims)
    if zoomMode
        pos = diff(alims);
        if modeIndex > 1
            pos = seconds(zoomSpan);
        else
            pos = pos + 1;
        end
        if modeIndex==1
            rng = diff(dataRows.Index(:))+1;
        else
            rng = seconds(diff(dataRows.RelTime(:)));
        end
        lims = [ ...
            resUnit, ...
            resUnit*ceil(rng/resUnit) ...
        ];
    else
        if modeIndex == 1
            lims = dataRows.Index(:);
        else
            lims = dataRows.RelTime(:);
            if modeIndex == 2
                lims = lims - timeZero;
            end
            lims = seconds(lims);
        end
        pos = lims(1);
    end
    minTicks = colonspace(lims(1), resUnit, lims(2));
    [majUnit, majFormat, sfac] = sbsense.SBSenseApp.chooseMajorResUnit(modeIndex, resUnit);
    majTicks = colonspace(lims(1), majUnit, lims(2));
    if sfac ~= 1
        majLabels = sfac\majTicks;
    else
        majLabels = majTicks;
    end
    majLabels = compose(majFormat, majLabels);
end




