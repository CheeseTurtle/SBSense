function TF = prepareFirstRecord(app)
% tms = timerfindall("Tag", "SBsense_vread");
% for tm = tms
%     if isa(tm, 'timer') && (tm.Running(2)=='n')
%         stop(tm);
%     end
%     delete(tm);
% end
fprintf('[prepareFirstRecord]\n');
TF = false;
if app.hasCamera % ... %isscalar(app.vobj) && isa(app.vobj, 'videoinput') && isvalid(app.vobj)
    %... %if isempty(app.vobj.UserData) || ~isstruct(app.vobj.UserData) ...
    %    ... %  && isstruct(app.vobj.UserData) && isfield(app.vobj.UserData, 'usingTimer')
    if startsWith(uiconfirm(app.UIFigure, ...
            {'Are you sure you are ready to begin collecting data?', ...
            ['Once data has been collected, the camera device and its settings, ' ...
            'the reference image, the vertical crop, and the channel layout\bf are locked ' ...
            'and cannot be modified\rm unless a new session is begun (and any collected ' ...
            'data in the current session is discarded).']}, ...
            'Proceed to data collection?', 'Options', {'OK', 'Cancel'}, ...
            'DefaultOption', 1, 'CancelOption', 2), 'Cancel')
        fprintf('[prepareFirstRecord] Returning from function without setting up.\n');
        return;
    else
        fprintf('[prepareFirstRecord] Setting up camera for acquisition.\n');
    end
    setupAcquisitionVideoObject(app);
    enablePhaseI(app, false);
elseif app.ReadFromFile % && ~app.hasCamera
    if isa(app.RFFTimer, 'timer')
        delete(app.RFFTimer);
    end
    app.RFFTimer = timer("BusyMode", "drop", ...
        "ExecutionMode", "fixedRate", ...
        "Name", "SB File Read Timer", "ObjectVisibility", "off", ...
        "StartDelay", 0, "Period", max(1/30, 0.5*app.SPPField.Value), ...
        "TasksToExecute", inf, "Tag", "SBsense_vread", ...
        'StartFcn', '', ... % @sbsense.SBSenseApp.readNextFrame, ...
        "TimerFcn", { @sbsense.SBSenseApp.readNextFrame, app.Analyzer.HCQueue, app.ResQueue, 2\app.FPPSpinner.Value}, ...
        "StopFcn", { @sbsense.SBSenseApp.stopReadingFrames, app.Analyzer.HCQueue }); % , ...
    %'StartDelay', str2num(app.SPFField.Value)); %#ok<ST2NM>
    sbsense.SBSenseApp.readNextFrame();
else
    uialert(app.UIFigure, 'No video object connected. Cannot begin acquisition.', 'Error');
    error('No video object connected.');
end


if ~isempty(app.HgtAxes.Legend)
    delete(app.HgtAxes.Legend);
end

if ~isempty(app.PosAxes.Legend)
    delete(app.PosAxes.Legend);
end

initialize(app.Analyzer, 0, app.ResQueue, ...
    app.ChBoundsPositions, app.ChannelHeights, ...
    app.ChannelDivHeights, ...
    app.RefImage, app.NumChannels, app.AnalysisScale);

% These assignments already occur when calling 'initialize'?
app.Analyzer.AnalysisParams.ChBoundsPositions = app.ChBoundsPositions;
app.Analyzer.AnalysisParams.ChHeights = app.ChannelHeights;
app.Analyzer.AnalysisParams.ChDivHeights = app.ChannelDivHeights;

set([app.overimg app.dataimg app.maskimg], ...
    'XData', [1 double(app.AnalysisParams.EffectiveWidth)], ...
    'YData', double(app.AnalysisParams.YCropBounds) + [1 -1] ...
);

app.ChannelIPs = NaN(0,0,app.NumChannels);
app.ChannelFPs = app.ChannelIPs;
app.ChannelFBs = uint16.empty(0,2,app.NumChannels);
app.ChannelWgts = cell.empty(0,app.NumChannels);
app.ChannelWPs = cell.empty(0,3,app.NumChannels);
app.ChannelXData = cell.empty(0,app.NumChannels);

