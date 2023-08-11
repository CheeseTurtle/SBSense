function  [channelPeakData,YDATA0, ...
    p1, successTF, cfitBounds, sampMask, sampMask0, roiMask, resnorm, wps,ws,XDATA] ...
    = sbestimatepeakloc(Y0c,Y1c,Ycc,...%estimatedLaserIntensity, ...
    origDims, peakSearchBounds, peakSearchZone, f, p01)%, sampMaskResults, preferFallbackMask)
arguments(Input)
    Y0c; Y1c; Ycc; %#ok<INUSA>
    origDims (1,2) uint16;
    peakSearchBounds (1,2) uint16;
    peakSearchZone = [];
    f = 1;
    p01 = [];
    %sampMaskResults = {}; %#ok<INUSA>
    %preferFallbackMask = true; %#ok<INUSA>
end

sampMask = [];
sampMask0 = [];
roiMask = [];
wps = [];
ws = [];
wd = double(origDims(2));

% TODO: better error handling to prevent loss of intensity profile etc

% 0) Divide Y1/Y0 = Yr.
% 1) Determine tail pixels and their weight for averaging
% 2) Determine A ≈ A1 ≈ A2 ≈ A3 (ALT+247)
%    A ≈ average of all Aij (value of tail pixel in Yr)
% 2) Multiply scalar estimated A with BG image Y0
% 3) Subtract Y1 from the product (or subtract
%    product from Y1)
% 4) Divide result of subtraction by each Aij
%    (or scalar A? or mean of scalar A and Aij?)
%    ** Fill outliers AND PEAK PART with scalar A **

if anynan(p01)
    p01 = double.empty();
end

if ~peakSearchBounds(1)
    peakSearchBounds(1) = 1;
end
if ~peakSearchBounds(2)
    peakSearchBounds(2) = origDims(2);
end

if isempty(peakSearchZone) || isequal(peakSearchZone, [0 0]) || anynan(peakSearchZone) || isequal(peakSearchZone, [1 origDims(2)])% || ~all(peakSearchZone)
    peakSearchZone0 = [];
    peakSearchZone = double(peakSearchBounds);
else
    if ~logical(peakSearchZone(1))
        if peakSearchBounds(1) < peakSearchZone(2)
            peakSearchZone(1) = peakSearchBounds(1);
        else
            peakSearchZone(1) = 1;
        end
    end
    if ~logical(peakSearchZone(2))
        if peakSearchBounds(2) > peakSearchZone(1)
            peakSearchZone(2) = peakSearchBounds(2);
        else
            peakSearchZone(2) = origDims(2);
        end
    end
    peakSearchZone0 = double(peakSearchZone);
    peakSearchZone = peakSearchZone0;
end


xmax = double(origDims(2));
XDATA = 1:xmax;
YDATA0 = mean(im2double(Ycc), 1, 'omitnan'); % TODO: what about Y0c and Y1c?


if ~isequal(f,1)
    fprintf(f, '[sbestimatepeakloc] (Switching to logging to diary/stdout instead of to this logfile.)\n');
end
fprintf('[sbestimatepeakloc] peakSearchBounds: [%g %g]; peakSearchZone: [%g %g];peakSearchZone0: %s\n', ...
    peakSearchBounds(1), peakSearchBounds(2), peakSearchZone(1), peakSearchZone(2), ...
    strrep(fdt(peakSearchZone0), '  ', ' '));

%% I. Attempt to find peaks
% [peakInfo, YDATA1, p0, tab] =
fprintf('[sbestimatepeakloc] ~~~~~~ PART I (GUIDE PEAK OBTAINMENT) ~~~~~~\n');
fprintf('[sbestimatepeakloc] >>> Calling getProfileContourInfo with arguments (size):\n\t\tXDATA (%s), YDATA0 (%s), p01=%s, AND peakSearchZone=%s\n', ...
    fdt(size(XDATA)), fdt(size(YDATA0)), fdt(p01), fdt(peakSearchZone));
[YDATA1, peakHgts, peakLocs, peakWids, peakPrms, peakScores, numPeaks, peakStrictness, msk0, ...
    maxValInProfile, medValInProfile, maxValInSmoothedProfile, medValInSmoothedProfile] ...
    = sbsense.improc.getProfileContourInfo(XDATA, YDATA0, p01, peakSearchZone); %#ok<ASGLU> 

maxPkHgt = 1.5*max(YDATA0, [], 'omitnan') + 0.5*mean(YDATA1, 'all', 'omitnan');

