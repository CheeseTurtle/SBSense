function ctx_ExportFigure(app, src, ~)

    % TODO: Use getFrame w/ TightInset property (compare tightPosition())
    % saveas, print, publish -- See "DPI-Aware Behavior in MATLAB"
    % hgexport?? exportgraphics, copygraphics, exportapp, print, orient, openfig, savefig
    % printpreview

    switch src.Tag(1)
        case 'P' % Intensity profile plots
            cobj = app.IProfPanel;
        case {'F', 'p'} % plot
            cobj = app.UIFigure.CurrentObject;
            if ~isgraphics(cobj) || ~isvalid(cobj)
                error('Invalid object');
            end
            if ~(endsWith(class(cobj), 'uiaxes') || cobj.Type~="Axes")
                if isa(cobj.Parent, 'uiaxes')
                    cobj = cobj.Parent;
                else
                    % disp(cobj);
                    disp(cobj);
                    disp(class(cobj));
                    error('Non-uiaxes current object without a (ui)axes parent object.');
                end
            end
        case 'd' % (data)img
            cobj = [app.DataImageAxes]; % app.dataimg app.maskimg app.overimg];
            set(app.PSBLines, 'Visible', false);
        otherwise
            error('Invalid ctx_ExportImage src tag: "%s"', src.Tag);
    end
    try
        if src.Tag(1)=='F' % endsWith(class(cobj), 'uiaxes') || endsWith(class(cobj), 'uipanel')
            % uif = uifigure('Visible', 'on', 'WindowStyle', 'normal', 'WindowState', 'maximized');
            try
                % uig = uigridlayout(uif, 'RowHeight', {'1x'}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0]);
                switch class(app.HgtAxes.XAxis)
                    case 'matlab.graphics.axis.decorator.NumericRuler'
                        xdata = app.DataTable{1}.Index;
                    case 'matlab.graphics.axis.decorator.DurationRuler'
                        xdata = app.DataTable{2}.RelTime;
                    otherwise
                        xdata = app.DataTable{2}.RelTime + app.TimeZero;
                end
                if isempty(xdata)
                    % delete(uif);
                    uialert(app.UIFigure, 'No data has been collected yet! Cannot export plot.', 'Error: No data recorded');
                    return;
                end
                isnum = int8(isnumeric(xdata));

                if isequal(cobj, app.PosAxes)
                    % idx (reltime) psb avgloc avghgt eli (peakloc*N) (peakhgt*N)
                    % colidxs = int8(1:app.NumChannels) + 5;
                    ydatas = app.DataTable{2-isnum}{:,end-1}';
                    yname = 'Peak Location';
                elseif isequal(cobj, app.HgtAxes)
                    % colidxs = int8(1:app.NumChannels) + int8(app.NumChannels) + 5;
                    ydatas = app.DataTable{2-isnum}{:,end}';
                else
                    % delete(uif);
                    uialert(app.UIFigure, 'Unrecognized uiaxes (expected HgtAxes or PosAxes) -- cannot collect data.', 'Error: Unrecognized uiaxes');
                    yname = 'Peak Height';
                    return;
                end
                xname = 'Index';

                varnames = compose('Ch %u', 1:app.NumChannels);
                
                %display((app.DataTable{2-isnum}));
                %display(size(app.DataTable{2-isnum}));
                %display({isnum, colidxs + isnum});
                %ydatas = app.DataTable{2 - isnum}(:, colidxs + isnum);
                
                
                % ax.XAxis = copy(cobj.XAxis,ax); % TODO: Set auto??
                if ~isnum
                    if isa(cobj.XAxis, 'matlab.graphics.axis.decorator.DurationRuler')
                        xax = matlab.graphics.axis.decorator.DurationRuler();
                    else
                        xax = matlab.graphics.axis.decorator.DatetimeRuler();
                    end
                    xax.Limits = xdata([1 end]);
                    xdata = ruler2num(xdata, xax)';
                else
                    xax = matlab.graphics.axis.decorator.NumericRuler();
                    xdata = xdata';
                    xax.Limits = xdata([1 end]);
                end
            catch ERR
                rethrow(ERR);
            end
            uif = figure('Visible', 'on');
            try
                ax = gca(uif); % TODO: Copy relevant object properties...
                ax.XAxis = xax;

                co = colororder(app.UIFigure);

                if isequal(cobj, app.HgtAxes)
                    yyaxis right;
                    ax.YColor = co(end,:);
                    plot(ax, xdata, app.DataTable{2-isnum}{:, 'ELI'}', 'DisplayName', 'ELI', ...
                        'Color', co(end,:)); % TODO: Copy ELI style
                    yyaxis left;
                    ax.YColor = [0 0 0];
                end

                hold("on");
                for i=1:app.NumChannels
                    plot(ax, xdata, ydatas(i,:), 'DisplayName', varnames{i}, ...
                        'Color', co(i,:));
                end
                hold("off");
                ax.YLim = cobj.YLim;
                ax.XLim = cobj.XLim;
                figure(uif);
                % cobjCopy = copyobj(cobj, uig); %#ok<NASGU>
            catch ERR
                delete(uif);
                rethrow(ERR);
            end
        else
            uif = figure('Visible', 'on'); % , 'WindowStyle', 'alwaysontop', 'WindowState', 'maximized');
            try
                if src.Tag(1) == 'p'
                    tl = tiledlayout(uif, 1, 1, 'TileSpacing', 'none', ...
                        'Padding', 'tight');
                    % disp(cobj);
                    cobjCopy = copyobj(cobj, tl);
                    cobjCopy.Layout = matlab.graphics.layout.TiledChartLayoutOptions('Tile', 1, 'TileSpan', [1 1]);
                else
                    if cobj.Type=="uipanel"
                        cobj = cobj.Children(1);
                    end
                    cobjCopy = copyobj(cobj,uif); %#ok<NASGU>
                end
                % disp(cobjCopy);
            catch ERR
                delete(uif);
                rethrow(ERR);
            end
            figure(uif);
        end
    catch ME0
        fprintf('[ctx_ExportFigure] Error "%s": %s\n', ME0.identifier, getReport(ME0));
        uialert(app.UIFigure, {'Data collection failed due to error:', sprintf('%s', ME0.message)}, ...
            'Data collection failed');
    end
end