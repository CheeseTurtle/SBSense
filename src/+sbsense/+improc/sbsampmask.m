% sampmask, sampmask0, roiMask
function [BW,BW0,msk0,Yr,Yrr, typeIsDouble, centroid, pimg] = sbsampmask(...
    Y0, Y1, peakSearchBounds, debug, f, peakSearchZone, peakInfo)
arguments(Input)
    Y0; Y1; peakSearchBounds;
    debug logical = false;
    f = 1;
    peakSearchZone = [];
    peakInfo = struct.empty();
end

numPixels = numel(Y0);

if isempty(peakSearchZone) || isequal(peakSearchZone, [0 0]) || anynan(peakSearchZone) || isequal(peakSearchZone, [1 size(Y0,2)])
    if isempty(peakSearchBounds) || anynan(peakSearchBounds)  || isequal(peakSearchBounds, [1 size(Y0,2)])
        PSZMsk = logical.empty();
    else
        PSZMsk = false(size(Y0));
        PSZMsk(:,peakSearchBounds(1):1:peakSearchBounds(2)) = true;
    end
else
    PSZMsk = false(size(Y0));
    PSZMsk(:,peakSearchZone(1):1:peakSearchZone(2)) = true;
end

% Integer division
fprintf(f, 'Class of Y0: %s; Class of Y1: %s.\n', ...
    class(Y0), class(Y1));
if isinteger(Y0) && ~isinteger(Y1)
    Y0 = double(Y0);
end
Yr  = imdivide(Y1, Y0); msk1 = (Yr  < 1);
Yrr = imdivide(Y0, Y1); msk2 = (Yrr > 1);

if(debug)
    fprintf(f, 'Sum msk1, msk2, msk1&msk2: %d, %d, %d\n', ...
        sum(msk1, "all", 'omitnan'), sum(msk2, "all", 'omitnan'), ...
        sum(msk1 & msk2, "all", 'omitnan'));
end

msk1Count = sum(msk1, "all");
msk2Count = sum(msk2, "all");
if(~msk1Count || ~msk2Count || ~isacceptablemask(msk1Count, numPixels) ...
        || ~msk2Count || ~isacceptablemask(msk2Count, numPixels))
    typeIsDouble = true;
    Y0d = im2double(Y0); Y1d = im2double(Y1);
    Yrd = (Y1d./Y0d); Yrrd = (Y0d./Y1d);
    msk1 = (Yrd < 1); msk2 = (Yrrd > 1);

    %Yr = fix(255*Yrd); Yrr = fix(255*Yrrd);
    Yr = Yrd; Yrr = Yrrd;
    %Yr = 255*Yrd; Yrr = 255*Yrrd;

    if(debug)
        mm0 = minmax(Y0(:)'); mm1 = minmax(Y1(:)');
        mm0d = minmax(Y0d(:)'); mm1d = minmax(Y1d(:)');
        mmYrd = minmax(Yrd(:)'); mmYrrd = minmax(Yrrd(:)');
        mmYr = minmax(Yr(:)'); mmYrr = minmax(Yrr(:)');

        fprintf(f,'Min/Max Y0,Y1: %0.4g:%0.4g, %0.4g:%0.4g\n', mm0(1), mm0(2), mm1(1), mm1(2));
        fprintf(f,'Min/Max Y0d,Y1d: %0.4g:%0.4g, %0.4g:%0.4g\n', mm0d(1), mm0d(2), mm1d(1), mm1d(2));
        fprintf(f,'Min/Max Yrd,Yrrd: %0.4g:%0.4g, %0.4g:%0.4g\n', mmYrd(1), mmYrd(2), mmYrrd(1), mmYrrd(2));
        fprintf(f,'Min/Max Yr,Yrr: %0.4g:%0.4g, %0.4g:%0.4g\n', mmYr(1), mmYr(2), mmYrr(1), mmYrr(2));
    end
    msk1Count = sum(msk1, "all");
    msk2Count = sum(msk2, "all");
    if(debug)
        fprintf(f,'After FP division: Sum msk1, msk2, msk1&msk2: %d, %d, %d\n', ...
            msk1Count, msk2Count, ...
            sum(msk1 & msk2, "all", 'omitnan'));
    end
else
    typeIsDouble = false;
    %Yrd = double(Yr); Yrrd = double(Yrr);
end

if(debug)
    fig12 = figure(12);
    tl = tiledlayout(fig12, 'flow', 'Padding', 'loose', 'TileSpacing', 'compact');
    ax = nexttile(tl, [2, 2]);
    if typeIsDouble
        Yrdisp = sbsense.utils.imadjstretch(im2uint16(max(0, min(1, Yr))), [0 1]);
    else
        Yrdisp = sbsense.utils.imadjstretch(max(0, min(1, im2uint36(Yr))), [0 1]);

    end
    montage({im2uint8(normalize(max(0, Yr),"range")), ...
        sbsense.utils.imadjstretch(max(Yrdisp,0))}, colormap("gray"), 'Parent', ax);
    title(ax, "Yr normalized, Yr clipped");
    ax = nexttile(tl, [2 2]);
    montage({labeloverlay(Y1, msk1), labeloverlay(Y1, msk2)}, ...
        "Parent", ax, "Size", [1 2]);
    title(ax, "msk01, msk02");
end

msk1 = logical(imdilate(uint8(msk1), strel('rectangle', [512 255]).Neighborhood));
msk2 = logical(imdilate(uint8(msk2), strel('rectangle', [1023 127]).Neighborhood));

if(debug)
    msk1Count = 0; %sum(msk1, "all");
    msk2Count = 0; %sum(msk2, "all");
end

EM0 = 0.55; EM = EM0; % TODO: What value for these?
if msk1Count
    if msk2Count
        msk = msk1 & msk2;
        mskCount = sum(msk, "all");
    else
        msk = msk1;
        mskCount = msk1Count;
    end
elseif msk2Count
    msk = msk2;
    mskCount = msk2Count;
