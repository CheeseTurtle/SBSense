function updateXAxisMajorTicks(app)
resUnit = pow2(app.XResKnob.Value);
[majorUnit, majorFormat, sfac] = sbsense.SBSenseApp.chooseMajorResUnit(app.XAxisModeIndex, resUnit);

lims = app.HgtAxes.XLim;
% if bitget(app.XAxisModeIndex, 2)
%     resUnit = seconds(resUnit);
%     %if ~bitget(app.XAxisModeIndex,1)
%     %    lims = lims - app.TimeZero;
%     %end
%     %lims = seconds(lims);
% end
majorTicks = colonspace(lims(1), majorUnit, ...
        lims(2));
    
if bitget(app.XAxisModeIndex, 2)
    if sfac >= 3600
        majorLabels = compose(majorFormat, 3600\majorTicks);
    else
        majorLabels = seconds(sfac\majorTicks);
        if ~bitget(app.XAxisModeIndex, 1)
            majorLabels = majorLabels + app.TimeZero;
        end
        majorLabels = string(majorLabels, majorFormat);
    end
else
    majorLabels = compose(majorFormat, majorTicks);
end
set([app.PosAxes.XAxis app.HgtAxes.XAxis], 'TickValues', majorTicks);
set(app.HgtAxes.XAxis, 'TickLabels', majorLabels);
end