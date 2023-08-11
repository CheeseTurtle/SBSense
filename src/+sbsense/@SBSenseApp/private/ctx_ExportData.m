function ctx_ExportData(app, src, ~)
try
    switch src.Tag(1)
        case 'P' % Intensity profiles
            cobj = fliplr(flipud(findobj(app.IProfPanel.Children, 'Type', 'Axes')));
        case {'F','p'} % plot
            cobj = app.UIFigure.CurrentObject;
            if ~isgraphics(cobj) || ~isvalid(cobj)
                error('Invalid object');
            end
            if ~(endsWith(class(cobj), 'uiaxes') || cobj.Type~="Axes")
                if (endsWith(class(cobj.Parent), 'uiaxes') || cobj.Parent.Type~="Axes")
                    cobj = cobj.Parent;
                else
                    display(cobj);
                    error('Non-uiaxes current object without a uiaxes parent object.');
                end
            end
            %case 'd' % (data)img
            %    cobj = app.DataImageAxes;
        otherwise
            error('Invalid ctx_ExportImage src tag: "%s"', src.Tag);
    end
    if isempty(cobj)
        error('Cannot find appropriate current object.');
    end

    if src.Tag(1)=='P'
        foundData = false;
        xdata = (1:app.AnalysisParams.EffectiveWidth)';
        xname = 'x'; yname = 'Variables';
        allVarNames = cell(1,app.NumChannels);
        allYDatas = cell(1, app.NumChannels);
        for idx = 1:app.NumChannels
            ch = findobj(cobj(idx).Children, 'Type', 'Line')';
            if ~isempty(ch)
                msk = arrayfun(@(x) isempty(x.XData) || isempty(x.YData), ch);
                ch(msk) = [];
            end
            if isempty(ch)
                continue;
            end
            ch = fliplr(flipud(ch));
            allYDatas{idx} = arrayfun(@(n) reshape(ch(n).YData, [], 1), 1:length(ch), 'UniformOutput', false);
            allVarNames{idx} = cellfun(@(x) sprintf('Ch %u %s', idx, x), {ch.DisplayName}, 'UniformOutput', false);
            
            foundData = true;
        end
        if foundData
            ydatas = horzcat(allYDatas{:});
            varnames = horzcat(allVarNames{:}); 
            % vartypes = repelem("double", 1, length(varnames));
            data = table(xdata, ydatas{:}, ... % 'VariableTypes', vartypes, ...
                'VariableNames', horzcat({xname}, varnames)); % , ...
                % 'RowNames', compose('%04u', xdata), 'DimensionNames', {xname, yname});
        else
            uialert(app.UIFigure, 'Cannot extract data from empty axes.', 'Error: Empty axes');
            return;
        end
    else
        ch = findobj(cobj.Children, 'Type', 'Line')';
        if ~isempty(ch)
            msk = arrayfun(@(x) isempty(x.XData) || isempty(x.YData), ch);
            ch(msk) = [];
        end
        if isempty(ch) % || all(msk) %all(arrayfun(@(x) any(isempty(x.XData)) || any(isempty(x.YData)), ch))
            uialert(app.UIFigure, 'Cannot extract data from empty axes.', 'Error: Empty axis');
            return;
        end
        ch = fliplr(flipud(ch));
        
        varnames = {ch.DisplayName};
        xdata = reshape(ch(1).XData, [], 1);
        ydatas = arrayfun(@(n) reshape(ch(n).YData, [], 1), 1:length(ch), 'UniformOutput', false);

        if (src.Tag(1)=='p')
            chNum = find(fliplr(flipud(app.IProfPanel.Children==cobj)), 1);
            if chNum > 0
                yname = sprintf('Channel %u Profile', chNum);
            else
                yname = 'Variables';
            end
        %elseif src.Tag(1)=='F'
            %if isequal(cobj, app.HgtAxes)
            %    yname = 'Variables';
            %else
        %        yname = 'Variables';
            %end
        else
            yname = 'Variables';
        end

    %     if ~iscell(xdata)
    %         xdata = mat2cell(xdata, ones(1,length(xdata)), 1);
    %     end
        if isa(cobj.XAxis, 'matlab.graphics.axis.decorator.NumericRuler')
            xname = {'Index'};
            % data = table(xdata, ydatas{:}, 'VariableNames', horzcat(xname, varnames));
            data = table(xdata, ydatas{:}, ...
                'VariableNames', horzcat(xname, varnames) ...
                ... % 'DimensionNames', {xname, yname} ...
                );
        else
            %xname = cobj(idx).Properties.DimensionNames(1);
            %if ~iscell(xname)
            %    xname = {xname};
            %elseif ischar(xname)
            %    xname = {cobj.properties.DimensionNames};
            %end
            %xname = cobj(idx).Properties.DimensionNames{1};
            if isa(cobj.XAxis, 'matlab.graphics.axis.decorator.DurationRuler')
                xname = 'Rel Time';
            else
                xname = 'Abs Time';
            end
            xdata = num2ruler(xdata, cobj.XAxis);
            data = timetable(ydatas{:}, ...
                'RowTimes', xdata, 'DimensionNames', {xname, yname}, ...
                'VariableNames', varnames); % Todo: Replace 'Variables' with name of plot?
        end
    end
    %persistent pv;

    if src.Tag(3)=='C' % Copy to clipboard
        % if src.Tag(1)~='P'
        %     try
        %         if all(isdatetime(xdata))
        %             xname = {'AbsDate', 'AbsTime'};
        %             xdata = horzcat(string(xdata, 'yyyy/MM/dd'), ...
        %                 string(xdata, 'HH:mm:ssss.SSSSS'));
        %         else
        %             if ~iscell(xname)
        %                 xname = {xname};
        %             end
        %             if all(isduration(xdata))
        %                 xdata = string(xdata, 'hh:mm:ssss.SSSSS');
        %             end
        %         end
        %         varnames = horzcat(xname, varnames);
        %         %display({class(varnames), class(xdata), class(ydatas)});
        %         %display(ydatas);
        %         %display({size(varnames), size(xdata), size(ydatas)});
        %         data = vertcat(varnames, num2cell(horzcat(xdata, ydatas{:})));
        %     catch ME % TODO
        %         fprintf('%s\n', getReport(ME));
        %     end
        % end

        %if pv || ~pv
        destPath = 'sbsense_tmp.csv'; % tempname('.'); % tempname(tempdir());
        f = fopen(destPath, 'w');
        try 
            if istable(data)
                %fprintf('writing table\n');
                writetable(data, destPath, 'FileType', 'text', ...
                    ... % 'DateLocale', 'en_US', ...
                    'WriteRowNames', true, 'WriteVariableNames', true, ...
                    ... % 'WriteMode', 'overwrite', ...
                    'Delimiter', 'comma', ...
                    'QuoteStrings', 'minimal', ...
                    'Encoding', 'UTF-8' );
            else
                %fprintf('writing cell\n');
                writecell(data, destPath, 'FileType', 'text', ...
                    ... % 'DateLocale', 'en_US', ...
                    ... 'WriteMode', 'overwrite', ...
                    'Delimiter', 'comma', ...
                    'QuoteStrings', 'minimal', ...
                    'Encoding', 'UTF-8' );
            end
        catch ME
            fclose(f);
            rethrow(ME);
        end
        fclose(f);
        %f = fopen(destPath, 'r');
        try
            cont = fileread(destPath);
            %display(cont);
            clipboard('copy', cont);
            %disp(clipboard('paste'));
            % clipboard('copy', data); clipboard('paste'); clipboard('pastespecial')
            % setImage(annotation, source): source can be 'clipboard'
        catch ME
            try
                %fclose(f);
                if isfile(destPath)
                    delete(destPath);
                end
                % delete(f);
            catch ME2 % TODO
                fprintf('%s\n', getReport(ME2));
            end
            rethrow(ME);
        end
        %fclose(f);
        delete(destPath);
        % delete(f);
        %pv = false;
        %else
        %    clipboard('copy', data);
        %    pv = true;
        %end
    else % to file, or to matfile
        [destPath,~,~] = sbuiputfile('data', 'Save data to file...', '.');
        if ~destPath
            return;
        end

        writetable(data, destPath, 'FileType', 'spreadsheet', ...
            ... % 'DateLocale', 'en_US', ...
            'WriteRowNames', true, 'WriteVariableNames', true, ...
            'WriteMode', 'overwritesheet', 'UseExcel', false, ...
            'AutoFitWidth', true, 'PreserveFormat', true);
    end
catch ME0
    fprintf('[ctx_ExportData] Error "%s": %s\n', ME0.identifier, getReport(ME0));
    uialert(app.UIFigure, {'Data collection failed due to error:', sprintf('%s', ME0.message)}, ...
        'Data collection failed');
end
end