else
    % Both are 0
    %msk = imbinarize(Yr, "global");
    % TODO: imhist --> pass value back to app for storage?
    [thresh0, EM0] = otsuthresh(imhist(Yr, 128)); % TODO: nbins
    if(true || (EM0 < 0.5))
        img0 = ~imbinarize(Yr, thresh0);
        EM00 = EM0; thresh00 = thresh0;
        [thresh0, EM0] = otsuthresh(imhist(Yr, 256)); % TODO: nbins
        if(debug)
            ax = nexttile(tl, [1 2]);
            montage({labeloverlay(Y1,img0), ...
                labeloverlay(Y1,~imbinarize(Yr,thresh0))}, "Parent", ax);
            title(ax, "thresh0 (otsu): " + ...
                sprintf("%d @ %0.4g, %d @ %0.4g", ...
                sum(img0,"all"), EM00, sum(~imbinarize(Yr,thresh0), "all"), EM0));
        end
        if(EM0 >= 0.5)
            thresh0 = thresh00; EM0 = EM00;
        end
    end
    msk = ~imbinarize(Yr, thresh0);
    mskCount = sum(msk, "all", 'omitnan');
end

if (EM0 < 0.5) || debug || ~isacceptablemask(mskCount, numPixels)
    Yrg = imgaussfilt(min(1,Yr), 3, "Padding", "replicate", ... %imgaussfilt(min(1,max(Yr,0)), 3, "Padding", "replicate", ...
        "FilterSize", [511 25]); % TODO: FilterDomain
    fprintf(f, 'Making Yrb.\n');
    Yrb = imboxfilt(max(0,Yrg), [127 5]);
    fprintf(f, 'Made Yrb.\n');
    if(debug)
        ax = nexttile(tl, [1 2]);
        montage({im2uint8(normalize(Yrg, "range")), im2uint8(normalize(Yrb, "range"))}, colormap("bone"), "Parent", ax);
        title(ax, "Yrg, Yrb");
    end
    % msk = (Yr <= prctile(Yr, 1, "all"));
    % Effectiveness metric of the threshold, returned as a
    % nonnegative number in the range [0, 1].
    % The lower bound is attainable only by images having a
    % single gray level,
    % and the upper bound is attainable only by two-valued images.
    % TODO: Minimum EM??
    [thresh1, EM1] = graythresh(Yrb);
    EM = EM1;
    msk = ~imbinarize(Yrb, thresh1);
    mskCount = sum(msk, "all", 'omitnan');
    unacceptableMask = ~isacceptablemask(mskCount,numPixels);
    if(debug)
        ax = nexttile(tl, [1 1]);
        imshow(labeloverlay(im2uint8(normalize(Yrb, "range")), msk), "Parent", ax);
        title(ax, sprintf("msk1 (%d @ %0.4g)", sum(msk, "all"), EM1));
    end
    if( unacceptableMask || (EM1 < 0.5) )
        % TODO: Num thresh levels?
        [threshes2, EM2] = multithresh(Yrb, 8);
        thresh2 = threshes2(1) + iqr(threshes2);
        msk2 = ~imbinarize(Yrb, thresh2);
        msk2Count = sum(msk2, "all", 'omitnan');

        if(debug)
            ax = nexttile(tl, [1 2]);
            seg_I = imquantize(Yrb,threshes2);
            %RGB = label2rgb(seg_I);
            % figure; imshow(RGB); axis off;
            montage({ ...
                labeloverlay(im2uint8(normalize(Yrb, "range")),seg_I), ...
                labeloverlay(im2uint8(normalize(Yrb, "range")), msk2)}, ...
                "Parent", ax);
            title(ax, sprintf("msk2 (%d @ %0.4g)", msk2Count, EM2));
        end
        %[threshes4, EM4] = multithresh(Yrb, 2); % TODO...
        acceptableMask2 = isacceptablemask(msk2Count,numPixels);
        if(acceptableMask2 && (...
                unacceptableMask... %&& isacceptablemask(msk3Count,numPixels) % TODO
                ||  (EM2 > EM1) ))
            msk = msk2; mskCount = msk2Count; EM = EM2;
        else % msk2 is unacceptable (or worse than msk1!)
            [thresh3, EM3] = multithresh(Yrb, 1);
            msk3 = imbinarize(Yrb, thresh3);
            msk3Count = sum(msk3, "all", 'omitnan');
            if(debug)
                ax = nexttile(tl, [1 1]);
                imshow(labeloverlay(im2uint8(normalize(Yrb, "range")), msk3), "Parent", ax);
                title(ax, sprintf("msk3 (%d @ %0.4g", msk3Count, EM3));
            end
            if((EM3 < 0.5) || ~isacceptablemask(msk3Count, numPixels))
                % msk3 is not acceptable
                if(unacceptableMask || (EM3 > EM0) || (EM3 > EM1))
                    % TODO: Which mask to use?
                    msk = msk3; mskCount = msk3Count; EM = EM3;
                    % TODO: Compare acceptability?????
                    if(debug)
                        fprintf(f,'Warning: Potentially uneffective thresholding performed. (E.M.: %0.4g)\n', EM3);
                    end
                    % else % Keep current mask, because it's acceptable.
                end
            elseif (EM3 > EM1) % msk3 is acceptable / better than msk1
                % TODO: Compare acceptability of masks?
                msk = msk3; mskCount = msk3Count;
            end
        end
    end
end

if(debug && (~isacceptablemask(mskCount,numPixels) || (EM < 0.5)))
    fprintf(f,'Warning: Potentially uneffective thresholding performed. (E.M.: %0.4g @ %d/%d pixels)\n', ...
        EM3, mskCount, numPixels);
end

% msk =  msk1 & msk2;
% fprintf(f,'Sum msk1, msk2, msk: %d, %d, %d\n', ...
%     sum(msk1,"all"), sum(msk2, "all"), sum(msk,"all"));
% fprintf(f,'Num NaN Yr, Yrr: %d, %d\n', ...
%     sum(isnan(Yr), "all"), sum(isnan(Yrr), "all"));
%     %sum(isnan(msk1),"all"), sum(isnan(msk2), "all"), sum(isnan(msk),"all"));

