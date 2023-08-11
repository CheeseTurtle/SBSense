function navzoomChanged(app)
    % % TODO: Disable relevant controls
    % try 
    %     if app.LockRangeButton.Value % Just switched to pan mode
    %         futs = app.ZoomFutures;
    %     else % Just switched to zoom mode
    %         futs = app.PanFutures;
    %     end
    %     if ~isempty(futs) && isa(futs, 'parallel.Future') % && all(isvalid(futs))
    %         %futs = futs(isvalid(futs));
    %         futs = futs(~strcmp({futs.State}, 'unavailable'));
    %         fut0 = afterAll(futs, ...
    %             @() parfeval(backgroundPool, @app.calcNavSliderLimits, 2), ...
    %             0, 'PassFuture', false);
    %         fut = afterAll(fut0, @app.navzoomChangedCleanup, 0, ...
    %             'PassFuture', true);
    %     end
    % catch
    %     % TODO: Enable relevant controls
    %     navzoomChangedErrorCleanup(app);
    % end
end