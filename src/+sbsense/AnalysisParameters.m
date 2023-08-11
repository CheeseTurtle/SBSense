classdef AnalysisParameters < handle & matlab.mixin.SetGetExactNames
properties(GetAccess=public, SetAccess=public)
    ChBoundsPositions (:,2) uint16;
    ChHeights (:,1) uint16;
    ChDivHeights (:,1) uint16;

    PSZLocations uint16;
    PSZWidth uint16;
end

properties(GetAccess=public, SetAccess=private)
    EffectiveWidth (1,1) uint16;
    
    EffectiveHeight (1,1) uint16;
    ChVertIdxs (1,:) cell;

    ScaledEffectiveHeight (1,1);
    ScaledChVertIdxs (1,:) cell;

    ScaledChBoundsPositions (:,2) uint16;
    ScaledChDivPositions (:,2) uint16;

    RefImg (:,:);
    RefImgScaled (:,:);

    CropRectangle images.spatialref.Rectangle;

    dpIdx0 (1,1) uint64 = 0;
end

properties(GetAccess=private,SetAccess=immutable)
    NotifyFcn;
end

properties(GetAccess=public,SetAccess=public)
    ParamHistories double; % [lastparams lastdp dps] (param#, var#, chan#+1)
    LastPSB;
    LastChFitProfiles;
end
    

properties(GetAccess=public, SetAccess=private)
    fdm (1,2);
end

properties(SetAccess=public,SetObservable,AbortSet)
    NumChannels (1,1) uint8 = 1;
    AnalysisScale (1,1) double = 1;
end

properties(GetAccess=public,SetAccess=public, Dependent)
    YCropLBound (1,1) uint16; YCropUBound (1,1) uint16;
    YCropBounds (1,2) uint16;
    ChDivPositions (1,:) uint16;
    fdf (1,2);
end

methods
    function obj = AnalysisParameters(notifyFcn, analysisScale) %(fdm, notifyFcn)
        % obj.fdm = fdm;
        obj.NotifyFcn = notifyFcn;
        obj.AnalysisScale = analysisScale;
        %addlistener(obj, {'YCropLBound', 'YCropUBound', 'YCropBounds', 'NumChannels'}, ...
        %    'PostSet', @obj.postset_heightvar);
        addlistener(obj, 'AnalysisScale', 'PostSet', @obj.postset_AnalysisScale);
    end

    function initialize(obj,  dpIdx0, chBoundsPositions, chHeights, chDivHeights, ...
            BGimg, numChannels, analysisScale)
        arguments(Input)
            obj; dpIdx0; chBoundsPositions; chHeights; chDivHeights; BGimg = []; numChannels = 1; analysisScale = 1;
        end
        fprintf('[AnalysisParams:initialize]\n');
        obj.ChBoundsPositions = chBoundsPositions;
        obj.ChHeights = chHeights;
        obj.ChDivHeights = chDivHeights;
        obj.dpIdx0 = dpIdx0;

        obj.PSZLocations = zeros(2, obj.NumChannels, 'uint16'); %NaN(2, obj.NumChannels); %uint16.empty(0,obj.NumChannels);
        if ~isequal(size(obj.PSZLocations), [2 obj.NumChannels])
            fprintf('[AnalysisParameters:initialize] Size of PSZLocations is potentially not correct.\n');
            disp(obj.PSZLocations);
        end

        if ~isempty(BGimg)
            if isequal(BGimg, false)
                obj.RefImg = [];
                obj.RefImgScaled = [];
                obj.CropRectangle = images.spatialref.Rectangle.empty();
            else
                obj.RefImg = BGimg;
                obj.fdm = size(BGimg);
                obj.EffectiveWidth = obj.fdm(2);
                if isempty(obj.ChBoundsPositions)
                    obj.EffectiveHeight = obj.fdm(1);
                    obj.CropRectangle = images.spatialref.Rectangle(...
                    [1 obj.EffectiveWidth],  [1 obj.fdm(1)]);
                else
                    obj.EffectiveHeight = diff(obj.ChBoundsPositions([1 end],1)') - 1;
                    obj.CropRectangle = images.spatialref.Rectangle(...
                        [1 obj.EffectiveWidth], ... % XLimits
                        double(obj.ChBoundsPositions([1 end],1)') + [1 -1]); % YLimits
                end
                obj.ScaledEffectiveHeight = fix(analysisScale*obj.EffectiveHeight);
                obj.RefImgScaled = imresize( ...
                    imcrop(BGimg, obj.CropRectangle), ...
                    [obj.EffectiveWidth obj.ScaledEffectiveHeight], ...
                    "lanczos3");
            end
        end
            
        if ~isempty(numChannels)
            if isequal(numChannels,false)
                obj.NumChannels = 1;
            else
                obj.NumChannels = numChannels;
            end
            % TODO: Calculate!!!!
            obj.ChBoundsPositions = zeros(obj.NumChannels+1,2);
            % obj.ChannelVertIdxs = cell(1,obj.NumChannels);
            obj.ChHeights = zeros(1,obj.NumChannels);
            % initialize(obj, 0, analysisScale);
        end
    end

    function prepare(obj, dpIdx0, varargin) % varargin: analysisScale
        fprintf('[AnalysisParams:prepare]\n');
        obj.ParamHistories = [];
        obj.LastPSB = uint16.empty(0,2);
        obj.LastChFitProfiles = double.empty(0,obj.NumChannels);
        obj.dpIdx0 = dpIdx0;

        obj.PSZWidth = bitset(fix(64\obj.EffectiveWidth), 1);
        
        if (nargin > 2) % && (varargin{1} ~= obj.AnalysisScale) % TODO
            obj.AnalysisScale = varargin{1};
            obj.ScaledEffectiveHeight = obj.AnalysisScale*obj.EffectiveHeight;
            % display(obj.CropRectangle);
            if ~isempty(obj.RefImg) && obj.EffectiveWidth
                obj.RefImgScaled = imresize( ...
                    imcrop(obj.RefImg, obj.CropRectangle), ...
                    [obj.ScaledEffectiveHeight obj.EffectiveWidth], ...
                    "lanczos3");
            end
        end
        % TODO: Move to "initialize" function
        % 1) Calculate scaled ch div positions
        obj.ScaledChDivPositions = uint16( ...
            fix(obj.AnalysisScale*(obj.ChBoundsPositions(2:end-1,:) ...
            - obj.CropRectangle.YLimits(1)))+1);
        obj.ScaledChBoundsPositions = vertcat( ...
            [0 0], obj.ScaledChDivPositions, repelem(obj.ScaledEffectiveHeight+1,1,2));
        
        % 2) Calculate (scaled) vert idxs
        obj.ChVertIdxs = cell(1,obj.NumChannels);
        obj.ScaledChVertIdxs = obj.ChVertIdxs;
        for ch=1:obj.NumChannels
            obj.ChVertIdxs{ch} = ...
                (obj.ChBoundsPositions(ch,2)+1) ...
                : 1 : (obj.ChBoundsPositions(ch+1,1)-1);
            obj.ScaledChVertIdxs{ch} = ...
                (obj.ScaledChBoundsPositions(ch,2)+1) ...
                : 1 : (obj.ScaledChBoundsPositions(ch+1,1)-1);
        end
    end

    function prepareReanalysis(obj, varargin)
        obj.ParamHistories = [];
        obj.LastPSB = uint16.empty(0,2);
        obj.LastChFitProfiles = double.empty(0,obj.NumChannels);

        % obj.PSZWidth = bitset(fix(64\obj.EffectiveWidth), 1);
        if (nargin > 1) && (varargin{1} ~= obj.AnalysisScale) % ??
            obj.AnalysisScale = varargin{1};
            obj.ScaledEffectiveHeight = obj.AnalysisScale*obj.EffectiveHeight;
            % display(obj.CropRectangle);
            if ~isempty(obj.RefImg) && obj.EffectiveWidth
                obj.RefImgScaled = imresize( ...
                    imcrop(obj.RefImg, obj.CropRectangle), ...
                    [obj.ScaledEffectiveHeight obj.EffectiveWidth], ...
                    "lanczos3");
            end
        end
    end

    function value = get.YCropLBound(obj)
        value = obj.ChBoundsPositions(1,1);
    end
    function value = get.YCropUBound(obj)
        value = obj.ChBoundsPositions(obj.NumChannels+1,1);
    end
    function value = get.YCropBounds(obj)
        value = obj.ChBoundsPositions([1 obj.NumChannels+1],1)';
    end
    function set.YCropLBound(obj,value)
        obj.ChBoundsPosiitons(1,:) = value;
        obj.ChHeights(1) = obj.ChBoundsPositions(2,1) - 1 - value;
    end
    function set.YCropUBound(obj,value)
        obj.ChBoundsPositions(obj.NumChannels+1,:) = value;
        obj.ChHeights(obj.NumChannels) = value - 1 - obj.ChBoundsPositions(obj.NumChannels,2);
    end
    function set.YCropBounds(obj,value)
        obj.ChBoundsPositions([1 obj.NumChannels+1],:) = repmat(value',1,2);
        obj.ChHeights([1 obj.NumChannels],:) = [ ...
            obj.ChBoundsPositions(2,1) - value(1), ...
            value(2) - obj.ChBoundsPositions(obj.NumChannels,1) ...
            ] - 1;
    end

    function value = get.ChDivPositions(obj)
        value = obj.ChBoundsPositions(2:obj.NumChannels,:);
    end
    function set.ChDivPositions(obj,value)
        obj.ChBoundsPositions(2:obj.NumChannels,:) = value;
        obj.ChHeights = diff(fliplr( ...
            reshape( obj.ChBoundsPositions(2:end-1), [], 2)), ...
            1, 1) - 1;
        % obj.ChHeights = diff(obj.ChBoundsPositions) - 1;
    end

    function value = get.fdf(obj)
        value = fliplr(obj.fdm);
    end
    function set.fdf(obj, value)
        obj.fdm = fliplr(value);
    end
end

% methods(Access=protected)
%     function postset_AnalysisScale(obj, src, event)
%         % TODO: Compare previous and new values?
%         % TODO: Copy from other file
%     end
% 
%     function postset_heightvar(obj, src, event)
%         if src.Name=="NumChannels"
%             % Update channel nominal height
%         else
%             % Update effective height
%         end
%         % TODO
%         % Overwrite ChBounds (redistribute channels)
%         % Call notify fcn to tell GUI to move ROIs 
%         % and recalculate their DrawingAreas.
%         obj.NotifyFcn(); % Set pos and area in same statement?
%         % TODO: Write event fcn
%     end
% end

end