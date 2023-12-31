function res = analyzeHCs(params, peakSearchBounds, ...
    isReanalysis, datapointIndex, timePos, HC1, varargin)
    f = fopen("SBSense_log.txt", "a");
    try
        if(isReanalysis)
            Y1 = im2uint16(HC1);
        else
            fprintf(f, '[analyzeHCs] Internal (%d args)\n', nargin);
            fprintf(f, '[analyzeHCs] timePos: %s', formattedDisplayText(timePos, 'SuppressMarkup',true));
            Y1 = sbsense.improc.makeFullComposite(HC1, varargin{1});
        end

        fprintf(f, '[analyzeHCs] Y0s class & size: %s, %s', ...
            class(params.RefImgScaled), ...
            formattedDisplayText(size(params.RefImgScaled)));


        fprintf(f, '[analyzeHCs] Y1 class & size before crop: %s, %s', ...
            class(Y1), ...
            formattedDisplayText(size(Y1)));
        Y1s = imcrop(Y1, params.CropRectangle);
        if params.AnalysisScale ~= 1
            fprintf(f, '[analyzeHCs] Y1 class & size before resize: %s, %s', ...
                class(Y1), ...
                formattedDisplayText(size(Y1)));
            fprintf(f, '[analyzeHCs] Scaled dim: [h w] = [ %0.4g %0.4g ]\n', ...
                params.ScaledEffectiveHeight, params.ScaledEffectiveWidth);
            Y1s = imresize(Y1s, ...
                [params.ScaledEffectiveHeight, params.ScaledEffectiveWidth], ...
                 "lanczos3");
        end

        % TODO: Why this number of IP points?
        numIntensityProfilePoints = floor(0.5*(size(Y1, 2)-1));
        % numFitPoints = min(225, numIntensityProfilePoints);
        fprintf(f, '[analyzeHCs] Num. IP points: %d; Y1s class & size: %s, %s', ...
            numIntensityProfilePoints, class(Y1s), ...
            formattedDisplayText(size(Y1s)));

        % peakSearchBounds = horzIdxs([1 end])+[-1 1];
        % horzIdxs = (peakSearchBounds(1)+1):(peakSearchBounds(2)-1);

        [Yc, Yr, peakData, estimatedLaserIntensity, ...
            p1s, intprofs, fitprofs, cfitBoundses, ...
            successCode, sampMask0s, sampMasks, roiMasks] = ...
        sbsense.improc.analyzeComposite(params.RefImgScaled, Y1s, ...
            numIntensityProfilePoints, ...
            params.fdm, params.NumChannels,...
            params.ScaledChVertIdxs, ...
            params.CropRectangle, peakSearchBounds, f);

        %res = {datapointIndex, timePos, peakSearchBounds, ...
        %    Y1, estimatedLaserIntensity, peakData, intprofs, p1s ...
        %    }; % TODO: Also send back Yc?
        if isReanalysis
            res = struct('ELI', estimatedLaserIntensity, ...
                'SuccessCode', successCode, 'PeakData', peakData, ...
                'IntensityProfiles', intprofs, 'EstParams', p1s, ...
                'CurveFitBounds', cfitBoundses, 'CompositeImage', Y1, ...
                'ScaledComposite', Yc, 'RatioImage', Yr, ...
                'FitProfiles', fitprofs);
        else
            res = struct('DatapointIndex', datapointIndex+params.dpIdx0, ...
                'RelativeDatapointIndex', datapointIndex, ...
                'AbsTimePos', timePos, 'PeakSearchBounds', ...
                peakSearchBounds, 'ELI', estimatedLaserIntensity, ...
                'SuccessCode', successCode, 'PeakData', peakData, ...
                'IntensityProfiles', intprofs, 'EstParams', p1s, ...
                'CurveFitBounds', cfitBoundses, 'FitProfiles', fitprofs, ...
                'CompositeImage', Y1, 'ScaledComposite', Yc, ...
                'RatioImage', Yr);
        end
        % res.('FitProfiles') = fitprofs;
        res.('ROIMasks') = roiMasks;
        res.('SampMask0s') = sampMask0s;
        res.('SampMasks') = sampMasks;
        fprintf(f,'[analyzeHCs] \tMade res:\n');
        fprintf(f,'[analyzeHCs] \t%s\n', formattedDisplayText(res, 'SuppressMarkup', true));
    catch ERR
        fprintf(f, '[analyzeHCs] < ERR: %s > ', formattedDisplayText(ERR, 'SuppressMarkup',true));
        fprintf(f, '[analyzeHCs] < ERR.message: %s > ', formattedDisplayText(ERR.message, 'SuppressMarkup', true));
        try
            %stk = ERR.stack;
            %fprintf(f, '[analyzeHCs] < Cause: %s >\n', formattedDisplayText(ERR.cause));
            %fprintf(f, '[analyzeHCs] < Stack: %s >\n', formattedDisplayText(struct2cell(ERR.stk)));
            fprintf(f, '[analyzeHCs] < Report: %s >\n', getReport(ERR,'extended','hyperlinks','off'));
            %fprintf(f, '[analyzeHCs] << file: %s; name: %s; line: %d >>\n', ...
            %    stk.file, ...
            %    stk.name, stk.line);
        catch ERR2
            fprintf(f,'[analyzeHCs] Error occurred while writing error stack to file: %s', ...
                formattedDisplayText(ERR2, 'SuppressMarkup', true));
        end
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
    fclose(f);
end