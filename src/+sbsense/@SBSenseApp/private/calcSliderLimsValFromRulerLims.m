function [sliderLims, sliderValue, sliderEnable] = calcSliderLimsValFromRulerLims( ...
    timeZero, axisModeIndex, zoomModeOn, resUnit, maxIdxOrRelTime, rulerLims)
    % Assume that lims are already quantized...?


    % fprintf('[calcSliLimsVFromRuLims] maxIdxOrRelTime: %s\n', formattedDisplayText(maxIdxOrRelTime));

timeMode = bitget(axisModeIndex, 2);
zoomSpan = diff(rulerLims);

if ~isscalar(resUnit) % icell(resUnitVals)
    resUnit = resUnit{axisModeIndex,1};
elseif timeMode && ~isnumeric(resUnit)
    resUnit = seconds(resUnit);
else % index mode
    resUnit = double(resUnit);
end

fprintf('[calcSliLimsVFromRuLims] >>> ARGS: ami/zm=%d/%d, resUnit=%s, maxIdxOrRT=%s, ruLims=[%s]\n', ...
    axisModeIndex, zoomModeOn, fdt(resUnit), fdt(maxIdxOrRelTime), fdt(rulerLims));
fprintf('[calcSliLimsVFromRuLims] >>> zoomSpan: %s\n', fdt(zoomSpan));

if zoomModeOn % ZOOM MODE
    % sliderEnable = maxIdxOrRelTime>=zoomSpan;
    sliderEnable = true;
    if timeMode % Time (abs or rel)
        maxSpan = min(100*resUnit, seconds(maxIdxOrRelTime));
        if bitget(nargout,2) % TODO: Efficiency of this vs bitand, using as logical value??
            sliderValue = double(max(0, min(maxSpan, seconds(zoomSpan))));
        end
    else % Index mode
        % resUnit = double(resUnit);
        maxSpan = double(min(50*resUnit, maxIdxOrRelTime)); %max(zoomSpan, double(maxIdxOrRelTime)); 
        sliderValue = max(1,min(double(zoomSpan), maxSpan));
    end
    llim = max(0, resUnit);
    ulim = max(llim, resUnit*ceil(maxSpan/resUnit)); % include min too...?
else % PAN MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if timeMode % Absolute or relative time
        llim = seconds(0);
        ulim = max(0, maxIdxOrRelTime); % - zoomSpan);
        if ulim <= llim
            sliderEnable = false;
            ulim = llim + resUnit;
        else
            sliderEnable = true;
        end
        % if (maxIdxOrRelTime - zoomSpan) < seconds(resUnit) % Not ok
        %     ulim = 2*resUnit; % or 2*resUnit???
        %     sliderEnable = false;
        % else
        %     ulim = seconds(maxIdxOrRelTime);
        %     sliderEnable = true;
        % end
    else % Index mode
        %ulim = double(maxIdxOrRelTime - resUnit + 1);
        llim = 1;
        if maxIdxOrRelTime > 1 % (zoomSpan+1)
            ulim = double(maxIdxOrRelTime); % - zoomSpan;
            sliderEnable = true;
        else
            sliderEnable = false;
            ulim = llim + resUnit;
        end
        % ulim = max(1, maxIdxOrRelTime); % - zoomSpan);
        % if ulim <= llim
        %     sliderEnable = false;
        %     ulim = llim + resUnit;
        % else
        %     sliderEnable = true;
        % end
        % if maxIdxOrRelTime < (resUnit + zoomSpan)
        %     ulim = maxIdxOrRelTime; % 2*resUnit;
        %     sliderEnable = false;
        % else
        %     ulim = max(2,maxIdxOrRelTime);
        %     sliderEnable = true;
        % end
        % zoomSpan = zoomSpan + 1; % ?????
    end
    if timeMode
        ulim = seconds(ulim); llim = seconds(llim);
        if bitget(nargout, 2)
            if bitget(axisModeIndex, 1) % Absolute time
                sliderValue = double(max(0, seconds(rulerLims(1))));
            else
                sliderValue = double(max(0, seconds(rulerLims(1)-timeZero)));
            end
        end
    elseif bitget(nargout,2)
        sliderValue = double(max(1,rulerLims(1)));
    end
%     if bitget(nargout,2) % TODO: Efficiency of this vs bitand, using as logical value??
%         if ~timeMode % Numeric mode
%             sliderValue = double(max(1,rulerLims(1)));
%         elseif bitget(axisModeIndex,1) % Relative time
%             sliderValue = double(max(0, seconds(rulerLims(1))));
%         else % Absolute time
%             %sliderValue = double(seconds(rulerLims(1) - timeZero));
%             sliderValue = double(max(0, seconds(rulerLims(1)-timeZero)));
%         end
%     end
sliderEnable = sliderEnable && maxIdxOrRelTime>=zoomSpan;
end

sliderLims = double([llim ulim]);
%display([sliderLims sliderValue]);
% if timeMode % TODO: Efficiency of this vs bitand, using as logical value??
sliderValue = min(sliderValue, double(ulim));
% end

fprintf('[calcSliLimsVFromRuLims] <<< (RU: %g) rulims %s, maxIdxOrRT=%s\n\t--> sli val,lims = %g, %s\n', ...
    resUnit, fdt(rulerLims), strrep(strip(formattedDisplayText(maxIdxOrRelTime)), '  ', ' '), ...
    sliderValue, fdt(sliderLims));
end