if numPeaks
    % disp({size(peakLocs),size(peakHgts), size(peakWids), size(peakPrms), size(peakScores), size(msk0)});
    tab = table(peakLocs', peakHgts', peakWids', peakPrms', peakScores', msk0', ...
        'VariableNames', {'Loc', 'Hgt', 'Wid', 'Prm', 'Score', 'Mask'});
    if ~any(msk0)
        fprintf('[sbestimatepeakloc] >> Found %u peaks (strictness: %d), of which none meet the general height and location requirements:\n%s\n', numPeaks, peakStrictness, fdt(tab));
    else
        fprintf('[sbestimatepeakloc] >> Found %u peaks (strictness: %d), of which %d meet(s) the general height and location requirements:\n%s\n', numPeaks, peakStrictness, ...
            sum(msk0), fdt(tab));
        if ~all(msk0)
            peakHgts = peakHgts(msk0); peakWids = peakWids(msk0); peakPrms = peakPrms(msk0); peakScores = peakScores(msk0);
            peakLocs = peakLocs(msk0);
        end
    end

    if ~isempty(p01) % We know previous frame's peak
        % Check for identical / near-identical peak to use as guide
        %tab = addvars(tab, ...
        %    abs(peakLocs - p01(1))./peakWids, ...
        % deltaLocs = abs(peakLocs - p01(1)) ./ (p01(2) + 0.5*peakWids);

        lastHgt = p01(3)/p01(2);
        msk03 = peakHgts >= 0.8 * lastHgt;
        deltaHgts = abs(1 - peakHgts / lastHgt);
        deltaWids = abs(1 - peakWids / (2*p01(2)));
        deltaLocs = abs(peakLocs - p01(1));
        maxDeltaLoc = max(10, min(0.75*p01(2), wd/32)); % 40));
        fprintf('[sbestimatepeakloc] > minmax deltaHgts: [%g %g], minmax deltaWids: [%g %g]\n', ...
            min(deltaHgts, [], 'all', 'omitnan'), max(deltaHgts, [], 'all', 'omitnan'), ...
            min(deltaWids, [], 'all', 'omitnan'), max(deltaWids, [], 'all', 'omitnan'));
        fprintf('[sbestimatepeakloc] > minmax deltaLocs: [%g %g], maxDeltaLoc: %g\n', ...
            min(deltaLocs, [], 'all', 'omitnan'), max(deltaLocs, [], 'all', 'omitnan'), ...
            maxDeltaLoc);

        msk = deltaLocs <= maxDeltaLoc;
        if any(msk & msk03)
            msk = msk & msk03;
        end

        % identLvl = 0;
        if any(msk)
            msk2 = (deltaHgts <= 0.05) & (deltaWids <= 0.10);
            if any(msk & msk2)
                msk = msk & msk2;
                identLvl = 3; % Identical
                fprintf(['[sbestimatepeakloc] >> At least 1 effectively identical peak found' ...
                    ' (deltaLoc<=%g & deltaHgt<=0.05 & deltaWid<=0.10).\n'], ...
                    maxDeltaLoc);
            else
                maxDeltaLoc = max(20, min(p01(2), 80));
                msk3 = deltaLocs <= maxDeltaLoc;
                if any(msk3 & msk2)
                    fprintf(['[sbestimatepeakloc] >> At least 1 similar peak found' ...
                        ' (deltaLoc<=%g & deltaHgt<=0.05 & deltaWid<=0.10).\n'], ...
                        maxDeltaLoc);
                    identLvl = 2; % Near-identical
                    msk = msk3 & msk2;
                    %elseif any(msk3)
                    %    identLvl = 1; % Nearby
                    %    msk = msk
                    %else
                    %    identLvl = 1; % No peaks nearby
                    %    msk = false;
                else
                    identLvl = 1; % Nearby
                    fprintf(['[sbestimatepeakloc] >> At least 1 nearby peak found' ...
                        ' (deltaLoc<=%g).\n'], maxDeltaLoc);
                end
            end
            %if any(msk & msk03 & msk0)
            %    fprintf('[sbestimatepeakloc] %d nearby peaks were found, of which %d meet(s) the general and precedent-based height requirements.\n', ...
            %        sum(msk), sum(msk & msk03 & msk0));
            %    msk = msk & msk03 & msk0;
            %elseif any(msk & msk03)
            if any(msk & msk03)
                fprintf('[sbestimatepeakloc] >> %d nearby peaks were found, of which %d meet(s) the precedent-based height requirements.\n', ...
                    sum(msk), sum(msk & msk03));
                msk = msk & msk03;
                %elseif any(msk & msk0)
                %    fprintf('[sbestimatepeakloc] %d nearby peaks were found, of which %d meet(s) the general height requirements.\n', ...
                %        sum(msk), sum(msk & msk0));
                %    msk = msk & msk0;
            end
            numPeaksNearby = sum(msk);

            if numPeaksNearby > 1
                if identLvl == 3 % Choose closest in position
                    idxs = 1:numPeaks;
                    idxs = idxs(msk);
                    [~,idx] = min(deltaLocs(msk), [], 'all', 'omitnan');
                    idx = idxs(idx);
                    fprintf('[sbestimatepeakloc] The closest nearby peak (peak %u) was chosen.\n', idx);
                else % Choose highest-scored peak
                    [~,idx] = max(peakScores.*msk, [], 'all', 'omitnan');
                    fprintf('[sbestimatepeakloc] The most highly-scored nearby peak (peak %u) was chosen.\n', idx);
                end
            else
                idx = find(msk, 1);
                fprintf('[sbestimatepeakloc] >>> The only nearby peak (peak %u) was chosen.\n', idx);
            end
            % TODO: For identLvl==1, look for competing peaks too??
        else % No peaks nearby -- choose most prominent
            [~,idx] = max(peakPrms, [], 'all', 'omitnan');
            fprintf('[sbestimatepeakloc] >>> The most prominent peak (peak %u) was chosen.\n', idx);
        end

        [~, idx1] = max(peakScores, [], 'all', 'omitnan');
        [~, idx2] = max(peakHgts, [], 'all', 'omitnan');
        [~, idx3] = max(peakPrms, [], 'all', 'omitnan');
        idxs1 = unique([idx1, idx2]); % TODO: Select indices with removal...?
        idxs2 = unique([idx1, idx3]); % TODO: Select indices with removal...?
        % bestPeakHgts = peakHgts(idxs1);
        % bestPeakPrms = peakPrms(idxs2);

        if any(abs(peakLocs(idx) - peakLocs([idxs1 idx3])) <= 2\peakWids([idxs1 idx3])) ...
                || (any(abs(peakLocs(idx) - peakLocs) <= 1.9\peakWids(idx)) ...
                && (any(abs(peakHgts(idxs1) - peakHgts(idx)) <= 0.5*peakHgts(idxs1)) ...
                || any(abs(peakPrms(idxs2) - peakPrms(idx)) <= 0.25)))
            guideLevel = 3;
        else
            fprintf('[sbestimatepeakloc] >>> The highest-scored peak (peak %u) will replace the chosen nearby peak as the guide, since the previous choice is questionable.\n', idx);
            guideLevel = 2;
            idx = idx1;
        end
    else % Previous frame's peak unknown -- must choose guide peak based on prominence
        guideLevel = 2;
        [~,idx] = max(peakScores, [], 'all', 'omitnan');
        % [~,idx] = max(peakScores.*msk0, [], 'all', 'omitnan');
        % if all(msk0)
        %     fprintf('[sbestimatepeakloc] The highest-scored peak (peak %u) was chosen (although none of the peaks met the general height requirements).\n', idx);
        % else
        %     fprintf('[sbestimatepeakloc] The highest-scored peak (peak %u) that meets the general height requirements was chosen.\n', idx);
        % end
    end
    guideHgt = peakHgts(idx);
    %guideWid = peakWids(idx);
    % guideHW = 2\guideWid;
    guideHW = 2\peakWids(idx);
    guideLoc = peakLocs(idx);
    p0g = [guideLoc guideHW guideHgt*guideHW];
