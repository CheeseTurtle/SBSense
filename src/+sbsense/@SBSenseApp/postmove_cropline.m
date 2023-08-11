function postmove_cropline(app, varargin)
persistent pv;
%fprintf('onCropMovement (%d)\n', nargin);
%celldisp(varargin);
if nargin > 2
    src = varargin{1};
    event = varargin{2};
    isSpin = (event.EventName(1) == 'V');
else
    event = varargin{1};
    src = event.Source;
    isSpin = false;
end
if isSpin
    %ValueChanging
    %ValueChanged
    shapeDone = (event.EventName(11) == 'e');
else
    shapeDone = event.EventName(1)=='R';%~startsWith(event.Name, "Moving");
end
try
    srcTag = uint8(src.Tag-48);
    if ~shapeDone
        if ~pv
            set(app.ChanDivLines, 'Visible', false);
            pv = true;
        end
        if isSpin % source is spinner, changing
            ny = src.Value;
            app.CropLines(srcTag).Position(:,2) = double(ny);
            % drawnow limitrate;
        else % source is ROI, moving
            ny = round(event.CurrentPosition(1,2));
            cropspin = app.CropSpins(srcTag);
            %if srcTag == 1
            %    ny = max(cropspin.Limits(1), min(cropspin.Limits(2), ny));
            %else
            %    ny = min(cropspin.Limits(2), max(cropspin.Limits(1), ny));
            %end
            %disp(ny);
            if ny < cropspin.Limits(1)
                ny = cropspin.Limits(1);
            elseif ny > cropspin.Limits(2)
                ny = cropspin.Limits(2);
            end
            try
                cropspin.Value = double(ny);
            catch ME
                display(ny);
                display(double(ny));
                display(cropspin.Limits);
                rethrow(ME);
            end
            src.Position(:,2) = double(ny); % TODO: Remove??
            % TODO: Only for PSB!!!
            %                         if (~app.highRect.Selected || ~app.highRect.FaceAlpha) ...
            %                                 && ((roiTag == "leftHL") || (roiTag == "rightHL"))
            %                             % TODO: Move to click etc instead?
            %                             app.highRect.Selected = true;
            %                             app.highRect.FaceAlpha = 0.2;
            %                             % else
            %                             % %eventData.Source.Selected = true;
            %                         end
        end
        if srcTag == 1
            if ny > 2
                app.shadRects(1).Position(4) = ny - 1;
            else
                app.shadRects(1).Position(4) = 0;
            end
        elseif srcTag == 2 % src.Tag == '2'
            if app.fdm(2) > ny  
                app.shadRects(2).Position([2 4]) = ...
                    [ny+1 double(app.fdm(1))+1-ny];
            else
                app.shadRects(2).Position(4) = 0;
            end
        else
            error('srcTag has unexpected value: %s', formattedDisplayText(srcTag));
        end
        % TODO: parfeval Future
        set(app.CroppedHeightField, 'Value', ...
            app.MaxYSpinner.Value - app.MinYSpinner.Value + 1 - double(app.NumChannels));
    else % shapeDone
        ny = app.CropSpins(srcTag).Value;
        % app.CropBounds(srcTag) = ny;
        if srcTag == 1
            app.BotCropBound = ny;
        else
            app.TopCropBound = ny;
        end
        
        if ~isempty(app.ChanDivLines)
            set(app.ChanDivLines, 'Visible', true);
        end
        pv = false;
    end
catch ME
    fprintf('[onCropMovement] ERROR: %s\n', getReport(ME));
    if ~isempty(app.ChanDivLines)
        set(app.ChanDivLines, 'Visible', true);
    end
    pv = false;
end
end