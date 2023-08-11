function [img1,img2,TF] = generateChannelOverlayImages(co, analysisParams)
    try
        effHeight = analysisParams.ScaledEffectiveHeight;
        effWidth = analysisParams.EffectiveWidth;
        
        if analysisParams.NumChannels > 1
            % img =  zeros([effHeight 3 effWidth], 'double');
            img1 = zeros([effHeight effWidth 3], 'double');
            img2 = zeros([effHeight effWidth 3], 'uint8');
            for ch=1:analysisParams.NumChannels
                %for i=1:3
                %    img1(analysisParams.ScaledChVertIdxs{ch},i,:) = co(ch,i);
                %end
                sz = diff(analysisParams.ScaledChVertIdxs{ch}([1 end])) + 1;
                img1(analysisParams.ScaledChVertIdxs{ch},:,:) = ...
                    repmat(shiftdim(co(ch,:),-1), ...
                    sz, effWidth); % analysisParams.ChHeights(ch), effWidth);
                if ch~=1
                    img2(analysisParams.ScaledChBoundsPositions(ch), ...
                        :, [1 2]) = 255;
                end
            end
            % img1 = permute(img, [1 3 2]);
        else
            % img1 = zeros([effHeight effWidth 3], 'double');
            %for i=1:3
            %    img1(:,:,i) = co(1,i);
            %end
            img1 = repmat( ...
                shiftdim(co(1,:), -1), effHeight, effWidth);
            img2 = [];
        end
        % app.overimg.CData = img1;
        TF = true;
    catch ME
        fprintf('[postset_ConfirmStatus] Error "%s" encountered while generating channel strip overlay image: %s\n', ...
            ME.identifier, getReport(ME));
        % app.overimg.CData = [];
        img1 = []; img2 = [];
        TF = false;
    end
end