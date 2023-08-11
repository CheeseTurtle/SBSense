function ctx_ExportImage(app, src, ~)
try
    switch src.Tag(1)
        case 'P' % Intensity profile plots
            cobj = app.IProfPanel;
        case {'F','p'} % plot
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

    disp(cobj);

    if src.Tag(3)=='C' % Copy to clipboard
        copygraphics(cobj, 'ContentType', 'image', ... % 'image',  ... % 'vector', ... )    
            'BackgroundColor', [1 1 1], ... % or 'none' or 'current'
            'Colorspace', 'rgb', ... % 'rgb' or 'gray'
            'Resolution', 300); % DPI (also try 150?)
    else % to file, or to matfile
        if src.Tag(3)=='M'
            [destPath,~,fmt] = sbuiputfile({{'*.fig', 'MATLAB figure' ...
                ; '*.m', 'MATLAB figure + script'}, ...
                {'',''}, {'fig', 'm'}}, 'Save as MATLAB figure', ... % TODO: Plot name
                '.');
                destPath = erase(destPath, '.');
            % TODO: strip extension
            ctype = 'saveas';
        else
            [destPath,fmt,ctype] = sbuiputfile('image', 'Save as image...', '.');
        end
        if ~destPath
            return;
        end
        
        if strcmp(ctype,'saveas')
            if endsWith(class(cobj), 'uiaxes')
                uif = uifigure('Visible', 'on', 'WindowStyle', 'normal', 'WindowState', 'normal');
                try
                    uig = uigridlayout(uif);
                    cobjCopy = copyobj(cobj, uig); %#ok<NASGU>
                catch ERR
                    delete(uif);
                    rethrow(ERR);
                end
            else
                uif = figure('Visible', 'on'); %, 'WindowStyle', 'alwaysontop', 'WindowState', 'maximized');
                try
                    tl = tiledlayout(uif, 1, 1);
                    cobjCopy = copyobj(cobj, tl); %#ok<NASGU>
                catch ERR
                    delete(uif);
                    rethrow(ERR);
                end
            end
            try
                % TODO: Remove suffix
                disp(destPath);
                destPath = extractBefore(destPath, '.');  % erase(destPath, '.');
                disp(destPath);
                if strcmp(fmt, 'fig')
                    savefig(uif, destPath, 'compact');
                else
                    saveas(uif, destPath, fmt);
                end
            catch ERR
                delete(uif);
                rethrow(ERR);
            end
            delete(uif);
        elseif strcmp(fmt, {'gif', 'pdf'})
            exportgraphics(cobj, destPath, 'ContentType', ctype, ...
                'BackgroundColor', [1 1 1], ...%'current', ... % 'none' ...
                'Colorspace', 'rgb', ... 'rgb' or 'cmyk' or 'gray'
                'Resolution', 300); % DPI
        else
            exportgraphics(cobj, destPath, 'ContentType', ctype, ...
                'BackgroundColor', [1 1 1], ...%'current', ... % 'none' ...
                'Colorspace', 'rgb', ... 'rgb' or 'cmyk' or 'gray'
                'Resolution', 300, ... % DPI
                'Append', false);
        end
    end
catch ME0
    fprintf('[ctx_ExportImage] Error "%s": %s\n', ME0.identifier, getReport(ME0));
    uialert(app.UIFigure, {'Image collection failed due to error:', sprintf('%s', ME0.message)}, ...
        'Image collection failed');
end

set(app.PSBLines, 'Visible', true);

    % Note: Use hgexport(fig, '-clipboard') to copy figure to clipboard:
    % hgexport(fig,'-clipboard') writes figure fig to the Microsoft® Windows® clipboard.
    % The format in which the figure is exported is determined by which renderer you use.
    % The Painters renderer generates a metafile. The OpenGL® renderer generate an image file.
    % 
    % hgexport(fig,filename) writes figure fig to the EPS file filename.
end