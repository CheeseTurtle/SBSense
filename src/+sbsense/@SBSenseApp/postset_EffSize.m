function postset_EffSize(app, src, ~)
fprintf('\n ===============================\n[postset_EffSize] src: %s\n', src.Name);
%arguments(Input)
%app sbsense.SBSenseApp;
%src meta.property;
% ~ event.EventData;
%end

persistent co;
if isempty(co)
    co = colororder(app.PreviewAxes);
end

numch = uint16(app.NumChannels);
numch1 = numch + 1;
%fprintf('[recalc] numch: %d\n', numch);

switch src.Name
    case "NumChannels"
        %app.MinMinChanHeight = idivide(uint16(app.fdm(1)), ...
        %    app.MinChanHeightDenom, "ceil");
        % fprintf('[recalc] MinMinChanHeight: %d\n', app.MinMinChanHeight);
        %app.MinChanHeight = idivide(app.EffHeight,app.MinChanHeightDenom,"ceil");
        postset_NumChannels(app);
        fprintf('ChanDivLines:\n'); display(app.ChanDivLines);
    case "EffHeight"
        % No special calculations necessary.
        app.CroppedHeightField.Value = double(app.EffHeight);
    otherwise % Crop bound(s)
        fprintf('[postset_EffSize] Otherwise... (src=%s)\n', src.Name);
        if (app.ChBoundsPositions(1,1)+app.MinCropHeight+1) >= app.ChBoundsPositions(end,1)%(app.fdm(1)+1) % app.ChBoundsPositions(end)
            % display(app.ChBoundsPositions);
            if 0==app.ChBoundsPositions(1,1)
                %fprintf('Cannot move upper bound any lower.\n');
                fprintf('Cannot move lower bound any lower or higher.\n');
                app.MinYSpinner.Enable = false;
                app.botCropLine.DrawingArea(4) = 1;
            else
                fprintf('Can still move lower bound higher (or lower).\n');
                app.MinYSpinner.Enable = true;
            end
            if app.ChBoundsPositions(end,1)>app.fdf(1)
                %fprintf('Cannot move lower bound any higher.\n');
                fprintf('Cannot omve upper bound any higher or lower.\n');
                app.MaxYSpinner.Enable = false;
                app.topCropLine.DrawingArea(4) = 1;
            else
                fprintf('Can still move upper bound lower (or higher).\n');
                app.MaxYSpinner.Enable = true;
            end
        else
            fprintf('Can still move lower bound higher (or lower).\n');
            app.MinYSpinner.Enable = true;
            fprintf('Can still move upper bound lower (or higher).\n');
            app.MaxYSpinner.Enable = true;
        end
        if app.MaxYSpinner.Enable && ~strcmp(src.Name, "TopCropBound")
            value = double(app.ChBoundsPositions(1,1) + app.MinCropHeight);
            app.MaxYSpinner.Limits = double([value, double(app.fdm(1))] + 1);
            app.topCropLine.DrawingArea([2 4]) = ...
                double(app.MaxYSpinner.Limits - [0, value]);
        end
        if app.MinYSpinner.Enable && ~strcmp(src.Name, "BotCropBound")
            %fprintf('[postset_EffSize] Setting bottom crop stuff due to src %s. app.ChBoundsPositions:\n', src.Name);
            %disp(app.ChBoundsPositions);
            value = double(app.ChBoundsPositions(end,1) - app.MinCropHeight) - 1;
            fprintf('[postset_EffSize] Setting spinner limits.\n');
            app.MinYSpinner.Limits = double([0, value - 1]);
            fprintf('[postset_EffSize] Setting cropline drawing area.\n');
            app.botCropLine.DrawingArea(4) = double(value); 
        end
        fprintf('[postset_EffSize] Setting EffHeight.\n');
        app.EffHeight = diff(app.ChBoundsPositions([1 end], 1)) + 1 - numch1;
        app.CroppedHeightField.Value = double(app.EffHeight);

        fprintf('MinCropHeight: %0.4g, MMCH: %0.4g\n', ...
                        app.MinCropHeight, app.MinMinChanHeight);
        fprintf('topCropLine position: %0.4g %0.4g ; %0.4g %0.4g\n', ...
            app.topCropLine.Position(1,1), app.topCropLine.Position(1,2), ...
            app.topCropLine.Position(2,1), app.topCropLine.Position(2,2));
        fprintf('topCropLine DrawingArea: %0.4g %0.4g %0.4g %0.4g\n', ...
            app.topCropLine.DrawingArea(1), app.topCropLine.DrawingArea(2), ...
            app.topCropLine.DrawingArea(3), app.topCropLine.DrawingArea(4));
        fprintf('topCropLine DrawingArea vert. "limits": %0.4g %0.4g\n', ...
            app.topCropLine.DrawingArea(2), ...
            app.topCropLine.DrawingArea(2) + app.topCropLine.DrawingArea(4) - 1);
        fprintf('MaxYSpinner Limits: %0.4g %0.4g\n', ...
            app.MaxYSpinner.Limits(1), app.MaxYSpinner.Limits(2));
        fprintf('botCropLine position: %0.4g %0.4g l %0.4g %0.4g\n', ...
            app.botCropLine.Position(1,1), app.botCropLine.Position(1,2), ...
            app.botCropLine.Position(2,1), app.botCropLine.Position(2,2));
        fprintf('botCropLine DrawingArea: %0.4g %0.4g %0.4g %0.4g\n', ...
            app.botCropLine.DrawingArea(1), app.botCropLine.DrawingArea(2), ...
            app.botCropLine.DrawingArea(3), app.botCropLine.DrawingArea(4));
        fprintf('botCropLine DrawingArea vert. "limits": %0.4g %0.4g\n', ...
            app.botCropLine.DrawingArea(2), ...
            app.botCropLine.DrawingArea(2) + app.botCropLine.DrawingArea(4) - 1);
        fprintf('MinYSpinner Limits: %0.4g %0.4g\n', ...
            app.MinYSpinner.Limits(1), app.MinYSpinner.Limits(2));

        if app.MaxYSpinner.Enable
            assert(isequal([app.topCropLine.DrawingArea(2), ...
                app.topCropLine.DrawingArea(2) + app.topCropLine.DrawingArea(4) - 1], ...
                app.MaxYSpinner.Limits));
        end
        if app.MinYSpinner.Enable
            assert(isequal([app.botCropLine.DrawingArea(2), ...
                app.botCropLine.DrawingArea(2) + app.botCropLine.DrawingArea(4) - 1], ...
                app.MinYSpinner.Limits));
        end
