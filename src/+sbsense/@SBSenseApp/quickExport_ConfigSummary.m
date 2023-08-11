function quickExport_ConfigSummary(app, varargin)
    [file,path,idx] = uiputfile( ...
        { '*.xls', 'MS Excel Spreadsheet file' }, ...
        { '*.csv', 'CSV (comma-separated value, plaintext) file' }, ...
        'Select export location and filename', ...
        '');
    if ~file
        return;
    end
    if idx==1
        suff = '.xls';
    else
        suff = '.csv';
    end

    if(~endsWith(file, suff))
        file = sprintf('%s%s', file, suff);
    end
    fullpath = fullfile(path, file);
    
    hasChs = app.ConfirmStatus;
    hasVobj = (isa(app.vobj,'videoinput') && isvalid(app.vobj));
    hasRefImg = ~isempty(app.RefImage);

    if hasChs
        numRows = size(app.ChBoundsPositions,1);
    elseif hasVobj || hasRefImg
        numRows = 2;
    else
        uialert(app.UIFigure, 'Nothing to export!');
        return;
    end

    tab = table('Size', [numRows 0], 'VariableTypes', {});

    if hasVobj
        % TODO: Try/catch???
        % TODO: Get other relevant imaqhwinfo!
        % S = imaqhwinfo(app.vobj);
        % S.('RefImg') = app.RefImage;
        % S.('Format') = app.vobj.VideoFormat;
        tab = addvars(tab, app.vobj.VideoFormat, ...
            'NewVariableNames', {'VideoFormat'});
    %else
        % S = struct('RefImg', app.RefImage, 'Format', 'N/A', ...
        %    'DeviceName', 'N/A');
    end

    % TODO: Need to write column-filling function!!
    
    if hasRefImg
        tab = addvars(tab, app.fdm', 'NewVariableNames', {'OriginalSize'});
        if app.ConfirmStatus
            tab = addvars(tab, [app.EffectiveHeight app.fdm(2)]', 'NewVariableNames', {'CroppedSize'});
            % TODO: Make sure this is up-to-date
            % TODO: Analysis scale, scaled size?

            tab = addvars(tab, app.NumChannels, 'NewVariableNames', {'NumChannels'});
            tab = addvars(tab, app.ChannelHeights', 'NewVariableNames', {'ChannelHeights'});
            tab = addvars(tab, app.ChDivPositions, 'NewVariableNames', {'ChDivPositions'});
            tab = addvars(tab, app.ChBoundsPositions, 'NewVariableNames', {'ChBoundsPositions'});
        end
    end
    writetable(tab, fullfile, 'WriteRowNames', false, 'WriteVariableNames', false, ...
        'QuoteStrings', 'minimal');
end