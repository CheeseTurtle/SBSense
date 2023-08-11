% TODO: Post-set BG, set ConfirmStatus=false
% TODO: When camera resolution changes, also adjust ROI DrawingAreas / spin lims / axes xlim and ylim (and scale?)

% TODO: During (re)init, set recbtn UserData=true (ie, first rec) --or use property of AnalysisParams?
% TODO: Startup initializes PlotTimer

% TODO: Add button underlying value

% TODO: When recording begins, override lock butons, disable l/r, if max datapoint exceeds curr vis domain, pan to rightmost (and update y, sync fields and sliders)
% TODO: When recording stops (due to error or normal stop): Temporarily disable rng button and all sliders, restore button values (chk shift key state!), then re-enable range button and sliders and menu items

% TODO: Resolution slider limits


classdef app_methods
    methods(Access=private)
        function addlisteners(app)
            % Crop ROI listeners
            % Chdiv ROI listeners
            % PSB ROI listeners
        end
    end

    methods(Access=private)
        % CroplineMoved,CroplineMoving
        % CropSpinValueChanged
        function onCropMovement(app, src, varargin)
            % TODO: How to get event name?
            shapeDone = ~startsWith(event.Name, "Moving");
            persistent pv;
            if shapeDone && ~logical(pv)
                % TODO: Hide ROIs
                pv = true;
            end

            try
                isSpin = shapeDone && (event.Name(1)=='V'); % ValueChanged
                if isSpin
                    % TODO: Set ROI position
                else
                    % TODO: Set spin value
                end
                if shapeDone
                    % TODO: Use Tag to determine upper or lower
                    % TODO: Update spin lims and cropline DrawingArea
                end
            catch % ME
                % TODO: Display error in console
                % TODO: Unhide ROIs
                pv = false;
            end
        end

        function onChDivPositionMovement(app, src, varargin)
            changeDone = ~startsWith(event.Name, "Moving");
            isSpin = shapeDone && (event.Name(1)=='V'); % ValueChanged
            if isSpin
                % TODO: Set ROI position
            else
                % TODO: Set spin value
            end
            if changeDone
                try
                    setNthDivPosition(app.AnalysisParams, src.Tag, value); % TODO
                    % TODO: Recalc neighboring spin lims / ROI drawing areas
                    %       (including top/bottom cropline and spins)
                catch % ME
                    % TODO: Display error message
                end
            end
        end

        function XResSliderValueChange(app, src, event)
            changing = event.Name(end) == 'g'; % TODO: Args
            % persistent pv;
            if changing
                %if ~pv
                %    pv = true;
                %    % TODO: Hide / disable major ticks?
                %end
                [newNavMinLim newNavMaxLim] = calcNavSliderLimits(app);
                app.XNavSlider.Limits = [newNavMinLim newNavMaxLim];
                % TODO: Set ticks mode to manual, labels mode to manual(?)
                % TODO: linkaxes and linkprop
                set(app.PeakHgtAxes.XAxis, 'Ticks', ...
                    app.PeakHgtAxes.XLim(1):...
                    app.XResSlider.Value:app.PeakHgtAxes.XLim(2)); % TODO: Tick labels
            else
                % TODO: Cancel and spawn: [future to choose major tick interval]
                % after which set & enable major ticks
                % TODO: Set new nav slider step, store step val for current mode (table)
                % pv = false;
                % app.XNavSlider.Step = app.XResSlider.Value;
                % TODO: Set X nav slider step from res. slider value
            end
        end

        function [newNavMinLim newNavMaxLim] = calcNavSliderLimits(app)
            % TODO: Set X axis minor tick from slider ItemsData
            % TODO: Set X nav slider lims
            if app.LockRangeButton.Value % Zooming
                if app.XAxisModeIndex == 1
                    entireRange = app.LargestIndexReceived; % TODO: Create prop
                else
                    entireRange = app.PeakDataTimeTable.RelTime(app.LargestIndexReceived);
                    if app.XAxisModeIndex == 2 % abs time mode
                        entireRange = entireRange + app.TimeZero;
                    end
                end
                newNavMinLim = 2\app.XResSlider.Value;
                newNavMaxLim = entireRange;
                if app.XAxisModeIndex == 1 % Index mode
                    newNavMinLim = ceil(newNavMinLim);
                end
            else % Panning
                zoomspan = diff(app.PeakHgtAxes.XLim);
                if app.XAxisModeIndex == 1 % Panning, index mode
                    newNavMinLim = 1;
                    newNavMaxLim = max(1, app.LargestIndexReceived - zoomspan + 1);
                else
                    entireRange = app.PeakDataTimeTable.RelTime(app.LargestIndexReceived);
                    if app.XAxisModeIndex == 2 % abstime mode
                        newNavMinLim = app.TimeZero;
                        entireRange = entireRange + newNavMinLim;
                    else
                        newNavMinLim = seconds(0);
                    end
                    newNavMaxLim = max(newNavMinLim, entireRange - zoomspan);
                end
            end
        end

        function RecordButtonValueChanged(app)
            app.RecordButton.Enable = false;
            if app.RecordButton.Value
                try
                    if app.Analyzer.IsFirstRecord
                        % TODO: Show confirm dialog. If "no", return.
                        %try
                            % TODO: Set up camera
                            % TODO: Set up controls (enable/disable, chg tooltips, show/hide axes)
                            % TODO: Preview fixed to BG (no live preview??)
                            % TODO: Set up data storage vars
                            prepare(app.Analyzer);
                        %catch % ME
                        %end
                    end
                    % TODO: Change nav state, set visible domain and corresp. control values, possibly auto Y
                    % TODO: Change rec button icon
                    % TODO: Start plot timer
                    % TODO: Start camera
                    % TODO: Enable rec button
                catch ME
                    % TODO: Print error
                    % Restore button icon
                    % Restore control values / nav state
                    % Stop timer if isa timer
                    % Otherwise, create timer! (and display dialog?)
                    % Enable button (depending on error type?)
                end
            else
                try
                    if app.Analyzer.IsFirstRecord
                        % TODO: Check if data collected successfully.
                        % If so, then set app.Analyzer.IsFirstRecord = false;
                    end
                    % TODO: Stop plot timer
                    % TODO: Stop camera (timeout? ask to keep waiting...)
                    % TODO: Restore rec button icon, control values, nav state
                    % TODO: Enable rec button
                catch
                    % TODO: Print error
                    % Restore button icon
                    % Restore control values / nav state
                    % Stop timer if isa timer
                    % Otherwise, create timer! (and display dialog?)
                    % Enable button (depending on error type?)
                    % Possible imaqreset if no camera???
                end
            end
        end
        
        function NavLockButtonValueChanged(app, src) % TODO: arguments
            if src.Tag == 'N' % range % TODO: Lock button tags
                if app.LockRangeButton.Value
                    app.LockLeftButton.Value = true;
                    app.LockRightButton.Value = true;
                else
                    app.LockLeftButton.Value = app.LockLeftValue;
                    app.LockRightButton.Value = app.LockRightValue;
                end
                app.LockRangeValue = app.LockRangeButton.Value;
                navzoomChanged(app);
            else
                if src.Tag == 'L' % left
                    app.LockLeftValue = app.LockLeftButton.Value;
                    %if ~app.LockLeftButton.Value && app.LockRightButton && app.LockRangeButton
                    %    app.LockRangeButton.Value = false;
                    %end
                else % right
                    app.LockRightValue = app.LockRightButton.Value;
                end
                if xor(app.LockLeftButton.Value, app.LockRightButton.Value)
                    app.LockRangeButton.Value = false;
                    navzoomChanged(app);
                elseif app.LockLeftButton.Value
                    app.LockRangeButton.Value = true;
                    navzoomChanged(app);
                end
            end
            setNavSliderFcn(app);
        end

        function navzoomChanged(app)
            % TODO: Disable relevant controls
            try 
                if app.LockRangeButton.Value % Just switched to pan mode
                    futs = app.ZoomFutures;
                else % Just switched to zoom mode
                    futs = app.PanFutures;
                end
                if ~isempty(futs) && isa(futs, 'parallel.Future') % && all(isvalid(futs))
                    %futs = futs(isvalid(futs));
                    futs = futs(~strcmp({futs.State}, 'unavailable'));
                    fut0 = afterAll(futs, ...
                        @() parfeval(backgroundPool, @app.calcNavSliderLimits, 2), ...
                        0, 'PassFuture', false);
                    fut = afterAll(fut0, @app.navzoomChangedCleanup, 0, ...
                        'PassFuture', true);
                end
            catch
                % TODO: Enable relevant controls
                navzoomChangedErrorCleanup(app);
            end
        end

        function setXNavSliderLims(app, llim, ulim)
            lims = [llim ulim];
            if bitand(app.XAxisModeIndex, 2) % 2 or 3, not 1
                if ~bitand(app.XAxisModeIndex,1) % 2, not 3
                    % Need to subtract TimeZero to convert to relative time
                    lims = lims - app.TimeZero;
                end
                % Convert from relative time to numeric
                
            end
            % TODO: Ticks and labels
            %majticks = llim:(app.XResSlider.Value):ulim;
            %if isempty(majticks)
            %    majticks = lims;
            %elseif majticks(end)<ulim
            %    majticks = [majticks ulim];
            %end
            %% TODO: TickLabels
            %set(app.XNavSlider, 'Limits', lims, ...
            %    'TickValues', majticks);
        end

        %function navargcell = navzoomChangedCalc(app)
        %    % TODO: Calculate changes to nav slider
        %    if app.LockRangeButton.Value % Just switched to pan mode
        %        
        %    else % Just switched to zoom mode
        %        futs = app.PanFutures;
        %    end
        %end

        function navzoomChangedCleanup(app, fut)
            hadError = false;
            % TODO: Enable relevant controls
            try
                if fut.Error
                    fprintf('fut.Error: %s\n', formattedDisplayText(fut.Error));
                    hadError = true;
                end
                if isempty(fut.OutputArguments)
                    fprintf('Future has no output arguments!');
                    hadError = true;
                elseif fut.OutputArguments{1}.Error
                    fprintf('fut.Error: %s\n', formattedDisplayText(fut.Error));
                    hadError = true;
                %elseif isprop(fut, 'OutputArguments') && ~isempty(fut.OutputArguments) && isempty(fut.OutputArguments{1}.OutputArguments)
                %    argcell = fut.Ou 
                else
                    %argcell = fut.OutputArguments{1}.OutputArguments{1};
                    %set(app.XNavSlider, argcell{:});
                    setXNavSliderLims(app, fut.OutputArguments{1}.OutputArguments{:});
                    setXNavSliderPos(app, app.PeakHgtAxes.XLim(1));
                end
            catch ME
                fprintf('Error occurred during navzoomChangedCleanup: %s', formattedDisplayText(ME));
                hadError = true;
            end
            %if hadError
            navzoomChangedErrorCleanup(app);
            %end
        end
        
        function setXNavSliderPos(app, pos)
            if app.XAxisModeIndex > 1 % Not index mode
                if app.XAxisModeIndex==2 % Absolute time
                    % Need to subtract TimeZero
                    pos = pos - app.TimeZero;
                end
                % Need to convert from relative time / duration to numeric

            end
        end

        function navzoomChangedErrorCleanup(app)
            % TODO: Enable relevant controls
        end

        function setNavSliderFcn(app)
            % TODO
        end

        function changeVisibleDomain(app, navLims, navPos, axisLims, minmaxChanges)
            % TODO: For each axis, check if any auto Y features are enabled
            % Pass new and current x axis lims, and change info to fcn in parfeval 
            % (calc new y bounds) after which (pass future, for error handling) set Y lims
            % TODO: Set X axis lims -- asssume field slider pos, vals
            % TODO: Set status bar (left, right)
        end

        function XAxisLimitsChanged(src, event)
            % event is "LimitsChanged"
            %OldLimits: [00:00.0000    00:01.0000]
            %NewLimits: [00:00.0000    00:03.0000]
            %Source: [1×1 DurationRuler]
            %EventName: 'LimitsChanged'
            if isa(src, 'matlab.graphics.axis.decorator.DurationRuler')
            elseif isa(src, 'matlab.graphics.axis.decorator.Ruler')
            end
        end

        % Never changes nav slider lims
        function [newNavPos, newAxisLims, minmaxChanges], ...
            = jumpToDatapoint(app, index)
            [ETF, pos, spanboundLeft, spanboundRight] = datapointInVisibleDomain(app, index);
            inView = isempty(ETF);
            viewspan = spanboundRight - spanboundLeft;

            rightmostPos = app.FPData(app.LastIndexReceived, app.XAxisModeIndex); % TODO: Create these properties             
            if bitand(app.XAxisModeIndex, 1) % Mode is not 2 (abs time)
                dataspan = rightmostPos;
                leftmostPos = 0;
            else % X axis mode = absolute time
                dataspan = rightmostPos - leftmostPos;
            end

            if inView && ... % TODO: Create these properties
                (dataspan <= 2*app.MinimumSpan{app.XAxisModeIndex})
                return; % Not enough room to move visible domain
            end
            lockLR = [app.LockLeftButton.Value, app.LockRightButton.Value];
            %if app.Recording
            %    % Pan so that right edge is on datapoint (+ resolution unit)?
            %    dx = index - spanboundRight;
            %    if bitand(app.XAxisModeIndex, 2) % Mode is 2 or 3 (not index mode)
            %        dxm = fix(dx / app.XResSlider.ItemsData{end}) + 1;
            %        dx = dx*dxm;
            %    %else
            %    %    dx = dx + 1;
            %    end
            %    % newNavLims = 
            %    newAxisLims = app.XNavSlider.Lims + dx;;
            %    newNavPos = newAxisLims(1); % Use left edge as position for now
            %    %newNavPos = 2\(newNavLims(1) + newNavLims(2));
            %    %newNavPos = newNavLims(2); % Assume we're in "LockRight" mode bc recording
            %elseif app.LockRangeButton.Value % Pan mode
            if app.LockRangeButton.Value % Pan mode
                % TODO: Create status variable??
                % Center to datapoint (exactly?)
                newNavPos = pos - 2\viewspan;
                newAxisLims = newNavPos + [0 viewspan];
                %if all(lockLR) % Both locked (lock range)
                %elseif ~app.LockLeftButton.Value % Lock right
                %elseif ~app.LockRightButton.Value % Lock left
                %end
                % if TF % In view
                % elseif ETF % out of domain, to the left
                % else % out of domain, to the right
                % end
            elseif (~inView && any(lockLR)) % Zoom mode, outside window + lock L/R
                % TODO: Extend span left or right to include point, update fields and set nav slider to match!
                % (calculate target index by calculating required span, then round up from linear interpolation)
                if ETF && app.LockRightButton.Value % out of domain, to the left (can assume ETF is not empty since ~inView)
                    requiredSpan = spanboundRight - pos;
                    requiredSpan = ceil(mod(requiredSpan, app.XResSlider.Value))*app.XResSlider.Value;
                    newNavPos = requiredSpan;
                    % newNavPos = spanboundRight - requiredSpan;
                    newAxisLims = [(spanboundRight - requiredSpan) spanboundRight];
                elseif ~ETF && app.LockLeftButton.Value  out of domain, to the right
                    requiredSpan = pos - spanboundLeft;
                    requiredSpan = ceil(mod(requiredSpan, app.XResSlider.Value))*app.XResSlider.Value;
                    newNavPos = requiredSpan;
                    % newNavPos = spanboundLeft;
                    newAxisLims = spanboundLeft + [0 requiredSpan];
                else % Jump to datapoint by centering since it's out of range in the wrong direction
                    requiredSpan = viewspan;
                    newNavPos = [];
                    % newNavPos = pos - 2\viewspan;
                    newAxisLims =  (pos - 2\viewspan) + [0 viewspan];
                end
            elseif lockLR % Zoom mode, within + left or right is locked
                newNavPos = [];
                newAxisLims = [];
                minmaxChanges = {logical.empty(), logical.empty()};
                return;
            else % Zoom mode, outside+nolock
                % TODO: Keep same range (nav slider lims/pos no change!)
                % TODO: Move view center to point, exactly(?)
                % TODO: Change L/R fields
                newNavPos = [];
                newAxisLims = (pos - 2\viewspan) + [0 viewspan];
                %newSpanbounds = (pos + 2\[-viewspan viewspan]) / app.XResSlider.Value;
                %newSpanbounds(1) = floor(newSpanbounds(1));
                %newSpanbounds(2) = ceil(newSpanBounds(2));
                %newAxisLims = newSpanBounds * app.XResSlider.Value;
            end

            % Calculate minmax changes
            % Empty (logical) array for no changes
            % Scalar false to not reeval?
            % Scalar true to reeval
            % Cell is empty: no change in min/max
            % Cell member is true: min/max lost -- must reeval range and store new min/max
            % Cell member is false: min/max superceded -- don't reeval, just update stored
            % (When assessing change: If any changes could result in auto Y adjustment 
            % and auto Y is enabled, returned future is an after for Y calculation; otherwise
            % returned future is empty (Future.empty()?)
            minmaxChanges = cell(2); %{ logical.empty, logical.empty ; 
                            %  logical.empty, logical.empty };
            [curMin1, curMax1] = getfield(app.PeakPosAxes.UserData, 'currentMinMax');
            minmaxChanges(:,:) = [ ...
                @SBSense_v09.getMinMaxChanges(app.PeakPosAxes,newAxisLims), ...
                @SBSense_v09.getMinMaxChanges(app.PeakHgtAxs,newAxisLims) ];
    

            % % TODO: What to do when there is only one datapoint?
            % % TODO: Use a different function than this one while plotting live recorded feed
            % %       to avoid unnecessary calculations.
            % % Calculate left changes
            % % TODO: Set UserData on init. Also include auto y feature switch/flag
            % % TODO: Must update pos vals when switching axis modes
            % [curMinPos1,curMaxPos1] = getfield(app.PeakPosAxes.UserData, 'currentMinMaxPos');
            % [curMin1, curMax1] = getfield(app.PeakPosAxes.UserData, 'currentMinMax');
            % [curMinPos2,curMaxPos2] = getfield(app.PeakHgtAxes.UserData, 'currentMinMaxPos');
            % [curMin2, curMax2] = getfield(app.PeakHgtAxes.UserData, 'currentMinMax');
            % if newAxisLims(1) < spanboundLeft % grew to the left
            %     % TODO: Write these functions
            %     [newMin1,newMinPos1, newMax1,newMaxPos1] = getDataExt(app.PeakPosAxes, newAxisLims(1), spanboundLeft);
            %     [newMin2,newMinPos2, newMax2,newMaxPos2] = getDataExt(app.PeakHgtAxes, newAxisLims(1), spanboundLeft);
            %     if newMin1 < curMin1 % Superceded
            %         setfield(app.PeakPosAxes.UserData, 'currentMinMax', [newMin1 curMax1]);
            %         minmaxChanges{1,1} = false;
            %     else
            %         newMin1 = curMin1;
            %     end
            %     if newMax1 > curMax1 % Superceded
            %         setfield(app.PeakPosAxes.UserData, 'currentMinMax', [newMin1 newMax1]);
            %         minmaxChanges{1,2} = false;
            %     end

            %     if newMin2 < curMin2 % Superceded
            %         setfield(app.PeakHgtAxes.UserData, 'currentMinMax', [newMin2 curMax2]);
            %         minmaxChanges{2,1} = false;
            %     else
            %         newMin2 = curMin2;
            %     end
            %     if newMax2 > curMax2 % Superceded
            %         setfield(app.PeakHgtAxes.UserData, 'currentMinMax', [newMin2 newMax2]);
            %         minmaxChanges{2,2} = false;
            %     end
            % elseif newAxisLims(1) > spanboundLeft % shrank from the left
            %     if curMinPos1 > 
            % end
            % % Calculate right changes
            % if newAxisLims(2) > spanboundRight % grew to the left
            % elseif newAxisLims(2) < spanboundRight % shrank from the left
            % end
        end

        % ETF: empty = in range, true = out of range to the left, false = out of range to the right
        function  [ETF, pos, spanboundLeft, spanboundRight] = datapointInVisibleDomain(app, index);
            [spanboundLeft, spanboundRight] = app.PeakHgtAxes.XLim;
            pos = app.FPData(index, app.XAxisModeIndex);
            if pos < spanboundLeft
                ETF = true;
            elseif spanboundRight < pos
                ETF = false;
            else
                ETF = logical.empty();
            end
        end

        % TODO: Fcns for setting nav slider pos, slider vals, L/R field values
        % TODO: Fcn for setting slider lims??
    end

    methods(Access=protected)
        function [newMin,newMinPos, newMax,newMaxPos] = getDataExtremes(app, axes, rows, lims)
            % matlab.graphics.axis.decorator.DurationRuler
            % [lines.YData] = deal([1 2 3 4])
            % [lines.YData] = deal([1 2 3 4], [2 3 4 5], [3 4 5 6], [4 5 6 7])
            % [lines.XData] = deal(lines.XData) % deal(days([1 2 3 4]))
            % lines = get(axes.UserData, 'Lines'); % Column matrix! TODO: Add this to axis UserData when setting up lines
            % xdatas = horzcat(lines.XData);
            % ydatas = horzcat(lines.YData);
            if app.XAxisModeIndex==1
                rrng = lims(1):lims(2);
            else
                if app.XAxisModeIndex==2 % Absolute time --convert to duration
                    lims = lims - app.TimeZero; % TODO: Add property??
                end
                rrng = timerange(lims(1),lims(2),"closed");
            end
            rows = app.PeakDataTimeTable{rrng, axes.UserData.TableVariableName}; % TODO: Create table property
            maxes = max(rows{:,:}, [], 2); mins = min(rows{:,:}, [], 2);
            [newMax, newMaxIdx] = max(maxes, [], 1); [newMin, newMinIdx] = min(mins, [], 1);
            if app.XAxisModeIndex==1
                newMaxPos = newMaxIdx; newMinPos = newMinIdx;
            else
                newMaxPos = app.PeakDataTimeTable.RelTime(newMaxIdx);
                newMinPos = app.PeakDataTimeTable.RelTime(newMinIdx);
                if bitxor(app.XAxisModeIndex,1) % Absolute time -- convert from duration
                    newMaxPos = app.TimeZero + newMaxPos;
                    newMinPos = app.TimeZero + newMinPos;
                end
            end
        end

        function changes = getMinMaxChanges(app, axes, lims)
            changes = {logical.empty() logical.empty()};
            [curMin,curMax] = getfield(axes.UserData, 'currentMinMax');
            [curMinPos,curMaxPos] = getfield(axes.UserData, 'currentMinMaxPos');
            [newMin,newMinPos, newMax,newMaxPos] = getDataExtremes(app, axes, lims);
            if newMin < curMin
                changes{1} = false;
            elseif (curMinPos < lims(1)) || (lims(2) < curMinPos)
                % changes{1} = true;
                changes{1} = false;
            end
            
            if newMax > curMax
                changes{2} = false;
            elseif (curMaxPos < lims(1)) || (lims(2) < curMaxPos)
                % changes{2} = true;
                changes{2} = false;
            end
        end
    end

end