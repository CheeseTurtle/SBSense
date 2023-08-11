function [Yc, Yr, peakData, estimatedLaserIntensity, ...
    p1s, intprofs, fitprofs, cfitBoundses, ...
    successCode, sampMasks, sampMask0s, roiMasks] = analyzeComposite(...
    Y0s,Y1s, ~, origDims, numChannels, ...
    scaledChVertIdxs, ~, peakSearchBounds, f)
    fprintf(f,'[analyzeComposite] Size of Y0s: %s', formattedDisplayText(size(Y0s)));
    fprintf(f,'[analyzeComposite] Size of Y1s: %s', formattedDisplayText(size(Y1s)));
    fprintf(f,'[analyzeComposite] numChannels: %d\n', numChannels);

    % TODO: Fallback masks / guide parameters based on whole image
    %       -- use during individual channel analysis

    sampMask0s = cell(1,numChannels+1); sampMask0s(:) = {logical.empty()};
    sampMasks = sampMask0s; roiMasks = sampMasks;

    [estimatedLaserIntensity, successTF, Yc, Yr, sampMask, sampMask0, roiMask, imgCentroid] ...
        = sbsense.improc.sbestimatelaserintensity(Y0s, Y1s, peakSearchBounds, f);
    sampMask0s{1,1} = sampMask0; sampMasks{1,1} = sampMask; roiMasks{1,1} = roiMask;

    [imgPeakData, imgIP, imgp1, successTF2img, imgcfitBounds] ...
        = sbsense.improc.sbestimatepeakloc(Y0s,Y1s,Yc, origDims, ...
            peakSearchBounds, f, [], {sampMask, sampMask0, roiMask, imgCentroid});
    if successTF2img
        p01 = imgp1;
    else
        p01 = [];
    end
    
    peakData = NaN(2,numChannels); p1s = NaN(3,numChannels);
    
    numIPpoints = origDims(2); %2*numHalfIPpoints + 1;
    intprofs = NaN(numIPpoints, numChannels);
    fitprofs = NaN(numIPpoints, numChannels);
    cfitBoundses = NaN(2, numChannels);
    peakSearchBounds = uint16(int32(peakSearchBounds) + [1 -1]); % TODO: Eliminate need for offset
    if ~successTF
        fprintf(f, '[analyzeComposite] Estimation of laser intensity was unsuccessful. Returning without performing further analysis.\n');
        return;
    end
    fprintf(f, '[analyzeComposite] Estimation of laser intensity was successful (num IP points: %d).\n', numIPpoints);
    %horizIdxs0 = 1:origDims(2);
    successTF2 = true;
    fitXs = 1:numIPpoints; % TODO: Subset?
    for chNum=1:numChannels
        Y0c = Y0s(scaledChVertIdxs{chNum}, :);
        Y1c = Y1s(scaledChVertIdxs{chNum}, :);
        Ycc = Yc(scaledChVertIdxs{chNum}, :);
        % TODO: Try/catch??? -- be sure to fill cell with NaNs
        %     peakInfo,intensityProfile, ...
        % p1, successTF, cfitBounds, sampMask, sampMask0, roiMask
        [channelPeakData, channelIP, p1, successTF2a, cfitBounds, sampMask, sampMask0, roiMask] ...
            = sbsense.improc.sbestimatepeakloc(Y0c,Y1c,Ycc, ...
            origDims, peakSearchBounds, f, p01); %...
            %numHalfIPpoints, numIPpoints, f);
        if successTF2a
            fprintf(f, '[analyzeComposite] Peak location estimation for Ch. %d was successful.\n', chNum);
            peakData([1 2],chNum) = channelPeakData; %'; % Unnecessary?
            p1s([1 2 3],chNum) = p1;%'; % Unnecessary?
            intprofs(:,chNum) = channelIP;
            fitprofs(:,chNum) = sbsense.lorentz(p1, fitXs); % TODO: Don't recalculate for each?
            cfitBoundses(:,chNum) = cfitBounds;
            fprintf(f, '[analyzeComposite] Size of intprofs(:,chNum): %s', formattedDisplayText(size(intprofs(:,chNum))));
            fprintf(f, '[analyzeComposite] Size of channelIP: %s', formattedDisplayText(size(channelIP)));
        elseif successTF2
            fprintf(f, '[analyzeComposite] WARNING: Peak location estimation for Ch. %d was unsuccessful.\n', chNum);
            successTF2 = false;
        end
        try
            sampMask0s{1,chNum+1} = sampMask0; sampMasks{1,chNum+1} = sampMask; roiMasks{1,chNum+1} = roiMask;
        catch ME
            fprintf(f, '[analyzeComposite] Error "%s" occurred while storing masks for channel %d: %s\n', ...
                ME.identifier, chNum, getReport(ME));
        end
    end
    fprintf(f, '[analyzeComposite] peakData:\n%s', formattedDisplayText(peakData));
    successCode = successTF + successTF2; %uint8(successTF + successTF2);
    fprintf(f, '[analyzeComposite] sC = %d = %d + %d = sTF + sTF2\n', ...
        successCode, successTF, successTF2);
end