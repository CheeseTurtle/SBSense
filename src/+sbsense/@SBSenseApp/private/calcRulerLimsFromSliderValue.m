function [rulerLims, value, newSliVal] = calcRulerLimsFromSliderValue(timeZero, ...
    axisModeIndex, zoomModeOn, minDomWd, rightmostPos, rulerLims0, value, TF)

import sbsense.utils.fdt;

fprintf('[calcRuLimsFromSliVal] >>> ARGS: ami/zm=%d/%d, minDWd=%s, rmp=%s, ruLims0=%s, val=%g\n', ...
    axisModeIndex, zoomModeOn, fdt(minDomWd), fdt(rightmostPos), fdt(rulerLims0), fdt(value));

timeMode = bitget(axisModeIndex, 2);
value0 = value;

if zoomModeOn % ZOOM MODE
    currSpan = diff(rulerLims0);
    % currCenter = mean(rulerLims0);
    if timeMode
        %dw = value - seconds(currSpan); % Convert duration to numeric value
        %dw2 = 2\seconds(dw2);
        value = seconds(value); % Convert numeric value to duration
        % else
        %     dw = value - currSpan;
        %     dw2 = 2\dw;
        %     dw2f = fix(dw2);
    else
        rulerLims0 = double(rulerLims0);
        currSpan = double(currSpan);
    end
    %if class(currSpan) ~= class(value)
    %    % keyboard;
    %end
    dw = value - currSpan; % <requested width> - <current width>
    dw2 = 2\dw;

    switch axisModeIndex
        case 1
            llim = double(1);
        case 2
            llim = timeZero;
            rulerLims0.Format = 'MM/dd HH:mm:ss.SSSSSS';
        case 3
            llim = seconds(0);
            rulerLims0.Format = 's';
        otherwise
            error('Unknown axis mode index.'); % llim = 0;
    end

    if (dw > 0) && ~(llim <= (rulerLims0(1)-dw2))
        % Positive (growing), and need to distribute change asymmetrically
        newLeft = llim; %max(llim, rulerLims0(1)-dw2);
        dwLeft = newLeft - rulerLims0(1);
        dwRight = dw - dwLeft;
        newRight = rulerLims0(2) + dwRight;
        if newRight > (rightmostPos + llim)
            newRight = rightmostPos + llim;
            newLeft = max(llim, newRight - currSpan);
        end
        if ~bitget(axisModeIndex, 1) % absolute time
            fprintf('[calcRuLimsFromSliVal] (rulerLims0(1)-dw2)=%s >= llim=%s,\n\tdwRight = %s = (dw - dwLeft) = (%s - %s),\n\t[%s,%s]->[%s,%s]\n', ...
                    string(rulerLims0(1)-dw2, 's'), ...
                    string(llim, 'HH:mm:ss.SSS'), string(dwRight, 's'), ...
                    string(dw, 's'), string(dwLeft, 's'), ...
                    string(rulerLims0(1), 'HH:mm:ss.SSS'), ...
                    string(rulerLims0(2), 'HH:mm:ss.SSS'), ...
                    string(newLeft, 'HH:mm:ss.SSS'), ...
                    string(newRight, 'HH:mm:ss.SSS'));
        elseif bitget(axisModeIndex, 2) % relative time
            fprintf('[calcRuLimsFromSliVal] (rulerLims0(1)-dw2)=%s >= llim=%s,\n\tdwRight = %s = (dw - dwLeft) = (%s - %s),\n\t[%s,%s]->[%s,%s]\n', ...
                    string(rulerLims0(1)-dw2, 's'), ...
                    string(llim, 'hh:mm:ss.SSS'), string(dwRight, 's'), ...
                    string(dw, 's'), string(dwLeft, 's'), ...
                    string(rulerLims0(1), 'hh:mm:ss.SSS'), ...
                    string(rulerLims0(2), 'hh:mm:ss.SSS'), ...
                    string(newLeft, 'hh:mm:ss.SSS'), ...
                    string(newRight, 'hh:mm:ss.SSS'));
        else % index mode
            fprintf('[calcRuLimsFromSliVal] (rulerLims0(1)-dw2)=%g >= llim=%g,\n\tdwRight = %g = (dw - dwLeft) = (%g - %g),\n\t[%g,%g]->[%g,%g]\n', ...
                    rulerLims0(1)-dw2, llim, dwRight, ...
                    dw, dwLeft, rulerLims0(1), rulerLims0(2), ...
                    newLeft, newRight);
        end
        rulerLims = [newLeft newRight];
    else % Negative, or not too far left to need uneven distribution
        rulerLims = rulerLims0 + [-dw2, dw2];
    end
    if ~timeMode
        rulerLims = uint64(rulerLims);
    end
    newSliVal = [];
