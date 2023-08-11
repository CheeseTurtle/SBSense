function [majorUnit, majorFormat, sfac] = chooseMajorResUnit(axisModeIndex, minorUnit)
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
            sfac = 3600;
    end
    if (majorUnit >= 60)
        sfac = 60;
        majorFormat = 'mm:ss';
    elseif (majorUnit < 3600)
        sfac = 1;
        majorFormat = 'mm:ss.SSS';
    else
        majorFormat = '%0.1fh';
    end
else % Indices
    switch minorUnit
        case {1,2}
            majorUnit = 10;
        case 5
            majorUnit = 25;
        case {15,20}
            majorUnit = 60;
        case {25,50}
            majorUnit = 100;
        case {100,250}
            majorUnit = 500;
        case {400,800}
            majorUnit = 1600;
        case {200,500}
            majorUnit = 1000;
        otherwise
            majorUnit = 10000;
    end
    majorFormat = '%2g';
    sfac = 1;
end
end