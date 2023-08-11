function quickExport_PrimaryData(app, varargin)
    [file,path,~] = uiputfile( ...
        { '*.xls', 'MS Excel Spreadsheet file' }, ...
        'Select export location and filename for primary data', ...
        '');
    if ~file
        return;
    end
    %if idx==1
        suff = '.xls';
    %else
    %    suff = '.csv';
    %end

    if(~endsWith(file, suff))
        file = sprintf('%s%s', file, suff);
    end
    fullpath = fullfile(path, file);

    relTimes = app.DataTable{1}.RelTime;
    absTimes = relTimes + app.TimeZero;
    %absDates = ymd(absTimes);
    %[absH,absM,absS] = hms(absTimes);
    %absTimes = [absH,absM,absS];
    %clear absH absM absS;
    %[relH, relM, relS] = hms(relTimes);
    %relTimes = [relH, relM, relS];
    %clear relH relM relS;
    absDates = string(absTimes, 'yyyy/MM/dd');
    absTimes = string(absTimes, 'HH:mm:ss.SSSSSS');
    relTimes = string(relTimes, 'mm:ss.SSSSSS');

    % psbs = app.DataTable{1}(:,'PSB');
    % psbs = splitvars(psbs, 'PSB', 'NewVariableNames', {'PSBL', 'PSBR'});
    psbs = app.DataTable{1}.PSB;
    
    indexColumns = table(absDates,absTimes, ...
        relTimes, app.DataTable{1}.Index, ...
        'VariableNames', {'Abs Date', 'Abs Time', 'Rel Time', 'Datapt Idx'});
    globalColumns = table(psbs(:,1), psbs(:,2), ...
        app.DataTable{1}.ELI, app.DataTable{1}.AvgPeakLoc, ...
        app.DataTable{1}.AvgPeakHgt, 'VariableNames', ...
        {'PSB L', 'PSB R', 'Est Laser Int', 'Avg Pk Loc', 'Avg Pk Hgt'});
    
    posVarNames = compose('Ch %d Pk Loc', 1:app.NumChannels);
    hgtVarNames = compose('Ch %d Pk Hgt', 1:app.NumChannels);
    posColumns = array2table(app.DataTable{1}.PeakLoc, ...
        'VariableNames', posVarNames);
    hgtColumns = array2table(app.DataTable{1}.PeakHgt, ...
        'VariableNames', hgtVarNames);
    
    writetable(horzcat(indexColumns, globalColumns), ...
        fullpath, 'Sheet', 'Primary Data', ...
        'WriteMode', 'overwritesheet', ... % or 'replacefile'?
        'WriteRowNames', false, ...
        'WriteVariableNames', true);
    writetable(horzcat(indexColumns, posColumns), ...
        fullpath, 'Sheet', 'Ch. Peak Location', ...
        'WriteMode', 'overwritesheet', ...
        'WriteRowNames', false, ...
        'WriteVariableNames', true);
    writetable(horzcat(indexColumns, hgtColumns), ...
        fullpath, 'Sheet', 'Ch. Peak Height', ...
        'WriteMode', 'overwritesheet', ...
        'WriteRowNames', false, ...
        'WriteVariableNames', true);
end