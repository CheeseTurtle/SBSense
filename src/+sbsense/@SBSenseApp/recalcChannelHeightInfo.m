function varargout = recalcChannelHeightInfo(app,setEH)
arguments(Input)
    app; setEH = true;
end
numch = uint16(app.NumChannels);
fprintf('[recalc] numch: %d\n', numch);
croppedHeight = uint16( ...
    (app.TopCropBound - app.BotCropBound) - 1) - numch;
fprintf('[recalc] croppedHeight: %d\n', croppedHeight);
app.MinMinChanHeight = idivide(uint16(app.fdm(1)), ...
    app.MinChanHeightDenom, "ceil");
fprintf('[recalc] MinMinChanHeight: %d\n', app.MinMinChanHeight);
%app.MinChanHeight = idivide(croppedHeight,app.MinChanHeightDenom,"ceil");
app.MinCropHeight = numch*(app.MinMinChanHeight+1) - 1;
fprintf('[recalc] MinCropHeight: %d\n', app.MinCropHeight);
app.MaxNumChannels = max(min(app.MaxMaxNumChs, ...
    floor((croppedHeight+1)/(app.MinMinChanHeight + 1))),...
    1);
fprintf('[recalc] MaxNumChannels: %d\n', app.MaxNumChannels);
set(app.NumChSpinner, ...
    ...%'Enable', (app.MaxNumChannels>1), ...
    'Value', double(min(app.NumChannels, app.MaxNumChannels)), ...
    'Limits', double([1 max(app.MaxNumChannels,2)]));

value = app.TopCropBound - 1 - app.MinCropHeight;
app.MinYSpinner.Limits(1,2) = value;
app.botCropLine.DrawingArea(4) = value;
value = app.BotCropBound + app.MinCropHeight + 1;
app.MaxYSpinner.Limits(1) = value;
app.topCropLine.DrawingArea([2 4]) = ...
    [ value app.fdm(1)+1-value ];
if setEH
    app.NominalChannelHeight = idivide( ...
        croppedHeight, numch, "fix");
end
if nargout
    varargout = {croppedHeight, numch};
end
end