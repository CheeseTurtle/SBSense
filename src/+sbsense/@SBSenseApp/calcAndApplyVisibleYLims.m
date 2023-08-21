function calcAndApplyVisibleYLims(app, varargin)
if nargin > 1
    xlims = varargin{1};
else
    xlims = app.HgtAxes.XLim;
end
% 
% if bitget(app.XAxisModeIndex, 2)
%     xlims = ruler2num(xlims, app.HgtAxes.XAxis);
% end
retries = 0;
while retries < 2
    if any([app.channelPeakHgtLines.Visible])
        hgtLines = app.channelPeakHgtLines([app.channelPeakHgtLines.Visible]);
        % This assumes all hgtLines XData is the same length.
        msk = [hgtLines.XData];
        msk = (xlims(1)<=msk) & (msk<=xlims(2));
        if any(msk)
            %mm = minmax([app.channelPeakPosLines(msk).YData]);
            ydat = [hgtLines.YData];
            try
                ydat = ydat(msk);
            catch % ME
                % The logical indices contain a true value outside of the array bounds. 
                retries = retries + 1;
                continue;
            end
            if ~allfinite(ydat)
                ydat = ydat(isfinite(ydat));
            end
            hgtLims = minmax(ydat);
            if ~(isempty(hgtLims) || isequal(hgtLims(1),hgtLims(2)))
                app.HgtAxes.YAxis(1).Limits = hgtLims;
                % app.FPPagePatches(1).YData = hgtLims([1 1 2 2]);
            end
        end
    end
    break;
end
retries = 0;
while retries < 2
    if any([app.channelPeakPosLines.Visible])
        posLines = app.channelPeakPosLines([app.channelPeakPosLines.Visible]);
        % This assumes all posLines XData is the same length.
        msk = [posLines.XData];
        msk = (xlims(1)<=msk) & (msk<=xlims(2));
        if any(msk)
            ydat = [posLines.YData];
            try
                ydat = ydat(msk);
            catch % ME
                % The logical indices contain a true value outside of the array bounds. 
                retries = retries + 1;
                continue;
            end
            if ~allfinite(ydat)
                ydat = ydat(isfinite(ydat));
            end
            posLims = minmax(ydat);
            if isempty(posLims) || isequal(posLims(1),posLims(2))
                return;
            end
            app.PosAxes.YAxis.Limits = posLims;
            % app.FPPagePatches(2).YData = posLims([1 1 2 2]);
        end
    end
    break;
end

    if ~app.IsRecording
        if ~isempty(app.HgtAxes.Legend) && ~isempty(app.PosAxes.Legend) && app.HgtAxes.Legend.Visible
            set([app.HgtAxes.Legend, app.PosAxes.Legend], 'Location', 'best');
        end
        if ~isequal(app.HgtAxes.InnerPosition([1 3]), app.PosAxes.InnerPosition([1 3]))
            % app.PosAxes.InnerPosition = app.HgtAxes.InnerPosition([1 3]);
            % onAxesPanelSizeChange(app, app.HgtAxesPanel, []);

            [p,pIdx] = max([app.HgtAxes.InnerPosition(1) app.PosAxes.InnerPosition(1)], [], 2);
            fs = sum([ app.HgtAxes.InnerPosition([1 3]) ; app.PosAxes.InnerPosition([1 3])], 2);
            [f,fIdx] = min(fs);
            w = f - p + 1;

            % pw = [p, f-p+1];
            %app.HgtAxes.InnerPosition([1 3]) = pw;
            %app.PosAxes.InnerPosition([1 3]) = pw;

            % posChanged = false; % TODO??

            if bitget(pIdx,1)
                app.PosAxes.InnerPosition([1 3]) = [p w];
                if fIdx ~= pIdx
                    app.HgtAxes.InnerPosition(3) = w;
                end
            else
                app.HgtAxes.InnerPosition([1 3]) = [p w];
                if fIdx ~= pIdx
                    app.PosAxes.InnerPosition(3) = w;
                end
            end


            % fut = parfeval(backgroundPool, @() pause(2), 0);
            % fut = [fut afterEach(fut, @() set(app.HgtAxes.UserData{3}, 'Visible', true), 0)];
            app.HgtAxes.UserData{3}.Position([1 3]) ...
                = app.PosAxes.InnerPosition([1 3]) + [-2 4];
        end
    end
end