function applyVisibleYLims(app, hgtLims, posLims)
    if ~isempty(hgtLims)
        app.HgtAxes.YAxis(1).Limits = hgtLims;
        app.FPPagePatches(1).YData = hgtLims([1 1 2 2]);
    end
    if ~isempty(posLims)
        app.PosAxes.YAxis.Limits = posLims;
        app.FPPagePatches(2).YData = posLims([1 1 2 2]);
    end
end