function setupPropListeners(app)

addlistener(app, 'RecordAbort', @(varargin) onRecordStop(app));

app.ChanCtlGroups = { ...
    [app.Ch1HeightField, app.Ch1HeightFieldLabel], ...
    [app.ChDivPositionsLabel, ...
    app.Ch2HeightField, app.Ch2HeightFieldLabel, ...
    app.ChDiv12Spinner, app.ChDiv12SpinnerLabel, ...
    app.ChDiv12HeightSpinner], ...
    [app.ChDiv23Spinner, app.ChDiv23SpinnerLabel, ...
    app.Ch3HeightField, app.Ch3HeightFieldLabel, ...
    app.ChDiv23HeightSpinner], ...
    [app.ChDiv34Spinner, app.ChDiv34SpinnerLabel, ...
    app.Ch4HeightField, app.Ch4HeightFieldLabel, ...
    app.ChDiv34HeightSpinner] ...
    [app.ChDiv45Spinner, app.ChDiv45SpinnerLabel, ...
    app.Ch5HeightField, app.Ch5HeightFieldLabel, ...
    app.ChDiv45HeightSpinner] ...
    [app.ChDiv56Spinner, app.ChDiv56SpinnerLabel, ...
    app.Ch6HeightField, app.Ch6HeightFieldLabel, ...
    app.ChDiv56HeightSpinner] };

app.propListeners = [ ...
    addlistener(app, {'EffHeight', 'NumChannels', 'CropBounds', 'TopCropBound', 'BotCropBound'}, ...
        'PostSet', @app.postset_EffSize) ...
    addlistener(app, {'PSBIndexes', 'PSBLeftIndex', 'PSBRightIndex'}, 'PostSet', @app.postset_PSBIndex) ...
    addlistener(app, {'hasBG', 'hasCamera'}, ...
        'PostSet', @app.postset_hasX) ...
    addlistener(app, 'PreviewActive', 'PostSet', @app.postset_PreviewActive) ...
    addlistener(app, 'ConfirmStatus', 'PostSet', @app.postset_ConfirmStatus) ...
    addlistener(app, 'XNavZoomMode', 'PreSet', @app.pxset_XNavZoomMode) ...
    addlistener(app, 'XNavZoomMode', 'PostSet', @app.pxset_XNavZoomMode) ...
    addlistener(app, 'LargestIndexReceived', 'PostSet', @app.postset_LargestIndexReceived) ...
    addlistener(app, 'SelectedIndex', 'PreSet', @app.postset_SelectedIndex) ...
    addlistener(app, 'SelectedIndex', 'PostSet', @app.postset_SelectedIndex) ...
    addlistener(app, 'PageLimits', 'PostSet', @app.postset_Page) ...
    ...%addlistener(app, {'PreviewFramerate', 'AcquisitionFramerate'}, 'PostSet', @app.postset_framerate) ...
    ...%addlistener(app, {'PreviewUsesTimer', 'AcquisitionUsesTimer'}, 'PostSet', @app.postset_usetimer) ...
    addlistener(app, {'IPPanelActive', 'IPPlotSelection'}, 'PostSet', @app.postset_IPPanelSelect) ...
    addlistener(app, {'CtrlDown', 'ShiftDown'}, 'PostSet', @app.postset_ModKeyDown) ...
    ];

app.propListeners(end).Enabled = false;

app.propLinks = [ ...
    linkprop([app.RefCaptureNoteLabel, ...
    app.RefExposureLabel, app.RefExposureCheckbox, ...
    app.RefBrightnessLabel, app.RefBrightnessCheckbox, ...
    app.RefGammaCheckbox, app.RefGammaLabel, ...
    app.RefCaptureSyncLamp, app.RefCaptureSyncLabel], ...
        'Enable') ...
    linkprop([app.CropRangePanel, app.MinYSpinner, app.MinYSpinnerLabel, ...
    app.MaxYSpinner, app.MaxYSpinnerLabel, app.CroppedHeightField, ...
    app.CroppedHeightLabel], 'Enable') ...
    linkprop([app.ChLayoutPanel, app.ChLayoutSubpanel, ...
    app.ChHeightsLabel, app.NumChSpinnerLabel], 'Enable') ...
    ... %...linkprop(findobj(app.ChLayoutPanel, '-property', 'Enable'), 'Enable') ...
    linkprop(findobj(app.BGStatsPanel, '-property', 'Enable'), 'Enable') ...
    linkprop(findobj([app.RatePanel app.RecPanel], '-property', 'Visible'), 'Visible') ... %'Enable'), 'Enable') ...
    linkprop(findobj([app.IProcPanel app.Phase2CenterGrid], '-property', 'Enable'), 'Enable') ...
    linkprop(findobj(app.Phase2RightGridPanel, '-property', 'Enable'), 'Enable') ...
    linkprop([app.PosAxesPanel app.PosAxes app.HgtAxes app.HgtAxesPanel], 'Visible') ...
    linkprop([reshape(app.FPXFields,1,4) app.FPXMinColonLabel app.FPXMaxColonLabel], 'Visible') ...
    linkprop([reshape(app.FPXFields,1,4) app.FPXMinColonLabel app.FPXMaxColonLabel], 'Enable') ...
    ];

