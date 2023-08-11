function onYAxisLimitsChanged(app, src, event)
    p = app.FPSelPatches(src.Parent.Tag-48);
    pp = app.FPPagePatches(src.Parent.Tag-48);
    %if (event.OldLimits(1) > event.NewLimits(2)) || (event.OldLimits(2) < event.NewLimits(2))
    % Extends beyond
    % msk = ~ismember(src.Parent.Children, {p, pp});
    % lines = src.Parent.Children(1:end-2); % TODO: Must change this if add any other children...
    if p.Visible % && ~isempty(p.XData)
        % p.YData = cumsum(event.NewLimits) + [0 -1];
        % p.YData = event.NewLimits([1 1 2 2]);
        set([p pp], 'YData', event.NewLimits([1 1 2 2])); % p.YData);
    else
        set(pp, 'YData', event.NewLimits([1 1 2 2]));
    end
end