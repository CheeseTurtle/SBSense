function onLegendClick(hSrc, ev)
    persistent fut; % lastPeer;
    %if isequal(ev.Peer, lastPeer)
    % if ~isempty(fut)
    %     cancel(fut);
    % end
    %end
    % ItemHitEventData with properties:
    %          Peer: [1×1 ConstantLine]
    %        Region: 'label'
    % SelectionType: 'normal' ('open' for double-click -- but also triggers the 2 single clicks)
    %        Source: [1×1 Legend]
    %     EventName: 'ItemHit'
    cs = hSrc.UserData(~isequal(hSrc.UserData, ev.Peer));
    if ev.SelectionType(1)=='n' % strcmp(ev.SelectionType, 'normal')
        val = ~ev.Peer.Visible;
        if val || any([cs.Visible])
            if ~isempty(fut)
                cancel(fut);
            end
            fut = parfeval(backgroundPool, @pause, 0, 0.25);
            fut = [fut afterEach(fut, @() set(ev.Peer, 'Visible', val), 0)];
        end
        %if strcmp(ev.Region, 'label')
        %    ev.Peer.Visible = ~ev.Peer.Visible;
        %elseif strcmp(ev.Region, 'icon')
        %    ev.Peer.Visible = ~ev.Peer.Visible;
        %else
        %    fprintf('[onLegendClick] Unexpected ev.Region: %s\n', ev.Region);
        %end
    elseif (ev.SelectionType(1)=='o') 
        if ~isempty(fut)
            cancel(fut);
        end
        if any([cs.Visible], 'all')
            % disp(cs);
            set(cs, 'Visible', false); % TODO: or zoom to?
        else
            set(cs, 'Visible', true);
        end
        if ~ev.Peer.Visible
            ev.Peer.Visible = true;
        end
    else
        fprintf('[onLegendClick] Unexpected ev.SelectionType: %s\n', ev.SelectionType);
    end
end

