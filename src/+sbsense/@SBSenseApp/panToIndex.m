function panToIndex(app, minBuffRU, varargin)
    if bitget(nargin,2)
        idx = varargin{1};
        if isempty(idx)
            idx = app.SelectedIndex;
        elseif idx > app.LargestIndexReceived
            return;
        end
        if bitget(nargin,1) % There is a third argument
            moveMode = varargin{2}; 
                % x0=detect, x1=left, x2=jump/center, x3=right
        else
            moveMode = 0;
        end
    else
        idx = app.SelectedIndex;
        moveMode = 0;
    end
    if ~idx || isempty(app.DataTable{1})
        return;
    end
    % if ~issortedrows(app.DataTable{1}, 'Index')
    %     app.DataTable{1} = sortrows(app.DataTable{1}, 'Index');
    % end

    ru = app.XResUnitVals{app.XAxisModeIndex,2};
    span = diff(app.HgtAxes.XLim);
    minBuff = minBuffRU * ru;

    if bitget(app.XAxisModeIndex,2) % Abs or rel time
        if idx==app.DataTable{1}.Index(idx) % TODO: Also reference DT2 and/or correct discrepancies in table contents?
            pos = app.DataTable{1}.RelTime(idx);
        else
            idxIdx = find(app.DataTable{1}.Index==idx, 1);
            if idxIdx
                pos = app.DataTable{1}.RelTime(idxIdx);
            else
                return; % TODO: Or error?
            end
        end 
        
        noLeftBufferReq = (pos <= minBuff);
        noRightBufferReq = ((app.LatestTimeReceived - pos) <= minBuff);

        if ismissing(pos)
            return; % TODO: or error?
        elseif bitget(app.XAxisModeIndex, 1) % Relative time
            lmp = seconds(0);
            rmp = app.LatestTimeReceived;
        else % Absolute time
            lmp = app.TimeZero;
            pos = pos + lmp;
            rmp = app.LatestTimeReceived + lmp;
        end

        if (moveMode==-1) && (app.HgtAxes.XLim(1)<=pos) && (app.HgtAxes.XLim(2)>=pos)
            return;
        elseif moveMode>0
            newLims = [];
        else
            dif = app.HgtAxes.XLim - pos; 
            % (L-p): is negative when p is within visible dom
            % (R-p): is positive when p is within visible dom
            if dif(1) > 0 % Not visible, to the left
                if noLeftBufferReq
                    newLims = [lmp, min(rmp, lmp + span)];
                elseif abs(app.HgtAxes.XLim(1) - pos) <= 0.5*span
                    moveMode = 1;
                    newLims = [];
                else
                    moveMode = 2;
                    newLims = [];
                end
            elseif dif(2) < 0 % Not visible, to the right
                if noRightBufferReq
                    newLims = [max(lmp, rmp - span), rmp];
                elseif abs(pos - app.HgtAxes.XLim(2)) <= 0.5*span
                    moveMode = 3;
                    newLims = [];
                else
                    moveMode = 2;
                    newLims = [];
                end
            else % In view. dif(1)<=0, dif(2)>=0
                % difdif = dif(2) + dif(1); %  =  dif(2) - (-dif(1))  =  |dif(2)| - |dif(1)|
                difdif = dif + [minBuff -minBuff];
                if all(difdif>0) % if ((minBuff+dif(1)) > 0) && (dif(2) > minBuff) % if difdif < 0
                    % Closer to left than to right, and there is excess buffer on the right
                    newLims = app.HgtAxes.XLim + min(difdif);
                elseif noLeftBufferReq && (difdif(2)<0)
                    return;
                elseif all(difdif<0) % (dif(2) < minBuff) && (dif(1) > minBuff)
                    % Closer to right than to left, and there is excess buffer on the left
                    newLims = app.HgtAxes.XLim - max(difdif);
                else
                    %newLims = [];
                    %moveMode = 2; % Jump
                    return; % No room to provide requested buffer on both sides
                end
            end
        end
    else % Index mode
        pos = uint64(idx);

        lmp = 1; rmp = app.LargestIndexReceived;

        noLeftBufferReq = (pos <= minBuff);
        noRightBufferReq = (rmp - pos) <= minBuff;
        
        if (moveMode==-1) && (app.HgtAxes.XLim(1)<=pos) && (app.HgtAxes.XLim(2)>=pos)
            return;
        elseif moveMode>0
            newLims = [];
        elseif app.HgtAxes.XLim(1) >= pos % To the left, or on the left border
            dif = app.HgtAxes.XLim(1) - pos;
            if noLeftBufferReq
                newLims = [1, 1+span];
            elseif ~dif % on border
                newLims = (pos-minBuff) + [0, span];
            elseif dif <= idivide(span, uint64(2), 'floor')
                moveMode = 1; % Slide
                newLims = [];
            else 
                moveMode = 2; % Jump
                newLims = [];
            end
        elseif app.HgtAxes.XLim(2) <= pos % To the right, or on the right border
            dif = pos - app.HgtAxes.XLim(1);
            if noRightBufferReq
                if noLeftBufferReq
                    newLims = [1 app.LargestIndexReceived];
                else
                    newLims = app.LargestIndexReceived - [span 0]; % TODO: check validity?
                end
            elseif ~dif % On border
                newLims = (pos+minBuff) - [span 0];
            elseif dif <= idivide(span, uint64(2),'floor')
                moveMode = 3; % Slide
                newLims = [];
            else
                moveMode = 2; % Jump
                newLims = [];
            end
        else % Somewhere within the visible domain (not including borders)
            % TODO
            dif = app.HgtAxes.XLim - pos;
            % (L-p): is negative when p is within visible dom
            % (R-p): is positive when p is within visible dom
            if dif(1) > 0 % Not visible, to the left
                if noLeftBufferReq
                    newLims = [lmp, lmp + span];
                elseif (app.HgtAxes.XLim(1) - pos) <= 0.5*span
                    moveMode = 1; % Slide
                    newLims = [];
                else
                    moveMode = 2; % Jump
                    newLims = [];
                end
            elseif dif(2) < 0 % Not visible, to the right
                if noRightBufferReq
                    newLims = [max(lmp, rmp - span), rmp];
                elseif (pos - app.HgtAxes.XLim(2)) <= 0.5*span
                    moveMode = 3; % Slide
                    newLims = [];
                else
                    moveMode = 2; % Jump
                    newLims = [];
                end
            else % In view. dif(1)<=0, dif(2)>=0
                % difdif = dif(2) + dif(1); %  =  dif(2) - (-dif(1))  =  |dif(2)| - |dif(1)|
                difdif = dif + [minBuff -minBuff];
                if all(difdif>0) % if ((minBuff+dif(1)) > 0) && (dif(2) > minBuff) % if difdif < 0
                    % Closer to left than to right, and there is excess buffer on the right
                    newLims = app.HgtAxes.XLim + min(difdif);
                elseif noLeftBufferReq && (difdif(2)<0)
                    return;
                elseif all(difdif<0) % (dif(2) < minBuff) && (dif(1) > minBuff)
                    % Closer to right than to left, and there is excess buffer on the left
                    newLims = app.HgtAxes.XLim - max(difdif);
                else
                    newLims = [];
                    moveMode = 2; % Jump
                    % return; % No room to provide requested buffer on both sides ==> no change in vis. dom.
                end
            end
        end
    end

    if isempty(newLims)
        if noLeftBufferReq
            newLims = [lmp min(rmp, lmp+span)];
        elseif noRightBufferReq
            if rmp >= (span+lmp)
                newLims = rmp - [span 0];
            else
                newLims = [lmp rmp];
            end
        elseif bitget(moveMode, 1) % Slide
            if bitget(moveMode, 2) % Slide right
                newLims = (pos+minBuff) - [span 0];
            else % Slide left
                newLims = (pos-minBuff) + [0 span];
            end
        else % Jump (center)
            midPos = mean(app.HgtAxes.XLim);
            if midPos > pos % Need to move view to the left
                dist = midPos - pos;
                if (lmp+dist) > app.HgtAxes.XLim(1) % Cannot move that far left
                    if (lmp+span) <= rmp
                        newLims = lmp + [0 span];
                    else
                        newLims = [lmp rmp];
                    end
                else
                    newLims = app.HgtAxes.XLim - dist;
                end
            elseif midPos == pos
                return; % No change in pos necessary.
            else % Need to move view to the right
                dist = pos - midPos;
                if (pos+dist) > rmp % Cannot move that far right
                    if rmp >= (span+lmp)
                        newLims = rmp - [span 0];
                    else
                        newLims = [lmp rmp];
                    end
                else
                    newLims = app.HgtAxes.XLim + dist;
                end
            end
        end
    end

    newLims1 = quantizeDomain(app.TimeZero, app.XAxisModeIndex, false, app.XResUnitVals, newLims);
    if (pos >= newLims1(1)) && (pos <= newLims1(2))
        if ~isequal(app.HgtAxes.XLim, newLims1) || ~isequal(app.PosAxes.XLim, newLims1)
            set([app.HgtAxes, app.PosAxes], 'XLim', newLims1); % TODO: Revert the first if the second fails?
        end
    elseif ~isequal(app.HgtAxes.XLim, newLims) || ~isequal(app.PosAxes.XLim, newLims)
        set([app.HgtAxes, app.PosAxes], 'XLim', newLims); % TODO: Revert the first if the second fails?
    end
end