end

if src.Name ~= "NumChannels"
    app.MaxNumChannels = max(min(app.MaxMaxNumChs, ...
        floor((app.EffHeight+1)/(app.MinMinChanHeight + 1))),...
        1);
    fprintf('[recalc] MaxNumChannels: %d\n', app.MaxNumChannels);
    if (app.MaxNumChannels<=1)
        app.NumChSpinner.Enable = "off";
    else
        app.NumChSpinner.Enable = "on";
    end
    set(app.NumChSpinner, ...
        'Value', double(min(app.NumChannels, app.MaxNumChannels)), ...
        'Limits', double([1 max(app.MaxNumChannels,2)]));
    if app.NumChannels > app.MaxNumChannels
        app.NumChannels = app.MaxNumChannels;
        % numch = uint16(app.MaxNumChannels);
        postset_NumChannels(app);
        postset_EffSize(app, src, []);
        return;
    end
end

app.NominalChannelHeight = idivide( ...
    app.EffHeight, numch, "fix");
% fprintf('Recalculated nominal channel height.\n');
fprintf('[postset_EffSize] Nominal channel height: %lu\n', app.NominalChannelHeight);

app.ChannelHeights = zeros(1,numch,"uint16") + uint16(app.NominalChannelHeight);
app.ChannelDivHeights = uint16([0 ones(1,numch-1,'uint16') 0]);
% app.ChannelDivHeights(2:end-1) = 1;
[app.ChanDivHeightSpins.Value] = deal(double(1));

