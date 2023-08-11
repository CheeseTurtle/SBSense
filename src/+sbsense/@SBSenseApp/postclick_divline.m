function postclick_divline(app,src,eventData)
arguments(Input)
    app sbsense.SBSenseApp;
    src;
    eventData images.roi.ROIClickedEventData;
end
if eventData.SelectionType == "ctrl"
    src.Selected = false;
else
    src.Selected = true;
    srcTag = uint8(src.Tag-48);
    set([app.CropLines ...
        app.ChanDivLines(1:srcTag) ...
        app.ChanDivLines(srcTag+1:end)], ...
        'Selected', false);
end
end