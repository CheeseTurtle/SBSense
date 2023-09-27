% function [Yc, Yr, peakData, estimatedLaserIntensity, ...
%     imgp1, imgIP, imgFP, imgcfitBounds, ...
%     p1s, intprofs, fitprofs, cfitBoundses, ...
%     successCode, sampMasks, sampMask0s, roiMasks] = analyzeCompositeParallel(...
function [fut0, futs, estimatedLaserIntensity, Yc, Yr] ... %[estimatedLaserIntensity, fut0, futs] ...% , Yc,Yr]...
     = analyzeCompositeParallel( ...
    Y0s,Y1s, ~, origDims, numChannels, ...
    scaledChVertIdxs, ~, peakSearchBounds, peakSearchZones, p01s, deadMask, f, varargin)

persistent bgPool;
if isempty(bgPool)
    bgPool = backgroundPool();
end

if nargin < 13
    datapointIndex = 0;
else
    datapointIndex = varargin{1};
end

try
    fprintf(f,'[analyzeCompositeP] (%u) Size of Y0s: %s\n', datapointIndex, strrep(strip(formattedDisplayText(size(Y0s))), '  ', ' '));
catch ME2
    fprintf(f,'[analyzeCompositeP] Error when printing: %s\n', getReport(ME2));
end
try
    fprintf(f,'[analyzeCompositeP] (%u) Size of Y1s: %s\n', datapointIndex, strrep(strip(formattedDisplayText(size(Y1s))), '  ', ' '));
catch ME2
    fprintf(f,'[analyzeCompositeP] Error when printing: %s\n', getReport(ME2));
end
try
    fprintf(f,'[analyzeCompositeP] (%u) numChannels: %d\n', datapointIndex, numChannels);
catch ME2
    fprintf(f,'[analyzeCompositeP] Error when printing: %s\n', getReport(ME2));
end

%sampMask0s = cell(1,numChannels); sampMask0s(:) = {logical.empty()};
%sampMasks = sampMask0s; roiMasks = sampMasks;