elseif ~isempty(p01) % No peaks found; try using prev. peak as guide peak
    fprintf('[sbestimatepeakloc] >>> No peaks found. Using previous peak ([%g %g %g]) as guide.\n', ...
        p01(1), p01(2), p01(3));
    [hgts_, locs_, wds_, prms_] = findpeaks(YDATA1, XDATA, 'NPeaks', 10, 'SortStr', 'descend');
    display(table(locs_',hgts_',wds_',prms_','VariableNames', {'Loc', 'Hgt', 'Wid', 'Prm'}));
    p0g = p01;
    guideHgt = p01(3)/p01(2);
    guideHW = p01(2);
    %guideWid = 2*guideHW;
    guideLoc = p01(1);
    guideLevel = 1;
else % No peaks found and previous frame's peak unknown. Fit naively.
    fprintf('[sbestimatepeakloc] >>> No peaks found and previous peak unknown. Fitting without guide.\n');
    [hgts_, locs_, wds_, prms_] = findpeaks(YDATA1, XDATA, 'NPeaks', 10, 'SortStr', 'descend');
    display(table(locs_',hgts_',wds_',prms_','VariableNames', {'Loc', 'Hgt', 'Wid', 'Prm'}));
    guideLevel = 0;
    [guideHgt, guideLoc] = max(YDATA1, [], 'all', 'omitnan');
    p0g = [guideLoc 1 guideHgt];
    guideHW = wd/1280; %1; % guideWid = 2;
end