surp = app.EffHeight - app.NominalChannelHeight*numch;
fprintf('[postset_EffSize] Surp: %0.4g\n', surp);

numchParity = mod(numch, 2);
mid = idivide(numch+1, 2, "fix");
surpParity = mod(surp, 2);
if surpParity
    if numchParity
        app.ChannelHeights(mid) = app.ChannelHeights(mid) + 1;
        surp = surp - 1;
        surpParity = ~surpParity;
    end
    if (numch>2) && (surp>2)
        app.ChannelHeights([1 numch]) = ...
            app.ChannelHeights([1 numch]) + 1;
        surp = surp - 2;
    end
end
if surp
    if surpParity && (numch>2)
        surp1 = mod(surp, numch-2);
        if surp1 && numchParity
            app.ChannelHeights(mid) = app.ChannelHeights(mid) + 1;
            surp = surp - 1;
            surp1 = surp1 - 1;
        end
    else
        surp1 = surp;
    end
    if surp
        surp2 = idivide(surp1, numch-2);
        app.ChannelHeights(2:numch-1) = ...
            app.ChannelHeights(2:numch-1) - surp2;
        surp = surp - surp2*(numch-2);

        if surp
            app.ChannelHeights(1) = app.ChannelHeights(1) ...
                + idivide(surp,2,"ceil");
            app.ChannelHeights(numch) = app.ChannelHeights(numch) ...
                + idivide(surp,2,"floor");
        end
    end
end

