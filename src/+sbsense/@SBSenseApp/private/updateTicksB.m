function TF = updateTicksB(app, typeIdx, ~, axisModeIndex, ...
    minTicks, showMinTicks, minTicksChanged, majTicksChanged, ...
    majTicks, majLabels, ~, varargin) % unused: lims, majTickInfo
TF = minTicksChanged || majTicksChanged;
% fprintf('[updateTicksB] minTicksChanged (%d, %d): %d, majTicksChanged (%d): %d\n', ...
%    length(minTicks), uint8(showMinTicks), uint8(majTicksChanged), length(majTicks), uint8(majTicksChanged));

fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
fprintf('~~~ UPON ENTERING updateTicksB (%d): ~~~\n', typeIdx);
if typeIdx
    majTicks0 = app.HgtAxes.XAxis.TickValues;
    minTicks0 = app.HgtAxes.XAxis.MinorTickValues;
    snapTicks0 = app.HgtAxes.XSnapTickValues;
    fprintf('~~~ (%d) Min Ticks visible: %d, maj ticks visible: %d\n', ...
        typeIdx, logical(app.HgtAxes.XMinorTick), ~logical(isempty(majTicks0)));
    majLabStr = 'N/A'; majLabels0 = '';
else
    majTicks0 = app.XNavSlider.MajorTicks;
    minTicks0 = app.XNavSlider.MinorTicks;
    snapTicks0 = app.XNavSlider.SnapTicks;
    majLabels0 = app.XNavSlider.MajorTickLabels;
    fprintf('~~~ (%d) Min Ticks shown: %d, maj ticks shown: %d\n', ...
        typeIdx, ~logical(isempty(minTicks0)), ~logical(isempty(majTicks0)));
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

fprintf('[updateTicksB]:%d >>> ARGS: ami=%d, NC/JC: %s/%s, showMin=%s,\n', ...
    typeIdx, axisModeIndex, fdt(logical(minTicksChanged)), fdt(logical(majTicksChanged)), ...
    fdt(showMinTicks));