if debug
    % TODO: Acceptable vs unacceptable mask count
    % TODO: Thresholding methods...
    %numPixels = numel(Yr);
    sens = 0.5;
    %while(~isacceptablemask(mskCount, numPixels))
    i = 1;
    msk4s = cell(1, 50);
    msk4Counts = zeros(1,50, "uint32");
    while sens <= 1.0
        % TODO: Thresh
        msk4 = ~imbinarize(Yr, "adaptive", "ForegroundPolarity", "dark", ...
            "Sensitivity", sens); % TODO: Sensitivity
        msk4Count = sum(msk4, "all", 'omitnan');
        if(sens <= 0.1)
            sens = 0.51;
        elseif (sens > 0.5)
            if (sens >= 0.6)
                msk4 = ~imbinarize(Yr, "global");
                msk4Count = sum(msk4, "all", 'omitnan');
                %fprintf(f,'Warning: Potentially uneffective thresholding performed (msk4 count: %d/%d pixels).\n', ...
                %    msk4Count, numPixels);
                msk4s{i} = msk4; msk4Counts(i) = msk4Count;
                i = i + 1;
                break;
            else
                sens = sens + 0.01;
            end
        else
            sens = sens - 0.1;
        end
        msk4s{i} = msk4; msk4Counts(i) = msk4Count;
        i = i + 1;
    end
    if i <= 50
        msk4s(i:end) = [];
        %msk4Counts(i:end) = [];
    end
    numMontageRows = 2; numMontageCols = ceil(i / numMontageRows);
    img4s = cellfun(@(m4) labeloverlay(Y1, m4), msk4s, 'UniformOutput', false);
    disp(size(img4s));
    ax = nexttile(tl, [2 5]);
    montage(img4s, colormap("flag"), ...
        "Size", [numMontageRows numMontageCols], "Parent", ax);
    title(ax, "msk4s");

    % TODO: Remove later... !!!
    if(~isacceptablemask(sum(msk, "all"), numPixels))
        msk1Count = sum(msk1, "all", 'omitnan');
        msk2Count = sum(msk2, "all", 'omitnan');
    end
    if msk1Count
        if msk2Count
            msk = msk1 & msk2;
            mskCount = sum(msk, "all", 'omitnan');
        else
            msk = msk1;
            mskCount = msk1Count;
        end
    elseif msk2Count
        msk = msk2;
        mskCount = msk2Count;
    end

    %ax = nexttile(tl, [1 2]);
    %montage({msk2,msk1}, colormap("gray"), 'Size', [1 2], "Parent", ax);
elseif ((EM < 0.5) || ~isacceptablemask(mskCount, numPixels))
    sens = 0.5;
    while(~isacceptablemask(mskCount,numPixels))
        % TODO: Thresh
        msk = ~imbinarize(Yr, "adaptive", "ForegroundPolarity", "dark", ...
            "Sensitivity", sens); % TODO: Sensitivity
        mskCount = sum(msk, "all");
        if(sens <= 0.1)
            sens = 0.51;
        elseif (sens > 0.5)
            if (sens >= 0.6)
                msk = ~imbinarize(Yr, "global");
                mskCount = sum(msk, "all", 'omitnan');
                %fprintf(f,'Warning: Potentially uneffective thresholding performed (msk4 count: %d/%d pixels).\n', ...
                %    msk4Count, numPixels);
                break;
            else
                sens = sens + 0.01;
            end
        else
            sens = sens - 0.1;
        end
    end
end

% TODO: How to avoid (unnecesssary?) conversion?
msk =  imdilate(uint8(msk), strel('line', 255, 90));
% %msk =  logical(imerode(msk, strel('disk', 31, 6)));
% % msk =  bwmorph(msk, 'bridge');


msk0 = logical(msk);
msk = msk0;
%msk = bwareafilt(msk0, 1, "largest");
colIdxs = any(msk, 1);

colIdxs1 = bwmorph(colIdxs, 'bridge');
if debug
    fprintf(f,'Sum of colIdxs: %d\n', sum(colIdxs, "all"));
    fprintf(f,'Sum of colIdxs1: %d\n', sum(colIdxs1, "all"));
end

% disp({size(colIdxs1) ; size(Yr) });
numRows = size(Y1, 1);
colIdxs1Img = repelem(colIdxs1, numRows, 1);
comps = bwconncomp(colIdxs1Img, 8); % TODO: 4 or 8?
%comps  = bwconncomp(colIdxs1);
compsm = bwconncomp(msk, 8);
if(~comps.NumObjects)
    fprintf(f, 'No objects. Checking compsm.\n');
    comps = compsm;
    colIdxs1 = any(msk,1);
    colIdxs1Img = msk;
end
if comps.NumObjects && ~isempty(comps)
    if ~isempty(PSZMsk)
        if isempty(peakSearchZone)
            wd = diff(peakSearchBounds) + 1;
        else
            wd = diff(peakSearchZone) + 1;
        end
        % hgt = size(Y0,1);
        fprintf(f, formattedDisplayText({size(comps.PixelIdxList{1}), size(sum(PSZMsk(comps.PixelIdxList{1}), 'all', 'omitnan', 'double')), size(double(min(wd,numel(comps.PixelIdxList{1}))))}));
        inPSZ = cellfun(@(idxs) sum(PSZMsk(idxs), 'all', 'omitnan', 'double')/double(min(wd,numel(idxs))), comps.PixelIdxList);
        if any(logical(inPSZ))
            inPSZ2 = (inPSZ >= 0.25);
            fprintf(f, '%d objects in comps; %d also within PSZ; %d included sufficiently.\n', comps.NumObjects, sum(logical(inPSZ)), sum(inPSZ2));
            fprintf(f, 'Size and class of comps.PixelIdxList: %s, %s\n', class(comps.PixelIdxList), strip(formattedDisplayText(size(comps.PixelIdxList))));
            fprintf(f, 'Size and class of inPSZ: %s, %s\n', class(inPSZ), strip(formattedDisplayText(size(inPSZ))));
            if ~all(inPSZ2)
                idxs = cellfun(@(x) reshape(x, 1, []), comps.PixelIdxList(~inPSZ2), 'UniformOutput', false);
                idxs = unique(horzcat(idxs{:}));
                colIdxs1Img(idxs) = 0;
                colIdxs1 = any(colIdxs1Img, 1);
                comps.PixelIdxList(~inPSZ2) = [];
                comps.NumObjects = sum(inPSZ2);
            end
        else
            fprintf(f, '%d objects in comps; 0 also within PSZ (so keeping all)!\n', comps.NumObjects);
        end
    end
