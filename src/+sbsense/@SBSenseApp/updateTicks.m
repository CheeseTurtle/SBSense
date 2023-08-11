function [TF, majTickInfo] = updateTicks(app, typeIdx, lims, ...
    axisModeIndex, zoomModeOn, resUnit, assumeChanged, varargin)
if typeIdx
    zoomModeOn = logical.empty();
    cmp = app.HgtAxes;
    cmps = [ cmp app.PosAxes];
    % cmp = cmps(1);
else
    %zoomModeOn = app.XNavZoomMode;
    % cmp = cmps;
    cmps = app.XNavSlider;
end
if ~isscalar(resUnit)
    resUnit = resUnit{axisModeIndex,1}; %typeIdx+1};
end

fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
fprintf('~~~ UPON ENTERING updateTicks (%d): ~~~\n', typeIdx);
if typeIdx
    majTicks0 = app.HgtAxes.XAxis.TickValues;
    minTicks0 = app.HgtAxes.XAxis.MinorTickValues;
    snapTicks0 = app.HgtAxes.XSnapTickValues;
    fprintf('~~~ (%d) Min Ticks visible: %d, maj ticks visible: %d\n', ...
        logical(app.HgtAxes.XMinorTick), ~isempty(majTicks0));
    majLabStr = 'N/A'; majLabels0 = '';
else
    majTicks0 = app.XNavSlider.MajorTicks;
    minTicks0 = app.XNavSlider.MinorTicks;
    snapTicks0 = app.XNavSlider.SnapTicks;
    majLabels0 = app.XNavSlider.MajorTickLabels;
    fprintf('~~~ (%d) Min Ticks shown: %d, maj ticks shown: %d\n', ...
        ~isempty(minTicks0), ~isempty(majTicks0));
    if isempty(majLabels0)
        majLabStr = '''''';
    elseif ischar(majLabels0) || isscalar(majLabels0)
        majLabStr = sprintf('[%s]', majLabels0);
    elseif iscell(majLabels0)
        majLabStr = sprintf('{%s (...) %s}', fdt(majLabels0{1}), fdt(majLabels0{end}));
    elseif isstring(majLabels0)
        majLabStr = sprintf('["%s" (...) "%s"]', majLabels0(1), majLabels0(end));
    else
        majLabStr = sprintf('[%s (...) %s]', fdt(majLabels0(1)), fdt(majLabels0(end)));
    end    
end
fprintf('~~~ (%d) minTicks#=%gx(%s), majTicks#=%gx(%s), snapTicks#=%gx(%s)\n', ...
    typeIdx, numel(minTicks0), fdt(mean(diff(minTicks0))), ...
    fdt(numel(majTicks0)), fdt(mean(diff(majTicks0))), ...
    numel(snapTicks0), fdt(mean(diff(snapTicks0))));
fprintf('~~~ (%d) majLabels (%g) = %s\n', ...
    typeIdx, numel(majLabels0), majLabStr);
fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');

fprintf('[updateTicks]:%d >>> ARGS: ami/zm/ac=%d/%s/%s, RU: %s,\n', ...
    typeIdx, axisModeIndex, fdt(zoomModeOn), fdt(assumeChanged), fdt(resUnit));
fprintf('[updateTicks]:%d     ARGS: varargin=%s\n', typeIdx, fdt(varargin));

[ minTicks, showMinTicks, minTicksChanged, majTicksChanged, ...
    majTicks, majLabels, majTickInfo ] = generateTicks( ...
    app.TimeZero, axisModeIndex, zoomModeOn, ...
    cmp.InnerPosition(3), lims, resUnit, assumeChanged, varargin{:});
