function postclick_cropline(app, src, eventData)
arguments(Input)
    app sbsense.SBSenseApp;
    src;
    eventData images.roi.ROIClickedEventData;
end
%set(app.CropLines, 'Selected', ...
%    eventData.SelectionType ~= "ctrl");
% src.Selected = eventData.SelectionType ~= "ctrl";
%disp(src);
%disp(eventData);
if eventData.SelectionType == "ctrl"
    src.Selected = false;
else
    src.Selected = true;
    app.CropLines(bitxor(uint8(src.Tag)-48,3)).Selected = false;
    if ~isempty(app.ChanDivLines)
        set(app.ChanDivLines, 'Selected', false);
    end
end
end