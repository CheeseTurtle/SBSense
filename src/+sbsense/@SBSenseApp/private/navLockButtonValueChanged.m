function navLockButtonValueChanged(app, src, event) % TODO: arguments
    if src.Tag == 'N' % range % TODO: Lock button tags
        if event.Value%app.LockRangeButton.Value
            app.LockLeftButton.Value = true;
            app.LockRightButton.Value = true;
        else
            app.LockLeftButton.Value = app.LockLeftValue;
            app.LockRightButton.Value = app.LockRightValue;
        end
        app.LockRangeValue = event.Value; %app.LockRangeButton.Value;
        app.XNavZoomMode = event.Value;
        %navzoomChanged(app);
    else
        if src.Tag == 'L' % left
            app.LockLeftValue = event.Value; %app.LockLeftButton.Value;
            %if ~app.LockLeftButton.Value && app.LockRightButton && app.LockRangeButton
            %    app.LockRangeButton.Value = false;
            %end
        else % right
            app.LockRightValue = event.Value; %app.LockRightButton.Value;
        end
        if xor(app.LockLeftButton.Value, app.LockRightButton.Value)
            app.LockRangeButton.Value = false;
            app.XNavZoomMode = false;
            %navzoomChanged(app);
        elseif app.LockLeftButton.Value
            app.LockRangeButton.Value = true;
            app.XNavZoomMode = true;
            %navzoomChanged(app);
        end
    end
    %setNavSliderFcn(app);
end