if guideLevel
    leftIdx = max(1,fix(guideLoc - guideHW));
    rightIdx = min(xmax, ceil(guideLoc + guideHW));
    fprintf('[sbestimatepeakloc] > p0g: [%g %g %g] (hgt: %g, HW: %g, L/R: [%g %g])\n', ...
        p0g(1), p0g(2), p0g(3), guideHgt, guideHW, leftIdx, rightIdx);
    peakBodyIdxs = leftIdx:rightIdx;
    maxValInPeakBody = max(YDATA0(leftIdx:rightIdx), [], 'all', 'omitnan');
    fprintf('[sbestimatepeakloc] > Max val in peak body: %g\n', ...
        maxValInPeakBody);
    minHgt = max(1e-10, 0.90*guideHgt);
    maxHgt = min(maxPkHgt, 0.50*(guideHgt + maxValInPeakBody) + 0.05*guideHgt);
    minHW = min(max(0.01*guideHW, wd/2560), wd/640); %0.5), 2); % TODO: Vary based on width of image??
    maxHW = 1.1*guideHW; % 1.05*guideHW;
    if ~isempty(peakSearchZone0)
        minmaxLoc = peakSearchZone;
        fprintf('[sbestimatepeakloc] > Hgt range: [%g %g], HW range: [%g %g], Loc range: [%g %g]=PSZ\n', ...
            minHgt, maxHgt, minHW, maxHW, minmaxLoc(1), minmaxLoc(2));
    else
        minmaxLoc = max(1,min(xmax, guideLoc + [-0.45,0.45]*guideHW));
        fprintf('[sbestimatepeakloc] > Hgt range: [%g %g], HW range: [%g %g], Loc range: [%g %g]\n', ...
            minHgt, maxHgt, minHW, maxHW, minmaxLoc(1), minmaxLoc(2));
    end
    minA = minHgt * minHW; maxA = maxHgt * maxHW;

    FBPM = false(size(Ycc));
    FBPM(:,peakBodyIdxs) = true;
    FBPMrow = FBPM(1,:);

    fitParamBounds = [ minmaxLoc(1) minHW minA ; ...
        minmaxLoc(2) maxHW maxA ];
    numFitPoints = length(peakBodyIdxs);
    %fprintf('[sbestimatepeakloc] numFitPoints: %d\n', ...
    %    numFitPoints);
    %display(fitParamBounds);


    fprintf('[sbestimatepeakloc] ~~~~~~ PART II (PRIMARY/PRELIMINARY FITTING) ~~~~~~\n');
    [p1QF,resnormQF,wpsQF,wsQF,~,~,residsQF] = sbsense.improc.lzcurvefit(p0g, ...
        peakBodyIdxs, YDATA0(peakBodyIdxs), ...
        peakSearchBounds, peakSearchZone, ...
        numFitPoints, FBPM, false, ... % TODO: prefer fallback?
        fitParamBounds, 1, p01); %#ok<ASGLU> 

    if isscalar(resnormQF)
        fprintf('[sbestimatepeakloc] < resnormQF, p1QF: %g, %s\n', resnormQF, fdt(p1QF));
    else
        fprintf('[sbestimatepeakloc] < resnormQF, p1QF: <nonscalar!!>, %s\n', fdt(p1QF));
        display(resnormQF);
    end
    resnormQF = abs(resnormQF);
    wresnorm0QF = resnormQF;
    % wresnorm0QF = resids(QF);

    [p1WF,wresWF0, p01WF,wpsWF, ~, ~, ~, predCurve, ~] ...
        = sbsense.improc.lzcurvefite(p01,XDATA,YDATA0,YDATA1,p0g); %#ok<ASGLU>
    fprintf('[sbestimatepeakloc] < p1WF: %s\n', fdt(p1WF));
    % if ~isempty(p1WF)
    %     p1WFhgt = p1WF(3)/p1WF(2);
    %     if ((p1WF(2) < minHW) || (p1WF(2) > maxHW) || ((p1WF(3)/p1WF(2))<minHgt) || ((p1WF(3)/p1WF(2))>maxHgt)
    %         resnormWF = sum((sbsense.lorentz(p1, XDATA(peakBodyIdxs))-YDATA0(peakBodyIdxs)).^2, 'all', 'omitnan');
    %         if resnormWF > 0.05
    %             p1WF = [];
    %         end
    %         en
    % end

    if isempty(p1WF) % TODO: Also check if p1WF is within bounds...
        WFisSuperior = false;
        predCurveQF = [];
        fprintf('[sbestimatepeakloc] <<< WF is not superior, since p1WF=[].\n');
    elseif isempty(p1QF)
        WFisSuperior = true;
        wresnorm0WF = sum(wresWF0.^2, 'all', 'omitnan');
        fprintf('[sbestimatepeakloc] <<< WF is superior, since p1QF=[] and p1WF~=[].\n');
        predCurveQF = [];
    elseif ((p1QF(3) / p1QF(2)) > maxPkHgt)
        WFisSuperior = true;
        wresnorm0WF = sum(wresWF0.^2, 'all', 'omitnan');
        fprintf('[sbestimatepeakloc] <<< WF is superior, since p1QF A/B = %g/%g = %g > maxPkHgt %g.\n', ...
            p1QF(3), p1QF(2), (p1QF(3) / p1QF(2)), maxPkHgt);
        predCurveQF = [];
    else
        % disp({size(wpsWF), size(residsQF)});
        %if true
            predCurveQF = sbsense.lorentz(p1QF, XDATA);
            wres2QF1 = ((YDATA0 - predCurveQF) .* wpsWF(end,:)) .^ 2;
            wres2QF2 = ((YDATA1 - predCurveQF) .* wpsWF(end,:)) .^ 2;
            wres2WF1 = wresWF0.^2;
            wres2WF2 = ((YDATA1 - predCurve).*wpsWF(end,:)) .^ 2;
            fprintf('[sbestimatepeakloc] < wres2QF1/2: [%g + %g -> %g], [%g + %g -> %g]\n', ...
                sum(wres2QF1(FBPMrow)), sum(wres2QF1(~FBPMrow)), sum(wres2QF1), ...
                sum(wres2QF2(FBPMrow)), sum(wres2QF2(~FBPMrow)), sum(wres2QF2));
            fprintf('[sbestimatepeakloc] < wres2WF1/2: [%g + %g -> %g], [%g + %g -> %g]\n', ...
                sum(wres2WF1(FBPMrow)), sum(wres2WF1(~FBPMrow)), sum(wres2WF1), ...
                sum(wres2WF2(FBPMrow)), sum(wres2WF2(~FBPMrow)), sum(wres2WF2));
        %end
        residsQF = 0.5*(YDATA0+YDATA1) - sbsense.lorentz(p1QF, XDATA);
        wresWF = 0.5*(wresWF0 + wpsWF(end,:).*(YDATA1 - predCurve)); %sbsense.lorentz(p1WF, XDATA)));
        % display(sum(wpsWF(end,:), 'all', 'omitnan'));
        wresQF = residsQF.*wpsWF(end,:); % ./ sum(wpsWF(end,:), 'all', 'omitnan');
        % disp({size(wresQF), size(residsQF)});
        % wres2QF = (residsQF.^2).*wpsWF(end,:) ./ sum(wpsWF(end,:), 'all', 'omitnan');% wresQF.^2;
        wres2QF = wresQF.^2;
        wres2WF = wresWF.^2;

        wresnorm0QF = sum(wres2QF, 'all', 'omitnan');
        wresnorm0WF = sum(wres2WF, 'all', 'omitnan');

        if (wresnorm0WF > 0.5) && ((wresnorm0QF <= 0.5) || (resnormQF <= 0.5))
            fprintf('[sbestimatepeakloc] <<< (wresnorm0WF %g > 0.5) && ((wresnorm0QF %g <= 0.5) || (resnormQF %g <= 0.5))\n\t\t==>WFisSuperior = false\n', ...
                wresnorm0WF, wresnorm0QF, resnormQF);
            WFisSuperior = false;
            if (resnormQF > 0.5) && ~isempty(wresnorm0QF)
                resnormQF = wresnorm0QF;
            end % TODO
        else
            % disp({size(wres2QF), size(wres2WF), size(FBPM)});
            wresnormQF = 0.3*sum(wres2QF(~FBPMrow), 'all', 'omitnan') + 0.7*sum(wres2QF(FBPMrow), 'all', 'omitnan');
            wresnormWF = 0.3*sum(wres2WF(~FBPMrow), 'all', 'omitnan') + 0.7*sum(wres2WF(FBPMrow), 'all', 'omitnan');
            % disp({size(wres2QF), size(wres2WF), size(FBPMrow), size(wresnormQF), size(wresnormWF)});
            fprintf('[sbestimatepeakloc] < wresnorms: [%g, %g + %g -> %g], [%g, %g + %g -> %g]\n', ...
                sum(wres2QF, 'all'), sum(wres2QF(FBPMrow), 'all'), sum(wres2QF(~FBPMrow), 'all'), wresnormQF, ...
                sum(wres2WF, 'all'), sum(wres2WF(FBPMrow), 'all'), sum(wres2WF(~FBPMrow), 'all'), wresnormWF);
            WFisSuperior = (((p1WF(3)/p1WF(2))<=maxPkHgt) && (wresnormWF <= wresnormQF)) || ((p1QF(3) / p1QF(2)) > maxPkHgt);
            fprintf('[sbestimatepeakloc] << WFisSuperior = ((B/A <= maxPkHgt) && (%g <= %g)) || (QF exceeds maxPkHgt) = %d\n', ...
                wresnormWF, wresnormQF, WFisSuperior);
        end
    end
    % [p1, successTF, cfitBounds, sampMask, sampMask0, roiMask, resnorm, wps,ws,XDATA]
    if WFisSuperior % weighted is superior to quick
        resnorm = wresnorm0WF;
        resids = [];
        fprintf('[sbestimatepeakloc] <<< WF result is superior to QF --> resnorm=%g, cfitBounds=[%g %g], p1=[%g %g %g]\n', ...
            resnorm, 1, origDims(2), p1WF(1), p1WF(2), p1WF(3));
        p1 = p1WF; ws = wpsWF(end-1:end,:); wps = wpsWF;
        cfitBounds = [1 origDims(2)];
        predCurve = sbsense.lorentz(p1, XDATA);
        resids = YDATA0 - predCurve;
    elseif isempty(p1QF) % Both were unsuccessful (returned empty p1)
        fprintf('[sbestimatepeakloc] <<< ### Both QF and WF were UNSUCCESSFUL. ### \n');
        p1 = []; %successTF = false;
        resids = [];
        % cfitBounds = []; resnorm = NaN; wps = []; ws = [];
        % channelPeakData = [NaN NaN];
        % return;
    else % quick is superior to weighted
        fprintf('[sbestimatepeakloc] <<< QF result is superior to WF --> resnorm=%g, cfitBounds=[%g %g], p1=[%g %g %g]\n', ...
            wresnorm0QF, leftIdx, rightIdx, p1QF(1), p1QF(2), p1QF(3));
        if ~isempty(wresnorm0QF) && (isempty(resnormQF) || (resnormQF > 0.5))
            resnorm = wresnorm0QF;
        else
            resnorm = resnormQF;
        end
        cfitBounds = [leftIdx rightIdx]; % TODO: Or use PSZ??
        wps = wpsQF; ws = wsQF; p1 = p1QF;
        
        %if isempty(predCurveQF)
            predCurve = sbsense.lorentz(p1, XDATA);
            resids = YDATA0 - predCurve;
        %else
        %    predCurve = predCurveQF;
        %    resids = residsQF;
        %end
    end
    % successTF = true;
