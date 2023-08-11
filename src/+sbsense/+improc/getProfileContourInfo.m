function [YDATA1, peakHgts, peakLocs, peakWids, peakPrms, peakScores, numPeaks, peakStrictness, msk0, ...
    maxValInProfile, medValInProfile, maxValInSmoothedProfile, medValInSmoothedProfile] ...
    = getProfileContourInfo(XDATA, YDATA, varargin)
YDATA1 = smoothdata(YDATA, 'lowess', 32, 'omitnan'); % TODO: Window?
maxValInProfile = max(YDATA, [], 'all', 'omitnan');
medValInProfile = median(YDATA, 'all', 'omitnan');
maxValInSmoothedProfile = max(YDATA1, [], 'all', 'omitnan');
medValInSmoothedProfile = median(YDATA1, 'all', 'omitnan');

[peakHgts, peakLocs, peakWids, peakPrms] = findpeaks(YDATA1, XDATA, ...
    'SortStr', 'descend', 'WidthReference', 'halfheight', ...
    'MinPeakWidth', 10, 'MaxPeakWidth', 250, 'MinPeakDistance', 10, ...
    'MinPeakHeight', 0.4*maxValInSmoothedProfile, ...
    ... % 'MaxPeakHeight', maxValInSmoothedProfile + (maxValInProfile - medValInSmoothedProfile)*0.1, ...
    'MinPeakProminence', 0.02);



if ~isempty(peakHgts)
    msk1 = peakHgts >= 0.7*medValInSmoothedProfile;
    if ~any(msk1)
        msk1 = peakHgts >= 0.33*medValInSmoothedProfile;
    end

    msk2 = peakHgts >= 0.5*maxValInProfile;
    if ~any(msk2)
        msk2 = peakHgts >= 0.2*maxValInSmoothedProfile;
    end

    msk0 = msk1 & msk2;
    if ~any(msk0)
        if all(msk1) && any(msk2)
            msk0 = msk2;
        elseif all(msk2) && any(msk1)
            msk0 = msk1;
        elseif any(msk1) && (sum(msk1)>=sum(msk2))
            msk0 = msk1;
        else
            msk0 = msk2;
        end
    end
else
    msk0 = true(size(peakHgts));
end

if isempty(peakHgts) || ~any(msk0) % || all(msk0)
    [peakHgts2, peakLocs2, peakWids2, peakPrms2] = findpeaks(YDATA1, XDATA, ...
        'SortStr', 'descend', 'WidthReference', 'halfheight', ...
        'MinPeakWidth', 2, 'MaxPeakWidth', 300, 'MinPeakDistance', 1, ...
        'MinPeakHeight', 0.2*maxValInProfile, ...
        ... % 'MaxPeakHeight', maxValInProfile + (maxValInProfile - medValInSmoothedProfile)*0.2, ...
        'MinPeakProminence', 0.01, 'NPeaks', 10);
    if ~isempty(peakHgts2)
        msk1 = peakHgts2 >= 0.7*medValInSmoothedProfile;
        if ~any(msk1)
            msk1 = peakHgts2 >= 0.33*medValInSmoothedProfile;
        end

        msk2 = peakHgts2 >= 0.5*maxValInProfile;
        if ~any(msk2)
            msk2 = peakHgts2 >= 0.2*maxValInSmoothedProfile;
        end

        msk02 = msk1 & msk2;
        if ~any(msk02)
            if all(msk1) && any(msk2)
                msk02 = msk2;
            elseif all(msk2) && any(msk1)
                msk02 = msk1;
            elseif any(msk1) && (sum(msk1)>=sum(msk2))
                msk02 = msk1;
            else
                msk02 = msk2;
            end
        end
    end
    if ~isempty(peakHgts2) && ~all(msk02)
        msk0 = msk02;
        peakHgts = peakHgts2;
        peakLocs = peakLocs2;
        peakWids = peakWids2;
        peakPrms = peakPrms2;
        peakStrictness = 1;
        % numPeaks = length(peakHgts);
    elseif isempty(peakHgts2) && ~isempty(peakHgts)
        peakStrictness = 3;
        % numPeaks = length(peakHgts);
    elseif ~isempty(peakHgts2)
        msk0 = msk02;
        peakHgts = peakHgts2;
        peakLocs = peakLocs2;
        peakWids = peakWids2;
        peakPrms = peakPrms2;
        peakStrictness = 1;
        % numPeaks = length(peakHgts);
    else
        peakStrictness = 0;
    %     [peakHgts3, peakLocs3, peakWids3, peakPrms3] = findpeaks(YDATA1, XDATA, ...
    %     'SortStr', 'descend', 'WidthReference', 'halfheight', ...
    %     ... %'MinPeakWidth', 0, 'MinPeakDistance', 1, ...
    %     ... %'MinPeakHeight', 0.2*maxValInProfile, ...
    %     ... % 'MaxPeakHeight', maxValInProfile + (maxValInProfile - medValInSmoothedProfile)*0.2, ...
    %     ... % 'MinPeakProminence', 0.01,
    %     'NPeaks', 10);
    %     peakHgts = peakHgts3;
    %     peakLocs = peakLocs3; % unnecessary?
    %     peakWids = peakWids3; % unnecessary?
    %     peakPrms = peakPrms3; % unnecessary?
    %     if isempty(peakHgts3)
            numPeaks = 0;
            peakScores = double.empty();
            return;
        % end 
    end
else
    peakStrictness = 2;
end

numPeaks = length(peakHgts);

