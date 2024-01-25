function postmove_divline(app, src, event)
%fprintf('<!>');
persistent fut pv chBoundsPositions1; %#ok<PSET> 
if event.EventName(1) == 'V'
    isSpin = true;
    shapeDone = (event.EventName(11) == 'e');
else
    isSpin = false;
    shapeDone = event.EventName(1)=='R';%~startsWith(event.Name, "Moving");
    %disp(event.EventName);
end
try
    srcTag = uint8(src.Tag(1)-48);
    % fprintf('(Tag: %d)', srcTag);
    if ~shapeDone
        if isempty(pv)
            chBoundsPositions1 = app.ChBoundsPositions;
            pv = true;
        end
        if ~isempty(fut)
            cancel(fut);
        end
        if isSpin % source is spinner, changing
            if src.Tag(2)=='p' % pos spinner
                spreadDist = 2\(app.ChannelDivHeights(srcTag+1) - 1);
                % app.ChBoundsPositions(srcTag+1, :) = [value-spreadDist, value+spreadDist];
                ny = [event.Value-spreadDist ; event.Value+spreadDist];
                % disp({event.Value, spreadDist, ny'});
            else % height spinner
                disp(event.Value);
                app.ChannelDivHeights(srcTag+1) = uint16(ceil(event.Value));
                spreadDist = 2\(event.Value-1);
                pos = mean(app.ChBoundsPositions(srcTag+1,:));
                % app.ChBoundsPositions(srcTag, :) = [pos-spreadDist, pos+spreadDist];
                ny = [pos-spreadDist ; pos+spreadDist];
                % disp({pos, spreadDist, ny'});
            end
            % app.ChanDivLines(srcTag).Position(:,2) = double(ny);
            app.ChanDivLines(srcTag).Position(1:4, 2) = repelem(double(ny), 2, 1);
        else % source is ROI, moving
            %fprintf('[postmove_divline] Unrounded position: %0.4g\n', event.CurrentPosition(1,2));
            % ny = round(event.CurrentPosition(1,2));
            ny = event.CurrentPosition([2 3],2);
            fprintf('[postmove_divline] Unrounded pos: [%0.4g %0.4g], Rounded position: %0.4g\n', ny(1), ny(2), double(round(mean(ny))));
            app.ChanDivSpins(srcTag).Value = double(round(mean(ny))); % double(ny);
        end

        chBoundsPositions1(srcTag+1, :) = ny';

        % fut1 = parfeval(backgroundPool, ...
        %     @sbsense.SBSenseApp.calcChannelHeightFromNthDiv, 2, ...
        %     chBoundsPositions1, srcTag);
        % fut = [fut1, afterEach(fut1, ...
        %     @(f) app.setChannelHeightFieldsFromFut(srcTag,f), ...
        %     0, 'PassFuture', true)];
        % app.chHeightFut = fut;
        % wait(fut, 'finished', 0.1);
        % pause(0.01);
        
        app.chHeightFut = parallel.Future.empty();
        [hgt1,hgt2] = sbsense.SBSenseApp.calcChannelHeightFromNthDiv( ...
            chBoundsPositions1, srcTag);
        app.ChanHgtFields(srcTag).Value = hgt1;
        app.ChanHgtFields(srcTag+1).Value = hgt2;
        %display(fut);
        drawnow limitrate;
    else % shapeDone
        app.ConfirmStatus = false;
        app.ChLayoutConfirmButton.Enable = false;
        if isSpin
            %ny = event.Value;
            %divspin = src;
            if src.Tag(2)=='p' % pos spinner
                spreadDist = 2\(app.ChannelDivHeights(srcTag+1) - 1);
                ny = [event.Value-spreadDist ; event.Value+spreadDist];
                divspin = src;
                %disp({event.Value, spreadDist, ny'});
            else % height spinner
                app.ChannelDivHeights(srcTag+1) = uint16(event.Value);
                spreadDist = 2\(event.Value-1);
                pos = mean(app.ChBoundsPositions(srcTag+1,:));
                ny = [pos-spreadDist ; pos+spreadDist];
                divspin = app.ChanDivSpins(srcTag);
                %disp({pos, spreadDist, ny'});
            end
            divline = app.ChanDivLines(srcTag);
            %if app.ChannelDivHeights(srcTag+1)<2
            %    keyboard;
            %end
        else
            divspin = app.ChanDivSpins(srcTag);
            divline = src;
            ny = round(event.CurrentPosition([2 3],2));
            ny = min(divspin.Limits(2), ny);
            ny = max(divspin.Limits(1), ny);
            % display(ny);
            % disp({event.CurrentPosition([2 3 4]), ny'});
        end
        divspin.Value = double(round(mean(ny)));
        divline.Position(1:4,2) = repelem(double(ny), 2, 1);
        
        %if ~isempty(chBoundsPositions1)
        %    app.ChBoundsPositions = chBoundsPositions1;
        %end
        app.ChBoundsPositions(srcTag+1,:) = ny';

        %fut1 = parfeval(backgroundPool, ...
        %    @sbsense.SBSenseApp.calcChannelHeightFromNthDiv, 2, ...
        %    app.DivBoundsPositions, srcTag);
        %fut = [ fut1 afterEach(fut1, ...
        %    @(f) app.setChannelHeightFieldsFromFut(srcTag,f), ...
        %    0, 'PassFuture', true)];
        % app.chHeightFut = fut;

        % hs = double(diff(app.ChBoundsPositions(srcTag:srcTag+2)));
        dp = app.ChBoundsPositions(srcTag:srcTag+2, :);
        % display(dp);
        % dp = fliplr(dp); dp = dp(2:end-1);
        dp = fliplr(reshape(dp(2:end-1), [], 2));
        % display(dp);
        % dp = fliplr(reshape(dp, [], 2));
        % display(dp);
        % hs = double(diff(dp,1,1) - 1);
        hs = double(diff(dp,1,2) - 1);
        % display(hs);
        app.ChanHgtFields(srcTag).Value = hs(1);
        app.ChanHgtFields(srcTag+1).Value = hs(2);
        app.ChannelHeights([srcTag, srcTag+1]) = hs;

        buf = double(app.MinMinChanHeight + 1);
        if srcTag>1
            value = ny(1) - buf;
            divspin = app.ChanDivSpins(srcTag-1);
            divspin.Limits(2) = double(value);
            app.ChanDivLines(srcTag-1).DrawingArea(4) = diff(divspin.Limits); %+ 1;
            %app.ChanDivHeightSpins(srcTag).Limits(2) = min( ...
            %    app.ChanDivHeightSpins(srcTag).Limits(2), ...
            %    app.ChanDivLines(srcTag).Position(2,1) - value);
            newLim = max(1, 2*min(abs(divspin.Value - divspin.Limits)));
            if newLim > 1
                app.ChanDivHeightSpins(srcTag-1).Limits(2) = newLim;
                app.ChanDivHeightSpins(srcTag-1).Enable = true;
            else
                app.ChanDivHeightSpins(srcTag-1).Value = 1;
                % app.ChanDivHeightSpins(srcTag-1).Limits(2) = 2;
                app.ChanDivHeightSpins(srcTag-1).Enable = false;
            end
            if ~isempty(app.ChanDivLines(srcTag-1).UserData)
                set(app.ChanDivLines(srcTag-1).UserData, 'Position', ...
                    app.ChanDivLines(srcTag-1).DrawingArea);
            end
        end
        if srcTag<(app.NumChannels-1)
            value = ny(2) + buf;
            divspin = app.ChanDivSpins(srcTag+1);
            % divline = app.ChanDivLines(srcTag+1);
            divspin.Limits(1) = value;
            app.ChanDivLines(srcTag+1).DrawingArea([2 4]) = ...
                divspin.Limits - double([0 value]);
            %app.ChanDivHeightSpins(srcTag).Limits(2) = min( ...
            %    app.ChanDivHeightSpins(srcTag).Limits(2), ...
            %    value - app.ChanDivLines(srcTag).Position(2,2));
            newLim = max(1, 2*min(abs(divspin.Value - divspin.Limits)));
            if newLim > 1
                app.ChanDivHeightSpins(srcTag+1).Limits(2) = newLim;
                app.ChanDivHeightSpins(srcTag+1).Enable = true;
            else
                app.ChanDivHeightSpins(srcTag+1).Value = 1;
                % app.ChanDivHeightSpins(srcTag-1).Limits(2) = 2;
                app.ChanDivHeightSpins(srcTag+1).Enable = false;
            end
            if ~isempty(app.ChanDivLines(srcTag+1).UserData)
                set(app.ChanDivLines(srcTag+1).UserData, 'Position', ...
                    app.ChanDivLines(srcTag+1).DrawingArea);
            end
        end
        if ~isSpin && ~isempty(src.UserData) % && isproperty(src.UserData, 'Position')
            set(src.UserData, 'Position', src.DrawingArea);
        end

        if ~isempty(fut)            
            wait(fut); % TODO: Timeout?
            % display(fut);
            clear fut;
        end
        drawnow limitrate;
        clear pv;
        app.ChLayoutConfirmButton.Enable = true;
    end
catch ME
    fprintf('[postmove_divline] %s\n', getReport(ME));
    clear pv;
    app.ChLayoutConfirmButton.Enable = true;
end
end

function setChannelDivCenterPos(app, idx, value)
    spreadDist = 2\(app.ChannelDivHeights(idx+1) - 1);
    app.ChBoundsPositions(idx+1, :) = [value-spreadDist, value+spreadDist];
end

function setChannelDivHeight(app, idx, value)
    app.ChannelDivHeights(idx+1) = uint16(value);
    spreadDist = 2\(value-1);
    pos = mean(app.ChBoundsPositions(idx+1,:));
    app.ChBoundsPositions(idx+1, :) = [pos-spreadDist, pos+spreadDist];
end