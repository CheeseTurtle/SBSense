function toggleFPLegends(app)
    if isempty(app.DataTable{1})
        return;
    end
    if ~isa(app.PosAxes.Legend, 'matlab.graphics.illustration.Legend') || ~isvalid(app.PosAxes.Legend)
        hgtLegendExists = (isa(app.HgtAxes.Legend, 'matlab.graphics.illustration.Legend') && isvalid(app.HgtAxes.Legend));
        if hgtLegendExists
            vis = ~app.HgtAxes.Legend.Visible;
        else
            vis = true;
        end
        legend(app.PosAxes, app.channelPeakPosLines, 'Location', 'best', 'ItemHitFcn', {@sbsense.SBSenseApp.onLegendClick}, ...
            'Visible', vis, 'UserData', app.channelPeakPosLines, 'ContextMenu', gobjects(0), 'Color', [1 1 1], 'AutoUpdate', false);
        if hgtLegendExists
            set(app.HgtAxes.Legend, 'Location', 'best', 'Visible', vis);
            return;
        end
    else
        hgtLegendExists = isa(app.HgtAxes.Legend, 'matlab.graphics.illustration.Legend') && isvalid(app.HgtAxes.Legend);
    end
    if ~hgtLegendExists
        legend(app.HgtAxes, [app.channelPeakHgtLines app.eliPlotLine], 'Location', 'best', 'ItemHitFcn', {@sbsense.SBSenseApp.onLegendClick}, ...
            'AutoUpdate', false, ...
            'UserData', [app.channelPeakHgtLines app.eliPlotLine], 'ContextMenu', gobjects(0), 'Visible', app.PosAxes.Legend.Visible, 'Color', [1 1 1]);
        vis = true;
    else
        vis = ~(app.HgtAxes.Legend.Visible && app.PosAxes.Legend.Visible);
    end
    if vis
        set([app.HgtAxes.Legend, app.PosAxes.Legend], 'Location', 'best', 'Visible', true);
    else
        set([app.HgtAxes.Legend, app.PosAxes.Legend], 'Visible', false);
    end
end