function setupPreviewAxes(app)
app.liveimg = image('Parent', app.PreviewAxes, ...
    'CDataMapping', 'direct', 'HitTest', 'on', ...
    'AlphaDataMapping', 'direct', ...
    'AlphaData', 255, ...
    'Interpolation', 'nearest', ...
    'Interruptible', true, ... % was false
    'BusyAction', 'queue', ...
    'CData', [], ...
    'Clipping', false, ...
    'SelectionHighlight', false, ...
    'PickableParts', 'visible', 'Visible', false);

app.dataimg = image('Parent', app.DataImageAxes, ...
    'CDataMapping', 'scaled', 'HitTest', 'on', ...
    'PickableParts', 'visible', 'Visible', false, ...
    'CData', [], ...
    'ContextMenu', app.DataImageContextMenu);

app.overimg = image('Parent', app.DataImageAxes, ...
    'CDataMapping', 'scaled', 'HitTest', 'on', ...
    'AlphaDataMapping', 'none', 'AlphaData', 0.45, ...%0.15, ...
    'PickableParts', 'none', 'Visible', false, ...
    'CData', [], ...
    'ContextMenu', app.DataImageContextMenu);

app.maskimg = image('Parent', app.DataImageAxes, ...
    'CDataMapping', 'scaled', 'HitTest', 'on', ...
    'AlphaDataMapping', 'none', 'AlphaData', 0.25, ...
    'PickableParts', 'none', 'Visible', false, ...
    'CData', [], ...
    'ContextMenu', app.DataImageContextMenu);

disableDefaultInteractivity(app.PreviewAxes);
disableDefaultInteractivity(app.DataImageAxes);

set([app.DataImageAxes, app.PreviewAxes], ...
    'DataAspectRatioMode', 'manual', ...
    'DataAspectRatio', [1 1 1]);

%app.FileSourceSwitch.Enable = "off";
%app.FileSelector.Filter = { ...
%    '*.avi;*.mov;*.gif;*.mp4;*.wmv', 'Video files' ; ...
%    '*.*', 'All files' };
end