else % PAN MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if timeMode % Relative or absolute
        if bitget(axisModeIndex,1) % Relative time
            newLeft = seconds(value);
            newRight = newLeft + diff(rulerLims0);
            if TF
                rulerLims0.Format = 's';
                if rightmostPos < newRight
                    newLeft = max(seconds(0), newLeft - (newRight - rightmostPos));
                    newSliVal = seconds(newLeft);
                else
                    newSliVal = [];
                end
            end % No second output arg if TF is false
            rulerLims = [newLeft newRight];
        else % Absolute time
            rulerLims0.Format = 'MM/dd HH:mm:ss.SSSS';
            span = diff(rulerLims0);
            newLeft = seconds(value) + timeZero;
            newRight = newLeft + span;
            if TF && ((newRight) > rightmostPos)
                dw = newRight - rightmostPos;
                if (rightmostPos - span) > timeZero
                    rulerLims = [newLeft newRight] - dw;
                    newSliVal = rulerLims(1);
                else
                    rulerLims = [timeZero rightmostPos];
                    if (rightmostPos - span) == timeZero
                        newSliVal = 0;
                    else
                        newSliVal = [];
                    end
                end
            else
                rulerLims = [newLeft newRight];
                newSliVal = [];
            end
        end
    else % Index mode
        span = diff(rulerLims0);
        newLeft = uint64(value);
        % rulerLims = newLeft + [0 diff(rulerLims0)];
        newRight = newLeft + span;
        if TF && (newRight > rightmostPos)
            if rightmostPos <= span
                rulerLims = [1 rightmostPos];
                newSliVal = double(1);
            else
                rulerLims = [(newLeft - (newRight - rightmostPos)), rightmostPos];
                newSliVal = double(rulerLims(1));
            end
        else
            rulerLims = [newLeft newRight];
            newSliVal = [];
        end        
    end
    % if timeMode % Absolute or relative time
    %     if bitget(axisModeIndex,1) % Relative time
    %         llim = seconds(0); % duration
    %         dx = seconds(value) - rulerLims0(1);  % duration
    %         rulerLims0.Format = 's';
    %     else % Absolute time
    %         llim = timeZero; % Datetime
    %         dx = seconds(value) - (rulerLims0(1)-timeZero); % Duration
    %         rulerLims0.Format = 'MM/dd HH:mm:ss.SSSS';
    %     end
    % else % Index mode
    %     llim = double(1);
    %     rulerLims0 = double(rulerLims0);
    %     dx = double(value) - double(rulerLims0(1));
    % end
    % newLeft = floor(max(llim, rulerLims0(1) + dx));
    % % dxLeft =  newLeft - rulerLims0(1);
    % % dxRight = 2*dx - dxLeft; % = dx + (dx - dxLeft)
    % % rulerLims = [newLeft, rulerLims0(2)+dxRight];
    % newRight = floor(max(newLeft+minDomWd, min(rightmostPos, rulerLims0(2) + dx)));
    % rulerLims = [newLeft, newRight];
end
%if ~timeMode
%    rulerLims = uint64(rulerLims);
if timeMode
    if bitget(axisModeIndex, 1) % Relative
        rulerLims.Format = 's';
    else % Absolute
        rulerLims.Format = 'MM/dd HH:mm:ss.SSSS';
    end
end

fprintf('[calcRuLimsFromSliVal] <<< (val=%g) %s --> %s\n', ...
    value0, fdt(rulerLims0), fdt(rulerLims));

% if rulerLims(2) > rightmostPos
%     rulerLims(2) = rightmostPos;
% end
% if rulerLims(1) >= rulerLims(2)
%     if bitget(axisModeIndex, 2) % time mode
%         if bitget(axisModeIndex, 1) % relative
%             rulerLims(1) = seconds(0);
%         else % absolute
%             rulerLims(1) = timeZero; % TODO: Handle NaN??
%         end
%     else % index mode
%         rulerLims(1) = 1;
%     end
%     if rulerLims(1) >= rulerLims(2)
%         rulerLims(2) = rulerLims(1) + minDomWd;
%     end
% end

end