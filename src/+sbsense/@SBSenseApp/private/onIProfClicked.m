function onIProfClicked(app, src, event)
    %fprintf('[onIProfClicked] !!');
    %display(src);
    %display(event);
    if endsWith(src.Type, 'anel')
        % if ~app.IPPanelActive
        %     app.IPPanelActive = true;
        % end
        app.IPPanelActive = ~app.IPPanelActive;
    elseif endsWith(src.Type, 'xes')
        % TODO: Don't allow selecting invalid plots
        idx = src.Tag - 48;
        if app.IPPanelActive
            if app.IPPlotSelection == idx
                if strcmp(event.EventName, 'Hit') && (event.Button==1)
                    % display(event.IntersectionPoint); % TODO
                    
                    %app.DataTable{1}{app.SelectedIndex, 'PSZW'}(idx) = app.AnalysisParams.PSZWidth;
                    %app.DataTable{2}{app.SelectedIndex, 'PSZW'}(idx) = app.AnalysisParams.PSZWidth;

                    xext = 2\(app.AnalysisParams.PSZWidth - 1);
                    xpos = min(app.fdm(2)-xext, max(1+xext, event.IntersectionPoint(1)));
                    %app.DataTable{1}{app.SelectedIndex, 'PSP'}(idx) = xpos;
                    %app.DataTable{2}{app.SelectedIndex, 'PSZP'}(idx) = xpos;
                    % setChunkTableItem(app, [], 'PSZL1', idx, xpos);
                    
                    if ~ishghandle(app.IPzoneRects(1,idx)) || ~isvalid(app.IPzoneRects(1,idx)) || ~isa(app.IPzoneRects(1,idx),'images.roi.Rectangle')
                        app.IPzoneRects(1,idx) = images.roi.Rectangle('Parent', app.tl.Children(app.NumChannels + 1 - idx), ...
                            'Color', [0.8 0.8 0.8], 'SelectedColor', [1 0 1], ...
                            'Selected', true, 'FixedAspectRatio', true, ...
                            'LineWidth', eps, 'FaceAlpha', 0.4, ...
                            "Deletable", true, "InteractionsAllowed", "translate", ...
                            "FaceSelectable", true, "LabelVisible", "off", "Rotatable", false, ...
                            'Tag', src.Tag);
                        addlistener(app.IPzoneRects(1,idx), 'ROIMoved', @app.postmove_PSZrect);
                        % addlistener(app.IPzoneRects(1,idx), 'MovingROI', @app.postmove_PSZrect);
                        addlistener(app.IPzoneRects(1,idx), 'ROIClicked', @app.postclick_PSZrect);
                        addlistener(app.IPzoneRects(1,idx), 'DeletingROI', @app.postdelete_PSZrect);

                        % This used to be after the next "end"
                        set(app.IPzoneRects(1,idx), 'Visible', true, ...
                            "InteractionsAllowed", "translate", ...
                            'DrawingArea', [src.XLim(1), min(0,src.YLim(1))-2, diff(src.XLim)+1, diff(src.YLim)+4], ...
                            'Position', [xpos - xext, min(0,src.YLim(1))-2, app.AnalysisParams.PSZWidth, diff(src.YLim)+4]);

                        newVal = [xpos-xext, xpos+xext];
                        if isempty(newVal) || anynan(newVal)
                            newVal = [NaN NaN];
                        end
                        
                        app.AnalysisParams.PSZLocations(:, idx) = newVal;
                        if ~isequal(size(app.AnalysisParams.PSZLocations), [2 app.NumChannels])
                            fprintf('[OnIProfClick] Size of PSZLocations is not correct.\n');
                            disp(app.AnalysisParams.PSZLocations);
                        end
                        % app.ReanalyzeButton.Enable = true;
                    end
                    % (used to be here)
                    setChunkTableItem(app, {}, 'PSZW1', idx, app.AnalysisParams.PSZWidth);
                    setChunkTableItem(app, [], 'PSZL1', idx, xpos);
                else
                    display(event); % TODO
                end                    
            else
                app.IPPlotSelection = idx;
                if ~isempty(app.IPzoneRects(1,idx)) && ishghandle(app.IPzoneRects(1,idx))
                    app.IPzoneRects(1,idx).Selected = true;
                end
            end
        else
            if app.IPPlotSelection ~= idx
                app.IPPlotSelection = idx;
                %if ishghandle(app.IPzoneRects(1,idx))
                %    app.IPzoneRects(1,idx).Selected = true;
                %end
            end
            app.IPPanelActive = true;
        end
    else
        fprintf('[onIProfClicked] Unknown type "%s".\n', src.Type);
    end
end