else
    fprintf('[sbestimatepeakloc] >>> No suitable guide peak could be obtained. ==> Proceeding to PART IIb (REPARATORY/UNGUIDED FITTING).\n');
    resnorm = inf;
    %fprintf('[sbestimatepeakloc] ~~~~~~ PART II (PRIMARY/PRELIMINARY FITTING) ~~~~~~\n');
    %fprintf('[sbestimatepeakloc] >>> Proceeding to PART IIb, UNGUIDED FITTING. Proceeding to PART IIb\n');
end


if resnorm >= 0.5 % No peaks found, or fitting was unsuccessful.
    fprintf('[sbestimatepeakloc] ~~~~~~ PART IIb (REPARATORY/UNGUIDED FITTING) ~~~~~~\n');
    if isfinite(resnorm)
        fprintf('[sbestimatepeakloc] >>> Performing an additional, unguided fitting since the preliminary guided fitting was unsatisfactory/unsuccessful (resnorm %g >= 0.5).\n', ...
            resnorm);
    else
        fprintf('[sbestimatepeakloc] >>> Performing an unguided fitting (since guided fitting is not possible without a guide curve).\n');
    end
    % TODO: sbsampmask??
    % successTF = false;
    cfitBounds = peakSearchZone;
    minHgt = 0.3*maxValInSmoothedProfile;
    maxHgt = min(maxPkHgt, maxValInProfile + 0.75*(maxValInProfile - maxValInSmoothedProfile) ...
        + 0.2*(maxValInSmoothedProfile - medValInSmoothedProfile));
    maxHW = wd; %double(origDims(2));
    minHW = 0.5*maxHW/double(diff(XDATA([1 end])) + 1);
    maxHW = 0.25*maxHW;
    minA = minHW*minHgt; maxA = maxHW*maxHgt;

    fitParamBounds = [peakSearchZone(1) minHW minA ; peakSearchZone(2) maxHW maxA];
    fprintf('[sbestimatepeakloc] > p0g: [%g %g %g] (hgt: %g, HW: %g)\n', ...
        p0g(1), p0g(2), p0g(3), guideHgt, guideHW);
    fprintf(['[sbestimatepeakloc] >>> CALLING lzcurvefit with arguments "p0"=p0=%s, XDATA, YDATA0, peakSearchBounds=[%g %g], peakSearchZone=[%g %g],\n' ...
        '\t\txmax, FBPM=[], preferFBM=false, fitParamBounds=[pSZ(1) eps eps ; pSZ(2) inf inf], 1, "p001"=p01=%s\n'], ...
        fdt(p0g), peakSearchBounds(1), peakSearchBounds(2), peakSearchZone(1), peakSearchZone(2), fdt(p01));
    try 
        [p1,resnorm,wps,ws] = sbsense.improc.lzcurvefit(p0g, ...
            double(XDATA(cfitBounds)), double(YDATA0(cfitBounds)), ...
            double(peakSearchBounds), double(peakSearchZone), ...
            origDims(2), [], false, ... % TODO: prefer fallback?
            fitParamBounds, 1, p01);
    catch ME0
        fprintf('[sbestimatepeakloc] Error "%s" occurred while calling lzcurvefit: %s\n', ...
            ME0.identifier, getReport(ME0));
        fprintf('[sbestimatepeakloc] Class and size of XDATA: %s, %s\n', ...
            class(XDATA), fdt(size(XDATA)));
        fprintf('[sbestimatepeakloc] Class and size of YDATA0: %s, %s\n', ...
            class(YDATA0), fdt(size(YDATA0)));
        fprintf('[sbestimatepeakloc] Class and size of p0g: %s, %s\n', ...
            class(p0g), fdt(size(p0g)));
        fprintf('[sbestimatepeakloc] Class and size of p01: %s, %s\n', ...
            class(p01), fdt(size(p01)));
        fprintf('[sbestimatepeakloc] Class and size of fitParamBounds: %s, %s\n', ...
            class(fitParamBounds), fdt(size(fitaramBounds)));
        p1 = [];
    end
    if ~isempty(p1)
        predCurve = sbsense.lorentz(p1, XDATA);
        if isempty(resnorm)
            fprintf('[sbestimatepeakloc] <<< *** Unguided fitting was SUCCESSFUL. *** (returned resnorm is empty, so resnorm value will now be calculated).\n');
            idxs = cfitBounds(1):cfitBounds(2);
            resnorm_2 = sum((YDATA0(idxs) - sbsense.lorentz(p1, idxs)), 'all', 'omitnan');
        else
            fprintf('[sbestimatepeakloc] <<< *** Unguided fitting was SUCCESSFUL ***\n');
        end

        %    p1(1), p1(2), p1(3), resnorm);
    else
        fprintf('[sbestimatepeakloc] <<< ### Unguided fitting was UNSUCCESSFUL (returned p1 is empty!). ### \n');
    end