if app.NumChannels>1
    % disp(repmat( ...
    % (cumsum(app.ChannelHeights(1:numch-1)) + ...
    % (1:numch-1)' + (app.ChBoundsPositions(1,1) + 1)), ...
    % 1, 2));
    app.ChDivPositions  = repmat( ...
        (cumsum(app.ChannelHeights(1:numch-1)) + ...
        (1:numch-1)' + (app.ChBoundsPositions(1,1) + 1)), ...
        1, 2);
else
    app.ChDivPositions = double.empty(0,2);
end

fprintf('[postset_EffSize] Heights: %s', formattedDisplayText(app.ChannelHeights));
fprintf('[postset_EffSize] ChBoundsPositions: %s', formattedDisplayText(app.ChBoundsPositions));
fprintf('[postset_EffSize] ChBoundsPositions diff: %s', formattedDisplayText(diff(app.ChBoundsPositions)));

% display(app.ChBoundsPositions);

for j=2:(numch)
    fprintf('j: %d\n', j);
    divline = app.ChanDivLines(j-1);
    divspin = app.ChanDivSpins(j-1);
    divypos = app.ChBoundsPositions(j,:)';
    
    buf = double(app.MinMinChanHeight + 1);
    st = double(app.ChBoundsPositions(j-1,2));
    en = double(app.ChBoundsPositions(j+1,1));
    fprintf('[postset_EffSize] (unbuffered) st: %0.4g, en: %0.4g, buf: %0.4g\n', st, en, buf);
    st1 = st + buf; en1 = en - buf;
    fprintf('[postset_EffSize] (buffered) st: %0.4g, en: %0.4g\n', st1, en1);
    assert(en1 >= st1); % TODO
    % if en <= st
    %     fprintf('[postset_EffSize] en <= st !!\n');
    %     %fprintf('[postset_EffSize] Setting drawing area.\n');
    %     divline.DrawingArea = double([ 1 divypos ...
    %         app.fdm(2) 1]);
    %     %fprintf('[postset_EffSize] Setting limits.\n');
    %     divspin.Limits = double(divypos + [0 1]);
    % else
    %     fprintf('[postset_EffSize] st < en.\n');
    %     %fprintf('[postset_EffSize] Setting drawing area.\n');
    %     divline.DrawingArea = double([ ...
    %         1 st app.fdm(2) (en-st+1) ]);
    %     %fprintf('[postset_EffSize] Setting limits.\n');
    %     divspin.Limits = double([st en]);
    % end
    fprintf('[postset_EffSize] Setting divline position.\n');
    divspin.Limits = [st1 en1];
    divline.DrawingArea([2 4]) = [st1 (en1-st1+1)];
    % newLim = max(1,2*min(abs(divspin.Value - divspin.Limits)));
    newLim = max(1, fix(0.5*(en1 - st1 + 1)) - 1);
    if newLim > 1
        fprintf('[postset_EffSize] New div height spinner limits: [%g %g]\n', 1, newLim);
        app.ChanDivHeightSpins(j-1).Limits = [1 newLim];
        app.ChanDivHeightSpins(j-1).Enable = true;
    else
        fprintf('[postset_EffSize] Disabling spinner because newLim %g <= 1. (divspin value: %g, divspin lims: [%g %g])\n', newLim, ...
            divspin.Value, st1, en1);   
        app.ChanDivHeightSpins(j-1).Value = 1; % (NOTE: Assumes divline height is already also 1!)
        %app.ChanDivHeightSpins(j-1).Limits = [1 2];
        app.ChanDivHeightSpins(j-1).Enable = false;
    end

    % %disp(divypos);
    % %disp(divline.Position(:,2));
    % % disp(size(divline.Position));
    % %if isempty(divline.Position)
    %     divline.Position = double([ 1 divypos ; app.fdm(2) divypos ]);
    % %else
    % %    divline.Position(:,2) = double(divypos);
    % %end
    
    divline.Position = horzcat( ...
        [1 ; repelem(app.fdm(2),2,1) ; 1], ...
        repelem(divypos, 2, 1) );
    if isempty(divline.UserData) || ~ishghandle(divline.UserData)
        %fprintf('Making rect\n');
        divline.UserData = images.roi.Rectangle(...
            'Tag', 'divdrawingarea', ...
            "Color", co(j-1,:), ...
            'Parent', app.PreviewAxes, 'InteractionsAllowed', 'none', ...
            'Visible', true, 'Position', double(divline.DrawingArea));
        %fprintf('Made rect\n');
    else
        %fprintf('UserData: %s\n', formattedDisplayText(divline.UserData));
        set(divline.UserData, 'Visible', true, ...
            "Color", co(j-1,:), ...
            'Position', double(divline.DrawingArea));
    end
    disp([divline.DrawingArea ; divline.UserData.Position ]);
    %fprintf('Set rect pos\n');
    %fprintf('[postset_EffSize] Bringing to front.\n');
    bringToFront(divline.UserData);
    bringToFront(divline);
    %fprintf('[postset_EffSize] End of loop.\n');
end
bringToFront(app.topCropLine);
bringToFront(app.botCropLine);
%fprintf('[postset_EffSize] Exited for loop.\n');
%fprintf('[postset_EffSize] Setting control values\n');
ctls = app.ChanHgtFields(1:app.NumChannels);
vals = num2cell(double(app.ChannelHeights));
[ctls.Value] = vals{:};
if app.NumChannels > 1
    ctls = app.ChanDivSpins(1:app.NumChannels-1);
    % vals = num2cell(double(app.ChDivPositions));
    vals = num2cell(round(mean(app.ChDivPositions,2)));
    [ctls.Value] = vals{:};
end
%end
% app.acquisitionObject.ChannelHeights = app.ChannelHeights;

fprintf('[postset_EffSize] botCropLine, topCropLine pos: %0.4g, %0.4g\n', ...
    app.botCropLine.Position(1,2), ...
    app.topCropLine.Position(1,2));

app.ConfirmStatus = false;
%fprintf('Diff: %s', formattedDisplayText(diff(app.acquisitionObject.ScaledChannelDivPositions)));
%fprintf('Range: %s', formattedDisplayText(cellfun(@range,app.acquisitionObject.ScaledChannelVertIdxs)));
end