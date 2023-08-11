function onRecButtonValueChanged(app, varargin)
    if nargin==1
        src = app.RecButton;
    else
        src = varargin{1};
        % val = varargin{2}.Value;
    end
    val = src.Value;
    src.Enable = false;
    try
        if val % (START)
            src.Text = '(R)';
            % TODO: Add this back in
            if (~app.hasCamera && app.ReadFromFile) || ...
                (~app.LargestIndexReceived || ismissing(app.TimeZero) ...
                    || isequal(app.TimeZero, NaT) || isempty(app.AnalysisParams.CropRectangle))
                    fprintf('[onRecButtonValueChanged]:%u PREPARING FIRST RECORD\n', uint8(val));   
                try
                    TF = prepareFirstRecord(app);
                catch ME2
                    fprintf('Error "%s" encountered while attempting to initialize variables for recording: %s\n', ...
                        ME2.identifier, getReport(ME2));
                    TF = false;
                end
                if ~TF
                    app.IsRecording = false;
                    src.Text = 'R';
                    src.Value = false;
                    src.Enable = true;
                    return;
                end
                app.FPAxesGridPanel.Enable = true;
            end
            if startRecording(app)
                src.Interruptible = false;
                app.IsRecording = true;
            else
                src.Text = 'R';
                stopRecording(app);
                app.IsRecording = false;
            end
        else % (STOP)
            fprintf('%s (%03u) REC BUTTON "STOP" PUSHED.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0);
            src.Interruptible = false;
            try
                src.Text = 'R';
                stopRecording(app);
                app.IsRecording = false;
            catch ME1
                % src.Interruptible = true;
                rethrow(ME1);
            end
            % src.Interruptible = true;
        end
    catch ME
        fprintf('[onRecButtonValueChanged] Error "%s": %s\n', ...
            ME.identifier, getReport(ME));
        if app.IsRecording
            src.Text = '(R)';
        else
            src.Text = 'R';
            try
                stop(app.PlotTimer);
            catch ME2
                fprintf('Error "%s" encountered while stopping plot timer object: %s', ...
                    ME2.identifier, getReport(ME2));
            end
        end
        src.Value = app.IsRecording;
        src.Enable = true;
        % src.Interruptible = true;
        rethrow(ME);
    end
    src.Value = app.IsRecording;
    src.Enable = true;
end