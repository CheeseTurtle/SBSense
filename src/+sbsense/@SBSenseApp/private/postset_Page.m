function postset_Page(app, varargin)
%if strcmp(src.Name, 'PageLimits')
%end
persistent pv;
%if ~iscell(event.Value)
%    val = event.Value;
%elseif isequal(size(event.Value), [1 2])
%    val = event.Value{2};
%else
%    val = event.Value{app.XAxisModeIndex, 2};
%end

%display(event);
val = app.PageLimitsVals{app.XAxisModeIndex, 2};
if isempty(val)
    app.AlertArea.Value = { ...
        erase(sprintf('HgtAxes.XLim: %s', formattedDisplayText(app.HgtAxes.XLim)), ...
        newline) ...
        'PageLims: []' ...
        };
    return;
end

try
    app.AlertArea.Value = { ...
        erase(sprintf('HgtAxes.XLim: %s (%s)', formattedDisplayText(app.HgtAxes.XLim), ...
        formattedDisplayText(app.FPRulers{1+~isnumeric(val)+isduration(val),1}.Limits)), ...
        newline) ...
        erase(sprintf('PageLims: %s', formattedDisplayText(val)),newline) ...
        };
catch ME
    fprintf('[postset_Page] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
end
try
    if ~isnumeric(val)
        val = ruler2num(val, app.FPRulers{2+isduration(val),1});
    end
    set(app.FPPagePatches, ...
        'XData', val([1 2 2 1]));
    app.FPPagePatches(1).YData = app.HgtAxes.YAxis(1).Limits([1 1 2 2]);
    app.FPPagePatches(2).YData = app.PosAxes.YLim([1 1 2 2]);
        %'YData', app.HgtAxes.YLim([1 1 2 2]));
catch ME
    fprintf('[postset_Page] Error "%s" while updating page patch vertex locations: %s\n', ...
        ME.identifier, getReport(ME));
    set(app.FPPagePatches, 'Visible', false);
    pv = true;
end

if pv
    try
        set(app.FPPagePatches, 'Visible', true);
        pv = false;
    catch ME
        fprintf('[postset_Page] Error "%s": %s\n', ...
            ME.identifier, getReport(ME));
        set(app.FPPagePatches, 'Visible', false);
        pv = true;
    end
end
drawnow limitrate nocallbacks;
end