app.DataTable{1}(:,:) = [];
app.DataTable{2}(:,:) = [];
app.DataTable{1} = addvars(addvars(removevars(app.DataTable{1}, {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm', 'PeakLoc', 'PeakHgt'}), ...
    NaN(0,app.NumChannels, 'double'), NaN(0,app.NumChannels, 'double'), ...
    'NewVariableNames', {'PeakLoc', 'PeakHgt'}), ...
        uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), ...
        double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
        NaN(0,app.NumChannels), ...
        'After', 'PSB', 'NewVariableNames', {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm'});
app.DataTable{2} = addvars(addvars(removevars(app.DataTable{2}, {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm', 'PeakLoc', 'PeakHgt'}), ...
    NaN(0,app.NumChannels, 'double'), NaN(0,app.NumChannels, 'double'), ...
    'NewVariableNames', {'PeakLoc', 'PeakHgt'}), ...
    uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), ...
    double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
    NaN(0,app.NumChannels), ...
    'After', 'PSB', 'NewVariableNames', {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm'});

app.ChunkTable = timetable( ...
    uint64.empty(), uint64.empty(), logical.empty(), ...
    uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), uint64.empty(), ...
    uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), ...
    uint8.empty(), logical.empty(), ...
    ... %'VariableTypes', {'uint64', 'uint64', 'logical', 'uint16', 'uint16', ...
    ... %    'uint64', 'uint16', 'uint16', ...
    ... %    'uint8', 'logical'}, ...
    'VariableNames', {'Index', 'EndIndex', 'IsActive', 'PSZL', 'PSZW', ...
        'EndIndex1' ,'PSZL1', 'PSZW1', ...
        'ChangeFlags', 'IsChanged'}, ...
    'DimensionNames', {'RelTime', 'Variables'}, 'TimeStep', seconds(NaN));

% RelTime | Index, SplitStatus, IsDiscontinuity, Discontinuities, ROI
app.DataTable{3}(:,:) = [];
for cl = app.DataTable{3}.ROI
    if all(isgraphics(cl), 'all') && all(ishghandle(cl), 'all') && any(isvalid(cl), 'all')
        delete(cl);
    end
end
app.DataTable{3} = addvars(removevars(app.DataTable{3}, 'Discontinuities'), ...
    logical.empty(0,app.NumChannels), 'After', 'IsDiscontinuity', ...
    'NewVariableNames', {'Discontinuities'});

set([app.IPfitLines, app.IPdataLines], 'Visible', false);
set(app.IPpeakLines, 'Value', NaN);

app.Composites = cell.empty();
app.Yrs = cell.empty();
app.Ycs = cell.empty();
app.SampMask0s = {};
app.SampMasks = {};
app.ROIMasks = {};


app.SelectedIndex = 0;
app.TimeZero = NaT;
app.LatestTimeReceived = seconds(0);
app.LargestIndexReceived = 0;
% app.AnalysisParams.dpIdx0 = 0;

app.PageLimits = [];
app.PageSize = 0;

co = colororder(app.UIFigure);
if ~isempty(app.channelPeakPosLines)
    delete(app.channelPeakPosLines);
end
if ~isempty(app.channelPeakHgtLines)
    delete(app.channelPeakHgtLines);
end
yyaxis(app.HgtAxes, 'left');
app.channelPeakHgtLines = matlab.graphics.primitive.Line.empty(0, app.NumChannels);
app.channelPeakPosLines = matlab.graphics.primitive.Line.empty(0, app.NumChannels);

%  matlab.graphics.primitive.Line vs matlab.graphics.chart.primitive.Line

for ch = 1:app.NumChannels
    dn = sprintf('Channel %d', ch);
    app.channelPeakHgtLines(ch) = matlab.graphics.primitive.Line( ...
        'Parent', app.HgtAxes, 'Color', co(ch,:), ...
        'MarkerSize', 6, 'Marker', '.', 'XData', [], 'YData', [], ...
        'LineStyle', '-', 'LineWidth', 1, 'DisplayName', dn);
    app.channelPeakPosLines(ch) = matlab.graphics.primitive.Line( ...
        'Parent', app.PosAxes, 'Color', co(ch,:), ...
        'MarkerSize', 6, 'Marker', '.', 'XData', [], 'YData', [], ...
        'LineStyle', '-', 'LineWidth', 1, 'DisplayName', dn);
end

set([app.eliPlotLine app.channelPeakHgtLines app.channelPeakPosLines], ...
    'XData', [], 'YData', []);

if ~isempty(app.HgtAxes.Legend)    
    app.HgtAxes.Legend.UserData = [app.channelPeakHgtLines app.eliPlotLine];
end
if ~isempty(app.PosAxes.Legend)
    app.PosAxes.Legend.UserData = app.channelPeakPosLines;
end

app.FPXModeDropdown.Value = 1;
FPXModeDropdownChanged(app, app.FPXModeDropdown, struct('Value', 1, 'PreviousValue', app.XAxisModeIndex));

if ~isempty(app.ProfileStore)
    clear(app.ProfileStore.UnderlyingDatastores{1});
    clear(app.ProfileStore.UnderlyingDatastores{2});
    reset(app.ProfileStore.UnderlyingDatastores{1});
    reset(app.ProfileStore.UnderlyingDatastores{2});
end
%if isempty(app.ImageStore)
    % imgdir = fullfile(app.SessionDirectory, 'images');
    % app.ImageStore = combine(...
    %     imageDatastore([imagedir '\Composites'], ...
    %         'FileExtensions', '.png', 'ReadSize', 1), ...
    %     imageDatastore([imagedir '\Ycs'], ...
    %         'FileExtensions', '.png', 'ReadSize', 1), ...
    %     imageDatastore([imagedir '\Yrs'], ...
    %         'FileExtensions', '.png', 'ReadSize', 1) ...
    % );
if ~isempty(app.ImageStore) %else
    oldState = recycle('on');
    imgdir = fullfile(app.SessionDirectory, 'images');
    try
        delete(fullfile(imgdir, 'Composites', '*.png'));
        delete(fullfile(imgdir, 'Yrs', '*.png'));
        delete(fullfile(imgdir, 'Ycs', '*.png'));
    catch ME
        try
            recycle(oldState);
        catch ME2
            fprintf(getReport(ME2));
            % TODO
        end
        rethrow(ME);
    end
    recycle(oldState);
    reset(app.ImageStore);
end

if ~app.IProfPanel.Visible
    app.IProfPanel.Enable = true;
    app.IProfPanel.Visible = true;
end

% setVisibleDomain(app, [1 5]);

% args = cell(1,app.NumChannels);

%app.ChannelIPs = table( ...
%);
TF = true;
end