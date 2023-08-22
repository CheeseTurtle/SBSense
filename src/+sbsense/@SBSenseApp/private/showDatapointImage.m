function TF = showDatapointImage(app, varargin)
if (nargin~=1)
    idx = varargin{1};
    if islogical(varargin{1})
        assumeChanged = idx;
        idx = app.SelectedIndex;
        idxIsImages = false;
        numIdx = idx;
    elseif iscell(varargin{1})
        numIdx = app.SelectedIndex;
        idxIsImages = true;
        assumeChanged = true;
    else
        assumeChanged = true;
        idxIsImages = false;
        numIdx = idx;
    end
else
    idx = app.SelectedIndex;
    assumeChanged = true;
    idxIsImages = false;
    numIdx = idx;
end




% TODO: Wrap all of this in try/catch

if ~idxIsImages && ~numIdx
    app.dataimg.CData = [];
    TF = true;
    return;
    % TODO: Show BG instead?
end

if ~idxIsImages && (app.SelectedIndex == numIdx) && (numIdx > 0)
    idx = app.SelectedIndexImages;
    idxIsImages = true;
end

if idxIsImages && isempty(idx)
    TF = false;
    return;
end

% TF = false;
if ~isobject(app.ImageStore)
    TF = false;
    return;
end
try
    if startsWith(app.DataImageDropdown.Value, 'Y1')
        % img = app.Composites{idx};
        if idxIsImages
            img = idx{1};
            assert(~isempty(img));
        else
            try
                img = readimage(app.ImageStore.UnderlyingDatastores{1}, double(idx));
                % disp(size(img));
                assert(~isequal(size(img), [1 1]));
            catch ME0
                if strcmp(ME0.identifier, "MATLAB:ImageDatastore:notLessEqual")
                    TF = logical.empty();
                    return;
                else
                    fprintf('Error occurred given index: %s\n', strtrim(formattedDisplayText(idx, 'SuppressMarkup', true)));
                    rethrow(ME0);
                end
            end
        end
        if isempty(img) || all(isnan(img), 'all')
            TF = logical.empty();
            return;
        end
        set(app.dataimg, 'YData', [1 size(img, 1)]);
    elseif startsWith(app.DataImageDropdown.Value, 'Yc')
        % img = app.Ycs{idx};
        % img = imcomplement(readimage(app.ImageStore.UnderlyingDatastores{2}, double(idx)));
        if idxIsImages
            img = idx{2};
            assert(~isempty(img));
        else
            img = readimage(app.ImageStore.UnderlyingDatastores{2}, double(idx));
            % disp(size(img));
            assert(~isequal(size(img), [1 1]));
        end
        set(app.dataimg, 'YData', double(app.AnalysisParams.YCropBounds) + [1 -1]);
    elseif startsWith(app.DataImageDropdown.Value, 'Yr')
        % img = app.Yrs{idx};
         if idxIsImages
            img = idx{3};
            assert(~isempty(img));
        else
            img = readimage(app.ImageStore.UnderlyingDatastores{3}, double(idx));
            % disp(size(img));
            assert(~isequal(size(img), [1 1]));
         end
        set(app.dataimg, 'YData', double(app.AnalysisParams.YCropBounds) + [1 -1]);
    elseif startsWith(app.DataImageDropdown.Value, 'Y0')
        img = app.AnalysisParams.RefImgScaled;
        set(app.dataimg, 'YData', double(app.AnalysisParams.YCropBounds) + [1 -1]);
        % assert(~isequal(size(img), [1 1]));
    else
        fprintf('Unknown DataImageDropdown value "%s".\n', app.DataImageDropdown.Value);
        TF = false;
        return;
    end
    app.dataimg.CData = img;

    %if xor(app.DI_ShowChannelsToggleMenu.Checked, ...
    %    app.overimg.Visible)
    %    app.overimg.Visible = app.DI_ShowChannelsToggleMenu.Checked;
    %end
catch ME
    fprintf('[showDatapointImage] Error "%s" encountered while parsing dropdown value: %s\n', ME.identifier, getReport(ME));
    if startsWith(app.DataImageDropdown.Value, 'Y1')
        TF = logical.empty();
    else
        TF = false;
    end
    app.dataimg.CData = [];
    return;
end


TF = true;

persistent co;
% try
if app.DI_ShowMaskToggleMenu.Checked
    if ~assumeChanged
        try
%             mskCfg = logical([ app.DI_ShowMask1ToggleMenu.Checked ...
%                 app.DI_ShowMask2ToggleMenu.Checked ...
%                 app.DI_ShowMask3ToggleMenu.Checked ]);
            assumeChanged = ~isequal(app.maskimg.UserData, logical([ app.DI_ShowMask1ToggleMenu.Checked ...
                app.DI_ShowMask2ToggleMenu.Checked ...
                app.DI_ShowMask3ToggleMenu.Checked ]));
        catch ME
            % TODO
            fprintf('[showDatapointImage] Error occurred while determining if mskCfg changed: %s\n', getReport(ME));
            assumeChanged = true;
        end
    end

    % TODO: Replace with toggle options menu
    % TODO: Also call this when DD value changes
    if assumeChanged
        try
            if isempty(co)
                co = colororder(app.UIFigure);
            end

            wd = size(img,2);
            
            mskCfg = logical([ app.DI_ShowMask1ToggleMenu.Checked ...
                app.DI_ShowMask2ToggleMenu.Checked ...
                app.DI_ShowMask3ToggleMenu.Checked ]);

            if any(bitand(mskCfg, [true false false]))