if (nargin > 2) % && (~isempty(varagin{1}) || (nargin>3))
    if (nargin > 3) && ~isempty(varargin{2}) && ~isequal(varargin{2}, [0 0]) % TODO
        % locsLeft = fix(peakLocs - 2\peakWids);
        % locsRight = ceil(peakLocs + 2\peakWids);
        % msk = (locsLeft >= varargin{2}(1)) & (varargin{2}(2) >= locsRight);
        msk = (varargin{2}(1) <= peakLocs) & (peakLocs <= varargin{2}(2));
        
        if ~any(msk)
            leftPoss = max(1,fix(peakLocs - 2\peakWids));
            rightPoss = ceil(peakLocs + 2\peakWids);

            areasInsidePSZ = max(0, min(varargin{2}(2), rightPoss, 'includenan') - max(varargin{2}(1), leftPoss, 'includenan'), 'includenan');
            if ~any(areasInsidePSZ)
                if peakStrictness>1
                    [peakHgts2, peakLocs2, peakWids2, peakPrms2] = findpeaks(YDATA1, XDATA, ...
                    'SortStr', 'descend', 'WidthReference', 'halfheight', ...
                    'MinPeakWidth', 10, 'MaxPeakWidth', 300, 'MinPeakDistance', 1, ...
                    'MinPeakHeight', 0.1*maxValInSmoothedProfile, ...
                    'MinPeakProminence', 0.01, 'NPeaks', 10);
                    peakStrictness = 1; %#ok<NASGU> 

                    msk = (varargin{2}(1) <= peakLocs2) & (peakLocs2 <= varargin{2}(2));

                    msk1 = peakHgts2 >= 0.7*medValInSmoothedProfile;
                    if ~any(msk1)
                        msk1 = peakHgts2 >= 0.33*medValInSmoothedProfile;
                    end

                    msk2 = peakHgts2 >= 0.5*maxValInProfile;
                    if ~any(msk2)
                        msk2 = peakHgts2 >= 0.2*maxValInSmoothedProfile;
                    end

                    msk03 = msk1 & msk2;
                    if ~any(msk03)
                        if all(msk1) && any(msk2)
                            msk03 = msk2;
                        elseif all(msk2) && any(msk1)
                            msk03 = msk1;
                        elseif any(msk1) && (sum(msk1)>=sum(msk2))
                            msk03 = msk1;
                        else
                            msk03 = msk2;
                        end
                    end
                    if any(msk)
                        peakLocs = peakLocs2; peakHgts = peakHgts2; peakWids = peakWids2; peakPrms = peakPrms2;
                        leftPoss = max(1,fix(peakLocs - 2\peakWids));
                        rightPoss = ceil(peakLocs + 2\peakWids);
                        areasInsidePSZ = max(0, min(varargin{2}(2), rightPoss, 'includenan') - max(varargin{2}(1), leftPoss, 'includenan'), 'incudenan');
                        if any(areasInsidePSZ)
                            peakLocs = peakLocs2; peakHgts = peakHgts2; peakWids = peakWids2; peakPrms = peakPrms2;
                            msk0 = msk03;
                        end
                    end
                end
            end           
        end
        if any(msk)
            if ~all(msk)
                peakHgts = peakHgts(msk);
                peakLocs = peakLocs(msk);
                peakWids = peakWids(msk);
                peakPrms = peakPrms(msk);
                numPeaks = length(peakHgts);
                msk0 = msk0(msk);
            end
        else
            if any(areasInsidePSZ)
                pctInsidePSZ = areasInsidePSZ ./ peakWids;
                [~, idxs] = maxk(pctInsidePSZ, 3);
            else % TODO: How many alternatives?
                dists = min(abs(peakLocs - varargin{2}(1)), abs(peakLocs - varargin{2}(2)), 'omitnan');
                [~, idxs] = mink(dists, 3); % , 'all', 'omitnan');
            end
            peakHgts = peakHgts(idxs);
            peakLocs = peakLocs(idxs);
            peakWids = peakWids(idxs);
            peakPrms = peakPrms(idxs);
            numPeaks = length(peakHgts);
            msk0 = msk0(idxs);
        end
    end
    if ~isempty(varargin{1}) % && ~anynan(varargin{1}) && allfinite(varargin{1}) % TODO: check elsewhere?
        % p0 = varargin{1};
        lastLoc = varargin{1}(1); % p0(1);
        b = varargin{1}(2); % p0(2);
        a = varargin{1}(3); % p0(3);
        lastHgt = a/b;
        lastWid = 2*b;
        %peakScores = 1 - 5\( ...
        %    3*normalize(abs(peakLocs - lastLoc), 'range') ...
        %    + normalize(abs(peakWids - lastWid), 'range') ...
        %    + 2*normalize(abs(peakHgts - lastHgt), 'range') );
        peakScores = 1 - 5\( ...
            rescale(abs(peakLocs - lastLoc), 0, 3.5) ...
            + rescale(abs(peakWids - lastWid), 0, 0.75) ...
            + rescale(abs(peakHgts - lastHgt), 0, 0.75) );
        % peakScores = rescale(peakPrms, 0, 0.85) + rescale(peakScores, 0, 0.15);
        peakScores = rescale(peakPrms, 0, 0.55) + rescale(peakScores, 0, 0.45);
    else
        % peakScores = (normalize(peakPrms, 'range').^2) .* normalize(peakHgts, 'range');
        % peakScores = rescale(peakPrms, 0, 0.75) + rescale(peakHgts, 0, 0.25);
        peakScores = rescale(peakPrms, 0, 0.65) + rescale(peakHgts, 0, 0.35);
    end
else
    % peakScores = (normalize(peakPrms, 'range').^2) .* normalize(peakHgts, 'range');
    % peakScores = rescale(peakPrms, 0, 0.75) + rescale(peakHgts, 0, 0.25);
    peakScores = rescale(peakPrms, 0, 0.65) + rescale(peakHgts, 0, 0.35);
end
% TODO: Refine scoring?
end