end

% if ~isscalar(resnorm)
%     display(resnorm);
% end
successTF = ~isempty(p1) && (resnorm < 1); %<= 0.5);

% if isempty(p1) || (resnorm > 0.5)
if ~successTF && (isempty(p1) || ~guideLevel)
    fprintf('[sbestimatepeakloc] <<< ### Peak location estimation was UNSUCCESSFUL (p1 is empty: %d, resnorm %g < 1: %d, guideLevel: %d). ###\n\t\t==> Returning empties.\n', ...
        isempty(p1), resnorm, guideLevel);
    p1 = [NaN NaN NaN]; successTF = false;
    cfitBounds = [NaN NaN]; resnorm = NaN; wps = []; ws = [];
    channelPeakData = [NaN NaN];
    disp({successTF, p1, channelPeakData, peakSearchBounds, peakSearchZone, cfitBounds, resnorm, wps, ws});
    return;
elseif resnorm <= 5e-4
    channelPeakData = [p1(1) p1(3)/p1(2)];
    fprintf(['[sbestimatepeakloc] <<< *** Fitting was SUCCESSFUL and needs no additional refinement since resnorm %g <= 5e-4. ***\n', ...
        '\tp1: [%g %g %g] (height: %g, width: %g)\n'], resnorm, ...
        p1(1), p1(2), p1(3), channelPeakData(2), 2*p1(2));
    disp({successTF, p1, channelPeakData, peakSearchBounds, peakSearchZone, cfitBounds, resnorm, wps, ws});
    return;
end

fprintf('[sbestimatepeakloc] <<< *** Fitting was SUCCESSFUL but resnorm %g > 5e-4, so attempting a second-pass fitting for refinement. ***\n', ...
    resnorm);

%% Perform second fitting
fprintf('[sbestimatepeakloc] ~~~~~~ PART III (SECONDARY/FOLLOW-UP FITTING) ~~~~~~\n');
if successTF
    leftIdx2 = max(1, fix(p1(1) - 0.5*p1(2)));
    rightIdx2 = min(xmax, ceil(p1(1) + 0.5*p1(2)));
else
    leftIdx2 = max(1,fix(p1(1) - 0.6*p1(2)));
    rightIdx2 = min(xmax, ceil(p1(1) + 0.6*p1(2)));
end
peakBodyIdxs2 = leftIdx2:rightIdx2;

peakBodyMask = false(size(YDATA0));
peakRightTailMask = peakBodyMask;
peakBodyMask(peakBodyIdxs2) = true;

