function postset_PSBIndex(app, src, event) 
    % Must remember to also set PSBIndices whenever effective width changes...?
    % Or just set whenever channel layout confirmed?
    % Always set when new DP loaded
    % display({src.Name, event});

    if src.Name(4) ~= 'R' % Left changed
        app.Analyzer.PSBL = app.PSBIndices(1);
        % TODO: Try/Catch?
        if (app.PSBIndices(2) < app.MinPSBWidth) || ...
            (app.PSBIndices(1)+1+app.MinPSBWidth < app.fdm(2))
            % Can still move PSB left and/or right (drawing area width is gt 1)
            app.PSBRightSpinner.Limits = double([ ...
                app.PSBIndices(1)+1+app.MinPSBWidth, ...
                app.fdm(2)+1]);
            app.rightPSBLine.DrawingArea = ...
                [double(app.PSBIndices(1)+app.MinPSBWidth) 0 diff(app.PSBRightSpinner.Limits) double(app.fdm(1)+1)];
            app.PSBRightSpinner.Enable = true;
        else % Left changed and (now) there is no room to move right PSB
            app.rightPSBLine.DrawingArea(3) = 1;
            app.PSBRightSpinner.Enable = false;
        end
        % fprintf('Left changed to %g --> Right PSB: %g=%g:[%g, %g], DA: [%g, %g, %g, %g]\n', ...
        %     app.PSBIndices(1), app.PSBIndices(2), ...
        %     app.PSBRightSpinner.Value, app.PSBRightSpinner.Limits(1), ...
        %     app.PSBRightSpinner.Limits(2), app.rightPSBLine.DrawingArea(1), ...
        %     app.rightPSBLine.DrawingArea(2), app.rightPSBLine.DrawingArea(3), ...
        %     app.rightPSBLine.DrawingArea(4));
    end
    if src.Name(4) ~= 'L' % Right changed
        app.Analyzer.PSBR = app.PSBIndices(2);
        if (app.PSBIndices(1) > 1) || ...
            (app.PSBIndices(2) > (app.MinPSBWidth+1+1))
            % Can still move PSB left and/or right (drawing area width is gt 1)
            app.PSBLeftSpinner.Limits = double([ ...
                1, app.PSBIndices(2)-app.MinPSBWidth ...
            ]);
            app.leftPSBLine.DrawingArea = ...
                [0 0 diff(app.PSBLeftSpinner.Limits) double(app.fdm(1)+1)];
            app.PSBLeftSpinner.Enable = true;
        else
            app.leftPSBLine.DrawingArea(3) = 1;
            app.PSBLeftSpinner.Enable = false;
        end
        % fprintf('Right changed to %g --> Left PSB: %g=%g:[%g, %g], DA: [%g, %g, %g, %g]\n', ...
        %     app.PSBIndices(2), app.PSBIndices(1), ...
        %     app.PSBLeftSpinner.Value, app.PSBLeftSpinner.Limits(1), ...
        %     app.PSBLeftSpinner.Limits(2), app.leftPSBLine.DrawingArea(1), ...
        %     app.leftPSBLine.DrawingArea(2), app.leftPSBLine.DrawingArea(3), ...
        %     app.leftPSBLine.DrawingArea(4));
    end
    
    if ~app.IsRecording && app.SelectedIndex
        app.ReanalyzeButton.Enable = true;
    end
    drawnow limitrate;
end


% Error in images.roi.internal.ROI 
% Warning: Error occurred while executing the listener callback for event WindowMouseMotion defined for class matlab.ui.Figure:
% Error using  + 
% Integers can only be combined with integers of the same class, or scalar doubles.
% Error in images.roi.internal.ROI/dragROI