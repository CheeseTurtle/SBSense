function I = insertIndexNumber(I, index, opts)
%INSERTINDEXNUMBER Summary of this function goes here
%   Detailed explanation goes here
arguments(Input)
    I (:,:) {mustBeNumeric};
    index (1,1) uint64;
    opts.Position (1,:) char {mustBeTextScalar, mustBeMember(opts.Position, ...
        ["LeftTop", "LeftCenter", "LeftBottom", "CenterTop", "Center", "CenterBottom", "RightTop", "RightCenter", "RightBottom"])} = "LeftTop";
    opts.TextboxColor = "black";
    opts.FontColor = [];
    opts.BoxOpacity (1,1) single {mustBeLessThanOrEqual(opts.BoxOpacity, 1), mustBeNonnegative} = 0.6;
end

sz = fliplr(size(I, [1 2]));
fsz = min(200, max(1, fix((3/4)*(0.1*min(sz))))); % Font size in points (1pt = 4/3 px)

switch opts.Position(1)
    case 'L' % LeftTop, LeftCenter, LeftBottom
        switch opts.Position(5)
            case 'T' % LeftTop
                boxPos = [0 0];
            case 'C' % LeftCenter
                boxPos = [0 sz(2)/2];
            case 'B' % LeftBottom
                boxPos = [0 sz(2)];
        end
    case 'C'
        switch length(opts.Position)
            case 6 % Center
                boxPos = sz./2;
            case 9 % CenterTop
                boxPos = [sz(1)/2 0];
            otherwise % CenterBottom
                boxPos = [sz(1)/2 sz(2)];
        end
    case 'R'
        switch opts.Position(5)
            case 'T' % RightTop
                boxPos = [sz(1) 0];
            case 'C' % RightCenter
                boxPos = [sz(1) sz(2)/2];
            case 'B' % RightBottom
                boxPos = sz;
        end
end

if isempty(opts.FontColor)
    maxValue = max(I, [], 'all', 'omitnan');
    opts.FontColor = [maxValue maxValue maxValue];
    if isinteger(I)
        opts.FontColor = opts.FontColor ./ intmax(class(I));
    end
end

I = insertText(I, boxPos, index, 'AnchorPoint', opts.Position, ...
    "FontSize", fsz, "FontColor", opts.FontColor, ...
    "TextBoxColor", opts.TextboxColor, "BoxOpacity", opts.BoxOpacity);
if(~ismatrix(I))
    I = squeeze(I(:,:,1));
end
end

