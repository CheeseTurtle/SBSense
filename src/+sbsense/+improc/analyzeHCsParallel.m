function res = analyzeHCsParallel(analyzerObj, params, peakSearchBounds,...
    isReanalysis, datapointIndex, timePos, HC1, varargin)
% 


fprintf('%s (%03u) RECEIVED HC DATA.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);

f = analyzerObj.LogFile;
% if ~isvalid
%     f = fopen("SBSense_log.txt", "a");
%     fprintf(f, '[analyzeHCsP] Warning: Logfile was not open.\n');
%end
try
    % if isa(analyzerObj.APTimer, 'timer') && (analyzerObj.APTimer.Running(2)=='n')
    if (analyzerObj.APTimer.Running(2)=='n')
        stop(analyzerObj.APTimer);
    end
catch ME
    fprintf(f, '[analyzeHcsP] Error occurred while trying to check running status of and/or stop APTimer: %s\n', ...
        getReport(ME));
end



try
    if(isReanalysis)
        fprintf(f, '[analyzeHCsP] (%1$u) Reanalyzing datapoint #%1$u.', datapointIndex);
        Y1 = im2uint16(HC1);
        peakSearchZones = varargin{1};
        peakSearchZones0 = peakSearchZones;
        % display(peakSearchZones);
    else
        fprintf(f, '[analyzeHCsP] (%u) Internal (%d args)\n', datapointIndex, nargin);
        fprintf(f, '[analyzeHCsP] (%u) timePos: %s', datapointIndex, formattedDisplayText(timePos, 'SuppressMarkup',true));

        % fprintf('%s (%03u) MAKING FULL COMPOSITE.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
        Y1 = sbsense.improc.makeFullComposite(HC1, varargin{1});
        % fprintf('%s (%03u) DONE MAKING FULL COMPOSITE.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
        peakSearchZones = [];
        % p01 = double.empty();
        peakSearchZones0 = NaN(2, params.NumChannels);
    end

    if (nargin > 8) && ~isempty(varargin{2})
        p01 = double(varargin{2});
    else
        p01 = double.empty();
    end

    fprintf(f, '[analyzeHCsP] (%u) Y0s class & size: %s, %s', ...
        datapointIndex, ...
        class(params.RefImgScaled), ...
        formattedDisplayText(size(params.RefImgScaled)));


    fprintf(f, '[analyzeHCsP] %u) Y1 class & size before crop: %s, %s', ...
        datapointIndex, class(Y1), ...
        formattedDisplayText(size(Y1)));
    Y1s = imcrop(Y1, params.CropRectangle);
    if params.AnalysisScale ~= 1
        fprintf(f, '[analyzeHCsP] (%u) Y1 class & size before resize: %s, %s', ...
            datapointIndex, class(Y1), ...
            formattedDisplayText(size(Y1)));
        fprintf(f, '[analyzeHCsP] (%u) Scaled dim: [h w] = [ %0.4g %0.4g ]\n', ...
            datapointIndex, ...
            params.ScaledEffectiveHeight, params.ScaledEffectiveWidth);
        Y1s = imresize(Y1s, ...
            [params.ScaledEffectiveHeight, params.ScaledEffectiveWidth], ...
            "lanczos3");
    end

    % TODO: Why this number of IP points?
    numIntensityProfilePoints = floor(0.5*(size(Y1, 2)-1));
    % numFitPoints = min(225, numIntensityProfilePoints);
    fprintf(f, '[analyzeHCsP] (%u) Num. IP points: %d; Y1s class & size: %s, %s', ...
        datapointIndex, ...
        numIntensityProfilePoints, class(Y1s), ...
        formattedDisplayText(size(Y1s)));

    if ~isempty(p01)
        p01s = double(p01);
    elseif ~isempty(params.ParamHistories)
        % param 1: lastp lastdp avgdp
        % param 2: ...
        % param 3: ...
        p01s = sum(double(params.ParamHistories) ...
            .* repmat(double([1 0.2 0.8]),params.NumChannels,1,params.NumChannels), ...
            2);
    else
        p01s = [];
    end

    deadMask = true(params.EffectiveHeight, params.EffectiveWidth);
    deadMask(horzcat(params.ScaledChVertIdxs{:}), :) = false;

    % fprintf('%s (%03u) CALLING ANALYZECOMPOSITEPARALLEL.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
    % [Yc, Yr, peakData, estimatedLaserIntensity, ...
    %     imgp1, imgIP, imgFP, imgcfitBounds, ...
    %     p1s, intprofs, fitprofs, cfitBoundses, ...
    %     successCode, sampMask0s, sampMasks, roiMasks] = ...
    % [estimatedLaserIntensity, futs, Yc, Yr] = ...
    [fut0, futs, estimatedLaserIntensity, Yc, Yr] = ...
        sbsense.improc.analyzeCompositeParallel(  ... % analyzerObj, ...
        params.RefImgScaled, Y1s, ... % TODO: why is it int16 instead of uint16?
        single(numIntensityProfilePoints), ...
        single(params.fdm), params.NumChannels,...
        params.ScaledChVertIdxs, ...
        params.CropRectangle, single(peakSearchBounds), single(peakSearchZones), ...
        squeeze(p01s), deadMask, f, datapointIndex);
    % fprintf('%s (%03u) DONE CALLING ANALYZECOMPOSITEPARALLEL.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);

    if isempty(futs)  % || isnan(estimatedLaserIntensity)
        fprintf(f, '[analyzeHcsP] (%u) Composite analysis was unsuccessful and no results could be obtained, since returned futs is empty.\n', ...
            datapointIndex);
        % fprintf(f, '[analyzeHCsP] (%u) Laser intensity estimation was unsuccessful and no results could be obtained (futs is empty: %d).\n', ... %, ELI is NaN: %d).\n', ...
        %     datapointIndex, isempty(futs));%, isnan(estimatedLaserIntensity));
    else
        msk = strcmp([futs.State], 'unavailable');
        if all(msk)
            fprintf(f, '[analyzeHCsP] (%u) All futs are unavailable...\n', datapointIndex);
            % display(futs);
        else
            futs(msk) = [];
            %futs = futs(~msk);
            %display(msk);
            %display(futs);
            fut = afterAll([fut0 futs(1,:)], @(fs) handleFuts(fs), 1, 'PassFuture', true);
            %fprintf(f, '[analyzeHCsP] fut: %s\n', strip(formattedDisplayText(fut)));
            futs1 = reshape([fut0 reshape(futs, 1, []) fut], 1, []);
            %fprintf(f, '[analyzeHCsP] futs1: %s\n', strip(formattedDisplayText(futs1)));

            if nargout
                try
                    analyzerObj.AnalysisFutures = futs1;
                    fprintf('%s (%03u) WAITING FOR FUTURES/RESULTS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
                    while ~wait(futs1, "finished", 0.010)
                        pause(0.050);
                    end
                    res = fetchOutputs(fut);
                    fprintf('%s (%03u) DONE WAITING FOR FUTURES/RESULTS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
                    ql = analyzerObj.FinishedQueue.QueueLength;
                    if ~ql
                        fprintf('[analyzeHCsP] (%u) FinishedQueue is unexpectedly empty!\n', datapointIndex);
                    else
                        if ql>1
                            fprintf('[analyzeHCsP] (%u) FinishedQueue is unexpectedly longer than 1 (length: %d).\n', datapointIndex, ql);
                        end
                        [x,TF] = poll(analyzerObj.FinishedQueue);
                        if ~TF
                            fprintf('[analyzeHCsP] (%u) Polling the FinishedQueue unexpectedly failed.\n', datapointIndex);
                        else
                            fprintf('[analyzeHCsP] (%u) Polled the FinishedQueue and got: %s\n', datapointIndex, strip(formattedDisplayText(x)));
                        end
                    end
                    % res = fetchOutputs(fut);
                catch ME
                    fprintf(f, '[analyzeHCsP] (%u) Error "%s" while waiting for afterAll future: %s\n', ...
                        datapointIndex, ME.identifier, getReport(ME));
                    cancel(futs1);
                    res = ME;
                    % display(futs1);
                end
            else
                fut2 = afterEach(fut, @(x) sendToResQueue(analyzerObj, datapointIndex, x), 0);
                analyzerObj.AnalysisFutures = [futs1 fut2];
            end
        end
    end



    % Y0s,Y1s, ~, origDims, numChannels, ...
    % scaledChVertIdxs, ~, peakSearchBounds, p01s, f

    % if successCode
    %      % [lastparams lastdp dpavg]
    %     if isempty(params.ParamHistories)
    %         params.ParamHistories = zeros(3,3,params.NumChannels+1);
    %         params.ParamHistories(:,:,1) = permute(imgp1, [1 3 2]);
    %         params.ParamHistories(:,:,2:end) = permute(p1s, [1 3 2]);
    %     else
    %         imgp1 = permute(imgp1, [1 3 2]);
    %         p1s = permute(p1s, [1 3 2]);
    %         params.ParamHistories(:,:,1) = cat(2, ...
    %             imgp1, imgp1 - params.ParamHistories(:,2,1), ...
    %             0.5*(params.ParamHistories(:,3,1) + params.ParamHistories(:,2,1)));
    %         params.ParamHistories(:,:,2:end) = ...
    %             cat(2, p1s, (p1s-params.ParamHistories(:,2,2:end)), ...
    %             0.5*(params.ParamHistories(:,3,2:end) + params.ParamHistories(:,2,2:end)));
    %     end
    %     params.LastPSB = peakSearchBounds;
    %     params.LastChFitProfiles = horzcat(imgFP, fitprofs);
    % end

    % %res = {datapointIndex, timePos, peakSearchBounds, ...
    % %    Y1, estimatedLaserIntensity, peakData, intprofs, p1s ...
    % %    }; % TODO: Also send back Yc?
    % if isReanalysis
    %     res = struct('ELI', estimatedLaserIntensity, ...
    %         'SuccessCode', successCode, 'PeakData', peakData, ...
    %         'IntensityProfiles', intprofs, 'EstParams', p1s, ...
    %         'CurveFitBounds', cfitBoundses, 'CompositeImage', Y1, ...
    %         'ScaledComposite', Yc, 'RatioImage', Yr, ...
    %         'FitProfiles', fitprofs);
    % else
    %     res = struct('DatapointIndex', datapointIndex+params.dpIdx0, ...
    %         'RelativeDatapointIndex', datapointIndex, ...
    %         'AbsTimePos', timePos, 'PeakSearchBounds', ...
    %         peakSearchBounds, 'ELI', estimatedLaserIntensity, ...
    %         'SuccessCode', successCode, 'PeakData', peakData, ...
    %         'IntensityProfiles', intprofs, 'EstParams', p1s, ...
    %         'CurveFitBounds', cfitBoundses, 'FitProfiles', fitprofs, ...
    %         'CompositeImage', Y1, 'ScaledComposite', Yc, ...
    %         'RatioImage', Yr);
    % end
    % % res.('FitProfiles') = fitprofs;
    % res.('ROIMasks') = roiMasks;
    % res.('SampMask0s') = sampMask0s;
    % res.('SampMasks') = sampMasks;
    % fprintf(f,'[analyzeHCsP] \tMade res:\n');
    % fprintf(f,'[analyzeHCsP] \t%s\n', formattedDisplayText(res, 'SuppressMarkup', true));
catch ERR
    % %fprintf(f, '[analyzeHCsP]  < ERR: %s > ', formattedDisplayText(ERR, 'SuppressMarkup',true));
    % %fprintf(f, '[analyzeHCsP] < ERR.message: %s > ', formattedDisplayText(ERR.message, 'SuppressMarkup', true));
    % try
    %     %stk = ERR.stack;
    %     %fprintf(f, '[analyzeHCsP] < Cause: %s >\n', formattedDisplayText(ERR.cause));
    %     %fprintf(f, '[analyzeHCsP] < Stack: %s >\n', formattedDisplayText(struct2cell(ERR.stk)));
    %     fprintf(f, '[analyzeHCsP] < Report: %s >\n', getReport(ERR,'extended','hyperlinks','off'));
    %     %fprintf(f, '[analyzeHCsP] << file: %s; name: %s; line: %d >>\n', ...
    %     %    stk.file, ...
    %     %    stk.name, stk.line);
    % catch ERR2
    %     fprintf(f,'[analyzeHCsP] Error occurred while writing error stack to file: %s', ...
    %         formattedDisplayText(ERR2, 'SuppressMarkup', true));
    % end
    fprintf(f, '[analyzeHCsP] (%u) Error occurred during analysis: %s\n',  ...
        datapointIndex, getReport(ERR,'extended','hyperlinks','off'));
    % fclose(f);
    res = ERR;
    %rethrow(ERR);
    %res = {datapointIndex, timePos, [], ...
    %    NaN, NaN(1,2,params.NumChannels), ...
    %    makeIPcellrow(params.CropRectangle), ... % TODO: Store blank template row in props
    %    NaN(1, numIntensityProfilePoints, params.NumChannels), [NaN NaN NaN]};
    %res = {isReanalysis, false, datapointIndex, timePos, ...
    %    [], [], [], [], []};
end

    function res = handleFuts(fs)
        % fprintf('%s (%03u) HANDLEFUTS RECEIVED FUTS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
        % channelPeakData,p1,channelIP,channelFP,cfitBounds,sampMask0,sampMask,roiMask
        % msk = arrayfun(@(f) isempty(f.Error), fs);
        % if all(msk)
        %     successCode = all(arrayfun(@(f) f.OutputArguments{1}, fs));
        %     peakData = arrayfun(@(f) f.OutputArguments{2}, fs, 'UniformOutput', false);
        %     peakData = vertcat(peakData{:});
        %     peakData = arrayfun(@(f) f.OutputArguments{3}, fs, 'UniformOutput', false);
        %     peakData = vertcat(peakData{:});
        % else
        %     successCode = false;
        % end
        f = 1; % TODO: Why??

        if length(fs)>params.NumChannels
            try
                if isempty(fs(1).Error)
                    [estimatedLaserIntensity, successTF, Yc, Yr] = fs(1).OutputArguments{:};
                    if ~successTF
                        fprintf(f, '[analyzeHCsP/handleFuts]::%u Laser intensity estimation was unsuccessful. (size of Yc: [%d %d], size of Yr: [%d %d])\n', datapointIndex, ...
                            size(Yc, 1), size(Yc, 2), size(Yr, 1), size(Yr, 2));
                    end
                    fs(1) = parallel.Future.empty();
                else
                    fprintf(f,'[analyzeHCsP/handleFuts]::%u Error reported while estimating laser intensity: %s\n', datapointIndex,  getReport(fs(1).Error));
                    res = fs(1).Error;
                    return;
                end
            catch ME
                fprintf(f, '[analyzeHCsP/handleFuts]::%u Error "%s" encountered while retrieving results of laser intensity estimation Future: %s\n', ...
                    datapointIndex, ME.identifier, getReport(ME));
                res = ME;
                return;
            end
        end

        % TODO: different number of IP points?
        numIPpoints = params.fdm(2);

        successCode = 0;
        peakData = NaN(2,params.NumChannels); p1s = NaN(3,params.NumChannels);
        intprofs = NaN(numIPpoints, params.NumChannels);
        fitprofs = NaN(numIPpoints, params.NumChannels);
        cfitBoundses = NaN(2, params.NumChannels);
        sampMask0s = cell(1,params.NumChannels); sampMask0s(:) = {logical.empty()};
        sampMasks = sampMask0s; roiMasks = sampMasks;
        resids = NaN(1,params.NumChannels);

        wps = cell(1,params.NumChannels);
        ws = cell(1,params.NumChannels);
        xdatas = cell(1,params.NumChannels);

        

        for i=1:params.NumChannels
            try
                if isempty(fs(i).Error)
                    %if successCode
                    successCode = successCode + logical(futs(i).OutputArguments{1});
                    %end
                    % fprintf(f, '[analyzeHCsP/handleFuts]::%u.%u Number of output arguments: %d\n', ...
                    %     datapointIndex, i, numel(futs(i).OutputArguments));
                    % fprintf(f, '\t>> Output arguments: %s\n', strip(formattedDisplayText(futs(i).OutputArguments)));
                    if numel(futs(i).OutputArguments) ~= 13
                        fprintf(f, '[analyzeHCsP/handleFuts]::%u.%u Invalid output argument quantity (not 13). Arguments: %s\n', ...
                            datapointIndex, i, ...
                            strip(formattedDisplayText(futs(i).OutputArguments)));
                        % res = futs(i).OutputArguments;
                        %successCode = 0;
                        %continue; %return;
                    elseif futs(i).OutputArguments{1} % successCode
                        % channelPeakData, channelIP, p1, successTF2a, cfitBounds, sampMask, sampMask0, roiMask, resnorm,...
                        % wps,ws,XDATA
                        % {channelPeakData, p1, channelIP, channelFP, cfitBounds, ...
                        % sampMask0, sampMask, roiMask, resnorm, wps,ws,XDATA}
                        try
                            [peakData(:,i), p1s(:,i), intprofs(:,i), ...
                                fitprofs(:,i), cfitBoundses(:,i), sampMask0s{i}, ...
                                sampMasks{i}, roiMasks{i}, resids(i), wps{i}, ...
                                ws{i}, xdatas{i}] = futs(i).OutputArguments{2:end};
                        catch
                            peakData(:,i) = futs(i).OutputArguments{2};
                            p1s(:,i) = futs(i).OutputArguments{3};
                            intprofs(:,i) = futs(i).OutputArguments{4};
                            fitprofs(:,i) = futs(i).OutputArguments{5};
                            cfitBoundses(:,i) = futs(i).OutputArguments{6};
                            sampMask0s{i} = futs(i).OutputArguments{7};
                            sampMasks{i} = futs(i).OutputArguments{8};
                            roiMasks{i} = futs(i).OutputArguments{9};
                            resids(i) = futs(i).OutputArguments{10};
                            wps{i} = futs(i).OutputArguments{11};
                            ws{i} = futs(i).OutputArguments{12};
                            xdatas{i} = futs(i).OutputArguments{13};
                        end
                    else
                        fprintf(f,'[analyzeHCsP/handleFuts]::%1$u.%2$u Warning: Unexpectedly zero successCode for channel %$2u.\n', datapointIndex, i);
                    end
                else
                    fprintf(f,'[analyzeHCsP/handleFuts]::%1$u.%2$u Error reported while analyzing Channel %2$u: %3$s\n', datapointIndex, i, getReport(fs(i).Error));
                    %successCode = false;
                end
            catch ME
                fprintf(f, '[analyzeHCsP/handleFuts]::%1$u.%2$u Error while processing Channel %2$u analysis results: %3$s\n', datapointIndex, i, getReport(ME));
                %successCode = false;
            end
        end

        % fprintf('%s (%03u) HANDLEFUTS: CREATING STRUCT.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);

        if isReanalysis
            res = struct('ELI', estimatedLaserIntensity, ...
                'SuccessCode', successCode, 'PeakData', peakData, ...
                'IntensityProfiles', intprofs, 'EstParams', p1s, ...
                'CurveFitBounds', cfitBoundses, 'CompositeImage', Y1, ...
                'PeakSearchZones', peakSearchZones0, ...
                'ScaledComposite', Yc, 'RatioImage', Yr, ...
                'ResNorms', resids, 'PeakSearchBounds', ...
                peakSearchBounds, 'FitProfiles', fitprofs, 'DeadMask', deadMask);
            % TODO: peakSearchBounds unnecessary?
        else
            % fprintf('[analyzeHCsP] peakSearchZones0:\n');
            % display(peakSearchZones0);
            res = struct('DatapointIndex', datapointIndex+params.dpIdx0, ...
                'RelativeDatapointIndex', datapointIndex, ...
                'AbsTimePos', timePos, 'PeakSearchBounds', ...
                peakSearchBounds, 'ELI', estimatedLaserIntensity, ...
                'ResNorms', resids, ...
                'SuccessCode', successCode, 'PeakData', peakData, ...
                'IntensityProfiles', intprofs, 'EstParams', p1s, ...
                'CurveFitBounds', cfitBoundses, 'FitProfiles', fitprofs, ...
                'PeakSearchZones', peakSearchZones0, ...
                'CompositeImage', Y1, 'ScaledComposite', Yc, ...
                'RatioImage', Yr, 'DeadMask', deadMask);
        end
        try
            % res.('FitProfiles') = fitprofs;
            res.('ChannelWgts') = ws;
            res.('ChannelXData') = xdatas;
            res.('ChannelWPs') = wps;
            res.('ROIMasks') = roiMasks;
            res.('SampMask0s') = sampMask0s;
            res.('SampMasks') = sampMasks;
        catch ME
            fprintf(f, '[analyzeHCsP/handleFuts] (%u) Error "%s" occurred while assigning mask fields: %s\n', datapointIndex, ME.identifier, getReport(ME));
            fprintf(f, '[analyzeHCsP/handleFuts] (%u) res @ error:\n%s\n', datapointIndex, strip(formattedDisplayText(res)));
            %rethrow(ME);
            res = ME;
            return;
        end
        % fprintf('%s (%03u) HANDLEFUTS: END OF FUNCTION.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
        % fprintf(f,'[analyzeHCsP/handleFuts] (%u) \tMade res:\n%s\n', ...
        %     datapointIndex, strip(formattedDisplayText(res, 'SuppressMarkup', true)));
    end

% fclose(f);
end

function sendToResQueue(analyzerObj, datapointIndex, res)
fprintf('%s (%03u) SENDTORESQUEUE RECEIVED DATA (HCQueue: %d, APQueue: %d, APQueue2: %d, ResQueue: %d).\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
    datapointIndex, ...
    analyzerObj.HCQueue.QueueLength, analyzerObj.APQueue.QueueLength, analyzerObj.APQueue2.QueueLength, analyzerObj.ResQueue.QueueLength);
try
    [x,TF] = poll(analyzerObj.FinishedQueue);
    if ~TF
        fprintf('[sendToResQueue] Polling the FinishedQueue unexpectedly failed (queue length: %d).\n',analyzerObj.FinishedQueue.QueueLength);
    else
        fprintf('[sendToResQueue] Polled the FinishedQueue and got: %s\n', strip(formattedDisplayText(x)));
    end
catch ME
    fprintf('[sendToResQueue] Error "%s" occurred when attempting to poll the FinishedQueue: %s\n', ...
        ME.identifier, getReport(ME));
end
try
    send(analyzerObj.ResQueue,res);
    if isstruct(res) && isfield(res, 'SuccessCode') && res.SuccessCode
        analyzerObj.LastParams = res.EstParams;
    end
catch ME
    fprintf('[sendToResQueue] Error "%s" prevented sending to ResQueue and/or storage of estimate parameters: %s\n', ...
        ME.identifier, getReport(ME));
end
if ~isequal(analyzerObj.APTimer.UserData,true)
    if  (analyzerObj.APTimer.Running(2) == 'f')
        start(analyzerObj.APTimer);
        fprintf('%s (%03u) SENDTORESQUEUE: END OF FUNCTION (AFTER STARTING APTIMER).\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
    else
        fprintf('%s (%03u) SENDTORESQUEUE: END OF FUNCTION (APTIMER ALREADY RUNNING).\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), datapointIndex);
    end
end
end