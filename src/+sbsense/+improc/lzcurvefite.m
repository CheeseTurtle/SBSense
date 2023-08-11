function [p1,wres, p01,wps, hgt,wid, npks, predCurve, profCurve] = lzcurvefite(varargin) % lzcurvefite(p0, XDATA, YDATA, varargin)
if nargin >= 6
    [XDATA, YDATA0, YDATA, pks, locs, wids, scores] = varargin{:};
    XDATA = double(XDATA);
    YDATA0 = double(YDATA0);
    % locs = double(locs);
    % wids = double(wids);
    if isempty(pks)
        npks = 0;
        p1=[]; wres = []; hgt = NaN; wid = NaN; wps = []; p01 = [];
        return;
    else
        npks = length(pks);
    end
    maxPkHgt = 1.5*max(YDATA0, [], 'omitnan') + 0.5*mean(YDATA, 'all', 'omitnan');
elseif nargin==5
    [~,XDATA,YDATA0,YDATA,p01] = varargin{:};
    npks = 1;
    XDATA = double(XDATA);
    YDATA0 = double(YDATA0);
    YDATA = double(YDATA);
    maxPkHgt = 1.5*max(YDATA0, [], 'omitnan') + 0.5*mean(YDATA, 'all', 'omitnan');
else
    [p0, XDATA, YDATA0] = varargin{1:3};
    XDATA = double(XDATA);
    YDATA0 = double(YDATA0);
    if nargin < 4
        YDATA = smoothdata(YDATA0, 'lowess', 32, 'omitnan');
        maxPkHgt = 1.5*max(YDATA0, [], 'omitnan') + 0.5*mean(YDATA, 'all', 'omitnan');
    else
        YDATA = double(varargin{4});
        % TODO: Handle varargin to specify findpeaks params?
%         if (nargin > 4) && iscell(varargin{5}) % TODO: Just assume?
%             varargin = varargin{5}{:};
%         else
%             varargin(4) = [];
%         end
    end
    % TODO: Parameters relative to width of image?
    imwd = length(XDATA);
    maxPkHgt = 1.5*max(YDATA0, [], 'omitnan') + 0.5*mean(YDATA, 'all', 'omitnan');
    [pks, locs, wids, prms] = findpeaks(YDATA, XDATA, ...
        'SortStr', 'descend', 'WidthReference', 'halfheight', ...
        'MinPeakWidth', 1, 'MaxPeakWidth', imwd/4, 'MinPeakDistance', 10, ... % TODO: params relative to imwd
        'MinPeakHeight', eps, 'MinPeakProminence', 0.02); %, varargin{:});
    msk = pks > maxPkHgt;
    if isempty(pks) || all(msk)
        npks = 0;
        p1=[]; wres = []; hgt = NaN; wid = NaN; wps = []; p01 = [];
        return;
    else
        if any(msk)
            pks(msk) = []; locs(msk) = []; wids(msk) = []; prms(msk) = [];
        end
        npks = length(pks);
    end

    if ~isempty(p0) && ~anynan(p0) % TODO: simplify checking?
        lastLoc = p0(1);
        lastHgt = p0(3)/p0(2);
        lastWid = 2*p0(2);
        % scores = (locs - lastLoc).^3 + abs(wids-lastWid) + (hgts - lastHgt).^2;
        % [~,idx] = min(scores, [], 'omitnan');
        scores = 1 - 5\( ...
            3*normalize(abs(locs - lastLoc), 'range') ...
            + normalize(abs(wds - lastWid), 'range') ...
            + 2*normalize(abs(hgts - lastHgt), 'range') );
        % scores = scores .* (rescale(prms, 0, 0.5) + 0.5); % TODO: Determine best ratio / method
        scores = rescale(prms, 0, 0.85) + rescale(scores, 0, 0.15);
    else
        % scores = (prms.^2).*normalize(hgts, 'range');
        % [~,idx] = max(scores, [], 'omitnan');
        scores = (normalize(prms, 'range').^2) .* normalize(hgts, 'range');
    end
end


if nargin ~=5 
    if length(scores)==1
        x0 = locs;
        hgt = pks;
        wid = wids;
    else
        [~,idx] = max(scores, [], 'omitnan');
        x0 = locs(idx);
        hgt = pks(idx);
        wid = wids(idx);
    end

    b = wid/2;
    a = hgt*b;
    p01 = [x0 b a];
else
    x0 = p01(1); b = p01(2); a = p01(3);
    hgt = a/b; hwd = b; wid = 2*hwd;
end




predCurve = double(sbsense.lorentz(double(p01), double(XDATA)));
profCurve = 2\double(smoothdata(YDATA, 'loess', 'omitnan') + ...
        smoothdata(YDATA, 'gaussian', 'omitnan'));

maxY = max(YDATA, [], 'all', 'omitnan');
predDeriv = smoothdata([0 diff(predCurve)], 'gaussian');
profDifs = (profCurve - predCurve);
profDeriv = smoothdata([0 diff(profCurve)], 'gaussian');
derivDifs = (profDeriv - predDeriv);

wgts1 = 1 - normalize(abs(maxY\profDifs), 'range');
wgts2 = 1 - normalize(2*abs(derivDifs)./(abs(predDeriv)+abs(profDeriv)), 'range');
wgts3msk0 = (YDATA0 < 0);
wgts3msk1 = (bwmorph(bwmorph(wgts3msk0, 'bridge'), 'fatten', 32));
wgts3 = double(wgts3msk1);
wgts3 = (1 - wgts3) + (sign(predCurve)==sign(YDATA));
wgts0 = (0.5*wgts1 + 0.5*wgts2);
wgts = wgts0 .* (0.01 + (~wgts3msk1.*((predCurve/hgt).^16).*(sign(predCurve)==sign(YDATA))) + 0.2*(wgts3.*(predCurve/hgt).^16));
idxs = [max(1,fix(x0 - 2\wid)),min(length(wgts3),ceil(x0 + 2\wid))];
wgts4 = false(size(wgts3));
wgts4(idxs(1):idxs(2)) = true;
if ~all(wgts4) && any(wgts4)
    wgts = (0.15 + 0.85*wgts4) .* wgts;
end


for attempts=1:8
    [p1, wres] = nlinfit(XDATA, YDATA0, @sbsense.lorentz, ...
         p01, 'Weights', eps+wgts); % TODO: fit param bounds??
    if ~bitand(attempts,8) && (isempty(p1) || ((p1(3) / p1(2)) > maxPkHgt))
        wgts = 0.25 + 2\wgts;
    else
        break;
    end
end

wps = vertcat(predCurve,profCurve,predDeriv,profDifs,profDeriv,derivDifs,wgts1,wgts2,wgts3,wgts0,wgts);
% TODO: Try alternative peaks if resnorm (= sum(wres.^2)) is too large?
end
