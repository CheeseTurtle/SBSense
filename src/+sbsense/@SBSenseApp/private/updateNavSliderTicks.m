function updateNavSliderTicks(app)
resUnit = pow2(app.XResKnob.Value);

% Nav slider limits (datatype: double) should be in # datapoints or in # seconds
minorTicks = sbsense.utils.colonspace(app.XNavSlider.Limits(1), resUnit, ...
    app.XNavSlider.Limits(2));
[majorUnit, majorFormat, sfac] = sbsense.SBSenseApp.chooseMajorResUnit(app.XAxisModeIndex, resUnit);
majorTicks = sbsense.utils.colonspace(app.XNavSlider.Limits(1), majorUnit, ...
        app.XNavSlider.Limits(2));
    
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
set(app.XNavSlider, 'MajorTicks', majorTicks, 'MajorTickLabels', majorLabels, ...
    'MinorTicks', minorTicks);
end