%             linkprop([app.Ch1HeightField, app.Ch1HeightFieldLabel], ...
%                 'Enable') ...
%                 linkprop([app.ChDivPositionsLabel, ...
%                 app.ChDiv12Spinner, app.ChDiv12SpinnerLabel], 'Enable') ...
%                 linkprop([app.ChDiv12Spinner, app.ChDiv12SpinnerLabel, ...
%                 app.Ch2HeightField, app.Ch2HeightFieldLabel], 'Enable') ...
%                 linkprop([app.ChDiv23Spinner, app.ChDiv23SpinnerLabel, ...
%                 app.Ch3HeightField, app.Ch3HeightFieldLabel], 'Enable') ...
%                 linkprop([app.ChDiv34Spinner, app.ChDiv34SpinnerLabel, ...
%                 app.Ch4HeightField, app.Ch4HeightFieldLabel], 'Enable') ...
%                 linkprop([app.ChDiv45Spinner, app.ChDiv45SpinnerLabel, ...
%                 app.Ch5HeightField, app.Ch5HeightFieldLabel], 'Enable') ...
%                 linkprop([app.ChDiv56Spinner, app.ChDiv56SpinnerLabel, ...
%                 app.Ch6HeightField, app.Ch6HeightFieldLabel], 'Enable') ...
end


% ans{1}{1} =
% ipt
% ans{1}{2} =
%    484   681
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   0×0 empty GraphicsPlaceholder array.
% ans{2} =
%   WindowMouseData with properties:
% 
%        Source: [1×1 Figure]
%     EventName: 'WindowMousePress'
% ans{1}{1} =
% fig
% ans{1}{2} =
%    484   681
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   0×0 empty GraphicsPlaceholder array.
% ans{2} =
%   MouseData with properties:
% 
%        Source: [1×1 Figure]
%     EventName: 'ButtonDown'
% ans{1}{1} =
% ipt2
% ans{1}{2} =
%    484   681
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   0×0 empty GraphicsPlaceholder array.
% ans{2} =
%   MouseData with properties:
% 
%        Source: [1×1 Figure]
%     EventName: 'ButtonDown'



% ans{1}{1} =
% ipt
% ans{1}{2} =
%    613   610
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   Panel with properties:
% 
%               Title: ''
%     BackgroundColor: [0.9400 0.9400 0.9400]
%            Position: [20 20 1236 602]
%               Units: 'pixels'
% 
%   Use get to show all properties
% ans{2} =
%   WindowMouseData with properties:
% 
%        Source: [1×1 Figure]
%     EventName: 'WindowMousePress'
% ans{1}{1} =
% pan
% ans{1}{2} =
%    613   610
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   Panel with properties:
% 
%               Title: ''
%     BackgroundColor: [0.9400 0.9400 0.9400]
%            Position: [20 20 1236 602]
%               Units: 'pixels'
% 
%   Use get to show all properties
% ans{2} =
%   MouseData with properties:
% 
%        Source: [1×1 Panel]
%     EventName: 'ButtonDown'


% ans{1}{1} =
% ipt
% ans{1}{2} =
%    643    40
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   UIAxes with properties:
% 
%              XLim: [0 1]
%              YLim: [0 1]
%            XScale: 'linear'
%            YScale: 'linear'
%     GridLineStyle: '-'
%          Position: [10 10 1215 581]
%             Units: 'pixels'
% 
%   Use get to show all properties
% ans{2} =
%   WindowMouseData with properties:
% 
%        Source: [1×1 Figure]
%     EventName: 'WindowMousePress'
% ans{1}{1} =
% axis
% ans{1}{2} =
%    643    40
% ans{1}{3} =
%     off
% ans{1}{4} =
%     off
% ans{1}{5} =
%     off
% ans{1}{6} =
%   UIAxes with properties:
% 
%              XLim: [0 1]
%              YLim: [0 1]
%            XScale: 'linear'
%            YScale: 'linear'
%     GridLineStyle: '-'
%          Position: [10 10 1215 581]
%             Units: 'pixels'
% 
%   Use get to show all properties
% ans{2} =
%   Hit with properties:
% 
%                Button: 1
%     IntersectionPoint: [0.4980 -0.0166 0.0916]
%                Source: [1×1 UIAxes]
%             EventName: 'Hit'