else
    fprintf(f, '0 objects in comps and compsm.\n');
%end
% elseif((comps.NumObjects > 1) && (compsm.NumObjects > 1))
%     fprintf(f, 'More than one object in both comps and compsm.\n');
%     % TODO: Check both compsm and comps
%     % Assume same Connectivity (4, 8, etc) and ImageSize ([x y])
%     %comps.NumObjects = comps.NumObjects + compsm.NumObjects;
%     %comps.PixelIdxList = {comps.PixelIdxList{:} compsm.PixelIdxList{:}};
end
if comps.NumObjects && ~isempty(peakInfo)
    pxs = peakInfo.xs;
    sz = size(Y0);
    if isequal(pxs([1 end]), [1 sz(2)])
        pimg = peakInfo.img; %repmat(peakInfo.imgRow, size(Y0,1), 1);
    else
        %pimg = zeros(sz);
        %pimg(:,pxs) = repmat(peakInfo.imgRow, size(Y0,1), 1);
        pimg = zeros(1,sz(2));
        pimg(1,pxs) = peakInfo.img;
    end
    pimg = repmat(pimg, sz(1), 1);
    %if ~isempty(PSZMsk)
    %end
    pmsk = true(1,comps.NumObjects);
    colidxs = peakInfo.xs(find(peakInfo.img >= 0.4));
    for i = 1:comps.NumObjects
        for ind = comps.PixelIdxList{i}
            [~, col] = ind2sub(sz, ind);
            if ismember(col, colidxs)
                break;
            end
        end
        % [~,cols] = ind2sub(sz, comps.PixelIdxList{i});
        pmsk(i) = false;
    end
    if ~any(pmsk)
        colidxs = peakInfo.xs(find(peakInfo.img >= 0.2));
        for i = 1:comps.NumObjects
            for ind = comps.PixelIdxList{i}
                [~, col] = ind2sub(sz, ind);
                if ismember(col, colidxs)
                    break;
                end
            end
            % [~,cols] = ind2sub(sz, comps.PixelIdxList{i});
            pmsk(i) = false;
        end
    end
    if any(pmsk)
        comps.PixelIdxList = comps.PixelIdxList(pmsk);
        comps.NumObjects = comps.NumObjects - sum(pmsk);
    %else
    %    comps.NumObjects = 0; % Note that the PixelIdxList is NOT cleared in this case
    end
else
    pimg = double.empty();
end

if(comps.NumObjects == 1) % TODO: Why not include msk here and only in the other case?
    fprintf(f, 'Only one object in (potentially combined) comps.\n');
    colIdxs2 = colIdxs1;
    colIdxs2Img = colIdxs1Img; %repelem(colIdxs2, numRows, 1);
    fprintf(f,'Size of msk: %s\nSize of colIdxs2: %s\nSize of colIdxs2Img: %s\n', ...
        erase(formattedDisplayText(size(msk)),newline), ...
        erase(formattedDisplayText(size(colIdxs2)),newline), ...
        erase(formattedDisplayText(size(colIdxs2Img)), newline));
    fprintf(f, 'Getting weighted centroid\n');
    rps = regionprops(colIdxs2Img, Yr, "WeightedCentroid");%[regionprops(msk, Yr, "WeightedCentroid")];
    if(length(rps) > 1)
        fprintf(f, 'Warning: Unexpectedly more than one region when getting weighted centroid of single columngroup.\n');
        rps = rps(1);
    end
    
    centroid = rps.WeightedCentroid;

    if ~isempty(peakInfo)
        centroid0 = centroid;
        rps = regionprops(comps, immultiply(pimg,Yr), 'WeightedCentroid');
        if(length(rps) > 1)
            fprintf(f, 'Warning: Unexpectedly more than one region when getting weighted centroid (based on pimg) of single columngroup.\n');
            rps = rps(1);
        end
        centroid = 0.4*centroid0 + 0.6*rps.WeightedCentroid;
        fprintf(f, 'WCentroid: [%g %g] + [%g %g] --> [%g %g]\n', ...
            centroid0(1), centroid0(2), rps.WeightedCentroid(1), ...
            rps.WeightedCentroid(2), centroid(1), centroid(2));
    end
    % TODO: Also take into account peakInfo???