%                 % disp({size(img), size(app.ROIMasks{idx,1})});
%                 img = im2double(app.ROIMasks{idx,1});
%                 % img(~app.ROIMasks{idx,1}) = NaN;
% 
%                 msks = app.ROIMasks(idx,2:end);
                msks = app.ROIMasks(numIdx,:);
                for ch = uint8(1:app.NumChannels)
                    if isempty(msks{ch})
                        msks{ch} = false(app.ChannelHeights(ch),wd,'logical');
                    end
                    % msks{ch} = ch*uint8(msks{ch});
                    %if ch > 1
                        msks{ch} = vertcat( ...
                            ch*uint8(msks{ch}), ...
                            zeros(app.AnalysisParams.ChDivHeights(ch),wd,'uint8')); %, ...
                    %else
                    %    msks{ch} = ch*uint8(msks{ch});
                    %end
                end
                % disp({size(img), size(vertcat(msks{:}))});
                % img = labeloverlay(img, vertcat(msks{:}), 'Colormap', co);
            elseif any(bitand(mskCfg, [false true false])) %mskCfg(2) % contains(app.DataImageDropdown.Value, '+')
%                 % disp({size(app.SampMasks{idx,1}), size(img)});
%                 % img = labeloverlay(img, app.SampMasks{idx,1}, 'Color', 'white');
%                 img = im2double(app.SampMasks{idx,1});
%                 img(~app.SampMasks{idx,1}) = NaN;
%                 msks = app.SampMasks(idx,2:end);
                msks = app.SampMasks(numIdx,:);
                for ch = uint8(1:app.NumChannels)
                    % msks{ch} = ch*uint8(msks{ch});
                    if isempty(msks{ch})
                        msks{ch} = false(app.ChannelHeights(ch),wd,'logical');
                    end
                    %if ch > 1
                        msks{ch} = vertcat( ...
                            ch*uint8(msks{ch}), ...
                            zeros(app.AnalysisParams.ChDivHeights(ch),wd,'uint8')); % , ...);
                    %else
                    %    msks{ch} = ch*uint8(msks{ch});
                    %end
                end
                % disp({size(vertcat(msks{:})), size(img)});
%                 img = labeloverlay(img, vertcat(msks{:}), 'Colormap', co);
%                 %for ch = 1:app.NumChannels
%                 %    img = labeloverlay(img, app.SampMasks{idx,ch+1}, 'Colormap', co(ch,:));
%                 %end
            elseif any(bitand(mskCfg, [false false true])) %(mskCfg(3)) % contains(app.DataImageDropdown.Value, '-')
                % disp({size(app.SampMask0s{idx,1}), size(img)});
%                 % img = labeloverlay(img, app.SampMask0s{idx,1}, 'Color', 'white');
%                 img = im2double(app.SampMask0s{idx,1});
%                 img(~app.SampMask0s{idx,1}) = NaN;
%                 msks = app.SampMask0s(idx,2:end);
                msks = app.SampMask0s(numIdx,:);
                for ch = uint8(1:app.NumChannels)
                    if isempty(msks{ch})
                        msks{ch} = false(app.ChannelHeights(ch),wd,'logical');
                    end
                    % msks{ch} = ch*uint8(msks{ch});
                    %if ch > 1
                        msks{ch} = vertcat( ...
                            ch*uint8(msks{ch}), ...
                            zeros(app.AnalysisParams.ChDivHeights(ch),wd,'uint8')); % , ...);
                    %else
                    %    msks{ch} = ch*uint8(msks{ch});
                    %end
                end
                % disp({size(vertcat(msks{:})), size(img)});
%                 img = labeloverlay(img, vertcat(msks{:}), 'Colormap', co);
%                 %for ch = 1:app.NumChannels
%                 %    img = labeloverlay(img, app.SampMask0s{idx,ch+1}, 'Colormap', co(ch,:));
%                 %end
            else
                img = double.empty();
                adata = img;
            end
            if ~isempty(img)
                img(:) = 0;
                msks = vertcat(msks{:});
                if isequal(size(img,1), size(msks,1))
                    img = labeloverlay(img, msks, 'Colormap', co);
                    ys = true(size(img,1));
                else
                    ys = (app.AnalysisParams.YCropBounds(1) + 1):(app.AnalysisParams.YCropBounds(2)-1);
                    img(ys,:) = labeloverlay(img(ys,:), msks, 'Colormap', co);
                end

                adata = any(img~=0,3) * 0.6;
            end
            set(app.maskimg, 'CData', im2double(img), 'Visible', true, ...
                'UserData', mskCfg, 'AlphaData', adata); %, 'XData', [1 size(img, 2)], 'YData', [1 size(img,1)]);
        catch ME
            fprintf('[showDatapointImage] Error "%s" encountered while compositing image and 0 or more overlay(s): %s\n', ME.identifier, getReport(ME));
            TF = false;
            if iscell(msks)
                fprintf('Size of vertcat(msks{:}), size of img(ys,:):\n');
                disp([size(vertcat(msks{:})) ; size(img(ys,:))]);
            else
                fprintf('Size of vertcat(msks), size of img(ys,:):\n');
                disp([size(msks) ; size(img(ys,:))]);
            end
        end
    else
        app.maskimg.Visible = true;
    end
elseif app.maskimg.Visible
    app.maskimg.Visible = false;
end

try
    bringToFront(app.leftPSBLine);
    bringToFront(app.rightPSBLine);
catch ME
    % TODO
    fprintf('[showDatapointImage] Error occurred while loading/displaying image(s): %s\n', getReport(ME));
end
end