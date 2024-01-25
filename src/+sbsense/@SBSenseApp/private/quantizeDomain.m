function lims = quantizeDomain(timeZero, axisModeIndex, zoomModeOn, resUnitVals, lims00)
if ~isrow(lims00)
    lims00 = lims00';
end
lims0 = lims00;
if isscalar(resUnitVals)
    resUnit = resUnitVals;
else
    resUnit = resUnitVals{axisModeIndex,1};
end

import sbsense.utils.fdt;

% fprintf('[quantizeDomain] >>> ARGS: ami/zm: %d/%d, resUnit: %s, lims00: %s\n', ...
%     axisModeIndex, zoomModeOn, fdt(resUnit), fdt(lims00));


if zoomModeOn % ZOOM MODE
    if axisModeIndex==1 % Index
        w0 = uint64(max(0,diff(lims0)));% + 1);
        w1 = uint64(resUnit*max(1,idivide(w0, uint64(resUnit), 'ceil')));
        wd = w1 - w0;
        % el = min(uint64(lims0(1)-1), max(uint64(0), idivide(wd,uint64(2),'fix')));
        % el = min(uint64(lims0(1)), max(uint64(0), idivide(wd,uint64(2),'fix')));
        el = min(uint64(lims0(1)), max(uint64(0), idivide(wd,uint64(2),'fix')));
        er = wd - el;
        soh = 0;
        lims1 = lims0;
        % fprintf('[quantizeDomain] (ZOOM/INDEX) wd=%g-%g=%g, [el,er]=[%g,%g]\n', ...
        %     w1, w0, wd, el, er);
    else % Time (abs or rel)
        w0 = max(0,seconds(diff(lims0))); % datetime/duration to numeric
        w1 = resUnit*max(1, ceil(w0/resUnit)); % numeric
        wd = w1 - w0; % numeric
        if axisModeIndex == 2 % relative time
            soh = dateshift(lims0(1), 'start', 'hour'); % datetime
            lims1 = seconds(lims0 - soh); % duration to numeric
            % lims1.Format = 's';
        else
            soh = seconds(0); % duration
            lims1 = seconds(lims0); % duration to numeric
            % lims1.Format = 'MM/dd HH:mm:ss.SSSS';
        end
        el = min(lims1(1), max(0, fix(0.5*wd))); % numeric
        er = seconds(wd - el); % numeric to duration
        el = seconds(el); % numeric to duration
        lims1 = seconds(lims1); % numeric to duration -- TODO: Reorder operations?
        % fprintf('[quantizeDomain] (ZOOM/TIME) wd=(%g-%g)=%g, [el,er]=[%g sec,%g sec]\n', ...
        %     w1, w0, wd, seconds(el), seconds(er));
    end
    % abs mode: duration + [duration,duration] + datetime
    lims = lims1 + [-el, er] + soh;
    % fprintf('[quantizeDomain] <<< (ZOOM) lims = %s = (%s + %s + %s)\n', ...
    %     fdt(lims), fdt(lims1), fdt([-el,er]), fdt(soh));
    % TODO: lims.Format?
else % PAN MODE
    %fprintf('##########hi###############\n');
    if axisModeIndex==1 % Index mode
        %lims0 = double(lims0);
        resUnit = uint64(resUnit);
        lims = [ ...
            ... max(1, 1 + resUnit*idivide(uint64(lims0(1)-1), resUnit, 'fix')), ...
            ... 1 + resUnit*idivide(uint64(lims0(2)), resUnit, 'ceil') ...
            max(1, 1 + resUnit*idivide(uint64(lims0(1)-1), resUnit, 'fix')), ...
            resUnit*idivide(uint64(lims0(2)), resUnit, 'ceil') ...
            ];
        if lims(2)<=lims(1)
            lims(2) = lims(1) + max(resUnit,1);
        end
        % fprintf('[quantizeDomain] <<< (PAN/INDEX) lims = %s\n', fdt(lims));
        % %display(lims);
    else % Time (abs or rel)
        %resUnit = seconds(resUnit);
        if axisModeIndex == 2 % Absolute time
            soh = dateshift(lims0(1), 'start', 'hour'); % datetime
            % dateshift(dt,'start','day') == (dt - timeofday(dt))
            lims0 = lims0 - soh; % duration
        else
            soh = seconds(0); % duration
        end
        lims0 = seconds(lims0); % numeric
        lims = [ ...
            ... % 1 + resUnit*fix((lims0(1)-1)/resUnit), ...
            ... 1 + resUnit*ceil(lims0(2)/resUnit) ...
            resUnit*fix((lims0(1))/resUnit), ...
            resUnit*ceil(lims0(2)/resUnit) ...
            ]; % numeric
        lims = seconds(max(lims, [0, lims(1)+resUnit]));
        % lims = seconds(lims); % duration
        if axisModeIndex == 2 % Absolute time
            lims = lims + soh; % datetime
            if (soh <= timeZero) && (lims(1) < timeZero)
                lims(1) = timeZero;
                lims(2) = max(lims(2), lims(1)+seconds(resUnit));
            end
            lims.Format = 'MM/dd HH:mm:ss.SSSS';
            lims00.Format = 'MM/dd HH:mm:ss.SSSS';
        else % Relative time
            % lims(1) = max(lims(1), seconds(0));
            lims.Format = 's';
            lims00.Format = 's';
        end
        % fprintf('[quantizeDomain] <<< (PAN/TIME) lims = %s\n', fdt(lims));
    end
end
% fprintf('[quantizeDomain]     (RU: %g) %s (--> %s) --> %s\n', ...
%      resUnit, fdt(lims00), fdt(lims0), fdt(lims));

% % fprintf('[quantizeDomain] (RU: %g, lims0: [%0.8g %0.8g])\n', ...
% %     resUnit, lims0(1), lims0(2));
% fprintf('[quantizeDomain]     (old span: %s, new span: %s)\n', ...
%     fdt(diff(lims00)), fdt(diff(lims)));
% %disp( vertcat(mat2cell(lims00, 1, [1 1]), ...
% %    mat2cell(lims - lims00, 1, [1 1]), mat2cell(lims, 1, [1 1])) );
% % disp(vertcat(lims00, lims));
% % disp(lims - lims00);
end