elseif(comps.NumObjects)
    fprintf(f, 'Getting regprops.\n');
    fprintf(f, 'comps fields: %s', formattedDisplayText(fieldnames(comps)));
    fprintf(f, 'comps PixelIdxList: %s', formattedDisplayText(comps.PixelIdxList));

    if ~isempty(peakInfo)
        %regprops = regionprops(comps, pimg, 'MeanIntensity', 'MinIntensity', 'MaxIntensity')';
        % % fprintf(f, 'regprops (based on pimg):\n%s\n', strip(formattedDisplayText(regprops)));
        regpropsParallel = regionprops(comps, immultiply(pimg,Yr), "MeanIntensity", "Area",... %"FilledArea", ... %"BoundingBox", ...
            "WeightedCentroid", "MajorAxisLength", "Orientation", ...
            "MinIntensity", "PixelIdxList", "BoundingBox"); % , "MinorAxisLength")'; % "Image");
    else
        regpropsParallel = regionprops(comps, Yr, "MeanIntensity", "Area",... %"FilledArea", ... %"BoundingBox", ...
            "WeightedCentroid", "MajorAxisLength", "Orientation", ...
            "MinIntensity", "PixelIdxList", "BoundingBox");%, "MinorAxisLength")'; % "Image");
    end
    % fprintf(f, 'regpropsParallel ( = regpropsCascade):\n%s\n', strip(formattedDisplayText(regpropsParallel)));

    nomask = true(size(regpropsParallel))';

    % Eliminate improperly oriented regions
    % TODO: Angle criteria? Give ratings instead of true/false?
    orientationDists = 90 - abs([regpropsParallel.Orientation]);

    bbs = vertcat(regpropsParallel.BoundingBox);
    bbWidths = bbs(:,3)';
    bbHeights = bbs(:,4)';
    
    bbWidthMask = ((bbWidths < 0.5*size(Y0,2)) | (bbHeights < 0.3*size(Y0,1)));
    if ~any(bbWidthMask)
        bbWidthMask = nomask;
    end

    bbsMaskParallel = ((bbWidths >= bbHeights) & (bbHeights >= 0.75*size(Y0,1)));
    % bbsMaskCascade  = bbsMaskParallel;

    orientationMask  = (orientationDists < 45) | bbsMaskParallel;
    fprintf(f, formattedDisplayText(orientationMask));

    regpropsParallel = regpropsParallel';
    regpropsCascade = regpropsParallel;
    fprintf(f, formattedDisplayText({size(regpropsParallel), size(orientationDists), size(bbsMaskParallel), size(regpropsCascade)}));

    cascadeIdxs = (1:length(regpropsParallel));
    if any(orientationMask, 'all') && ~all(orientationMask, 'all')
        regpropsCascade = regpropsCascade(orientationMask);
        cascadeIdxs = cascadeIdxs(orientationMask);
        % bbsMaskCascade = bbsMaskCascade(orientationMask);
        parallelAndCascadeSame = false;
    else
        orientationMask = nomask; % TODO: How to avoid redundant assignment?
        parallelAndCascadeSame = true;
    end

    % Eliminate regions that are less than 50% of the longest length
    % TODO: Less strict requirements? Give ratings instead of true/false?
    majorLengths = abs([regpropsParallel.MajorAxisLength]);
    fprintf(f, 'Calculating maxMajorLength.\n');
    maxMajorLength = max(majorLengths, [], "all", 'omitnan');
    fprintf(f, 'Calculated maxMajorLength.\n');
    minMajorLength = 0.5*maxMajorLength;
    majorLengthMask = or((majorLengths >= minMajorLength), bbsMaskParallel);
    if ~any(majorLengthMask, 'all')
        majorLengthMask = nomask;
    end
    if parallelAndCascadeSame
        %majorLengthsCascade = majorLengths;
        %maxMajorLengthCascade = maxMajorLength;
        %minMajorLengthCascade = minMajorLength;
        majorLengthMaskCascade = majorLengthMask;
    else
        majorLengthsCascade = abs([regpropsCascade.MajorAxisLength]);
        maxMajorLengthCascade = max(majorLengthsCascade, [], 'all', 'omitnan');
        minMajorLengthCascade = 0.5*maxMajorLengthCascade;
        majorLengthMaskCascade = majorLengthsCascade >= minMajorLengthCascade;
    end
    parallelAndCascadeSame = parallelAndCascadeSame && all(majorLengthMask);
    if(~parallelAndCascadeSame && (any(majorLengthMaskCascade) && ~all(majorLengthMaskCascade)))
        regpropsCascade = regpropsCascade(majorLengthMaskCascade);
        cascadeIdxs = cascadeIdxs(majorLengthMaskCascade);
    end

    % Eliminate regions that are less than 50% of the largest area
    regionAreas = [regpropsParallel.Area];
    fprintf(f, 'Calculating largestArea.\n');
    largestArea = max(regionAreas(bbWidthMask), [], "all", 'omitnan');
    fprintf(f, 'Calculated largestArea.\n');
    minArea = 0.5*largestArea;
    regionAreaMask = regionAreas > minArea;
    if(all(~regionAreaMask))
        regionAreaMask = nomask;
    end
    if(parallelAndCascadeSame)
        regionAreaMaskCascade = regionAreaMask;
    else
        regionAreasCascade = [regpropsCascade.Area];
        fprintf(f, 'Calculating largestArea.\n');
        largestAreaCascade = max(regionAreasCascade, [], "all", 'omitnan');
        fprintf(f, 'Calculated largestArea.\n');
        minAreaCascade = 0.5*largestAreaCascade;
        regionAreaMaskCascade = regionAreasCascade > minAreaCascade;
    end
    parallelAndCascadeSame = parallelAndCascadeSame && all(regionAreaMask);
    if ~parallelAndCascadeSame ...
            && (any(regionAreaMaskCascade) && ~all(regionAreaMaskCascade))
        regpropsCascade = regpropsCascade(regionAreaMaskCascade);
        cascadeIdxs = cascadeIdxs(regionAreaMaskCascade);
    end

    % Eliminate regions that have a mean intensity higher than 200% min
    meanIntensities = [regpropsParallel.MeanIntensity];
    minMeanIntensity = min(meanIntensities, [], "all", 'omitnan');
    maxMeanIntensity = 2*minMeanIntensity;
    meanIntensityMask = meanIntensities <= maxMeanIntensity;
    if(all(~meanIntensityMask))
        meanIntensityMask = nomask;
    end
    if parallelAndCascadeSame
        meanIntensityMaskCascade = meanIntensityMask;
    else
        meanIntensitiesCascade = [regpropsCascade.MeanIntensity];
        minMeanIntensityCascade = min(meanIntensitiesCascade);
        maxMeanIntensityCascade = 2*minMeanIntensityCascade;
        meanIntensityMaskCascade = meanIntensitiesCascade <= maxMeanIntensityCascade;
    end
    parallelAndCascadeSame = parallelAndCascadeSame && all(regionAreaMask);
    if(~parallelAndCascadeSame && (any(meanIntensityMaskCascade) && ~all(meanIntensityMask)))
        fprintf(f, 'regionAreaMask: %s\n', strip(formattedDisplayText(regionAreaMask)));
        fprintf(f, 'regionAreaMaskCascade: %s\n', strip(formattedDisplayText(regionAreaMaskCascade)));
        fprintf(f, 'meanIntensities: %s\n', strip(formattedDisplayText(meanIntensities)));
        fprintf(f, 'meanIntensitiesCascade: %s\n', strip(formattedDisplayText(meanIntensitiesCascade)));
        fprintf(f, 'meanIntensityMask: %s\n', strip(formattedDisplayText(meanIntensityMask)));
        fprintf(f, 'meanIntensityMaskCascade: %s\n', strip(formattedDisplayText(meanIntensityMaskCascade)));
        fprintf(f, 'regpropsCascade: %s\n', strip(formattedDisplayText(regpropsCascade)));
        fprintf(f, 'cascadeIdxs: %s\n', strip(formattedDisplayText(cascadeIdxs)));
        regpropsCascade = regpropsCascade(meanIntensityMaskCascade);
        cascadeIdxs = cascadeIdxs(meanIntensityMaskCascade);
    end
    
    % Eliminate regions that have a min intensity higher than 125% min
    minIntensities = [regpropsParallel.MinIntensity];
    minMinIntensity = min(minIntensities, [], "all", 'omitnan');
    maxMinIntensity = 1.25*minMinIntensity;
    minIntensityMask = minIntensities <= maxMinIntensity;
    if(all(~minIntensityMask))
        minIntensityMask = nomask;
    end
    if parallelAndCascadeSame
        minIntensityMaskCascade = minIntensityMask;
    else
        minIntensitiesCascade = [regpropsCascade.MinIntensity];
        minMinIntensityCascade = min(minIntensitiesCascade, [], "all", 'omitnan');
        maxMinIntensityCascade = 1.25*minMinIntensityCascade;
        minIntensityMaskCascade = minIntensitiesCascade <= maxMinIntensityCascade;
    end
    parallelAndCascadeSame = parallelAndCascadeSame && all(minIntensityMask);
    if(~parallelAndCascadeSame && (any(minIntensityMaskCascade) && ~all(minIntensityMaskCascade)))
        regpropsCascade = regpropsCascade(meanIntensityMaskCascade);
        cascadeIdxs = cascadeIdxs(meanIntensityMaskCascade);
    end

    try
        fprintf(f, 'Choosing largest remaining area.\n');
        % Choose largest area of the remaining
        regParallelMask = (orientationMask & majorLengthMask & regionAreaMask & ...
            meanIntensityMask & minIntensityMask);
        numselectedregions = sum(regParallelMask, "all", 'omitnan');