peakBodyProfile = YDATA0(peakBodyIdxs2);
peakLeftTailProfile = YDATA0(1:leftIdx2-1); %#ok<NASGU>


if rightIdx2 >= xmax
    peakRightTailProfile = []; %#ok<NASGU>
    peakLeftTailMask = ~peakBodyMask;
else
    peakRightTailProfile = YDATA0(rightIdx2+1:end); %#ok<NASGU>
    peakRightTailMask(rightIdx2+1:end) = true;
    peakLeftTailMask = ~(peakRightTailMask | peakBodyMask);
end

p1Hgt = p1(3)/p1(2);

if abs(mean(peakBodyProfile - predCurve(peakBodyIdxs2))) <= 0.15*p1Hgt
    fprintf(['[sbestimatepeakloc] > %g = |mean(Y0body - predbody)| <= 0.15*p1Hgt = %g\n' ...
        '\t\t==> Performing SF on peak body with guess "p0"=p1=[%g %g %g].\n'], ...
        abs(mean(peakBodyProfile - predCurve(peakBodyIdxs2))), ...
        0.15*p1Hgt, p1(1), p1(2), p1(3));
    [p1_2, resnorm_2, resids_2] = lsqcurvefit(...
        @sbsense.lorentz, p1, peakBodyIdxs2, peakBodyProfile, ...
        fitParamBounds(1,:), ... % TODO: Recalc fit param bounds??
        fitParamBounds(2,:), ...
        sbsense.LorentzFitter.OptsSlow);
    if ~isempty(p1_2)
        cfitBounds_2 = peakBodyIdxs2([1 end]);
        wps_2 = wps; ws_2 = ws;
        fprintf('[sbestimatepeakloc] <<< Second fitting (slow, peak body only) succeeded with p1_2=[%g %g %g] and resnorm_2=%g.\n', ...
            p1_2(1), p1_2(2), p1_2(3), resnorm_2);
    else
        fprintf('[sbestimatepeakloc] <<< Second fitting (slow, peak body only) was not successful.\n');
        % cfitBounds_2 = [NaN NaN];
        resids_2 = [];
        resnorm_2 = [];
    end
elseif (sum(max(0, YDATA1(peakLeftTailMask)-predCurve(peakLeftTailMask))) <= 0.03*p1Hgt) ...
        && (sum(max(0, YDATA1(peakRightTailMask)-predCurve(peakRightTailMask))) <= 0.03*p1Hgt)
    fprintf(['[sbestimatepeakloc] > (%g = sum(max(0,Y1left - predleft)) <= 0.03*p1Hgt)\n' ...
        '\t && (%g = sum(max(0,Y1right - predright)) <= 0.03*p1Hgt = %g)'
        '\t\t==> Performing SF on peak body with guess "p0"=p1=[%g %g %g].\n'], ...
        sum(max(0, YDATA1(peakLeftTailMask)-predCurve(peakLeftTailMask))), ...
        sum(max(0, YDATA1(peakRightTailMask)-predCurve(peakRightTailMask))), ...
        0.03*p1Hgt, p1(1), p1(2), p1(3));
    [p1_2, resnorm_2, resids_2] = lsqcurvefit(...
        @sbsense.lorentz, p1, XDATA, YDATA0, ...
        fitParamBounds(1,:), ... % TODO: Recalc fit param bounds??
        fitParamBounds(2,:), ...
        sbsense.LorentzFitter.OptsSlow);
    if ~isempty(p1_2)
        cfitBounds_2 = [1 xmax];
        wps_2 = wps; ws_2 = ws;
        fprintf('[sbestimatepeakloc] <<< Second fitting (slow, full profile) succeeded with p1_2=[%g %g %g] and resnorm_2=%g.\n', ...
            p1_2(1), p1_2(2), p1_2(3), resnorm_2);
    else
        fprintf('[sbestimatepeakloc] <<< Second fitting (slow, full profile) was not successful.\n');
        resids_2 = [];
        resnorm_2 = [];
    end
else
    if (resnorm < 100e-4) || (guideLevel<2) % Fit peak body only, using predCurve as new guide
        p0g_2 = p1;
        fprintf('[sbestimatepeakloc] >>> (resnorm %g < 100e-4) or (guideLevel %g < 2) ==> Using p1 as new guide [%g %g %g]\n', ...
            resnorm, guideLevel, p0g_2(1), p0g_2(2), p0g_2(3));
    else % Perform weighted fitting on peak body only, reusing old guide
        p0g_2 = p0g;
        fprintf('[sbestimatepeakloc] >>> resnorm %g >= 100e-4 ==> Reusing old guide (guide level: %d) [%g %g %g]\n', ...
            resnorm, guideLevel, p0g_2(1), p0g_2(2), p0g_2(3));
    end
    [p1_2,wres_2, p01_2,wps_2, ~,~, ~, predCurve_2, profCurve_2] ...
        = sbsense.improc.lzcurvefite([],peakBodyIdxs2,YDATA0(peakBodyIdxs2),YDATA1(peakBodyIdxs2), p0g_2); %#ok<ASGLU>
    resids_2 = wres_2;
    if ~isempty(p1_2)
        if all(isnan(wres_2))
            fprintf('[sbestimatepeakloc] <<< Second fitting (weighted) was not successful -- wres_2 is all NaN:.\n');
            disp(wres_2);
        else
            resnorm_2 = sum(wres_2.^2, 'all', 'omitnan');
            cfitBounds_2 = peakBodyIdxs2([1 end]);
            ws_2 = wps_2(end-1:end,:);
            fprintf('[sbestimatepeakloc] <<< Second fitting (weighted) succeeded with p1_2=[%g %g %g] and resnorm_2=%g.\n', ...
                p1_2(1), p1_2(2), p1_2(3), resnorm_2);
        end
    else
        fprintf('[sbestimatepeakloc] <<< Second fitting (weighted) was not successful.\n');
    end
