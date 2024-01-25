function [lims, sliEnab] = clampDomain(timeZero, axisModeIndex, zoomModeOn, ...
    rightmostPos, minDomWd, lims)

import sbsense.utils.fdt;

fprintf('[clampDomain] >>> ARGS: ami/zm=%d/%d, rmp=%s, minDomWd=%s, lims=%s\n', ...
    axisModeIndex, zoomModeOn, fdt(rightmostPos), fdt(minDomWd), fdt(lims));
    
lims0 = lims;

switch axisModeIndex
    case 1 % Index mode
        if lims(1) >= rightmostPos
            if rightmostPos >= diff(lims)
                lims(1) = rightmostPos + 1 - diff(lims); % TODO: +1?
            else
                lims(1) = 1;
            end
        elseif lims(1) < 1
            lims(1) = 1;
        end
    case 2
        if lims(1) >= rightmostPos
            lims(1) = max(timeZero, lims(2) - diff(lims));
        elseif lims(1) < timeZero
            lims(1) = timeZero;
        end
    case 3
        if lims(1) >= rightmostPos
            lims(1) = max(seconds(0), lims(2) - diff(lims));
        elseif lims(1) < seconds(0)
            lims(1) = seconds(0);
        end
    otherwise
        if (nargout > 1)
            sliEnab = logical.empty(); % TODO?
        end
        return;
end

if (lims(2) > rightmostPos)
    lims(2) = rightmostPos;
    sliEnab = false;
elseif (nargout > 1)
    if lims(2) <= rightmostPos
        sliEnab = false;
    else
        sliEnab = true;
    end
end

domWd = (lims(2) - lims(1));
if domWd < minDomWd
    lims(2) = lims(1) + minDomWd;
    sliEnab = false;
elseif (domWd==minDomWd) && (nargout > 1) && sliEnab
    %if (domWd <= minDomWd)
        sliEnab = false;
    %else
    %    sliEnab = true;
    %end
end

% if bitget(axisModeIndex,2) % Abs or rel time
%     absTimeMode = ~bitget(axisModeIndex, 1);
%     % if zoomModeOn % ZOOM MODE
%     % else % PAN MODE
%     % end
% else % Index mode
% end

if isequal(lims0, lims)
    fprintf('[clampDomain] <<< [%s] --> (no change)\n', ...
        erase(strrep(strip(formattedDisplayText(lims0)), '  ', ' '), newline));
else
    fprintf('[clampDomain] <<< [%s] --> [%s]\n', ...
        erase(strrep(strip(formattedDisplayText(lims0)), '  ', ' '), newline), ...
        erase(strrep(strip(formattedDisplayText(lims)), '  ', ' '), newline));
end
end