function restorePreviewOrder(app, divlines)
arguments(Input)
    app;
    divlines = true;
end
if ~isempty(app.shadRects(1).Position) %&& app.shadRects(1).Position(4) %.Visible=="on"
    bringToFront(app.shadRects(1));
end
if ~isempty(app.shadRects(2).Position) %&& app.shadRects(2).Position(4) %.Visible=="on"
    bringToFront(app.shadRects(2));
end

%if app.highRect.Visible=="on"
%    bringToFront(app.highRect);
%end

%bringToFront(app.leftPSBLine);
%bringToFront(app.rightPSBLine);

bringToFront(app.topCropLine);%.bringToFront;
bringToFront(app.botCropLine);%.bringToFront;

if divlines
    for i=1:app.NumChannels-1
        bringToFront(app.ChanDivLines(i));
    end
end
end