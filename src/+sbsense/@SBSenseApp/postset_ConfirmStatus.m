function postset_ConfirmStatus(app, ~, ~)
    % fprintf('[postset_ConfirmStatus] %d\n', int8(app.ConfirmStatus));
    % TODO: Dull color, check icon
    % Enable relevant controls
    if app.ConfirmStatus
        % app.ChLayoutConfirmButton.Color = 
        app.ChLayoutConfirmButton.Icon = 'success';
            
        % TODO: Set up axes!!!  
        if any(isvalid(app.IPdataLines))
            delete(app.IPdataLines);
        end
        if any(isvalid(app.IPfitLines))
            delete(app.IPfitLines);
        end
        if any(isvalid(app.IPpeakLines))
            delete(app.IPpeakLines);
        end
        if ~isempty(app.IPzoneRects) && all(isgraphics(app.IPzoneRects),'all') && any(isvalid(app.IPzoneRects),'all')
            delete(app.IPzoneRects);
            % delete(app.IPzoneRects(ishghandle(app.IPzoneRects)));
        end
        if any(isvalid(app.IPpatches))
            delete(app.IPpatches);
        end
        app.IPdataLines = matlab.graphics.primitive.Line.empty(0, app.NumChannels);
        app.IPfitLines = matlab.graphics.chart.primitive.Area.empty(0, app.NumChannels);
        app.IPpeakLines = matlab.graphics.chart.decoration.ConstantLine.empty(0, app.NumChannels);
        app.IPzoneRects = repelem(matlab.graphics.GraphicsPlaceholder, 1, app.NumChannels); % images.roi.Rectangle.empty(0, app.NumChannels);
        app.IPpatches = matlab.graphics.primitive.Patch.empty(0, app.NumChannels);
        app.IPzoneRects = gobjects(2,app.NumChannels);
        for i=1:app.NumChannels
            ax = nexttile(app.tl, i);
            cla(ax);
            setupIPAxis(app, ax, i);
        end
        % app.ChannelDivHeights = zeros(app.NumChannels+1,1);
        % for i=2:app.NumChannels
        %     app.ChannelDivHeights(i) = diff(app.ChBoundsPositions(i-1,:))+1;
        % end
    else
        % app.ChLayoutConfirmButton.Color =
        if ~isempty(app.RefImage)
            app.ChLayoutConfirmButton.Icon = 'warning';
        else
            app.ChLayoutConfirmButton.Icon = '';
        end
        % Set up axes?
    end

    
    
    set([app.leftPSBLine, app.rightPSBLine, ...
        app.DataImageAxes, app.dataimg], ...
        'Visible', app.ConfirmStatus);
    sbsense.SBSenseApp.enablehier(app.RatePanel, app.ConfirmStatus);
    set([app.RecPanel app.RecButton app.RatePanel ...
        app.RecLabel app.RecStatusArea, app.IProcPanel], 'Enable', app.ConfirmStatus);
    set(findobj(app.RatePanel.Children, '-property', 'Enable'), 'Enable', app.ConfirmStatus);
    % app.ChLayoutConfirmButton.Enable = ~app.ConfirmStatus;
end