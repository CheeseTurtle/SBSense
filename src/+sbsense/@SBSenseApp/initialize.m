function initialize(app,reinit,camenable)
arguments
    app sbsense.SBSenseApp;
    reinit logical = false;
    camenable logical = true;
end
if reinit
    app.AlertArea.Value = "";
    app.AlertArea.BackgroundColor = "white";
    if ~isempty(app.VInputDeviceDropdown.Items) && ...
            ~isempty(app.VInputDeviceDropdown.Value) && ...
            strlength(app.VInputDeviceDropdown.Value)
        currDeviceName = app.VInputDeviceDropdown.Value;
    else
        currDeviceName = char.empty();
    end
    if isempty(app.RefImage)
        app.ChLayoutConfirmButton.Enable = false;
        app.ChLayoutConfirmButton.Icon = '';
    else
        app.ChLayoutConfirmButton.Enable = true;
        app.ChLayoutConfirmButton.Icon = 'warning';
    end

    set([app.MinYSpinner, app.MaxYSpinner, ...
        app.CroppedHeightField, app.CropRangePanel, ...
        app.ChannelLayoutPanel], 'Enable', true);
    set(findobj(app.ChLayoutPanel), 'Enable', true);
else % Not reinit
    % set(app.UIFigure, 'WindowButtonMotionFcn', @app.onMouseMove);
    % set(app.UIFigure, 'WindowButtonDownFcn', @app.onMouseButton);
    % set(app.UIFigure, 'WindowButtonUpFcn', @app.onMouseButton);
    % set(app.UIFigure, 'WindowScrollWheelFcn', @app.onMouseWheel);

    currDeviceName = char.empty();
    % TODO: Remove this if-block since not using preview timer
    if camenable
        if isa(app.PreviewTimer, 'timer') && ~isempty(app.PreviewTimer) % isvalid(app.previewTimer)
            %if any(strcmp(app.PreviewTimer.Running,"on"))
                stop(app.PreviewTimer);
            %end
            delete(app.PreviewTimer); % Or just keep it?
        end
        app.PreviewTimer = timer( ...
            'StartFcn', @(~,~) app.onPreviewTimerStart, ...
            'TimerFcn', @(~,~) app.onPreviewTimerTick, ...
            ... % 'StopFcn', @(~,~) app.onPreviewTimerStop, ...
            'ExecutionMode', 'fixedRate', ...
            'BusyMode', 'drop', ...
            'Name', 'SBSense_Preview', ...
            'StartDelay', 0, ...
            'TasksToExecute', Inf, ...
            'ObjectVisibility', 'off', ...
            'Tag', 'SBSense', ...
            'Period', 1.0 ... % TODO: Configurable period
            ... % 'ErrorFcn', @app.onPreviewTimerError, ...
            );
    end
end

app.IsRecording = false;
app.ConfirmStatus = false;
app.XNavZoomMode = false;
app.AxisLimitsCallbackEnabled = true;

% Reinitialize data storage variables
app.Composites = cell.empty();
app.Yrs = cell.empty();
app.Ycs = cell.empty();
app.SampMask0s = {};
app.SampMasks = {};
app.ROIMasks = {};

% ????
% enablePhaseI(app);


%varnames = arrayfun(@(n) sprintf('Channel%d', n), 1:app.NumChannels, 'UniformOutput', false);
%vartypes = cellstr(repelem("doublenan",1,app.NumChannels));
%app.ChannelIPs = table('Size', [0, app.NumChannels], ...
%    'VariableTypes', vartypes, 'VariableNames', varnames);
% TODO: Create ChannelIPs vars and/or Composites, Yrs, Ycs WHEN PHASE II STARTS (?)


% Index, RelTime, PSB, PSZL, PSZW, CFBL, CFBR, ResNorm, ELI, PeakLoc, PeakHgt

app.DataTable{1} = table('Size', [0, 5], 'VariableTypes', ...
    {'uint64', 'duration', 'uint16', 'uint16', 'doublenan'}, ...
    'VariableNames', {'Index', 'RelTime', 'PSBL','PSBR', 'ELI'},...
    'DimensionNames', {'Rows', 'Variables'});
