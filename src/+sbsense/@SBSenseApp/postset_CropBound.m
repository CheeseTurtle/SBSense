function postset_CropBound(app, src, ~) %eventData)
arguments(Input)
    app sbsense.SBSenseApp;
    src; %meta.property;
    ~;%eventData event.EventData;
end
fprintf('=====================================\n');
%fprintf('%s', formattedDisplayText(eventData));
fprintf('[postset_CropBound] Src: %s\n', src.Name);
if src.Name(1) == 't' % topCB
    value = max(double(app.MinCropHeight), ...
        double(app.TopCropBound - 1 - app.MinCropHeight));
    app.MinYSpinner.Limits(1,2) = value;
    app.botCropLine.DrawingArea(4) = value;
    if ~isempty(app.botCropLine.UserData)
        app.botCropLine.UserData.Position(4) = value;
    end
else % botCB
    value = double(app.BotCropBound + app.MinCropHeight + 1);
    value = min(value, double(app.fdm(1)-app.MinCropHeight-1));
    app.topCropLine.DrawingArea([2 4]) = ...
        double([ value app.fdm(1)+1-value ]); % or app.fdm(1)+2-value?
    app.MaxYSpinner.Limits(1,1) = double(value);
    if ~isempty(app.topCropLine.UserData)
        app.topCropLine.UserData.Position([2 4]) ...
            = app.topCropLine.DrawingArea([2 4]);
    end
end
drawnow limitrate;
fprintf('[postset_CropBound] Setting EffHeight to %0.4g\n', ...
    double(app.TopCropBound - app.BotCropBound));
app.EffHeight = app.TopCropBound - app.BotCropBound + 1 - app.NumChannels;
end