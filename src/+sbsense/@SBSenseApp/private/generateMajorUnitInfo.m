% arg in: axisModeIndex, zoomModeOn, resUnit
% arg out: {majUnit,sfac,fmt} or [majUnit, sfac, fmtPan, fmtZoom, fmtStatus]
function varargout = generateMajorUnitInfo(axisModeIndex, minorUnit)
    if bitget(axisModeIndex,2) % Time
        % 0.001 0.002 0.005 0.010 0.025 0.050 ...
        % 0.1 0.2 0.25 0.5 1.0 1.5 2.0 5.0 10 15 20 30 ...
        % 60 120 300 600 900
        switch minorUnit
            case {0.001, 0.002, 0.005}
                majorUnit = 0.010;
            case {0.0010, 0.025}
                majorUnit = 0.050;
            case {0.1 0.2 0.25 0.5}
                majorUnit = 1.0;
            case 2
                majorUnit = 4;
            case {1.0 2.5}
                majorUnit = 5.0;
            case 1.5
                majorUnit = 3;
            case 5
                majorUnit = 15;
            case 10
                majorUnit = 30;
            case {20 30}
                majorUnit = 60;
            case {60 120 180 240 300}
                majorUnit = 600;
            case {600 900}
                majorUnit = 1800;
            otherwise
                majorUnit = 3600;
        end
        if bitget(axisModeIndex,2) % Relative time
            h = 'h';
        else
            h = 'H';
        end
        if majorUnit >= 3600
            sfac = 3600;
            fmtPan = sprintf('%1$c%1$c:mm', h);
            fmtZoom = '%0.1fh';
            fmtStatus = fmtPan;
        elseif (majorUnit >= 60)
            sfac = 60;
            fmtPan = sprintf('%1$c%1$c:mm', h);
            fmtZoom = '%0.1fm';
            fmtStatus = horzcat(fmtPan, ':ss');
        elseif (majorUnit >= 1)
            fmtPan = 'mm:ss';
            fmtZoom = 'mm:ss';
            fmtStatus = sprintf('%1$c%1$c:mm:ss.SS', h);
            sfac = NaN;
        else
            sfac = 1;
            if(minorUnit >= 0.001)
                fmtPan = 'mm:ss.SS';
                fmtZoom = '%0.2f';
                fmtStatus = sprintf('%1$c%1$c:mm:ss.SS', h);
            else
                fmtPan = 'mm:ss.SSS';
                fmtZoom = '%0.3f';
                fmtStatus = sprintf('%1$c%1$c:mm:ss.SSSS', h);
            end
        end
    else % Indices
        % minorUnit = uint64(minorUnit);
        switch minorUnit
            case {1,2}
                majorUnit = uint64(10);
            case 5
                majorUnit = uint64(25);
            case {15,20}
                majorUnit = uint64(60);
            case {25,50}
                majorUnit = uint64(100);
            case {100,250}
                majorUnit = uint64(500);
            case {400,800}
                majorUnit = uint64(1600);
            case {200,500}
                majorUnit = uint64(1000);
            otherwise
                majorUnit = uint64(10000);
        end
        fmtZoom = '%2g';
        fmtPan = fmtZoom;
        fmtStatus = fmtZoom;
        sfac = 1;
    end



    if nargout > 1
        varargout = {majorUnit, sfac, fmtPan, fmtZoom, fmtStatus};
    else
        varargout = {{majorUnit, sfac, fmtPan, fmtZoom, fmtStatus}};
    end 
end