%         fprintf(f,'regParallelMask (size %d x %d):\n%s\n', ...
%             size(regParallelMask,1),size(regParallelMask,2), ...
%             evalc('disp(regParallelMask)'));
%         fprintf(f,'regpropsParallel (size %d x %d):\n%s\n', ...
%             size(regpropsParallel,1),size(regpropsParallel,2), ...
%             evalc('disp(regpropsParallel)'));
%         fprintf(f,'cascadeIdxs (size %d x %d):\n%s\n', ...
%             size(cascadeIdxs,1),size(cascadeIdxs,2), ...
%             evalc('disp(cascadeIdxs)'));
%         fprintf(f,'regpropsCascade (size %d x %d):\n%s\n', ...
%             size(regpropsCascade,1),size(regpropsCascade,2), ...
%             evalc('disp(regpropsCascade)'));

        fprintf(f, 'regParallelMask (%d selected regions): %s', ...
            int16(numselectedregions), formattedDisplayText(regParallelMask));
        regprops = regpropsParallel(regParallelMask);

        if(numselectedregions)
            regionAreas = regionAreas(regParallelMask);
        elseif ~isempty(regpropsCascade) && ~parallelAndCascadeSame % TODO: ??
            regprops = regpropsCascade;
            fprintf(f,'regpropsCascade (%d selected regions) idxs: %s', ...
                int16(numel(regpropsCascade)), formattedDisplayText(cascadeIdxs));
            regionAreas = [regpropsCascade.Area];
        end
        numselectedregions = numel(regionAreas);
    catch ME
        fprintf(f,'Error: %s\n\n', getReport(ME));
        numselectedregions = 0;
        fprintf(f,'regParallelMask: %s', formattedDisplayText(regParallelMask));
        fprintf(f,'regpropsParallel (numel: %d):\n%s', numel(regpropsParallel), ...
            evalc('disp(regpropsParallel)'));
        fprintf(f,'cascadeIdxs: %s', formattedDisplayText(cascadeIdxs));
        fprintf(f,'regpropsCascade (numel: %d):\n%s', numel(regpropsCascade), ...
            evalc('disp(regpropsCascade)'));
    end

    if (numselectedregions > 1)
        fprintf(f, 'Making largestAreaMask.\n');
        largestAreaMask = (regionAreas==max(regionAreas));
        if(any(largestAreaMask))
            firstIdx = find(largestAreaMask,1,'first');
            regprops = regprops(firstIdx);
        else
            regprops = regprops(1); % TODO
        end

        % comps = comps(regMask);
        % pxlList = comps.PixelIdxList{firstIdx}; %regionprops(comps(firstIdx), "PixelIdxList");
    elseif numselectedregions==0
        fprintf(f, '[sbsampmask] ERROR: Somehow there are no regions left. Unable to evaluate.\n');
        fprintf(f,'regParallelMask: %s', formattedDisplayText(regParallelMask));
        fprintf(f,'regpropsParallel (numel: %d):\n%s', numel(regpropsParallel), ...
            evalc('disp(regpropsParallel)'));
        fprintf(f,'cascadeIdxs: %s', formattedDisplayText(cascadeIdxs));
        fprintf(f,'regpropsCascade (numel: %d):\n%s', numel(regpropsCascade), ...
            evalc('disp(regpropsCascade)'));
        % error('Somehow there are no regions left.\n');
        BW = logical.empty(); BW0 = logical.empty();
        return;
    end
    fprintf(f, 'Chose largest remaining area.\n');
    fprintf(f, 'Getting weighted centroid and mask image.\n');
    % Get its weighted centroid and mask image
    try
        fprintf(f, 'regprops: %s', formattedDisplayText(regprops));
        centroid = regprops.WeightedCentroid;
        % centroidX = centroid(1,1);
        pxlList = regprops.PixelIdxList;
        %colIdxs2 = false(size(colIdxs));
        %colIdxs2(pxlList) = true;
        % %colIdxs2Img = repelem(colIdxs2, numRows, 1);
        % colIdxs2Img = colIdxs2;
        %colIdxs2Img = repelem(false(size(colIdxs)), numRows, 1);
        colIdxs2Img = false(size(Y1));%, 'like', Y1);
        colIdxs2Img(pxlList) = true;
        fprintf(f, 'Got weighted centroid and mask image.\n');
    catch ME
        fprintf(f, 'Could not get weighted centroid and mask image.\n--> Error (%s): %s\n%s\n', ME.identifier, ME.message, getReport(ME));
        %if(ME.identifier ~= "MATLAB:atLeastOneIndexIsRequired")
        %    rethrow(ME);
        %end
        centroid = [-1 -1];
        % Choosing only based on area
        try
            %colIdxs2    = bwareafilt(colIdxs1, 1, "largest");
            colIdxs2Img = bwareafilt(colIdxs1, 1, "largest");
            %colIdxs2Img = repelem(colIdxs2, numRows, 1);
            % TODO: msk vs msk0
            meanROI  = mean(Yr(msk0), "all", "omitnan");
            meanBWA  = mean(Yr(colIdxs2Img), "all", "omitnan");
            minROI   = min(Yr(msk0), "all", "omitnan");
            minBWA   = min(Yr(colIdxs2Img), "all", "omitnan");
            if( (meanBWA <= 1.2*meanROI) && (minBWA <= 1.1*minROI))
                fprintf(f, 'Using largest contiguous area as largest area instead (comparing it to the ROI region only and without considering other region factors).\n');
            else
                %colIdxs2 = any(msk0,1);
                colIdxs2Img = msk0; %colIdxs2Img = repelem(colIdxs2, numRows, 1);
                fprintf(f, 'Using ROI mask as largest area instead.\n');
            end
        catch ME
            fprintf(f, 'Unhandled error (%s): %s', ME.identifier, ME.message);
            %colIdxs2 = any(msk0,1);
            colIdxs2Img = msk0; %repelem(colIdxs2, numRows, 1);
        end
    end
