function postmove_PSBline(app, varargin)
persistent pv nx;
if nargin==2
    event = varargin{1};
    src = event.Source;
    isSpin = false;
else
    [src,event] = varargin{:};
    isSpin = (event.EventName(1) == 'V');
end
if isSpin
    % ValueChanging
    % ValueChanged
    shapeDone = event.EventName(11) == 'e';
else
    % MovingROI
    % ROIMoved
    shapeDone = event.EventName(1) == 'R';
end
try
    srcTag = uint8(src.Tag)-48;
    if ~shapeDone
        if ~pv
            % TODO: highRect
        end
    end
        if isSpin % src is spinner, changing
            nx = src.Value;
            app.PSBLines(srcTag).Position(:,1) = double(nx);
            % drawnow limitrate;
        else % src is ROI, moving
            nx = round(event.CurrentPosition(1,1));
            spin = app.PSBSpins(srcTag);
            if nx < spin.Limits(1)
                nx = spin.Limits(1);
                % src.Position(:,1) = nx;
            elseif nx > spin.Limits(2)
                nx = spin.Limits(2);
                % src.Position(:,2) = nx;
            end
            try
                spin.Value = double(nx);
            catch ME
                display({nx, double(nx)}); %#ok<*DISPLAYPROG> 
                display(spin.Limits);
                rethrow(ME);
            end
        end
        % TODO: highRect
    if shapeDone %else % shapeDone
        %if isempty(nx)
        nx = uint16(app.PSBSpins(srcTag).Value);
        %end
        if srcTag == 1
            app.PSBLeftIndex = nx;
        else
            app.PSBRightIndex = nx;
        end

        % TODO: highRect
        pv = false;
        clear nx;
    end
catch ME
    fprintf('[postmove_PSBline] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
    pv = false;
    clear nx;
    % TODO: highRect
end     
end