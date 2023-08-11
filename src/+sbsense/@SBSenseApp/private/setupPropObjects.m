function setupPropObjects(app)
app.tl = tiledlayout(app.IProfPanel, 1, ...
    1, "TileSpacing", "tight", ...
    "Padding", "compact", "Interruptible", true, ...
    "TileIndexing", "rowmajor");

app.AnalysisParams = sbsense.AnalysisParameters( ...
    @() fprintf('<<notify>>'), app.AnalysisScale);
app.Analyzer = sbsense.Analyzer( ...
    app.ResQueue, @() fprintf('<<signal>>'), ...
    app.AnalysisParams);

% app.HCqueue = parallel.pool.DataQueue();
% app.APqueue = parallel.pool.DataQueue();
app.ResQueue = parallel.pool.DataQueue();
app.PlotQueue = parallel.pool.PollableDataQueue();
% afterEach(app.HCqueue, @app.HCqueueFcn);
% afterEach(app.APqueue, @app.APqueueFcn);
afterEach(app.ResQueue, @app.handleResData);

app.PlotTimer = timer('Name', 'PlotTimer', 'Period', 1.0, ... % TODO
    'ExecutionMode', 'fixedRate', ...
    'TimerFcn', @(tobj, ~) processPlotQueue(app, tobj), ...
    ... % 'ErrorFcn', @imaqcallback, ... % TODO
    ... %'StopFcn', @app.onPlotTimerStop, ... % TODO
    'BusyMode', 'drop', ...
    'UserData', parallel.Future.empty());
app.RFFObject = VideoReader("YP_7_catF.avi");%, "CurrentTime", 0);
% app.RFFTimer = timer('ExecutionMode', 'FixedSpacing', ...
%     'StartFcn', @sbsense.SBSenseApp.readNextFrame, ...
%     'TimerFcn', {@app.readNextFrame, app.Analyzer.HCQueue, ...
%     app.Analyzer.HCQueue, app.ResQueue}, ...
%     ... % 'StartFcn', @app.onRecordingStart, ...
%     ... % 'StopFcn', @app.onRecordingStop, ...
%     'Period', round(1/6,3, 'decimals', 'TieBreaker', 'fromzero'), ...
%     'UserData', struct('HCQueue', app.Analyzer.HCQueue, 'resQueue', app.ResQueue, 'shouldStop', false));
    % Add VideoReader to timer UD struct later
    % TODO: Error fcns
end