else % Number of connected compenents found is 0
    fprintf(f, 'Could not find any connected components. Using ROI mask.\n');
    centroid = [-1 1];
    %colIdxs2 = any(msk0,1);
    colIdxs2Img = msk0; %repelem(colIdxs2, numRows, 1);
end

colIdxs2 = any(colIdxs2Img, 1);

if debug
    fprintf(f,'Sum of colIdxs2: %d\n', sum(colIdxs2, "all"));
end

if debug
    if(typeIsDouble)
        img = Yr.*double(colIdxs2Img);
    else
        img = Yr.*uint8(colIdxs2Img);
    end

    ax = nexttile(tl, [2, 2]);
    montage({labeloverlay(Y1, repelem(colIdxs, numRows, 1)), ...
        labeloverlay(Y1, repelem(colIdxs1, numRows, 1)), ...
        labeloverlay(Y1, repelem(colIdxs2, numRows, 1)), ...
        img}, 'Size', [2 2], ...
        "Parent", ax);
    title(ax, "colIdxs, colIdxs1, colIdxs2, Yr&colIdxs");
end

fprintf(f, 'Making Y2.\n');
% colIdxs = colIdxs2;
fprintf(f, 'Size of Yr: %s', formattedDisplayText(size(Yr)));
fprintf(f, 'Size of colIdxs2Img: %s', formattedDisplayText(size(colIdxs2Img)));
fprintf(f, 'colIdxs2: %d:%d\n', find(colIdxs2(1,:), 1, 'first'), ...
    find(colIdxs2(1,:), 1, 'last'));
%if(isvector(colIdxs2))
%    colIdxs2 = repelem(colIdxs2Im,numRows,1);
%end
%fprintf(f, 'colIdxs2 (%s):\n%s\n', class(colIdxs2), formattedDisplayText(colIdxs2, 'SuppressMarkup',true, 'LineSpacing','compact'));
%fprintf(f, 'colIdxs2Img (%s):\n%s\n', class(colIdxs2Img), formattedDisplayText(colIdxs2Img, 'SuppressMarkup',true, 'LineSpacing','compact'));
Y2 = Yr(:,colIdxs2);
%Y2 = Yr(colIdxs2Img);
fprintf(f, 'Made Y2. Size: %s', formattedDisplayText(size(Y2)));

%[L, ~] = superpixels(Y2, 500, "Compactness", 5, "NumIterations",10);
%idxs = label2idx(L);
%Y2 = zeros(size(Y1), 'like', Y1);
%for i=1:N
%    idx = idxs{i};
%    Y2(idx) = mean(Yr(idx), "all", "omitnan");
%end


if isempty(Y2)
    BW = []; BW0 = [];
    return;
end


%BW = msk;
if debug
    ax = nexttile(tl, [1 1]);
    imshow(sbsense.utils.imadjstretch(Y2), "Parent", ax);
    title(ax, "Y2");
    fprintf(f,'Size of Y2: %s\n', strip(formattedDisplayText(size(Y2)), "right", newline));
    %disp(size(Y2));
end
try
fprintf(f,'CWT\n');
%fprintf(f, 'Y2:\n%s\n', formattedDisplayText(Y2, 'SuppressMarkup',true, 'LineSpacing','compact'));
cwtresult = cwtft2(Y2, ...
    'scales', 3, 'angles', ... %[3 4 5], 'angles', ...
    [0 pi/12 pi/6 pi/4 pi/3 11*pi/12 3*pi/4 5*pi/6 pi 11*pi/12 4*pi/3 5*pi/4 7*pi/4 11*pi/6 23*pi/12 ],...
    ...%[0 pi/6 pi/4 pi/3 pi/2 2*pi/3 3*pi/4 4*pi/5 7*pi/6 5*pi/4 4*pi/3 3*pi/2], ...
    'wavelet', 'esmexh'); %{'esmexh', {1,0.5}}, 'norm', 'L2');