end

% [p1, successTF, cfitBounds, sampMask, sampMask0, roiMask, resnorm, wps,ws,XDATA]
% disp({p1_2, size(resnorm_2), size(resnorm), resnorm_2, resnorm});
if ~isempty(p1_2)
    idxs = cfitBounds_2(1):cfitBounds_2(2);
    if isempty(resnorm_2)
        resnorm_2 = sum((YDATA0(idxs) - sbsense.lorentz(p1_2, idxs)).^2, 'all', 'omitnan');
    end
    if isnan(resnorm_2) || isempty(resnorm_2)
        use2 = false;
        fprintf('[sbestimatepeakloc] < resnorm_2 is NaN or empty.\n');
    else
        if (resnorm_2 <= resnorm)
            use2 = true;
            fprintf('[sbestimatepeakloc] <<< @@@ resnorm_2 (%g) <= resnorm (%g) ==> Returning p1 = p1_2 ([%g %g %g])\n', ...
                resnorm_2, resnorm, p1_2(1), p1_2(2), p1_2(3));
        elseif ~isempty(resids_2) && (resnorm_2 <= 0.05) && (resnorm_2 <= 4.2*resnorm)
            if isempty(resids)
                use2 = true;
            else
                try
                    resids1 = resids(idxs);
                    if length(resids_2) == length(idxs)
                        resids2 = resids_2; % (idxs);
                    else
                        resids2 = YDATA0(idxs) - sbsense.lorentz(p1_2, idxs);
                    end
                    countHW = ceil(2\(diff(cfitBounds_2)+1));
                    resnorm1L = sum(resids1(countHW).^2, 'all', 'omitnan');
                    resnorm2L = sum(resids2(countHW).^2, 'all', 'omitnan');
                    resnorm1R = sum(resids1(end+1-countHW).^2, 'all', 'omitnan');
                    resnorm2R = sum(resids2(end+1-countHW).^2, 'all', 'omitnan');
                    % TODO: More sophisticated comparison criteria
                    if (resnorm2L <= resnorm1L) || (resnorm2R <= resnorm1R)
                        use2 = true;
                        fprintf('[sbestimatepeakloc] <<< @@@ L/R resnorm_2 (%g, %g) <= resnorm (%g, %g) ==> Returning p1 = p1_2 ([%g %g %g])\n', ...
                            resnorm2L, resnorm2R, resnorm1L, resnorm1R, p1_2(1), p1_2(2), p1_2(3));
                    else
                        use2 = false;
                        channelPeakData = [p1(1) p1(3)/p1(2)];
                        fprintf('[sbestimatepeakloc] <<< L&R resnorm (%g, %g) < resorm_2(%g, %g) ==> @@@ Returning estimation [%g %g %g] height: %g, width: %g\n', ...
                            resnorm1L, resnorm1R, resnorm2L, resnorm2R, p1(1), p1(2), p1(3), channelPeakData(2), 2*p1(2));
                    end
                catch ME0
                    fprintf('[sbestimatepeakloc] Error "%s" occurred while calculating left and right resnorms: %s\n', ...
                        ME0.identifier, getReport(ME0));
                    use2 = false;
                    channelPeakData = [p1(1) p1(3)/p1(2)];
                    % TODO: Thresholds for resnorm and resnorm_2...?
                    fprintf('[sbestimatepeakloc] <<< Reverting to resnorm (%g) ==> @@@ Returning estimation [%g %g %g] height: %g, width: %g\n', ...
                        resnorm, p1(1), p1(2), p1(3), channelPeakData(2), 2*p1(2));
                end
            end
        else
            use2 = false;
            channelPeakData = [p1(1) p1(3)/p1(2)];
            fprintf('[sbestimatepeakloc] <<< resnorm (%g) < resorm_2(%g) ==> @@@ Returning estimation [%g %g %g] height: %g, width: %g\n', ...
                resnorm, resnorm_2, p1(1), p1(2), p1(3), channelPeakData(2), 2*p1(2));
        end
    end
    if use2 
        % TODO: What to do if they are equal?
           resnorm = resnorm_2;
           p1 = p1_2; cfitBounds = cfitBounds_2; wps = wps_2; ws = ws_2;
           successTF = true;
           channelPeakData = [p1(1) p1(3)/p1(2)];
           % disp({successTF, p1, peakSearchBounds, peakSearchZone, cfitBounds, resnorm, wps, ws});
    elseif ~isempty(p1)
        channelPeakData = [p1(1) p1(3)/p1(2)];
    else
        channelPeakData = [NaN NaN];
    end
else
    channelPeakData = [p1(1) p1(3)/p1(2)];
    fprintf('[sbestimatepeakloc] <<< (resnorm: %g) @@@ Returning estimation [%g %g %g] height: %g, width: %g\n', ...
        resnorm, p1(1), p1(2), p1(3), channelPeakData(2), 2*p1(2));
end


disp({successTF, p1, channelPeakData, peakSearchBounds, peakSearchZone, cfitBounds, resnorm, wps, ws});

end


% function txt = fdt(x)
% txt = strip(formattedDisplayText(x, 'SuppressMarkup', true)); % , 'LineSpacing', 'compact')); % , 'NumericFormat', 'shortG'));
% end

% getReport(ME, 'extended', 'hyperlinks', 'off')