app.DataTable{1} = mergevars(app.DataTable{1}, {'PSBL', 'PSBR'}, 'NewVariableName', 'PSB');
app.DataTable{1} = addvars(app.DataTable{1}, ...
    uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), ...
    double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
    NaN(0,app.NumChannels), ...
    'After', 'PSB', 'NewVariableNames', {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm'});
app.DataTable{1} = addvars(app.DataTable{1}, ...
    NaN(0,app.NumChannels, 'double'), NaN(0,app.NumChannels, 'double'), ...
    ... %double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
    'NewVariableNames', {'PeakLoc', 'PeakHgt'});
app.DataTable{1}.RelTime.Format = 's';

app.DataTable{2} = timetable('Size', [0, 4], 'VariableTypes', ...
    {'uint64', 'uint16', 'uint16', 'doublenan'}, ...
    'VariableNames', {'Index', 'PSBL','PSBR', 'ELI'},...
    'TimeStep', seconds(NaN), 'DimensionNames', {'RelTime', 'Variables'});
app.DataTable{2} = mergevars(app.DataTable{2}, {'PSBL', 'PSBR'}, 'NewVariableName', 'PSB');
app.DataTable{2} = addvars(app.DataTable{2}, ...
    uint16.empty(0,app.NumChannels), uint16.empty(0,app.NumChannels), ...
    double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
    NaN(0,app.NumChannels), ...
    'After', 'PSB', 'NewVariableNames', {'PSZL', 'PSZW', 'CFBL', 'CFBR', 'ResNorm'});
app.DataTable{2} = addvars(app.DataTable{2}, ...
    NaN(0,app.NumChannels, 'double'), NaN(0,app.NumChannels, 'double'), ...
    ... %double.empty(0,app.NumChannels), double.empty(0,app.NumChannels), ...
    'NewVariableNames', {'PeakLoc', 'PeakHgt'});

    % RelTime | Index, SplitStatus, IsDiscontinuity, Discontinuities, ROI
app.DataTable{3} = addvars(timetable('Size', [0, 4], 'VariableTypes', ...
    {'uint64' 'int8' 'logical' 'matlab.graphics.chart.decoration.ConstantLine'}, ... % 'images.roi.Line'}, ...
    'VariableNames', {'Index' 'SplitStatus' 'IsDiscontinuity' 'ROI'}, ...
    'TimeStep', seconds(NaN), 'DimensionNames', {'RelTime', 'Variables'}), ...
        logical.empty(0,app.NumChannels), 'After', 'IsDiscontinuity', ...
        'NewVariableNames', {'Discontinuities'});


% Number of variables:
%    00  ::  RelTime (duration)
%  + 01  ::  Index (uint64)
%  + 01  ::  EndIndex (uint64)
%  + 01  ::  IsActive (bool)
%  + 01  ::  PSZL (uint16)
%  + 01  ::  PSZW (uint16)
%  + 01  ::  EndIndex1 (uint64)
%  + 01  ::  PSZL1 (uint16)
%  + 01  ::  PSZW1 (uint16)
%  + 01  ::  ChangeFlags (bits)
%  + 01  ::  IsChanged (bool)
%  --------------------------
%  = 10

% ChangeFlags bits (LSB first)
% 1: IsNew
% 2: EndIndex changed
% 3: PSZL changed
% 4: PSZW changed
% ------------------
% 5: Params1 changed
% 6: Params2 changed
% 7: Params3 changed
% 8: Params4 changed
% ------------------
% ====> Datatype: uint8

app.ChunkTable = timetable('Size', [0, 10], ...
    'VariableTypes', {'uint64', 'uint64', 'logical', 'uint16', 'uint16', ...
        'uint64', 'uint16', 'uint16', ...
        'uint8', 'logical'}, ...
    'VariableNames', {'Index', 'EndIndex', 'IsActive', 'PSZL', 'PSZW', ...
        'EndIndex1' ,'PSZL1', 'PSZW1', ...
        'ChangeFlags', 'IsChanged'}, ...
    'DimensionNames', {'RelTime', 'Variables'}, 'TimeStep', seconds(NaN));

app.ChannelFBs = uint16.empty(0,2,app.NumChannels);
app.ChannelWgts = cell.empty(0,app.NumChannels);
app.ChannelWPs = cell.empty(0,3,app.NumChannels);
app.ChannelXData = cell.empty(0,app.NumChannels);

populateVInputDeviceDropdown(app, currDeviceName);
app.SessionDatepicker.Value = datetime('today');
end

% timetable('Size', [1 4], 'VariableTypes', {'datetime','double','string','double'}, 'SampleRate', 2, 'DimensionNames', {'RelTime', 'Variables'}, 'VariableNames', {'AbsTime)
% 
% RelTime, Index (uint64), PSB (uint16), AvgPL (double), AvgPH (double), ELI (double), PeakLocs, PeakHeights