% % fprintf('%s (%03u) ESTIMATING LASER INTENSITY.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
% % [estimatedLaserIntensity, successTF, Yc, Yr] ...%, sampMask, sampMask0, roiMask] ...
% %    = sbsense.improc.sbestimatelaserintensity(Y0s, Y1s, peakSearchBounds, deadMask, f); % analyzerObj.AnalysisParams.DeadMask, f);
% fprintf('%s (%03u) SPAWNING LASER INTENSITY ESTIMATION FUTURE.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
% fut0 = parfeval(backgroundPool, @sbsense.improc.sbestimatelaserintensity, 4, ...
%     Y0s, Y1s, peakSearchBounds, deadMask, f); % analyzerObj.AnalysisParams.DeadMask, f);)
% fprintf('%s (%03u) DONE SPAWNING LASER INTENSITY ESTIMATION FUTURE.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
% % sampMask0s{1,1} = sampMask0; sampMasks{1,1} = sampMask; roiMasks{1,1} = roiMask;
% % fprintf('%s (%03u) DONE ESTIMATING LASER INTENSITY.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);

fut0 = parallel.Future.empty();

% Y0 = im2double(Y0s); Y1 = im2double(Y1s);
% Yr = Y1./Y0;

Y0 = im2uint16(Y0s); Y1 = im2uint16(Y1s);
Y0(Y0==0) = 1;
Yr = im2single(imdivide(Y1,Y0));

if any(deadMask)
    estimatedLaserIntensity = mean(Yr(deadMask), 'all', 'omitnan'); %mean(Yr(~sampMask), "all");
else
    % estimatedLaserIntensity = sbestimatelaserintensity % TODO
    estimatedLaserIntensity = mean(Yr, 'all', 'omitnan');
end

if estimatedLaserIntensity == 0
    estimatedLaserIntensity = realmin('single');
end

fprintf(f, '[analyzeCompositeP]::%u Class of Y0s,Y1s,Y0,Y1,Yr, ELI: %s,%s,%s,%s,%s, %s\n', ...
    class(Y0s), class(Y1s), class(Y0), class(Y1), class(Yr), class(estimatedLaserIntensity));
Yc = imcomplement(Yr ./ estimatedLaserIntensity);

% Yc0 = Yr./estimatedLaserIntensity;
% Yc = 1.0 - Yc0;

% TODO: Shouldn't offset be added BEFORE estimating laser intensity???
% display(peakSearchZones);
peakSearchBounds = single(peakSearchBounds) + single([1 -1]); % TODO: Eliminate need for offset

% peakSearchBounds(1) = peakSearchBounds(1) + 1;
% peakSearchBounds(2) = peakSearchBounds(2) - 1;


if isempty(peakSearchZones)
    peakSearchZones = zeros(2, numChannels, 'single');
end


% if ~successTF
%     fprintf(f, '[analyzeCompositeP] (%u) Estimation of laser intensity was unsuccessful. Returning without performing further analysis.\n', datapointIndex);
%     % successCode = false;
%     futs = parallel.Future.empty(); Yc = []; Yr = [];
%     estimatedLaserIntensity = NaN;
%     % peakLocs = NaN(1,numChannels);
%     % resids = peakLocs;
%     return;
% end

% TODO: different number of IP points???
% What is the class of origDims?
numIPpoints = origDims(2); %2*numHalfIPpoints + 1;
% numIPpoints = length(peakSearchZone);

futs = parallel.Future.empty(2,0); % numChannels);%+1);
for chNum=1:numChannels
    if isempty(p01s)
        p01 = single.empty(); % [NaN ; NaN ; NaN]; % TODO?
    else
        p01 = single(p01s(:,chNum));
        if isempty(p01)
            fprintf(f, '[analyzeCompositeP]::%u/ch%u : No guess parameters supplied.\n', ...
                datapointIndex, chNum);
        elseif size(p01,1)==3
            fprintf(f, '[analyzeCompositeP]::%u/ch%u : Using supplied params "[%g %g %g]" as guess.\n', ...
                datapointIndex, chNum, p01(1,1), p01(2,1), p01(3,1));
        else
            fprintf(f, '[analyzeCompositeP]::%u/ch%u : Using supplied params "%s" as guess.\n', ...
                datapointIndex, chNum, fdt(p01'));
        end
    end
    %Y0c = Y0s(scaledChVertIdxs{chNum}, :);
    %Y1c = Y1s(scaledChVertIdxs{chNum}, :);
    %Ycc = Yc(scaledChVertIdxs{chNum}, :);
    
    
    % if all(~logical(peakSearchZones(:,chNum))) || anynan(peakSearchZones(:,chNum))
    %     peakSearchZones(:,chNum) = double([1 ; origDims(2)]);
    % end
    % % display(peakSearchZones);
    fprintf(f, '[analyzeCompositeP]::ch%u : Effective PSZ: %s.\n', ...
            chNum, strip(formattedDisplayText(peakSearchZones(:,min(size(peakSearchZones,2),chNum))')));
    
    futs(1,chNum) = parfeval(bgPool, ...
        @analyzeCompositeChannel, 13, ...
        ... % [NaN ; NaN], [NaN ; NaN ; NaN], ...
        ... % intprofs(:,chNum), fitprofs(:,chNum), ...
        numIPpoints, p01, ... % [NaN ; NaN], ...
        chNum, origDims, peakSearchBounds, ...%peakSearchBounds + [1 -1], ...
        peakSearchZones(:,min(size(peakSearchZones(2), chNum))), ...
        Y0s(scaledChVertIdxs{chNum}, :), ...
        Y1s(scaledChVertIdxs{chNum}, :), ...
        Yc(scaledChVertIdxs{chNum}, :), ...
        1, ...
        sprintf('::%u/%u', datapointIndex, chNum) ...
        );
    futs(2,chNum) = afterEach(futs(1,chNum), ...
        @(fut) printDiaryToFile(fut, chNum), 0, 'PassFuture', true);
    %futs(2,chNum) = afterEach(futs(1,chNum), ...
    %    @(fut) handleChAnalysisResults(chNum, fut), ...
    %    1);
end

futs = futs(1,:); % TODO?
% fprintf('%s (%03u) DONE SPAWNING FUTURES.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);

    function printDiaryToFile(fut, chNum)
        if isprop(fut, 'Diary')
            if isempty(fut.Diary)
                fprintf(f, '[analyzeCompositeP/printDiaryToFile] (%1$u) DIARY OF FUTURE %2$d (chNum %3$u) IS EMPTY.\n', datapointIndex, fut.ID, chNum);
            else
                try
                    fprintf(f, ['vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n' ...
                        '[analyzeCompositeP/printDiaryToFile] (%1$u) DIARY OF FUTURE %2$d (chNum %3$u):\n%4$s\n' ...
                        '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n'], ...
                        datapointIndex, fut.ID, chNum, strip(formattedDisplayText(fut.Diary, 'SuppressMarkup', true, 'LineSpacing', 'compact')));
                catch ME2
                    try
                        fprintf(f,'[analyzeCompositeP/printDiaryToFile] Error when printing: %s\n', getReport(ME2));
                    catch ME1
                        fprintf('[analyzeCompositeP/printDiaryToFile] Error when printing: %s\n', getReport(ME1));
                    end
                end
                % fprintf(f, formattedDisplayText(fut.Diary, 'SuppressMarkup', true, 'LineSpacing', 'compact'));
            end
        elseif isprop(fut, 'ID')
            fprintf(f, '[analyzeCompositeP/printDiaryToFile] (%u) Future %d (chNum %d) has no property "Diary".\n', datapointIndex, fut.ID, chNum);
        else
            fprintf(f, '[analyzeCompositeP/printDiaryToFile] (%u) Future for chNum %u has no property "ID" (and also no property "Diary").\n', datapointIndex, chNum);
        end
    end

% futs(:,numChannels+1) = afterAll()

% try
%     analyzerObj.AnalysisFutures = futs;
% %    wait(futs);
% %    % successTFs = fetchOutputs(futs(2,:));
% %    successTF2 = all(arrayfun(@(f) f.OutputArguments{1}, futs(2,:)));
% catch ME
% %    fprintf(f, 'Error "%s" occurred while waiting for futures / fetching outputs: %s\n', ME.identifier, getReport(ME));
%     fprintf(f, 'Error "%s" occurred while assigning futs to property: %s\n', ME.identifier, getReport(ME));
%     % successTF2 = false;
% end



% fprintf(f, '[analyzeCompositeP] peakData:\n%s', formattedDisplayText(peakData));
% successCode = successTF + successTF2; %uint8(successTF + successTF2);
% fprintf(f, '[analyzeCompositeP] sC = %d = %d + %d = sTF + sTF2\n', ...
%     successCode, successTF, successTF2);

% function successTF = handleChAnalysisResults(chNum,fut)
%     try
%         if isempty(fut.Error)
%             successTF = fut.OutputArguments{1};
%             if successTF
%                 [   peakData([1 2], chNum), ....
%                     p1s([1 2 3], chNum), ...
%                     intprofs(:, chNum), ...
%                     fitprofs(:, chNum), ...
%                     cfitBoundses(:, chNum) ...
%                 ] = fut.OutputArguments{2:6};
%                 fprintf(f, '[analyzeCompositeP] Size of intprofs(:,chNum): %s', formattedDisplayText(size(intprofs(:,chNum))));
%                 fprintf(f, '[analyzeCompositeP] Size of channelIP: %s', formattedDisplayText(size(fut.OutputArguments{4})));
%                 try
%                     sampMask0s{1,chNum+1} = fut.OutputArguments{7};
%                     sampMasks{1,chNum+1} = fut.OutputArguments{8};
%                     roiMasks{1,chNum+1} = fut.OutputArguments{9};
%                 catch ME
%                     fprintf(f, '[analyzeComposite] Error "%s" occurred while storing masks for channel %d: %s\n', ...
%                         ME.identifier, chNum, getReport(ME));
%                 end
%             end
%         else
%             rethrow(fut.Error);
%         end
%     catch ME
%         fprintf(f, '[analyzeCompositeP] Error "%s" occurred while analyzing channel %d and/or storing its analysis results: %s\n', ...
%             ME.identifier, chNum, getReport(ME));
%         successTF = false;
%     end
% end
end

function [successTF2a,varargout] = ... %channelPeakData,p1,channelIP,channelFP,cfitBounds,sampMask0,sampMask,roiMask, resids] = ...
    analyzeCompositeChannel(...%~,~,~,~,~, ... %channelPeakData,p1,channelIP,channelFP,cfitBounds, ...
    numIPpoints, p01, chNum,origDims,peakSearchBounds,peakSearchZone,Y0c,Y1c,Ycc,f,chanNumStr)
% TODO: Try/catch??? -- be sure to fill cell with NaNs
%     peakInfo,intensityProfile, ...
% p1, successTF, cfitBounds, sampMask, sampMask0, roiMask
% sampMask0 = []; sampMask = []; roiMask = []; % TODO: varargout in case some of the masks etc are not assigned?
fprintf(f, '[analyzeCompositeChannel]%s PSB class: %s, PSZ class: %s\n', chanNumStr, class(peakSearchBounds), class(peakSearchZone));
peakSearchBounds = [ max(peakSearchBounds(1), peakSearchZone(1)), ...
    min(peakSearchBounds(2), peakSearchZone(2)) ];
fprintf(f, '[analyzeCompositeChannel]%s NaN count Y0c: %d/%d, Y1c: %d/%d, Ycc: %d/%d\n', ...
    chanNumStr, sum(isnan(Y0c), 'all'), numel(Y0c), sum(isnan(Y1c), 'all'), numel(Y1c), ...
    sum(isnan(Ycc),'all'), numel(Ycc));

if ~isempty(p01) && ~any(isnan(p01))
    [channelPeakData, channelIP, p1, successTF2a, cfitBounds, sampMask, sampMask0, roiMask, resnorm, ...
        wps,ws,XDATA] ...
        = sbsense.improc.sbestimatepeakloc(Y0c,Y1c,Ycc, ...
        origDims, peakSearchBounds, peakSearchZone, f, p01);
else
    [channelPeakData, channelIP, p1, successTF2a, cfitBounds, sampMask, sampMask0, roiMask, resnorm,...
        wps,ws,XDATA] ...
        = sbsense.improc.sbestimatepeakloc(Y0c,Y1c,Ycc, ...
        origDims, peakSearchBounds, peakSearchZone, f);
end

fprintf(f, '[analyzeCompositeChannel]%s NaN count XDATA: %d/%d, channelIP: %d/%d\n', ...
    chanNumStr, sum(isnan(XDATA), 'all'), numel(XDATA), sum(isnan(channelIP), 'all'), numel(channelIP));

if successTF2a
    fprintf(f, '[analyzeCompositeChannel]%s Peak location estimation for Ch. %d was successful.\n', chanNumStr, chNum);
    channelFP = sbsense.lorentz(p1, 1:numIPpoints);
    varargout = {channelPeakData, p1, channelIP, channelFP, cfitBounds, ...
        sampMask0, sampMask, roiMask, resnorm, wps,ws,XDATA};
    % peakData([1 2],chNum) = channelPeakData; %'; % Unnecessary?
    % p1s([1 2 3],chNum) = p1;%'; % Unnecessary?
    % intprofs(:,chNum) = channelIP;
    % fitprofs(:,chNum) = sbsense.lorentz(p1, fitXs); % TODO: Don't recalculate for each?
    % cfitBoundses(:,chNum) = cfitBounds;
    % fprintf(f, '[analyzeComposite] Size of intprofs(:,chNum): %s', formattedDisplayText(size(intprofs(:,chNum))));
    % fprintf(f, '[analyzeComposite] Size of channelIP: %s', formattedDisplayText(size(channelIP)));
else %if successTF2
    fprintf(f, '[analyzeCompositeChannel]%s WARNING: Peak location estimation for Ch. %d was unsuccessful.\n', chanNumStr, chNum);
    varargout = {[NaN NaN],[NaN NaN NaN],[],[],[NaN NaN],[],[],[], NaN, [], [],[]}; % TODO: Unnecessary?
    % successTF2 = false;
end

end