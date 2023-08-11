function updateDiscontinuityTable(app, varargin)
    if isempty(app.DataTable{2})
        return;
    elseif size(app.DataTable{2},1) < 5
        app.DataTable{3}(:,:) = [];
        delete(findobj(app.HgtAxes.Children, 'Type', 'ConstantLine'));
        return;
    end

    % thr = 5\app.fdm(2); %3.5\app.fdm(2);
    % locDiffs = diff(app.DataTable{2}.PeakLoc,1);
    % msk1 = [false ; sum(locDiffs>thr,2,'omitnan')>=(1+idivide(app.NumChannels,2,'fix'))];
    % msk2 = [false ; sum(locDiffs<-thr,2,'omitnan')>=(1+idivide(app.NumChannels,2,'fix'))];
    % msk = msk1 | msk2;
    
    thr = 5\app.fdm(2); %3.5\app.fdm(2);

    locDiffs = vertcat(zeros(1,app.NumChannels), diff(app.DataTable{2}.PeakLoc,1));
    locDiffsDeriv = [diff(locDiffs,1) ; zeros(1,app.NumChannels)];
    locDiffsMean = movmean(locDiffs, 16, 1, 'omitnan', 'Endpoints', 'shrink');
    
    % "sample points"?
    % movmean([1 2 3 4 5 ; 6 7 8 9 10 ; 11 12 13 14 15], 2, 1, 'Endpoints', 'shrink', 'SamplePoints', [10 20 30])

    discs1 = abs(locDiffs) > thr;
    discs2 = abs(locDiffsDeriv) > locDiffsMean;%(0.4*locDiffsMean);
    discs  = discs1 | discs2;

    msk1 = any(discs1, 2);
    msk2 = any(discs2, 2);
    
    mm1 = movmean(single(msk1), 4, 'omitnan');
    msk1 = (mm1 > 0.4) | ((mm1 <= 0.25) & msk1);
    mm2 = movmean(single(msk2), 4, 'omitnan');
    msk2 = (mm2 > 0.4) | ((mm2 <= 0.25) & msk2);

    % display([mm1' ; mm2' ; msk1' ; msk2']);

    msk1 = msk1 & (~([msk1(2:end) ; true] | [true ; msk1(1:end-1)]) | ~([msk1(2:end) ; true] | [true ; msk1(1:end-1)]));
    msk2 = msk2 & (~([msk2(2:end) ; true] | [true ; msk2(1:end-1)]) | ~([msk2(2:end) ; true] | [true ; msk2(1:end-1)]));

    % msk = msk1 | msk2;

    msk3 = any(isnan(app.DataTable{2}{:, ["PeakLoc" "PeakHgt"]}), 2);
    
    timeDiffs = filloutliers(seconds(diff(app.DataTable{2}.RelTime)), "linear", "percentiles", [0 95]);
    thrTime = seconds(0.25*(app.SPPField.Value + 3*median(timeDiffs, 'omitnan')));
    msk4 = [false ; diff(app.DataTable{2}.RelTime) >= 20*thrTime];
    msk4 = msk4 & (~([msk4(2:end) ; true] | [true ; msk4(1:end-1)]) | ~([msk4(2:end) ; true] | [true ; msk4(1:end-1)]));
    msk4(end) = false;

    msk = msk1 | msk2 | msk3;


    msk = bwmorph(msk, 'bridge', 2);

    msk = msk | msk4;
    
    % display(discs1');
    % display(discs2');
    % display([repelem(thr, 1, length(locDiffs)) ; locDiffs' ; 0.4*locDiffsMean' ; locDiffsDeriv' ; double(discs') ; ...
    %    double(msk1') ; double(msk2') ; double(msk')]);
    % display(msk');

    if (nargin > 1) 
        if ~isempty(varargin{1})
            msk = msk & ~(app.DataTable{2}.Index < varargin{1}(1));
            if ~isscalar(varargin{1})
                msk = msk & ~(app.DataTable{2}.Index > varargin{1}(2));
            end
            % display(msk');
        end
        msk0 = ismember(app.DataTable{2}.RelTime, app.DataTable{3}.RelTime);
        rows = app.DataTable{3}(app.DataTable{2}.RelTime(msk0), ["SplitStatus" "IsDiscontinuity"]);
        msk1 = ~rows.IsDiscontinuity | ~logical(bitget(rows.SplitStatus, 1));
        msk(msk0) = msk1;
        % display(msk');
    end

    
    relTimes = app.DataTable{2}.RelTime(msk);
    relTimes0 = app.DataTable{3}.RelTime;
    removedTimes = setdiff(relTimes0, relTimes);
    addedTimes = setdiff(relTimes, relTimes0);

    % display(removedTimes);
    
    for i=1:length(removedTimes)
        t = removedTimes(i);
        roiLine = app.DataTable{3}{t, 'ROI'};
        % display(roiLine);
        if ~isempty(roiLine) && ishandle(roiLine) && isgraphics(roiLine) && isvalid(roiLine)
            roiLine.Visible = false;
            delete(roiLine); % TODO: Change sync status instead??
        end
        app.DataTable{3}(t,:) = [];
    end

    for i=1:length(addedTimes)
        t = addedTimes(i);
        idx = app.DataTable{2}{t, 'Index'};
        if isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.NumericRuler')
            pos = idx;
        else
            if isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.DurationRuler')
                pos = t;
            else
                pos = t + app.TimeZero;
            end
            pos = ruler2num(pos, app.HgtAxes.XAxis);
        end
        %markLine = xline(app.HgtAxes, pos, 'Visible', true, 'Color', [1 0 1]);
        markLine = matlab.graphics.chart.decoration.ConstantLine('InterceptAxis', 'x', ...
            'Parent', app.HgtAxes, 'Value', NaN(1,1,'double'), 'Visible', true, ...% 'Color', [0.35 0.35 0.35], 'LineWidth', 0.5);
            'Color', [0 0 0], 'LineWidth', 0.5, 'Alpha', 1.0);
        markLine.Value =  double(pos);
        
        % display(app.DataTable{3});
        % disp({t,idx,false,true,discs(i),markLine});
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TODO: UPDATE ROW CONTENTS
        %app.DataTable{3}(t,:) = {idx, true, false, markLine...
        %    }; % TODO: Threshold for automatically adding a boundary?
        app.DataTable{3}(t,:) = {idx, false, true, discs(i,:), markLine};
    end
    
    keptTimes = setdiff(relTimes, addedTimes);
    for i = 1:length(keptTimes)
        t = keptTimes(i);
        idx = app.DataTable{2}{t, 'Index'};
        if ~ishandle(app.DataTable{3}{t,'ROI'}) || ~isvalid(app.DataTable{3}{t,'ROI'})
            % TODO: Warn and/or recreate?
            continue;
        end
        if isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.NumericRuler')
            pos = double(idx);
        else
            if isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.DurationRuler')
                pos = t;
            else
                pos = t + app.TimeZero;
            end
            pos = ruler2num(pos, app.HgtAxes.XAxis);
        end
        set(app.DataTable{3}{t,'ROI'}, 'Value', pos); %[pos app.HgtAxes.YLim(1) pos app.HgtAxes.YLim(1)]);
    end

    cls = findobj(app.HgtAxes.Children, 'Type', 'ConstantLine');
    msk = ismember(cls, app.DataTable{3}.ROI);
    delete(cls(~msk));
end