fprintf(f,'CWT done\n');


    cwt3s = cwtresult.cfs(:,:,1,1,:);
    cwt3sAbs = squeeze(abs(cwt3s));
    fprintf(f, 'Calculating cwt3sAbsMax.\n');
    cwt3sAbsMax = max(cwt3sAbs, [], "all", "omitnan");
    fprintf(f, 'Calculated cwt3sAbsMax.\n');
    imemaxs = imextendedmax(cwt3sAbs, 0.925*cwt3sAbsMax);
    imemins = imcomplement(imextendedmin(cwt3sAbs, cwt3sAbsMax*0.075));
    imemaxs = imdilate(imemaxs, strel('rectangle', [61 3]).Neighborhood);
    imemins = imdilate(imemins, strel('rectangle', [61 3]).Neighborhood);
    imemaxs = imclose(imemaxs, strel('disk', 25));
    imemins = imclose(imemins, strel('disk', 25));
    improd  = (prod(imemins,3)|prod(imemaxs,3));
catch ME
    fprintf(f, 'Error during use of cwt results: %s\n' , getReport(ME));
    improd = Y2;
end

    improd0 = improd;
    %improd = imopen(improd, strel('disk', 2));
    improd = imdilate(improd, strel('rectangle', [61 31]).Neighborhood);
    improd = bwfill(improd, "holes");
    %improd = imresize(improd, 2, "nearest");
    fprintf(f,'Made improd\n');

if debug
    ax = nexttile(tl, [2 1]);
    % disp({size(imemaxs); size(imemins) ; size(improd0); size(improd)});
    montage({avgframes(imemaxs), avgframes(imemins), improd0, improd}, 'Size', [1 4], "Parent", ax);
    title(ax, "imemaxs, imemins, improd0, improd");
end

fprintf(f,'Making BW\n');
% % BW0 = msk;
% % BW0(~colIdxs) = 0;
% % BW0(:,colIdxs) = improd; % TODO: Wut.

fprintf(f,'Size of colIdxs2Img: %s, Size of improd: %s\b', ...
    strip(erase(formattedDisplayText(size(colIdxs2Img)), newline)), ...
    strip(formattedDisplayText(size(improd))));

%if size(improd,1)>1
    BW0 = false(size(msk));
    BW0(:,colIdxs2) = improd;
%else
%    BW0 = false(1,size(msk,2));
%    BW0(1,colIdxs2) = improd;
%    BW0 = repmat(BW0, size(msk,1), 1);
%end

% BW0 = (~colIdxs2Img) & improd;
BW0 = imclose(BW0, strel('disk', 50).Neighborhood);

fprintf(f,'Checking BW\n');
BWrows = any(BW0, 2);
mskRows = any(msk, 2);
rowMsk = mskRows & ~BWrows;

BW = BW0;
if any(rowMsk)
    fprintf(f,'Refining BW\n');
    BW(rowMsk, :) = msk(rowMsk, :);
    BW = imclose(BW, strel('disk', 50).Neighborhood);
    % TODO: Erode protrusions?
    BW = imdilate(BW, strel('disk', 10).Neighborhood);
end
fprintf(f,'Returning BW\n');
return;
%
% FGmask = improd;
% %FGmask = bwmorph(improd,'erode', 2);
%
% disp({sum(FGmask, "all"), sum(~msk, "all")});
% %BGmask = bwmorph(~improd, "dilate", 10);
% %FGmask = bwmorph(improd, 'erode', 20);
%
%
% BW = lazysnapping(Y2, L, FGmask, imcomplement(msk)...%L, msk, FGmask, ~BGmask...%, ...
%     ...%"Connectivity", 4, ...
%     ...%"MaximumIterations", 100
%     );
%
% % BW = activecontour(Y2, msk, 100, ... % Default: 100 iterations
% %     "Chan-vese", "SmoothFactor", 0, ... % Default: 0
% %     "ContractionBias", 0 ... % Default: 0
% %     );
% %BW = activecontour(Y2, msk, 100, ... % Default: 100 iterations
% %    "edge", "SmoothFactor", 1, ... % Default: 1
% %    "ContractionBias", 0.3 ... % Default: 0.3 (typically between [-1 1])
% %    );
end


% imshow(imimposemin(YP_8, imerode(YrP_8, strel('disk',50))))
% montage({YdA_8, imlincomb(0.5,YdA_8,0.5,YddA_8), YddA_8}, 'Size', [1 3])
% [gx,gy] = imgradientxy(imlincomb(0.5,YdA_8, 0.5,YddA_8)); montage({gx,gy});
% [gx,gy] = imgradientxy(imlincomb(0.5,im2double(YdA_8), 0.5,im2double(YddA_8),'double')); [gm, gd] = imgradient(gx,gy); montage({gx,gy,gm,gd});
% [gx,gy] = imgradientxy(imlincomb(0.5,im2double(YdA_8), 0.5,im2double(YddA_8),'double')); [gm, gd] = imgradient(gx,gy); montage({normalize(gx,"range"),normalize(gy,"range"),normalize(gm,"range"),normalize(gd,"range")});
% [gx,gy] = imgradientxy(imlincomb(0.5,im2double(YdA_8), 0.5,im2double(YddA_8),'double')); [gm, gd] = imgradient(gx,gy); montage({normalize(max(gx,0),"range"),normalize(max(gy,0),"range"),normalize(gm,"range"),normalize(gd,"range")});
% [gx,gy] = imgradientxy(imboxfilt(imlincomb(0.5,im2double(YdA_8), 0.5,im2double(YddA_8),'double'), [127 5])); [gm, gd] = imgradient(gx,gy); montage({gx,gy,gm,gd});
% imshow(bwconvhull(0<entropyfilt(YrP_8)))

% imshow(bwmorph(0<entropyfilt(YrP_8),"fatten", 50))

% iqr([0.5 0.75 0.85 1 1.5 2 2.5 3 3.5  5 9 10])




% sum([1 2 5 8 9 10]) \ [ cumsum([1 2 5 8 9 10]) ; flip(cumsum(flip([1 2 5 8 9 10], 2)),2)]

function TF = isacceptablemask(mskCount, numPixels)
% TODO: What defines acceptable values??
numPixels = single(numPixels);
TF = ((mskCount && (mskCount >= 0.001*numPixels))...%(mskCount >= max(1,0.001*numPixels)) ...
    && (mskCount < 0.5*numPixels));
end