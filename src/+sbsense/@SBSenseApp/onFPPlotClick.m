function onFPPlotClick(app, src, ev)
    if isempty(app.DataTable{1}) || ismissing(app.TimeZero)
        return;
    end

    % disp(ev.IntersectionPoint(1));

    if bitget(app.XAxisModeIndex, 2) % Time mode
        x = num2ruler(ev.IntersectionPoint(1), app.HgtAxes.XAxis);
        if ~bitget(app.XAxisModeIndex, 1) % Abs mode
            x = x - app.TimeZero; % datetime to duration
        end
        [~, idx] = min(abs(app.DataTable{1}.RelTime - x), [], 'omitnan');
    else % Index mode
        x = uint64(round(ev.IntersectionPoint(1)));
        if (x < 1)
            idx = 1;
        elseif (x > app.LargestIndexReceived)
            idx = app.LargestIndexReceived;
        elseif  ismember(x, app.DataTable{1}.Index) % (x~=app.SelectedIndex) &&
            idx = x;
        else
            [~, idx] = min(max(app.DataTable{1}.Index, x) - min(app.DataTable{1}, x));
        end
    end
    if app.SelectedIndex == idx
        panToIndex(app, app.SelectedIndex, 2);
    else
        app.SelectedIndex = idx;    
    end
end