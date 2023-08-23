% Code that executes after component creation
function startupFcn(app)
% set(app.pdlg, 'Value', 0.175,  'Message', 'Configuring figure window...');
waitbar(0.175, app.wbar, 'Configuring window...');
iptPointerManager(app.UIFigure);
app.UIFigure.Name = app.WindowTitleBase; % TODO: Version number, loaded file name
app.UIFigure.AutoResizeChildren = "on";
% set(app.pdlg, 'Value', 0.2,  'Message', 'Configuring components...');
waitbar(0.2, app.wbar, 'Configuring components...');
setupComponents(app);
app.NumChannels = 1; % TODO: Reset this and spinner during reinit as well
app.MaxMaxNumChs = length(app.ChanHgtFields);

app.UIFigure.WindowKeyPressFcn = {@app.onKeyboard};
app.UIFigure.WindowKeyReleaseFcn = {@app.onKeyboard};

imaqreset();
imaqmex('feature','-limitPhysicalMemoryUsage',false);

waitbar(0.3, app.wbar); % app.pdlg.Value = 0.3;
for pl = [app.propListeners app.leftLineListener ...
        app.rightLineListener app.topLineListener ...
        app.botLineListener app.rectListener app.roiClickListener ...
        app.divLineListeners app.divLineListeners2 ...
        app.divLineListeners3]
    if isa(pl, 'event.listener')
        delete(pl);
    end
end

waitbar(0.4, app.wbar); % app.pdlg.Value = 0.4;
setupComponentUserData(app);
% set(app.pdlg, 'Value', 0.5,  'Message', 'Setting up graphics and property objects...');
waitbar(0.175, app.wbar, 'Setting up graphics and property objects...');
setupROIs(app); % Also creates some ROI listeners

waitbar(0.6, app.wbar); % app.pdlg.Value = 0.6;

setupPropObjects(app);

%set(app.pdlg, 'Value', 0.75,  'Message', 'Setting up property and event listeners...');
waitbar(0.75, app.wbar, 'Setting up property and event listeners...');

setupPropListeners(app);

% set(app.pdlg, 'Value', 0.85,  'Message', 'Setting up axes objects...');
waitbar(0.85, app.wbar, 'Setting up axes objects...');

setupPreviewAxes(app);
setupFPAxes(app);

% set(app.pdlg, 'Value', 0.95,  'Message', 'Performing Analyzer and parameter object initialization...');
waitbar(0.95, app.wbar, 'Performing Analyzer and parameter object initialization...');


try
    usrdir = fullfile(getenv("USERPROFILE"), 'Documents');
catch
    try 
        usrdir = ['C:\Users\' getenv('USERNAME') '\Documents'];
        if ~isfolder(usrdir)
            usrdir = 'C:\My Documents';
        end
    catch
        usrdir = 'C:\My Documents';
    end
end

if isfolder(usrdir)
    rootDir = fullfile(usrdir, 'SBSense');
    [status,msg,msgID] = mkdir(usrdir, 'SBSense');
    app.RootDirectory = '';
    if status
        app.RootDirectory = rootDir;
    elseif isempty(msg)
        fprintf('Error occurred (%s)\n', msgID);
    elseif isempty(msgID)
        fprintf('Error occurred: %s\n', msg);
    else
        fprintf('Error "%s" occurred: %s\n', msgID, msg);
    end
else
    usrdir = 0;
    app.RootDirectory = '';
end

while isempty(app.RootDirectory) && (isequal(usrdir, 0) || ~isfolder(usrdir))
    usrdir = uigetdir(pwd, 'Select root directory for SBSense Application');
    if isequal(usrdir,0) || ~isfolder(usrdir)
        continue;
    end
    [status,msg,msgID] = mkdir(usrdir, 'SBSense');
    if status
        app.RootDirectory = fullfile(usrdir, 'SBSense');
    elseif isempty(msg)
        fprintf('Error occurred (%s)\n', msgID);
    elseif isempty(msgID)
        fprintf('Error occurred: %s\n', msg);
    else
        fprintf('Error "%s" occurred: %s\n', msgID, msg);
    end
    if ~status
        continue;
    end
end

% set(app.pdlg, 'Value', 1.0,  'Message', 'Done! Displaying interface window.');
waitbar(1.0, app.wbar, 'Done! Displaying interface window now.');
app.wbar.CloseRequestFcn = 'closereq'; %@(varargin) celldisp(varargin);
close(app.wbar);
delete(app.wbar);

initialize(app, false);

app.UIFigure.Visible = 'on';



% close(app.pdlg); delete(app.pdlg);




end