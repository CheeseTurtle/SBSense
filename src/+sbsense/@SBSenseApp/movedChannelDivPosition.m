function movedChannelDivPosition(app, idx, y)
if idx>1
    below = app.ChanDivLines(idx-1);
    belowspin = app.ChanDivSpins(idx-1);
    limabove = y + 1 + app.MinMinChanHeight;
    limbelow = y - 1 - app.MinMinChanHeight;
    belowspin.Limits(2) = limbelow;
    below.DrawingArea(4) = limbelow - below.DrawingArea(2) + 1;
    %else
    %    below = app.botCropLine;
    %    belowspin = app.MinYSpinner;
end
if idx < (app.NumChannels - 1)
    above = app.ChanDivLines(idx+1);
    abovespin = app.ChanDivSpins(idx+1);
    difabove = limabove - abovespin.Limits(1);
    abovespin.Limits(1) = limabove;
    above.DrawingArea(2) = limabove;
    above.DrawingArea(4) = max(1, above.DrawingArea(4)-difabove);
    %else
    %    above = app.topCropLine;
    %    abovespin = app.MaxYSpinner;
end
end