fprintf('[updateTicksB]:%d     ARGS: minTicks#=%gx(%s), majTicks#=%gx(%s),\n', ...
    typeIdx, numel(minTicks), fdt(mean(diff(minTicks))), ...
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
fprintf('[updateTicksB]:%d     ARGS: majLabels (%g) = %s,\n', ...
    typeIdx, numel(majLabels), majLabStr);
% fprintf('[updateTicksB]:%d     ARGS: majTickInfo = {%s}\n', ...
%    typeIdx, strjoin(cellfun(@fdt, majTickInfo)));
fprintf('[updateTicksB]:%d     ARGS: varargin=%s\n', typeIdx, fdt(varargin));

if ~isempty(majTicks) && length(majTicks)>1
    if typeIdx
        difs = diff(majTicks);
        if axisModeIndex==1
            if ~all(difs)
                majTicks = majTicks([true difs>0]);
            end
        else
            difs = seconds(difs) > 1e-12;
            if ~all(difs)
                majTicks = [true difs];
            end

        end
    else
        difs = diff(majTicks) > 1e-12;
        if ~all(difs)
            majTicks = [true difs];
        end
    end
end

try
    if typeIdx
        if TF
            if ~showMinTicks && app.HgtAxes.XMinorTick
                set([app.HgtAxes app.PosAxes], 'XMinorTick', false, ...
                    'XMinorGrid', false);
            end
            rules = [app.FPRulers{axisModeIndex, :}];
            if majTicksChanged
                if minTicksChanged
                    app.HgtAxes.XSnapTickValues = minTicks;
                    if showMinTicks && (isempty(minTicks) || isscalar(minTicks) || (minTicks(1)<minTicks(end)))
%                         display(class(majTicks));
%                         disp([min(diff(majTicks)), max(diff(majTicks))]);
%                         disp(majTicks([1 end]));
%                         disp(seconds([min(diff(minTicks)), min(abs(diff(minTicks)))]));
                        set(rules, 'MinorTickValues', minTicks, 'TickValues', majTicks);
                    elseif isempty(majTicks) || isscalar(majTicks) || (majTicks(1)<majTicks(end))
                        set(rules, 'TickValues', majTicks);
                    end
                else
                    set(rules, 'TickValues', majTicks);
                end
                % TODO: Annotation lims
            elseif minTicksChanged
                app.HgtAxes.XSnapTickValues = minTicks;
                if showMinTicks && (isempty(minTicks) || isscalar(minTicks) || (minTicks(1)<minTicks(end)))
                    set(rules, 'MinorTickValues', minTicks);
                end
            end
            if app.HgtAxes.XMinorTick == showMinTicks
                dispEnd();
                return;
            end
        elseif app.HgtAxes.XMinorTick ~= showMinTicks
            TF = true;
        else
            dispEnd();
            return;
        end
        set([app.HgtAxes app.PosAxes], 'XMinorTick', showMinTicks, ...
            'XMinorGrid', showMinTicks);
        dispEnd();
        return;
    elseif majTicksChanged
        if ~showMinTicks && app.HgtAxes.XMinorTick
            set([app.HgtAxes app.PosAxes], 'XMinorTick', false, ...
                'XMinorGrid', false);
        end
        if minTicksChanged
            set(app.XNavSlider, varargin{:}, 'SnapTicks', minTicks, ...
                'MinorTicks', minTicks, ...
                'MajorTicks', majTicks, 'MajorTickLabels', majLabels);
        else
            set(app.XNavSlider, varargin{:}, 'MajorTicks', majTicks, ...
                'MajorTickLabels', majLabels);
        end
        if showMinTicks ~= isempty(app.XNavSlider.MinorTicks)
            dispEnd();
            return;
        end
    elseif minTicksChanged
        % app.XNavSlider.MinorTicks = minTicks;
        % app.XNavSlider.SnapTicks = minTicks;
        set(app.XNavSlider, varargin{:}, ...
            'SnapTicks', minTicks, 'MinorTicks', minTicks);
        if showMinTicks ~= isempty(app.XNavSlider.MinorTicks)
            dispEnd();
            return;
        end
    elseif ~isempty(varargin)
        try
            set(app.XNavSlider, varargin{:});
        catch ME2
            celldisp(varargin);
            rethrow(ME2);
        end
        TF = true;
    elseif showMinTicks == isempty(app.XNavSlider.MinorTicks)
        TF = true;
    else
        dispEnd();
        return;
    end
    if showMinTicks
        app.XNavSlider.MinorTicks = app.XNavSlider.SnapTicks;
    elseif ~isempty(showMinTicks)
        fprintf('[updateTicksB]:%d SETTING MINOR TICKS TO EMPTY. SnapTicks length: %d\n', ...
            typeIdx, length(app.XNavSlider.SnapTicks));
        app.XNavSlider.MinorTicks = [];
    end
catch ME
    fprintf('[updateTicksB]:%d Error "%s": %s\n', ...
        typeIdx, ME.identifier, getReport(ME));
    disp({minTicksChanged, showMinTicks, majTicksChanged});
    celldisp(varargin);
    display({min(minTicks), max(minTicks), min(diff(minTicks))>0, max(diff(minTicks))>0}); %#ok<DISPLAYPROG> 
    display(minTicks);
    display(majTicks);
    display(majLabels);
end

dispEnd();

function dispEnd()
    fprintf('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n');
    fprintf('~~~ UPON LEAVING updateTicksB (%d): ~~~\n', typeIdx);
if typeIdx
    majTicks0 = app.HgtAxes.XAxis.TickValues;
    minTicks0 = app.HgtAxes.XAxis.MinorTickValues;
    snapTicks0 = app.HgtAxes.XSnapTickValues;
    fprintf('~~~ (%d) Min Ticks visible: %d, maj ticks visible: %d\n', ...
        typeIdx, logical(app.HgtAxes.XMinorTick), ~isempty(majTicks0));
    majLabStr = 'N/A'; majLabels0 = '';
else
    majTicks0 = app.XNavSlider.MajorTicks;
    minTicks0 = app.XNavSlider.MinorTicks;
    snapTicks0 = app.XNavSlider.SnapTicks;
    majLabels0 = app.XNavSlider.MajorTickLabels;
    fprintf('~~~ (%d) Min Ticks shown: %d, maj ticks shown: %d\n', ...
        typeIdx, ~logical(isempty(minTicks0)), ~logical(isempty(majTicks0)));
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