TF = minTicksChanged || majTicksChanged;
if typeIdx
    if TF
        if ~showMinTicks && app.HgtAxes.XMinorTick
            set(cmps, 'XMinorTick', false, 'XMinorGrid', false);
        end
        %c = bitor(bitshift(majTicksChanged,1), minTicksChanged);
        rules = [app.FPRulers{axisModeIndex, :}];
        if majTicksChanged
            if minTicksChanged
                try
                    app.HgtAxes.XSnapTickValues = minTicks;
                    if showMinTicks
                        set(rules, 'MinorTickValues', minTicks, 'TickValues', majTicks);
                    else
                        set(rules, 'TickValues', majTicks);
                    end
                catch ME
                    display(ME.identifier);
                    disp(class(minTicks));
                    disp(length(minTicks));
                    if ~isempty(minTicks)
                        display(minTicks([1 end]));
                        disp({min(diff(minTicks)), max(diff(minTicks))});
                    end
                    disp(class(majTicks));
                    disp(length(majTicks));
                    if ~isempty(majTicks)
                        display(majTicks([1 end]));
                        disp({min(diff(majTicks)), max(diff(majTicks))});
                    end
                    if ME.identifier == "MATLAB:hg:shaped_arrays:TickPredicate"
                        app.HgtAxes.XSnapTickValues = majTicks;
                        set(rules, 'MinorTickValues', [], 'TickValues', majTicks);
                    else
                        rethrow(ME);
                    end
                end
            else
                set(rules, 'TickValues', majTicks);
            end
            % TODO: Annotation lims
        elseif minTicksChanged
            try
                app.HgtAxes.XSnapTickValues = minTicks;
                if showMinTicks
                    set(rules, 'MinorTickValues', minTicks);
                end
            catch ME
                disp(class(minTicks));
                disp(length(minTicks));
                if ~isempty(minTicks)
                    display(minTicks([1 end]));
                    disp({min(diff(minTicks)), max(diff(minTicks))});
                end
                if ME.identifier == "MATLAB:hg:shaped_arrays:TickPredicate"
                    set(rules, 'MinorTickValues', []);
                    app.HgtAxes.XSnapTickValues = majTicks;
                else
                    rethrow(ME);
                end
            end
        end
        if cmps(1).XMinorTick == showMinTicks
            dispEnd();
            return;
        end
    elseif cmps(1).XMinorTick ~= showMinTicks
        TF = true;
    else
        dispEnd();
        return;
    end
    set(cmps, 'XMinorTick', showMinTicks, 'XMinorGrid', showMinTicks);
    dispEnd();
    return;
elseif majTicksChanged
    if minTicksChanged
        set(cmp, varargin{:}, 'MinorTicks', minTicks, 'SnapTicks', minTicks, ...
            'MajorTicks', majTicks, 'MajorTickLabels', majLabels);
    else
        set(cmp, varargin{:}, 'MajorTicks', majTicks, 'MajorTickLabels', majLabels);
    end
    if showMinTicks ~= isempty(cmp.MinorTicks)
        dispEnd();
        return;
    end
elseif minTicksChanged
    % app.XNavSlider.MinorTicks = minTicks;
    % app.XNavSlider.SnapTicks = minTicks;
    set(cmp, varargin{:}, 'SnapTicks', minTicks, 'MinorTicks', minTicks);
    if showMinTicks ~= isempty(cmp.MinorTicks)
        dispEnd();
        return;
    end
elseif ~isempty(varargin)
    set(cmp, varargin{:});
    TF = true;
elseif showMinTicks == isempty(cmp.MinorTicks)
    TF = true;
else
    dispEnd();
    return;
end
if showMinTicks
    cmp.MinorTicks = cmp.SnapTicks;
else
    cmp.MinorTicks = [];
end

dispEnd();

    function dispEnd()
        fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
        fprintf('~~~ UPON LEAVING updateTicks (%d): ~~~\n', typeIdx);
        if typeIdx
            majTicks0 = app.HgtAxes.XAxis.TickValues;
            minTicks0 = app.HgtAxes.XAxis.MinorTickValues;
            snapTicks0 = app.HgtAxes.XSnapTickValues;
            fprintf('~~~ (%d) Min Ticks visible: %d, maj ticks visible: %d\n', ...
                logical(app.HgtAxes.XMinorTick), ~isempty(majTicks0));
            majLabStr = 'N/A'; majLabels0 = '';
        else
            majTicks0 = app.XNavSlider.MajorTicks;
            minTicks0 = app.XNavSlider.MinorTicks;
            snapTicks0 = app.XNavSlider.SnapTicks;
            majLabels0 = app.XNavSlider.MajorTickLabels;
            fprintf('~~~ (%d) Min Ticks shown: %d, maj ticks shown: %d\n', ...
                ~isempty(minTicks0), ~isempty(majTicks0));
            if isempty(majLabels0)
                majLabStr = '''''';
            elseif ischar(majLabels0) || isscalar(majLabels0)
                majLabStr = sprintf('[%s]', majLabels0);
            elseif iscell(majLabels0)
                majLabStr = sprintf('{%s (...) %s}', fdt(majLabels0{1}), fdt(majLabels0{end}));
            elseif isstring(majLabels0)
                majLabStr = sprintf('["%s" (...) "%s"]', majLabels0(1), majLabels0(end));
            else
                majLabStr = sprintf('[%s (...) %s]', fdt(majLabels0(1)), fdt(majLabels0(end)));
            end    
        end
        fprintf('~~~ (%d) minTicks#=%gx(%s), majTicks#=%gx(%s), snapTicks#=%gx(%s)\n', ...
            typeIdx, numel(minTicks0), fdt(mean(diff(minTicks0))), ...
            fdt(numel(majTicks0)), fdt(mean(diff(majTicks0))), ...
            numel(snapTicks0), fdt(mean(diff(snapTicks0))));
        fprintf('~~~ (%d) majLabels (%g) = %s\n', ...
            typeIdx, numel(majLabels0), majLabStr);
        fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
    end
end