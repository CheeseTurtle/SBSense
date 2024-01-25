% Create UIFigure and components
function createComponents(app)

% Create UIFigure and hide until all components are created
app.UIFigure = uifigure('Visible', false);
app.UIFigure.Position = [100 100 1333 722];
app.UIFigure.Name = 'MATLAB App';
app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
%pdlg = uiprogressdlg(app.UIFigure, 'Value', 0.0, ...
%    'Title', 'The SBSense application is starting up...', ...
%    'Message', 'Creating menu and Phase I components...');
app.wbar = waitbar(0, 'Creating menus...', ...
    'Name', 'The SBSense application is starting up', ...
    'WindowStyle', 'modal');
% varargin: Figure, matlab.ui.eventdata.WindowCloseRequestData
app.wbar.CloseRequestFcn = @(~,~) closewbar(app);
% TODO: 'CreateCancelBtn' function handle... see documentation for effect on close/delete!

% Create context menus
app.PlotContextMenu = uicontextmenu(app.UIFigure, ...
    'ContextMenuOpeningFcn', '', ...
    'CreateFcn', '', ...
    'DeleteFcn', '', ...
    'Interruptible', 'on', ...
    'BusyAction', 'queue', ...
    'HandleVisibility', 'on', ...
    'Tag', 'plot'); %, 'UserData', []);


uimenu(app.PlotContextMenu, 'Text', 'Copy plot image to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'piC');
uimenu(app.PlotContextMenu, 'Text', 'Save plot image to file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'piF');

uimenu(app.PlotContextMenu, 'Text', 'Copy plot data to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'pdC', 'Separator', 'on');
uimenu(app.PlotContextMenu, 'Text', 'Save plot data to new Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'pdFn');
uimenu(app.PlotContextMenu, 'Text', 'Save plot data to existing Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'pdFo');

uimenu(app.PlotContextMenu, 'Text', 'Open plot in new Figure window', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportFigure, ...
    'Tag', 'p', 'Separator', 'on');


% Create FileMenu
app.FileMenu = uimenu(app.UIFigure);
app.FileMenu.Text = 'File    ';

% Create FileSaveSessionMenu
app.FileSaveSessionMenu = uimenu(app.FileMenu);
app.FileSaveSessionMenu.Enable = 'off';
app.FileSaveSessionMenu.Accelerator = 'S';
app.FileSaveSessionMenu.Text = 'Save session';

% Create FileLoadSessionMenu
app.FileLoadSessionMenu = uimenu(app.FileMenu);
app.FileLoadSessionMenu.Accelerator = 'O';
app.FileLoadSessionMenu.Text = 'Load Session';

% Create ImportReferenceImageMenu
app.ImportReferenceImageMenu = uimenu(app.FileMenu);
app.ImportReferenceImageMenu.Separator = 'on';
app.ImportReferenceImageMenu.Text = 'Import Reference Image';

% Create ExportReferenceImageMenu
app.ExportReferenceImageMenu = uimenu(app.FileMenu);
app.ExportReferenceImageMenu.Enable = 'off';
app.ExportReferenceImageMenu.Text = 'Export Reference Image';

% Create quick-export menu hierarchy
app.FileQuickExportMenu = uimenu(app.FileMenu, ...
    'Enable', 'on', 'Text', 'Quick export...', ...
    'Separator', 'on');
app.ExportNotesMenu = uimenu(app.FileQuickExportMenu, ...
    'Enable', 'off', 'Text', 'Session and datapoint notes', ...
    'MenuSelectedFcn', @app.quickExport_Notes);
app.ExportConfigSummaryMenu = uimenu(app.FileQuickExportMenu, ...
    'Enable', 'off', 'Text', 'Session technical summary', ...
    'Tooltip', 'Video device information and settings, image format/resolution, and channel layout', ...
    'MenuSelectedFcn', @app.quickExport_ConfigSummary);
app.ExportPrimaryDataMenu = uimenu(app.FileQuickExportMenu, 'Separator', 'on', ...
    'Enable', 'off', 'Text', 'Export primary data', ...
    'Tooltip', 'ELI, avg peak pos/hgt, peak search bounds', ...
    'MenuSelectedFcn', @app.quickExport_PrimaryData);
app.ExportChannelIPsMenu = uimenu(app.FileQuickExportMenu, ...
    'Enable', 'off', 'Text', 'Export channel intensity profiles', ...
    'MenuSelectedFcn', @app.quickExport_ChannelIPs);

app.ExportImagesMenu = uimenu(app.FileQuickExportMenu, ...
    'Enable', 'on', 'Text', 'Export images', ...
    'Separator', 'on');
app.ExportCompositesMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'off', 'Text', 'Export composite images', ...
    'Tooltip', 'The unprocessed images used for analysis', ...
    'MenuSelectedFcn', @app.quickExport_CompositeImages);
app.ExportYcsMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'off', 'Text', 'Export complement images', ...
    'Tooltip', 'TODO: Write tooltip text', ...
    'MenuSelectedFcn', @app.quickExport_ComplementImages);
app.ExportYrsMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'off', 'Text', 'Export ratio images', ...
    'Tooltip', 'TODO: Write tooltip text', ...
    'MenuSelectedFcn', @app.quickExport_RatioImages);
app.ExportWithMaskToggleMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'off', 'Text', 'Export with mask overlay?', ...
    'Separator', 'on', 'Tooltip', 'TODO: Write tooltip text', ...
    'MenuSelectedFcn', @app.quickExport_FeatureToggle, 'Tag', '0');
app.ExportWithMaskSelectionMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'on', 'Text', 'Choose mask overlay');
app.ExportWithMask1ToggleMenu = uimenu(app.ExportWithMaskSelectionMenu, ...
    'Enable', 'off', 'Text', 'ROI mask', 'Tag', '00', ...
    'MenuSelectedFcn', @app.quickExport_SelectFeature);
app.ExportWithMask2ToggleMenu = uimenu(app.ExportWithMaskSelectionMenu, ...
    'Enable', 'off', 'Text', 'SampMask0', 'Tag', '01', ...
    'MenuSelectedFcn', @app.quickExport_SelectFeature);
app.ExportWithMask3ToggleMenu = uimenu(app.ExportWithMaskSelectionMenu, ...
    'Enable', 'off', 'Text', 'SampMask', 'Tag', '02', ...
    'MenuSelectedFcn', @app.quickExport_SelectFeature);
app.ExportWithPeakLineToggleMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'off', 'Text', 'Mark image with index number?', 'Tag', '1', ...
    'Separator', 'on', 'MenuSelectedFcn', @app.quickExport_FeatureToggle);
app.ExportWithDPNumPosMenu = uimenu(app.ExportImagesMenu, ...
    'Enable', 'on', 'Text', 'Choose index number position');
app.ExportWithDPNumLeftToggleMenu = uimenu(app.ExportWithDPNumPosMenu, ...
    'Enable', 'off', 'Text', 'Write idx # on left edge', 'Tag', '10', ...
    'MenuSelectedFcn', @app.quickExport_SelectFeature);
app.ExportWithDPNumRightToggleMenu = uimenu(app.ExportWithDPNumPosMenu, ...
    'Enable', 'off', 'Text', 'Write idx # on right edge', 'Tag', '11', ...
    'MenuSelectedFcn', @app.quickExport_SelectFeature);

set([app.ExportWithMaskToggleMenu, ...
    app.ExportWithMask1ToggleMenu, app.ExportWithMask2ToggleMenu, ...
    app.ExportWithMask3ToggleMenu], 'UserData', app.ExportWithMaskSelectionMenu);
set([app.ExportWithDPNumToggleMenu, app.ExportWithDPNumLeftToggleMenu, ...
    app.ExportWithDPNumRightToggleMenu], 'UserData', app.ExportWithDPNumPosMenu);

% Create ImageViewMenu
app.ImageViewMenu = uimenu(app.UIFigure);
app.ImageViewMenu.Enable = 'off';
app.ImageViewMenu.Text = 'Image View    ';

% Create DisplayresolutionMenu
app.DisplayresolutionMenu = uimenu(app.ImageViewMenu);
app.DisplayresolutionMenu.Text = 'Display resolution...';

% Create ColormapMenu
app.ColormapMenu = uimenu(app.ImageViewMenu);
app.ColormapMenu.Text = 'Colormap';

% Create MonochromeMenu
app.MonochromeMenu = uimenu(app.ColormapMenu);
app.MonochromeMenu.Text = 'Monochrome';

% Create grayMenu
app.grayMenu = uimenu(app.MonochromeMenu);
app.grayMenu.Text = 'gray';

% Create boneMenu
app.boneMenu = uimenu(app.MonochromeMenu);
app.boneMenu.Text = 'bone';

% Create pinkMenu
app.pinkMenu = uimenu(app.MonochromeMenu);
app.pinkMenu.Text = 'pink';

% Create copperMenu
app.copperMenu = uimenu(app.MonochromeMenu);
app.copperMenu.Text = 'copper';

% Create TwoPoleMenu
app.TwoPoleMenu = uimenu(app.ColormapMenu);
app.TwoPoleMenu.Text = 'Two-Pole';

% Create parulaMenu
app.parulaMenu = uimenu(app.TwoPoleMenu);
app.parulaMenu.Text = 'parula';

% Create springMenu
app.springMenu = uimenu(app.TwoPoleMenu);
app.springMenu.Text = 'spring';

% Create summerMenu
app.summerMenu = uimenu(app.TwoPoleMenu);
app.summerMenu.Text = 'summer';

% Create autumnMenu
app.autumnMenu = uimenu(app.TwoPoleMenu);
app.autumnMenu.Text = 'autumn';

% Create winterMenu
app.winterMenu = uimenu(app.TwoPoleMenu);
app.winterMenu.Text = 'winter';

% Create coolMenu
app.coolMenu = uimenu(app.TwoPoleMenu);
app.coolMenu.Text = 'cool';

% Create SpectrumMenu
app.SpectrumMenu = uimenu(app.ColormapMenu);
app.SpectrumMenu.Text = 'Spectrum';

% Create hotMenu
app.hotMenu = uimenu(app.SpectrumMenu);
app.hotMenu.Text = 'hot';

% Create jetMenu
app.jetMenu = uimenu(app.SpectrumMenu);
app.jetMenu.Text = 'jet';

% Create turboMenu
app.turboMenu = uimenu(app.SpectrumMenu);
app.turboMenu.Text = 'turbo';

% Create hsvMenu
app.hsvMenu = uimenu(app.SpectrumMenu);
app.hsvMenu.Text = 'hsv';

% Create CaptureMenu
app.CaptureMenu = uimenu(app.UIFigure);
app.CaptureMenu.Enable = 'off';
app.CaptureMenu.Text = 'Capture';

app.CaptureResetMenuItem = uimenu(app.CaptureMenu);
app.CaptureResetMenuItem.Enable = 'off';
app.CaptureResetMenuItem.Text = 'Reset camera';
app.CaptureResetMenuItem.MenuSelectedFcn = @app.captureReset;

% Create FPPlotsMenu
app.FPPlotsMenu = uimenu(app.UIFigure);
app.FPPlotsMenu.Enable = 'off';
app.FPPlotsMenu.Text = 'Full-Profile Plots    ';

% Create IPPlotsMenu
app.IPPlotsMenu = uimenu(app.UIFigure);
app.IPPlotsMenu.Enable = 'off';
app.IPPlotsMenu.Text = 'Intensity Profile Plots    ';

% Create MainGridLayout
app.MainGridLayout = uigridlayout(app.UIFigure);
app.MainGridLayout.ColumnWidth = {'1x'};
app.MainGridLayout.RowHeight = {'1x', 30, 15};

% Create MainTabGroup
app.MainTabGroup = uitabgroup(app.MainGridLayout);
app.MainTabGroup.Layout.Row = 1;
app.MainTabGroup.Layout.Column = 1;
app.MainTabGroup.SelectionChangedFcn = @app.onMainTabSelectionChanged;

waitbar(0.02, app.wbar, 'Creating Phase I components...');

% Create Phase1Tab
app.Phase1Tab = uitab(app.MainTabGroup);
app.Phase1Tab.Title = 'Phase I - Acquire Reference';
app.Phase1Tab.Tag = '1';

% Create Phase1Grid
app.Phase1Grid = uigridlayout(app.Phase1Tab);
app.Phase1Grid.ColumnWidth = {340, '1x', 380}; %{339, '1x', 300};
app.Phase1Grid.RowHeight = {'1x'};
app.Phase1Grid.ColumnSpacing = 20;
app.Phase1Grid.Scrollable = 'on';

% Create Phase1RightGrid
app.Phase1RightGrid = uigridlayout(app.Phase1Grid);
app.Phase1RightGrid.ColumnWidth = {380}; %{300};
app.Phase1RightGrid.RowHeight = {35, 20, 100, 20, 300, '1x'};
app.Phase1RightGrid.ColumnSpacing = 0;
app.Phase1RightGrid.RowSpacing = 0;
app.Phase1RightGrid.Padding = [0 0 0 10];
app.Phase1RightGrid.Layout.Row = 1;
app.Phase1RightGrid.Layout.Column = 3;
app.Phase1RightGrid.Scrollable = 'on';

% Create ChLayoutPanel
app.ChLayoutPanel = uipanel(app.Phase1RightGrid);
app.ChLayoutPanel.Enable = 'off';
app.ChLayoutPanel.Title = 'Channel Layout';
app.ChLayoutPanel.Layout.Row = [5 6];
app.ChLayoutPanel.Layout.Column = 1;

% Create ChLayoutGrid
app.ChLayoutGrid = uigridlayout(app.ChLayoutPanel);
app.ChLayoutGrid.ColumnWidth = {'1x'};
app.ChLayoutGrid.RowHeight = {50, '1x'};
app.ChLayoutGrid.RowSpacing = 0;
app.ChLayoutGrid.Padding = [0 0 0 5];

% Create ChLayoutSubpanel
app.ChLayoutSubpanel = uipanel(app.ChLayoutGrid);
app.ChLayoutSubpanel.BorderType = 'none';
app.ChLayoutSubpanel.Layout.Row = 2;
app.ChLayoutSubpanel.Layout.Column = 1;

% Create ChLayoutGrid2
app.ChLayoutGrid2 = uigridlayout(app.ChLayoutSubpanel);
app.ChLayoutGrid2.ColumnWidth = {125, '1x'};
app.ChLayoutGrid2.RowHeight = {25, '1x'};
app.ChLayoutGrid2.RowSpacing = 0;
app.ChLayoutGrid2.Padding = [10 10 10 5];
app.ChLayoutGrid2.Scrollable = 'on';

% Create ChDivPositionsGrid
app.ChDivPositionsGrid = uigridlayout(app.ChLayoutGrid2);
app.ChDivPositionsGrid.ColumnWidth = {'1x', 75, 75};
app.ChDivPositionsGrid.RowHeight = {'1x', 25, '1x', 25, '1x', 25, '1x', 25, '1x', 25, '1x'};
app.ChDivPositionsGrid.RowSpacing = 0;
app.ChDivPositionsGrid.Layout.Row = 2;
app.ChDivPositionsGrid.Layout.Column = [2 3];

% Create ChDiv12SpinnerLabel
app.ChDiv12SpinnerLabel = uilabel(app.ChDivPositionsGrid);
app.ChDiv12SpinnerLabel.HorizontalAlignment = 'right';
app.ChDiv12SpinnerLabel.Enable = 'off';
app.ChDiv12SpinnerLabel.Layout.Row = 2;
app.ChDiv12SpinnerLabel.Layout.Column = 1;
app.ChDiv12SpinnerLabel.Text = '1 - 2';

% Create ChDiv12Spinner
app.ChDiv12Spinner = uispinner(app.ChDivPositionsGrid);
app.ChDiv12Spinner.ValueChangingFcn = @app.postmove_divline;%createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv12Spinner.ValueChangedFcn =  @app.postmove_divline;%createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv12Spinner.Tag = ('1p');
app.ChDiv12Spinner.Enable = 'off';
app.ChDiv12Spinner.Layout.Row = 2;
app.ChDiv12Spinner.Layout.Column = 2;

% Create ChDiv12HeightSpinner
app.ChDiv12HeightSpinner = uispinner(app.ChDivPositionsGrid);
set(app.ChDiv12HeightSpinner, 'ValueChangingFcn', @app.postmove_divline, ...
    'ValueChangedFcn', @app.postmove_divline, ...
    'Tag', '1h', 'Enable', 'off', 'Step', 2, 'Value', 1, 'Limits', [1 inf]);
app.ChDiv12HeightSpinner.Layout.Row = 2;
app.ChDiv12HeightSpinner.Layout.Column = 3;

% Create ChDiv23SpinnerLabel
app.ChDiv23SpinnerLabel = uilabel(app.ChDivPositionsGrid);
app.ChDiv23SpinnerLabel.HorizontalAlignment = 'right';
app.ChDiv23SpinnerLabel.Enable = 'off';
app.ChDiv23SpinnerLabel.Layout.Row = 4;
app.ChDiv23SpinnerLabel.Layout.Column = 1;
app.ChDiv23SpinnerLabel.Text = '2 - 3';

% Create ChDiv23Spinner
app.ChDiv23Spinner = uispinner(app.ChDivPositionsGrid);
app.ChDiv23Spinner.ValueChangingFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv23Spinner.ValueChangedFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv23Spinner.Tag = ('2p');
app.ChDiv23Spinner.Enable = 'off';
app.ChDiv23Spinner.Layout.Row = 4;
app.ChDiv23Spinner.Layout.Column = 2;

% Create ChDiv23HeightSpinner
app.ChDiv23HeightSpinner = uispinner(app.ChDivPositionsGrid);
set(app.ChDiv23HeightSpinner, 'ValueChangingFcn', @app.postmove_divline, ...
    'ValueChangedFcn', @app.postmove_divline, ...
    'Tag', '2h', 'Enable', 'off', 'Step', 2, 'Value', 1, 'Limits', [1 inf]);
app.ChDiv23HeightSpinner.Layout.Row = 4;
app.ChDiv23HeightSpinner.Layout.Column = 3;

% Create ChDiv34SpinnerLabel
app.ChDiv34SpinnerLabel = uilabel(app.ChDivPositionsGrid);
app.ChDiv34SpinnerLabel.HorizontalAlignment = 'right';
app.ChDiv34SpinnerLabel.Enable = 'off';
app.ChDiv34SpinnerLabel.Layout.Row = 6;
app.ChDiv34SpinnerLabel.Layout.Column = 1;
app.ChDiv34SpinnerLabel.Text = '3 - 4';

% Create ChDiv34Spinner
app.ChDiv34Spinner = uispinner(app.ChDivPositionsGrid);
app.ChDiv34Spinner.ValueChangingFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv34Spinner.ValueChangedFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv34Spinner.Tag = ('3p');
app.ChDiv34Spinner.Enable = 'off';
app.ChDiv34Spinner.Layout.Row = 6;
app.ChDiv34Spinner.Layout.Column = 2;

% Create ChDiv34HeightSpinner
app.ChDiv34HeightSpinner = uispinner(app.ChDivPositionsGrid);
set(app.ChDiv34HeightSpinner, 'ValueChangingFcn', @app.postmove_divline, ...
    'ValueChangedFcn', @app.postmove_divline, ...
    'Tag', '3h', 'Enable', 'off', 'Step', 2, 'Value', 1, 'Limits', [1 inf]);
app.ChDiv34HeightSpinner.Layout.Row = 6;
app.ChDiv34HeightSpinner.Layout.Column = 3;

% Create ChDiv45SpinnerLabel
app.ChDiv45SpinnerLabel = uilabel(app.ChDivPositionsGrid);
app.ChDiv45SpinnerLabel.HorizontalAlignment = 'right';
app.ChDiv45SpinnerLabel.Enable = 'off';
app.ChDiv45SpinnerLabel.Layout.Row = 8;
app.ChDiv45SpinnerLabel.Layout.Column = 1;
app.ChDiv45SpinnerLabel.Text = '4 - 5';

% Create ChDiv45Spinner
app.ChDiv45Spinner = uispinner(app.ChDivPositionsGrid);
app.ChDiv45Spinner.ValueChangingFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv45Spinner.ValueChangedFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv45Spinner.Tag = ('4p');
app.ChDiv45Spinner.Enable = 'off';
app.ChDiv45Spinner.Layout.Row = 8;
app.ChDiv45Spinner.Layout.Column = 2;

% Create ChDiv45HeightSpinner
app.ChDiv45HeightSpinner = uispinner(app.ChDivPositionsGrid);
set(app.ChDiv45HeightSpinner, 'ValueChangingFcn', @app.postmove_divline, ...
    'ValueChangedFcn', @app.postmove_divline, ...
    'Tag', '4h', 'Enable', 'off', 'Step', 2, 'Value', 1, 'Limits', [1 inf]);
app.ChDiv45HeightSpinner.Layout.Row = 8;
app.ChDiv45HeightSpinner.Layout.Column = 3;

% Create ChDiv56SpinnerLabel
app.ChDiv56SpinnerLabel = uilabel(app.ChDivPositionsGrid);
app.ChDiv56SpinnerLabel.HorizontalAlignment = 'right';
app.ChDiv56SpinnerLabel.Enable = 'off';
app.ChDiv56SpinnerLabel.Layout.Row = 10;
app.ChDiv56SpinnerLabel.Layout.Column = 1;
app.ChDiv56SpinnerLabel.Text = '5 - 6';

% Create ChDiv56Spinner
app.ChDiv56Spinner = uispinner(app.ChDivPositionsGrid);
app.ChDiv56Spinner.ValueChangingFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv56Spinner.ValueChangedFcn = @app.postmove_divline; % createCallbackFcn(app, @ChDiv12SpinnerValueChanging, true);
app.ChDiv56Spinner.Tag = ('5p');
app.ChDiv56Spinner.Enable = 'off';
app.ChDiv56Spinner.Layout.Row = 10;
app.ChDiv56Spinner.Layout.Column = 2;

% Create ChDiv56HeightSpinner
app.ChDiv56HeightSpinner = uispinner(app.ChDivPositionsGrid);
set(app.ChDiv56HeightSpinner, 'ValueChangingFcn', @app.postmove_divline, ...
    'ValueChangedFcn', @app.postmove_divline, ...
    'Tag', '5h', 'Enable', 'off', 'Step', 2, 'Value', 1, 'Limits', [1 inf]);
app.ChDiv56HeightSpinner.Layout.Row = 10;
app.ChDiv56HeightSpinner.Layout.Column = 3;

% Create ChDivPositionsLabel
app.ChDivPositionsLabel = uilabel(app.ChLayoutGrid2);
app.ChDivPositionsLabel.HorizontalAlignment = 'right';
app.ChDivPositionsLabel.VerticalAlignment = 'bottom';
app.ChDivPositionsLabel.Enable = 'off';
app.ChDivPositionsLabel.Layout.Row = 1;
app.ChDivPositionsLabel.Layout.Column = [2 3];
app.ChDivPositionsLabel.Text = {'Channel Divider Positions', '& Heights'};

% Create ChDivHeightsLabel
% app.ChDivHeightsLabel = uilabel(app.ChLayoutGrid2);


% Create ChHeightsGrid
app.ChHeightsGrid = uigridlayout(app.ChLayoutGrid2);
app.ChHeightsGrid.ColumnWidth = {'1x', 50};
app.ChHeightsGrid.RowHeight = {25, '1x', 25, '1x', 25, '1x', 25, '1x', 25, '1x', 25};
app.ChHeightsGrid.RowSpacing = 0;
app.ChHeightsGrid.Layout.Row = 2;
app.ChHeightsGrid.Layout.Column = 1;

% Create Ch1HeightFieldLabel
app.Ch1HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch1HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch1HeightFieldLabel.FontAngle = 'italic';
app.Ch1HeightFieldLabel.Enable = 'off';
app.Ch1HeightFieldLabel.Layout.Row = 1;
app.Ch1HeightFieldLabel.Layout.Column = 1;
app.Ch1HeightFieldLabel.Text = 'Ch. 1 ';

% Create Ch1HeightField
app.Ch1HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch1HeightField.Tag = ('1');
app.Ch1HeightField.Editable = 'off';
app.Ch1HeightField.FontAngle = 'italic';
app.Ch1HeightField.Enable = 'off';
app.Ch1HeightField.Layout.Row = 1;
app.Ch1HeightField.Layout.Column = 2;

% Create Ch2HeightFieldLabel
app.Ch2HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch2HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch2HeightFieldLabel.FontAngle = 'italic';
app.Ch2HeightFieldLabel.Enable = 'off';
app.Ch2HeightFieldLabel.Layout.Row = 3;
app.Ch2HeightFieldLabel.Layout.Column = 1;
app.Ch2HeightFieldLabel.Text = 'Ch. 2 ';

% Create Ch2HeightField
app.Ch2HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch2HeightField.Tag = ('2');
app.Ch2HeightField.Editable = 'off';
app.Ch2HeightField.FontAngle = 'italic';
app.Ch2HeightField.Enable = 'off';
app.Ch2HeightField.Layout.Row = 3;
app.Ch2HeightField.Layout.Column = 2;

% Create Ch3HeightFieldLabel
app.Ch3HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch3HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch3HeightFieldLabel.FontAngle = 'italic';
app.Ch3HeightFieldLabel.Enable = 'off';
app.Ch3HeightFieldLabel.Layout.Row = 5;
app.Ch3HeightFieldLabel.Layout.Column = 1;
app.Ch3HeightFieldLabel.Text = 'Ch. 3 ';

% Create Ch3HeightField
app.Ch3HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch3HeightField.Tag = ('3');
app.Ch3HeightField.Editable = 'off';
app.Ch3HeightField.FontAngle = 'italic';
app.Ch3HeightField.Enable = 'off';
app.Ch3HeightField.Layout.Row = 5;
app.Ch3HeightField.Layout.Column = 2;

% Create Ch4HeightFieldLabel
app.Ch4HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch4HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch4HeightFieldLabel.FontAngle = 'italic';
app.Ch4HeightFieldLabel.Enable = 'off';
app.Ch4HeightFieldLabel.Layout.Row = 7;
app.Ch4HeightFieldLabel.Layout.Column = 1;
app.Ch4HeightFieldLabel.Text = 'Ch. 4 ';

% Create Ch4HeightField
app.Ch4HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch4HeightField.Tag = ('4');
app.Ch4HeightField.Editable = 'off';
app.Ch4HeightField.FontAngle = 'italic';
app.Ch4HeightField.Enable = 'off';
app.Ch4HeightField.Layout.Row = 7;
app.Ch4HeightField.Layout.Column = 2;

% Create Ch5HeightFieldLabel
app.Ch5HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch5HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch5HeightFieldLabel.FontAngle = 'italic';
app.Ch5HeightFieldLabel.Enable = 'off';
app.Ch5HeightFieldLabel.Layout.Row = 9;
app.Ch5HeightFieldLabel.Layout.Column = 1;
app.Ch5HeightFieldLabel.Text = 'Ch. 5 ';

% Create Ch5HeightField
app.Ch5HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch5HeightField.Tag = ('5');
app.Ch5HeightField.Editable = 'off';
app.Ch5HeightField.FontAngle = 'italic';
app.Ch5HeightField.Enable = 'off';
app.Ch5HeightField.Layout.Row = 9;
app.Ch5HeightField.Layout.Column = 2;

% Create Ch6HeightFieldLabel
app.Ch6HeightFieldLabel = uilabel(app.ChHeightsGrid);
app.Ch6HeightFieldLabel.HorizontalAlignment = 'right';
app.Ch6HeightFieldLabel.FontAngle = 'italic';
app.Ch6HeightFieldLabel.Enable = 'off';
app.Ch6HeightFieldLabel.Layout.Row = 11;
app.Ch6HeightFieldLabel.Layout.Column = 1;
app.Ch6HeightFieldLabel.Text = 'Ch. 6 ';

% Create Ch6HeightField
app.Ch6HeightField = uieditfield(app.ChHeightsGrid, 'numeric');
app.Ch6HeightField.Tag = ('6');
app.Ch6HeightField.Editable = 'off';
app.Ch6HeightField.FontAngle = 'italic';
app.Ch6HeightField.Enable = 'off';
app.Ch6HeightField.Layout.Row = 11;
app.Ch6HeightField.Layout.Column = 2;

% Create ChHeightsLabel
app.ChHeightsLabel = uilabel(app.ChLayoutGrid2);
app.ChHeightsLabel.HorizontalAlignment = 'center';
app.ChHeightsLabel.VerticalAlignment = 'bottom';
app.ChHeightsLabel.FontAngle = 'italic';
app.ChHeightsLabel.Enable = 'off';
app.ChHeightsLabel.Layout.Row = 1;
app.ChHeightsLabel.Layout.Column = 1;
app.ChHeightsLabel.Text = 'Channel Heights';

% Create ChLayoutGrid1
app.ChLayoutGrid1 = uigridlayout(app.ChLayoutGrid);
app.ChLayoutGrid1.ColumnWidth = {100, 10, 55, '1x', 30, 30, 30, '1x'};
app.ChLayoutGrid1.RowHeight = {30};
app.ChLayoutGrid1.ColumnSpacing = 0;
app.ChLayoutGrid1.RowSpacing = 0;
app.ChLayoutGrid1.Layout.Row = 1;
app.ChLayoutGrid1.Layout.Column = 1;

% Create NumChSpinnerLabel
app.NumChSpinnerLabel = uilabel(app.ChLayoutGrid1);
app.NumChSpinnerLabel.HorizontalAlignment = 'right';
app.NumChSpinnerLabel.Enable = 'off';
app.NumChSpinnerLabel.Layout.Row = 1;
app.NumChSpinnerLabel.Layout.Column = 1;
app.NumChSpinnerLabel.Text = {'Number '; 'of channels'};

% Create NumChSpinner
app.NumChSpinner = uispinner(app.ChLayoutGrid1);
app.NumChSpinner.Limits = [1 6];
app.NumChSpinner.ValueDisplayFormat = '%.0f';
app.NumChSpinner.ValueChangedFcn = createCallbackFcn(app, @NumChSpinnerValueChanged, true);
app.NumChSpinner.Enable = 'off';
app.NumChSpinner.Layout.Row = 1;
app.NumChSpinner.Layout.Column = 3;
app.NumChSpinner.Value = 1;

% Create ChLayoutResetButton
app.ChLayoutResetButton = uibutton(app.ChLayoutGrid1, 'push');
app.ChLayoutResetButton.ButtonPushedFcn = createCallbackFcn(app, @ChLayoutResetButtonPushed, true);
app.ChLayoutResetButton.Enable = 'off';
app.ChLayoutResetButton.Layout.Row = 1;
app.ChLayoutResetButton.Layout.Column = 5;
app.ChLayoutResetButton.Text = 'R';

% Create ChLayoutImportButton
app.ChLayoutImportButton = uibutton(app.ChLayoutGrid1, 'push');
app.ChLayoutImportButton.ButtonPushedFcn = createCallbackFcn(app, @ChLayoutImportButtonPushed, true);
app.ChLayoutImportButton.Enable = 'off';
app.ChLayoutImportButton.Layout.Row = 1;
app.ChLayoutImportButton.Layout.Column = 6;
app.ChLayoutImportButton.Text = 'I';

% Create ChLayoutExportButton
app.ChLayoutExportButton = uibutton(app.ChLayoutGrid1, 'push');
app.ChLayoutExportButton.ButtonPushedFcn = createCallbackFcn(app, @ChLayoutExportButtonPushed, true);
app.ChLayoutExportButton.Enable = 'off';
app.ChLayoutExportButton.Layout.Row = 1;
app.ChLayoutExportButton.Layout.Column = 7;
app.ChLayoutExportButton.Text = 'E';

% Create CropRangePanel
app.CropRangePanel = uipanel(app.Phase1RightGrid);
app.CropRangePanel.Enable = 'off';
app.CropRangePanel.Title = 'Crop Range';
app.CropRangePanel.Layout.Row = 3;
app.CropRangePanel.Layout.Column = 1;

% Create CropRangeGrid
app.CropRangeGrid = uigridlayout(app.CropRangePanel);
app.CropRangeGrid.ColumnWidth = {'fit', '1x', 'fit'};
app.CropRangeGrid.RowHeight = {'1x'};
app.CropRangeGrid.ColumnSpacing = 0;
app.CropRangeGrid.Padding = [0 0 10 0];

% Create CropRangeHeightGrid
app.CropRangeHeightGrid = uigridlayout(app.CropRangeGrid);
app.CropRangeHeightGrid.ColumnWidth = {'1x', 50};
app.CropRangeHeightGrid.RowHeight = {'1x', '1x', '1x'};
app.CropRangeHeightGrid.Padding = [0 0 0 0];
app.CropRangeHeightGrid.Layout.Row = 1;
app.CropRangeHeightGrid.Layout.Column = 3;

% Create CroppedHeightLabel
app.CroppedHeightLabel = uilabel(app.CropRangeHeightGrid);
app.CroppedHeightLabel.HorizontalAlignment = 'right';
app.CroppedHeightLabel.FontAngle = 'italic';
app.CroppedHeightLabel.Enable = 'off';
app.CroppedHeightLabel.Layout.Row = 2;
app.CroppedHeightLabel.Layout.Column = 1;
app.CroppedHeightLabel.Text = 'Cropped Height';

% Create CroppedHeightField
app.CroppedHeightField = uieditfield(app.CropRangeHeightGrid, 'numeric');
app.CroppedHeightField.RoundFractionalValues = 'on';
app.CroppedHeightField.ValueDisplayFormat = '%4d';
app.CroppedHeightField.Editable = 'off';
app.CroppedHeightField.FontAngle = 'italic';
app.CroppedHeightField.Enable = 'off';
app.CroppedHeightField.Layout.Row = 2;
app.CroppedHeightField.Layout.Column = 2;

% Create CropRangeMinMaxGrid
app.CropRangeMinMaxGrid = uigridlayout(app.CropRangeGrid);
app.CropRangeMinMaxGrid.ColumnWidth = {35, 80};
app.CropRangeMinMaxGrid.Layout.Row = 1;
app.CropRangeMinMaxGrid.Layout.Column = 1;

% Create MinYSpinnerLabel
app.MinYSpinnerLabel = uilabel(app.CropRangeMinMaxGrid);
app.MinYSpinnerLabel.HorizontalAlignment = 'right';
app.MinYSpinnerLabel.Enable = 'off';
app.MinYSpinnerLabel.Layout.Row = 1;
app.MinYSpinnerLabel.Layout.Column = 1;
app.MinYSpinnerLabel.Text = 'Min Y';

% Create MinYSpinner
app.MinYSpinner = uispinner(app.CropRangeMinMaxGrid);
app.MinYSpinner.Tag = ('1');
app.MinYSpinner.Enable = 'off';
app.MinYSpinner.Layout.Row = 1;
app.MinYSpinner.Layout.Column = 2;

% Create MaxYSpinnerLabel
app.MaxYSpinnerLabel = uilabel(app.CropRangeMinMaxGrid);
app.MaxYSpinnerLabel.HorizontalAlignment = 'right';
app.MaxYSpinnerLabel.Enable = 'off';
app.MaxYSpinnerLabel.Layout.Row = 2;
app.MaxYSpinnerLabel.Layout.Column = 1;
app.MaxYSpinnerLabel.Text = 'Max Y';

% Create MaxYSpinner
app.MaxYSpinner = uispinner(app.CropRangeMinMaxGrid);
app.MaxYSpinner.Tag = ('2');
app.MaxYSpinner.Enable = 'off';
app.MaxYSpinner.Layout.Row = 2;
app.MaxYSpinner.Layout.Column = 2;

% Create ChLayoutConfirmButtonGrid
app.ChLayoutConfirmButtonGrid = uigridlayout(app.Phase1RightGrid);
app.ChLayoutConfirmButtonGrid.ColumnWidth = {'3x', '5x', '3x'};
app.ChLayoutConfirmButtonGrid.RowHeight = {35};
app.ChLayoutConfirmButtonGrid.RowSpacing = 0;
app.ChLayoutConfirmButtonGrid.Padding = [0 0 0 0];
app.ChLayoutConfirmButtonGrid.Layout.Row = 1;
app.ChLayoutConfirmButtonGrid.Layout.Column = 1;

% Create ChLayoutConfirmButton
app.ChLayoutConfirmButton = uibutton(app.ChLayoutConfirmButtonGrid, 'push');
app.ChLayoutConfirmButton.ButtonPushedFcn = createCallbackFcn(app, @ChLayoutConfirmButtonPushed, true);
app.ChLayoutConfirmButton.Icon = 'success';
app.ChLayoutConfirmButton.FontWeight = 'bold';
app.ChLayoutConfirmButton.Enable = 'off';
app.ChLayoutConfirmButton.Layout.Row = 1;
app.ChLayoutConfirmButton.Layout.Column = 2;
app.ChLayoutConfirmButton.Text = 'Confirm Layout';

% Create Phase1CenterGrid
app.Phase1CenterGrid = uigridlayout(app.Phase1Grid);
app.Phase1CenterGrid.ColumnWidth = {'1x'};
app.Phase1CenterGrid.RowHeight = {'1x', 80, 100};
app.Phase1CenterGrid.Padding = [0 0 0 0];
app.Phase1CenterGrid.Layout.Row = 1;
app.Phase1CenterGrid.Layout.Column = 2;

% Create BGStatsPanel
app.BGStatsPanel = uipanel(app.Phase1CenterGrid);
app.BGStatsPanel.Enable = 'off';
app.BGStatsPanel.BorderType = 'none';
app.BGStatsPanel.TitlePosition = 'centertop';
app.BGStatsPanel.Title = 'Background Image Statistics';
app.BGStatsPanel.Layout.Row = 3;
app.BGStatsPanel.Layout.Column = 1;
app.BGStatsPanel.Scrollable = 'on';

% Create BGStatsGrid
app.BGStatsGrid = uigridlayout(app.BGStatsPanel);
app.BGStatsGrid.ColumnWidth = {'3x', 60, 10, '1x', '1x', '1x', 60, 10, '1x', '3x'};
app.BGStatsGrid.ColumnSpacing = 0;
app.BGStatsGrid.Scrollable = 'on';

% Create BGMaxCountLabel
app.BGMaxCountLabel = uilabel(app.BGStatsGrid);
app.BGMaxCountLabel.HorizontalAlignment = 'right';
app.BGMaxCountLabel.Enable = 'off';
app.BGMaxCountLabel.Layout.Row = 2;
app.BGMaxCountLabel.Layout.Column = 7;
app.BGMaxCountLabel.Text = 'Max count';

% Create BGMaxCountField
app.BGMaxCountField = uieditfield(app.BGStatsGrid, 'numeric');
app.BGMaxCountField.Limits = [0 Inf];
app.BGMaxCountField.RoundFractionalValues = 'on';
app.BGMaxCountField.ValueDisplayFormat = '%7.0g';
app.BGMaxCountField.Editable = 'off';
app.BGMaxCountField.Enable = 'off';
app.BGMaxCountField.Layout.Row = 2;
app.BGMaxCountField.Layout.Column = 9;

% Create BGMinCountField
app.BGMinCountField = uieditfield(app.BGStatsGrid, 'numeric');
app.BGMinCountField.Limits = [0 Inf];
app.BGMinCountField.RoundFractionalValues = 'on';
app.BGMinCountField.ValueDisplayFormat = '%6.0g';
app.BGMinCountField.Editable = 'off';
app.BGMinCountField.Enable = 'off';
app.BGMinCountField.Layout.Row = 2;
app.BGMinCountField.Layout.Column = 4;

% Create BGMinCountLabel
app.BGMinCountLabel = uilabel(app.BGStatsGrid);
app.BGMinCountLabel.HorizontalAlignment = 'right';
app.BGMinCountLabel.Enable = 'off';
app.BGMinCountLabel.Layout.Row = 2;
app.BGMinCountLabel.Layout.Column = 2;
app.BGMinCountLabel.Text = 'Min count';

% Create BGMaxValueField
app.BGMaxValueField = uieditfield(app.BGStatsGrid, 'numeric');
app.BGMaxValueField.ValueDisplayFormat = '% -3.4g';
app.BGMaxValueField.Editable = 'off';
app.BGMaxValueField.Enable = 'off';
app.BGMaxValueField.Layout.Row = 1;
app.BGMaxValueField.Layout.Column = 9;

% Create BGMaxValueLabel
app.BGMaxValueLabel = uilabel(app.BGStatsGrid);
app.BGMaxValueLabel.HorizontalAlignment = 'right';
app.BGMaxValueLabel.Enable = 'off';
app.BGMaxValueLabel.Layout.Row = 1;
app.BGMaxValueLabel.Layout.Column = 7;
app.BGMaxValueLabel.Text = 'Max value';

% Create BGMinValueField
app.BGMinValueField = uieditfield(app.BGStatsGrid, 'numeric');
app.BGMinValueField.ValueDisplayFormat = '% -3.4g';
app.BGMinValueField.Editable = 'off';
app.BGMinValueField.Enable = 'off';
app.BGMinValueField.Layout.Row = 1;
app.BGMinValueField.Layout.Column = 4;

% Create BGMinValueLabel
app.BGMinValueLabel = uilabel(app.BGStatsGrid);
app.BGMinValueLabel.HorizontalAlignment = 'right';
app.BGMinValueLabel.Enable = 'off';
app.BGMinValueLabel.Layout.Row = 1;
app.BGMinValueLabel.Layout.Column = 2;
app.BGMinValueLabel.Text = 'Min value';

% Create RefDisplayControlsGrid
app.RefDisplayControlsGrid = uigridlayout(app.Phase1CenterGrid);
app.RefDisplayControlsGrid.ColumnWidth = {'1x', 120, 15, 'fit', 15, 100, '1x'};
app.RefDisplayControlsGrid.RowHeight = {40, 30};
app.RefDisplayControlsGrid.RowSpacing = 5;
app.RefDisplayControlsGrid.Padding = [0 0 0 0];
app.RefDisplayControlsGrid.Layout.Row = 2;
app.RefDisplayControlsGrid.Layout.Column = 1;

% Create BGImportExportLabel
app.BGImportExportLabel = uilabel(app.RefDisplayControlsGrid);
app.BGImportExportLabel.HorizontalAlignment = 'center';
app.BGImportExportLabel.VerticalAlignment = 'top';
app.BGImportExportLabel.Enable = 'off';
app.BGImportExportLabel.Layout.Row = 2;
app.BGImportExportLabel.Layout.Column = 6;
app.BGImportExportLabel.Text = {'Import/Export'; 'Reference Image'};

% Create RefImportExportGrid
app.RefImportExportGrid = uigridlayout(app.RefDisplayControlsGrid);
app.RefImportExportGrid.ColumnWidth = {40, 40};
app.RefImportExportGrid.RowHeight = {'1x'};
app.RefImportExportGrid.Padding = [5 0 5 0];
app.RefImportExportGrid.Layout.Row = 1;
app.RefImportExportGrid.Layout.Column = 6;

% Create ExportBGButton
app.ExportBGButton = uibutton(app.RefImportExportGrid, 'push');
app.ExportBGButton.ButtonPushedFcn = createCallbackFcn(app, @ExportBGButtonPushed, true);
app.ExportBGButton.Enable = 'off';
app.ExportBGButton.Layout.Row = 1;
app.ExportBGButton.Layout.Column = 2;
app.ExportBGButton.Text = 'E';

% Create ImportBGButton
app.ImportBGButton = uibutton(app.RefImportExportGrid, 'push');
app.ImportBGButton.ButtonPushedFcn = createCallbackFcn(app, @ImportBGButtonPushed, true);
app.ImportBGButton.Layout.Row = 1;
app.ImportBGButton.Layout.Column = 1;
app.ImportBGButton.Text = 'I';

% Create RefCaptureButtonGrid
app.RefCaptureButtonGrid = uigridlayout(app.RefDisplayControlsGrid);
app.RefCaptureButtonGrid.ColumnWidth = {40};
app.RefCaptureButtonGrid.RowHeight = {'1x'};
app.RefCaptureButtonGrid.Padding = [50 0 50 0];
app.RefCaptureButtonGrid.Layout.Row = 1;
app.RefCaptureButtonGrid.Layout.Column = 4;

% Create CaptureBGButton
app.CaptureBGButton = uibutton(app.RefCaptureButtonGrid, 'push');
app.CaptureBGButton.ButtonPushedFcn = createCallbackFcn(app, @CaptureBGButtonPushed, true);
app.CaptureBGButton.Enable = 'off';
app.CaptureBGButton.Tooltip = {'Save reference image'};
app.CaptureBGButton.Layout.Row = 1;
app.CaptureBGButton.Layout.Column = 1;
app.CaptureBGButton.Text = 'Capture reference image';

% Create CaptureBGButtonLabel
app.CaptureBGButtonLabel = uilabel(app.RefDisplayControlsGrid);
app.CaptureBGButtonLabel.HorizontalAlignment = 'center';
app.CaptureBGButtonLabel.VerticalAlignment = 'top';
app.CaptureBGButtonLabel.Enable = 'off';
app.CaptureBGButtonLabel.Layout.Row = 2;
app.CaptureBGButtonLabel.Layout.Column = 4;
app.CaptureBGButtonLabel.Text = {'Capture New'; 'Reference Image'};

% Create BGPreviewSwitchLabel
app.BGPreviewSwitchLabel = uilabel(app.RefDisplayControlsGrid);
app.BGPreviewSwitchLabel.HorizontalAlignment = 'center';
app.BGPreviewSwitchLabel.VerticalAlignment = 'top';
app.BGPreviewSwitchLabel.Enable = 'off';
app.BGPreviewSwitchLabel.Layout.Row = 2;
app.BGPreviewSwitchLabel.Layout.Column = 2;
app.BGPreviewSwitchLabel.Text = {'Captured image'; '/ Live feed display'};

% Create BGPreviewSwitch
app.BGPreviewSwitch = uiswitch(app.RefDisplayControlsGrid, 'slider');
app.BGPreviewSwitch.Items = {'Cap', 'Live'};
app.BGPreviewSwitch.ItemsData = {'0', '1'};
app.BGPreviewSwitch.ValueChangedFcn = createCallbackFcn(app, @BGPreviewSwitchValueChanged, true);
app.BGPreviewSwitch.Enable = 'off';
app.BGPreviewSwitch.Layout.Row = 1;
app.BGPreviewSwitch.Layout.Column = 2;
app.BGPreviewSwitch.Value = '0';

% Create PreviewAxesGridPanel
app.PreviewAxesGridPanel = uipanel(app.Phase1CenterGrid);
app.PreviewAxesGridPanel.BorderType = 'none';
app.PreviewAxesGridPanel.Layout.Row = 1;
app.PreviewAxesGridPanel.Layout.Column = 1;

% Create PreviewAxesGrid
app.PreviewAxesGrid = uigridlayout(app.PreviewAxesGridPanel);
app.PreviewAxesGrid.ColumnWidth = {'1x'};
app.PreviewAxesGrid.RowHeight = {'1x'};
app.PreviewAxesGrid.Padding = [0 0 0 0];

% Create PreviewAxes
app.PreviewAxes = uiaxes(app.PreviewAxesGrid);
app.PreviewAxes.Toolbar.Visible = 'off';
app.PreviewAxes.CameraUpVector = [0 1 0];
app.PreviewAxes.CameraViewAngle = 6.86726051912591;
app.PreviewAxes.DataAspectRatio = [3264 2448 1];
app.PreviewAxes.PlotBoxAspectRatio = [3264 2448 1];
app.PreviewAxes.TickLabelInterpreter = 'none';
app.PreviewAxes.XLim = [-5326847.5 5326848.5];
app.PreviewAxes.YLim = [-2996351.5 2996352.5];
app.PreviewAxes.ZLim = [0 1];
app.PreviewAxes.Layer = 'top';
app.PreviewAxes.XColor = [0.15 0.15 0.15];
app.PreviewAxes.XTick = [];
app.PreviewAxes.XTickLabelRotation = 0;
app.PreviewAxes.XTickLabel = '';
app.PreviewAxes.YColor = [0.15 0.15 0.15];
app.PreviewAxes.YTick = [];
app.PreviewAxes.YTickLabelRotation = 0;
app.PreviewAxes.YTickLabel = '';
app.PreviewAxes.ZColor = [0.15 0.15 0.15];
app.PreviewAxes.ZTick = [0 0.5 1];
app.PreviewAxes.ZTickLabelRotation = 0;
app.PreviewAxes.LineWidth = 1;
app.PreviewAxes.Color = [1 1 0.0667];
app.PreviewAxes.ClippingStyle = 'rectangle';
app.PreviewAxes.FontSize = 12;
app.PreviewAxes.TickDir = 'in';
app.PreviewAxes.Clipping = 'off';
app.PreviewAxes.NextPlot = 'add';
app.PreviewAxes.Box = 'on';
app.PreviewAxes.Layout.Row = 1;
app.PreviewAxes.Layout.Column = 1;
app.PreviewAxes.ButtonDownFcn = createCallbackFcn(app, @PreviewAxesButtonDown, true);
app.PreviewAxes.BusyAction = 'queue'; % was 'cancel'
app.PreviewAxes.HitTest = 'on';
app.PreviewAxes.Visible = 'off';
colormap(app.PreviewAxes, 'gray')

% Create Phase1LeftGrid
app.Phase1LeftGrid = uigridlayout(app.Phase1Grid);
app.Phase1LeftGrid.ColumnWidth = {'1x'};
app.Phase1LeftGrid.RowHeight = {'fit', '1x', 10, 'fit', 10, 290, '1x'};
app.Phase1LeftGrid.ColumnSpacing = 0;
app.Phase1LeftGrid.RowSpacing = 0;
app.Phase1LeftGrid.Padding = [0 0 0 0];
app.Phase1LeftGrid.Layout.Row = 1;
app.Phase1LeftGrid.Layout.Column = 1;
app.Phase1LeftGrid.Scrollable = 'on';

% Create SessionInfoPanel
app.SessionInfoPanel = uipanel(app.Phase1LeftGrid);
app.SessionInfoPanel.Title = 'Experiment Session Information';
app.SessionInfoPanel.Layout.Row = [6 7];
app.SessionInfoPanel.Layout.Column = 1;

% Create SessionInfoGrid
app.SessionInfoGrid = uigridlayout(app.SessionInfoPanel);
app.SessionInfoGrid.ColumnWidth = {'1x'};
app.SessionInfoGrid.RowHeight = {70, 20, 50, 20, '1x'};
app.SessionInfoGrid.RowSpacing = 0;

% Create SessionInfoHeaderGrid
app.SessionInfoHeaderGrid = uigridlayout(app.SessionInfoGrid);
app.SessionInfoHeaderGrid.ColumnWidth = {95, '1x'};
app.SessionInfoHeaderGrid.Padding = [0 10 0 0];
app.SessionInfoHeaderGrid.Layout.Row = 1;
app.SessionInfoHeaderGrid.Layout.Column = 1;

% Create SessionDatepickerLabel
app.SessionDatepickerLabel = uilabel(app.SessionInfoHeaderGrid);
app.SessionDatepickerLabel.HorizontalAlignment = 'right';
app.SessionDatepickerLabel.Layout.Row = 2;
app.SessionDatepickerLabel.Layout.Column = 1;
app.SessionDatepickerLabel.Text = 'Session Date';

% Create SessionDatepicker
app.SessionDatepicker = uidatepicker(app.SessionInfoHeaderGrid);
app.SessionDatepicker.DisplayFormat = 'dd/MMM/uuuu';
app.SessionDatepicker.Tooltip = {'Note: H:M:S time is automatically recorded for each datapoint during data acquisition.'};
app.SessionDatepicker.Layout.Row = 2;
app.SessionDatepicker.Layout.Column = 2;

% Create SessionTitleLabel
app.SessionTitleLabel = uilabel(app.SessionInfoHeaderGrid);
app.SessionTitleLabel.HorizontalAlignment = 'right';
app.SessionTitleLabel.Layout.Row = 1;
app.SessionTitleLabel.Layout.Column = 1;
app.SessionTitleLabel.Text = 'Session Title';

% Create SessionTitleField
app.SessionTitleField = uieditfield(app.SessionInfoHeaderGrid, 'text');
app.SessionTitleField.CharacterLimits = [0 128];
app.SessionTitleField.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionTitleField.Layout.Row = 1;
app.SessionTitleField.Layout.Column = 2;

% Create SessionNotesLabel
app.SessionNotesLabel = uilabel(app.SessionInfoGrid);
app.SessionNotesLabel.VerticalAlignment = 'bottom';
app.SessionNotesLabel.Layout.Row = 4;
app.SessionNotesLabel.Layout.Column = 1;
app.SessionNotesLabel.Text = 'Notes';

% Create SessionNotesTextarea
app.SessionNotesTextarea = uitextarea(app.SessionInfoGrid);
app.SessionNotesTextarea.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionNotesTextarea.Layout.Row = 5;
app.SessionNotesTextarea.Layout.Column = 1;

% Create SessionCustomFieldsLabel
app.SessionCustomFieldsLabel = uilabel(app.SessionInfoGrid);
app.SessionCustomFieldsLabel.VerticalAlignment = 'bottom';
app.SessionCustomFieldsLabel.Layout.Row = 2;
app.SessionCustomFieldsLabel.Layout.Column = 1;
app.SessionCustomFieldsLabel.Text = 'Custom Fields';

% Create SessionCustomFieldsGrid
app.SessionCustomFieldsGrid = uigridlayout(app.SessionInfoGrid);
app.SessionCustomFieldsGrid.ColumnWidth = {'fit', '1x', 10, 'fit', '1x'};
app.SessionCustomFieldsGrid.Padding = [0 0 0 0];
app.SessionCustomFieldsGrid.Layout.Row = 3;
app.SessionCustomFieldsGrid.Layout.Column = 1;

% Create SessionCustomField1Label
app.SessionCustomField1Label = uilabel(app.SessionCustomFieldsGrid);
app.SessionCustomField1Label.HorizontalAlignment = 'right';
app.SessionCustomField1Label.Layout.Row = 1;
app.SessionCustomField1Label.Layout.Column = 1;
app.SessionCustomField1Label.Text = '1';

% Create SessionCustomField4
app.SessionCustomField4 = uieditfield(app.SessionCustomFieldsGrid, 'text');
app.SessionCustomField4.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionCustomField4.Layout.Row = 2;
app.SessionCustomField4.Layout.Column = 5;

% Create SessionCustomField2Label
app.SessionCustomField2Label = uilabel(app.SessionCustomFieldsGrid);
app.SessionCustomField2Label.HorizontalAlignment = 'right';
app.SessionCustomField2Label.Layout.Row = 2;
app.SessionCustomField2Label.Layout.Column = 1;
app.SessionCustomField2Label.Text = '2';

% Create SessionCustomField3Label
app.SessionCustomField3Label = uilabel(app.SessionCustomFieldsGrid);
app.SessionCustomField3Label.HorizontalAlignment = 'right';
app.SessionCustomField3Label.Layout.Row = 1;
app.SessionCustomField3Label.Layout.Column = 4;
app.SessionCustomField3Label.Text = '3';

% Create SessionCustomField3
app.SessionCustomField3 = uieditfield(app.SessionCustomFieldsGrid, 'text');
app.SessionCustomField3.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionCustomField3.Layout.Row = 1;
app.SessionCustomField3.Layout.Column = 5;

% Create SessionCustomField2
app.SessionCustomField2 = uieditfield(app.SessionCustomFieldsGrid, 'text');
app.SessionCustomField2.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionCustomField2.Layout.Row = 2;
app.SessionCustomField2.Layout.Column = 2;

% Create SessionCustomField1
app.SessionCustomField1 = uieditfield(app.SessionCustomFieldsGrid, 'text');
app.SessionCustomField1.ValueChangedFcn = createCallbackFcn(app, @SessionCustomField1ValueChanged, true);
app.SessionCustomField1.Layout.Row = 1;
app.SessionCustomField1.Layout.Column = 2;

% Create SessionCustomField4Label
app.SessionCustomField4Label = uilabel(app.SessionCustomFieldsGrid);
app.SessionCustomField4Label.HorizontalAlignment = 'right';
app.SessionCustomField4Label.Layout.Row = 2;
app.SessionCustomField4Label.Layout.Column = 4;
app.SessionCustomField4Label.Text = '4';

% Create RefCapturePanel
app.RefCapturePanel = uipanel(app.Phase1LeftGrid);
app.RefCapturePanel.Enable = 'off';
app.RefCapturePanel.Title = 'Image Capture Parameters';
app.RefCapturePanel.Layout.Row = 4;
app.RefCapturePanel.Layout.Column = 1;

% Create RefCaptureGrid
app.RefCaptureGrid = uigridlayout(app.RefCapturePanel);
app.RefCaptureGrid.ColumnWidth = {'1x', '1x', 25, '1x'};
app.RefCaptureGrid.RowHeight = {25, 25, 25, 25};

% Create RefBrightnessLabel
app.RefBrightnessLabel = uilabel(app.RefCaptureGrid);
app.RefBrightnessLabel.HorizontalAlignment = 'right';
app.RefBrightnessLabel.Layout.Row = 3;
app.RefBrightnessLabel.Layout.Column = 1;
app.RefBrightnessLabel.Text = 'Brightness';

% Create RefGammaLabel
app.RefGammaLabel = uilabel(app.RefCaptureGrid);
app.RefGammaLabel.HorizontalAlignment = 'right';
app.RefGammaLabel.Layout.Row = 4;
app.RefGammaLabel.Layout.Column = 1;
app.RefGammaLabel.Text = 'Gamma';

% Create RefExposureLabel
app.RefExposureLabel = uilabel(app.RefCaptureGrid);
app.RefExposureLabel.HorizontalAlignment = 'right';
app.RefExposureLabel.Layout.Row = 2;
app.RefExposureLabel.Layout.Column = 1;
app.RefExposureLabel.Text = 'Exposure';

% Create RefGammaCheckbox
app.RefGammaCheckbox = uicheckbox(app.RefCaptureGrid);
app.RefGammaCheckbox.ValueChangedFcn = createCallbackFcn(app, @RefGammaCheckboxValueChanged, true);
app.RefGammaCheckbox.Enable = 'off';
app.RefGammaCheckbox.Tooltip = {'If checked, the system will try to set this parameter to the best value when the next reference image is taken. (User-entered value will be ignored.)'};
app.RefGammaCheckbox.Text = 'Autoset';
app.RefGammaCheckbox.Layout.Row = 4;
app.RefGammaCheckbox.Layout.Column = [3 4];

% Create RefBrightnessCheckbox
app.RefBrightnessCheckbox = uicheckbox(app.RefCaptureGrid);
app.RefBrightnessCheckbox.ValueChangedFcn = createCallbackFcn(app, @RefBrightnessCheckboxValueChanged, true);
app.RefBrightnessCheckbox.Enable = 'off';
app.RefBrightnessCheckbox.Tooltip = {'If checked, the system will try to set this parameter to the best value when the next reference image is taken. (User-entered value will be ignored.)'};
app.RefBrightnessCheckbox.Text = 'Autoset';
app.RefBrightnessCheckbox.Layout.Row = 3;
app.RefBrightnessCheckbox.Layout.Column = [3 4];

% Create RefExposureCheckbox
app.RefExposureCheckbox = uicheckbox(app.RefCaptureGrid);
app.RefExposureCheckbox.ValueChangedFcn = createCallbackFcn(app, @RefExposureCheckboxValueChanged, true);
app.RefExposureCheckbox.Enable = 'off';
app.RefExposureCheckbox.Tooltip = {'If checked, the system will try to set this parameter to the best value when the next reference image is taken. (User-entered value will be ignored.)'};
app.RefExposureCheckbox.Text = 'Autoset';
app.RefExposureCheckbox.Layout.Row = 2;
app.RefExposureCheckbox.Layout.Column = [3 4];

% Create RefGammaSpinner
app.RefGammaSpinner = uispinner(app.RefCaptureGrid);
app.RefGammaSpinner.Limits = [-72 Inf];
app.RefGammaSpinner.ValueDisplayFormat = '%.0f';
app.RefGammaSpinner.ValueChangedFcn = createCallbackFcn(app, @RefGammaSpinnerValueChanged, true);
app.RefGammaSpinner.Enable = 'off';
app.RefGammaSpinner.Layout.Row = 4;
app.RefGammaSpinner.Layout.Column = 2;

% Create RefBrightnessSpinner
app.RefBrightnessSpinner = uispinner(app.RefCaptureGrid);
app.RefBrightnessSpinner.Limits = [-100 100];
app.RefBrightnessSpinner.ValueDisplayFormat = '%.0f';
app.RefBrightnessSpinner.ValueChangedFcn = createCallbackFcn(app, @RefBrightnessSpinnerValueChanged, true);
app.RefBrightnessSpinner.Enable = 'off';
app.RefBrightnessSpinner.Layout.Row = 3;
app.RefBrightnessSpinner.Layout.Column = 2;

% Create RefExposureSpinner
app.RefExposureSpinner = uispinner(app.RefCaptureGrid);
app.RefExposureSpinner.Limits = [-13 -1];
app.RefExposureSpinner.ValueDisplayFormat = '%.0f';
app.RefExposureSpinner.ValueChangedFcn = createCallbackFcn(app, @RefExposureSpinnerValueChanged, true);
app.RefExposureSpinner.Enable = 'off';
app.RefExposureSpinner.Layout.Row = 2;
app.RefExposureSpinner.Layout.Column = 2;
app.RefExposureSpinner.Value = -1;

% Create RefCaptureSyncLabel
app.RefCaptureSyncLabel = uilabel(app.RefCaptureGrid);
app.RefCaptureSyncLabel.FontAngle = 'italic';
app.RefCaptureSyncLabel.Enable = 'off';
app.RefCaptureSyncLabel.Layout.Row = 1;
app.RefCaptureSyncLabel.Layout.Column = 4;
app.RefCaptureSyncLabel.Text = '---';

% Create RefCaptureSyncLamp
app.RefCaptureSyncLamp = uilamp(app.RefCaptureGrid);
app.RefCaptureSyncLamp.Enable = 'off';
app.RefCaptureSyncLamp.Layout.Row = 1;
app.RefCaptureSyncLamp.Layout.Column = 3;

% Create RefCaptureNoteLabel
app.RefCaptureNoteLabel = uilabel(app.RefCaptureGrid);
app.RefCaptureNoteLabel.FontSize = 9;
app.RefCaptureNoteLabel.FontAngle = 'italic';
app.RefCaptureNoteLabel.Enable = 'off';
app.RefCaptureNoteLabel.Layout.Row = 1;
app.RefCaptureNoteLabel.Layout.Column = [1 2];
app.RefCaptureNoteLabel.Text = {'Note: Export reference image in SBREF '; 'format to preserve parameter information.'};

% Create VInputSetupPanel
app.VInputSetupPanel = uipanel(app.Phase1LeftGrid);
app.VInputSetupPanel.Title = 'Video Input Device Setup';
app.VInputSetupPanel.Layout.Row = 1;
app.VInputSetupPanel.Layout.Column = 1;

% Create VInputSetupGrid
app.VInputSetupGrid = uigridlayout(app.VInputSetupPanel);
app.VInputSetupGrid.RowHeight = {25, 25};

% Create VInputDeviceDropdownLabel
app.VInputDeviceDropdownLabel = uilabel(app.VInputSetupGrid);
app.VInputDeviceDropdownLabel.HorizontalAlignment = 'right';
app.VInputDeviceDropdownLabel.Layout.Row = 1;
app.VInputDeviceDropdownLabel.Layout.Column = 1;
app.VInputDeviceDropdownLabel.Text = 'Input Device';

% Create VInputResolutionDropdownLabel
app.VInputResolutionDropdownLabel = uilabel(app.VInputSetupGrid);
app.VInputResolutionDropdownLabel.HorizontalAlignment = 'right';
app.VInputResolutionDropdownLabel.Layout.Row = 2;
app.VInputResolutionDropdownLabel.Layout.Column = 1;
app.VInputResolutionDropdownLabel.Text = 'Input Image Resolution';

% Create VInputResolutionDropdown
app.VInputResolutionDropdown = uidropdown(app.VInputSetupGrid);
app.VInputResolutionDropdown.Items = {};
app.VInputResolutionDropdown.ValueChangedFcn = createCallbackFcn(app, @VInputResolutionDropdownValueChanged, true);
app.VInputResolutionDropdown.Enable = 'off';
app.VInputResolutionDropdown.Tooltip = {'Output resolution of video input device (before cropping and/or scaling for analysis)'};
app.VInputResolutionDropdown.Layout.Row = 2;
app.VInputResolutionDropdown.Layout.Column = 2;
app.VInputResolutionDropdown.Value = {};

% Create VInputDeviceDropdown
app.VInputDeviceDropdown = uidropdown(app.VInputSetupGrid);
app.VInputDeviceDropdown.Items = {'None'};
app.VInputDeviceDropdown.DropDownOpeningFcn = createCallbackFcn(app, @VInputDeviceDropdownDropDownOpening, true);
app.VInputDeviceDropdown.ValueChangedFcn = createCallbackFcn(app, @VInputDeviceDropdownValueChanged, true);
app.VInputDeviceDropdown.Tooltip = {'Video input device to use for reference image capture and data acquisition'};
app.VInputDeviceDropdown.Layout.Row = 1;
app.VInputDeviceDropdown.Layout.Column = 2;
app.VInputDeviceDropdown.ClickedFcn = createCallbackFcn(app, @VInputDeviceDropdownClicked, true);
app.VInputDeviceDropdown.Value = 'None';

%set(pdlg, 'Message', 'Creating Phase II components...', 'Value', 0.05);
waitbar(0.05, app.wbar, 'Creating Phase II components...');

% Create Phase2Tab
app.Phase2Tab = uitab(app.MainTabGroup);
app.Phase2Tab.Title = 'Phase II - Acquire and Process Data';
app.Phase2Tab.Tag = '2';

% Create Phase2Grid
app.Phase2Grid = uigridlayout(app.Phase2Tab);
app.Phase2Grid.ColumnWidth = {300, '1x', '1x'};
app.Phase2Grid.Padding = [10 10 10 10];
app.Phase2Grid.RowHeight = {'1x'};

% Create Phase2LeftGrid
app.Phase2LeftGrid = uigridlayout(app.Phase2Grid);
app.Phase2LeftGrid.ColumnWidth = {'1x'};
app.Phase2LeftGrid.RowHeight = {'fit', 'fit', '1x'};
app.Phase2LeftGrid.Padding = [0 0 0 0];
app.Phase2LeftGrid.Layout.Row = 1;
app.Phase2LeftGrid.Layout.Column = 1;

% Create RatePanel
app.RatePanel = uipanel(app.Phase2LeftGrid);
app.RatePanel.Enable = 'off';
app.RatePanel.Title = 'Datapoint Frequency';
app.RatePanel.Layout.Row = 1;
app.RatePanel.Layout.Column = 1;

% Create RateGrid
app.RateGrid = uigridlayout(app.RatePanel);
app.RateGrid.ColumnWidth = {62, 60, '1x', 63, 50};
app.RateGrid.RowHeight = {30, 30};
app.RateGrid.ColumnSpacing = 5;
app.RateGrid.Padding = [10 15 15 10];

% Create SPFLabel
app.SPFLabel = uilabel(app.RateGrid);
app.SPFLabel.HorizontalAlignment = 'right';
app.SPFLabel.Enable = 'off';
app.SPFLabel.Layout.Row = 1;
app.SPFLabel.Layout.Column = 1;
app.SPFLabel.Text = {'Seconds'; 'per Frame*'};

% Create SPFField
app.SPFField = uieditfield(app.RateGrid, 'text');
app.SPFField.CharacterLimits = [0 Inf];
app.SPFField.HorizontalAlignment = 'right';
app.SPFField.Enable = 'off';
app.SPFField.Tooltip = {'1/n where integer N in [1,30]'; 'or a finite real number c>=1.0'};
app.SPFField.Placeholder = 'c>1 or 1/n';
app.SPFField.Layout.Row = 1;
app.SPFField.Layout.Column = 2;
app.SPFField.ValueChangingFcn = @app.onSPFFieldChange;
app.SPFField.ValueChangedFcn = @app.onSPFFieldChange;
app.SPFField.Value = '1/2';

% Create FPSLabel
app.FPSLabel = uilabel(app.RateGrid);
app.FPSLabel.HorizontalAlignment = 'right';
app.FPSLabel.FontAngle = 'italic';
app.FPSLabel.Enable = 'off';
app.FPSLabel.Layout.Row = 1;
app.FPSLabel.Layout.Column = 4;
app.FPSLabel.Text = {'Frames'; 'per Second'};

% Create FPSField
app.FPSField = uieditfield(app.RateGrid, 'numeric');
app.FPSField.LowerLimitInclusive = 'off';
app.FPSField.Limits = [0 Inf];
app.FPSField.Editable = 'off';
app.FPSField.FontAngle = 'italic';
app.FPSField.Enable = 'off';
app.FPSField.Layout.Row = 1;
app.FPSField.Layout.Column = 5;
app.FPSField.Value = 2;

% Create FPPLabel
app.FPPLabel = uilabel(app.RateGrid);
app.FPPLabel.HorizontalAlignment = 'right';
app.FPPLabel.Enable = 'off';
app.FPPLabel.Layout.Row = 2;
app.FPPLabel.Layout.Column = 1;
app.FPPLabel.Text = {'Frames'; 'per Datapt.'};

% Create FPPSpinner
app.FPPSpinner = uispinner(app.RateGrid);
app.FPPSpinner.Limits = [2 32];
app.FPPSpinner.ValueDisplayFormat = '%.0f';
app.FPPSpinner.Enable = 'off';
app.FPPSpinner.ValueChangedFcn = @app.onRateFieldChanged;
app.FPPSpinner.Layout.Row = 2;
app.FPPSpinner.Layout.Column = 2;
app.FPPSpinner.Value = 2;
app.FPPSpinner.Step = 2;

% Create SPPLabel
app.SPPLabel = uilabel(app.RateGrid);
app.SPPLabel.HorizontalAlignment = 'right';
app.SPPLabel.FontAngle = 'italic';
app.SPPLabel.Enable = 'off';
app.SPPLabel.Layout.Row = 2;
app.SPPLabel.Layout.Column = 4;
app.SPPLabel.Text = {'Seconds'; 'per Datapt.'};

% Create SPPField
app.SPPField = uieditfield(app.RateGrid, 'numeric');
app.SPPField.LowerLimitInclusive = 'off';
app.SPPField.Limits = [0 Inf];
app.SPPField.Editable = 'off';
app.SPPField.FontAngle = 'italic';
app.SPPField.Enable = 'off';
app.SPPField.Layout.Row = 2;
app.SPPField.Layout.Column = 5;
app.SPPField.Value = 1;

% Create RecPanel
app.RecPanel = uipanel(app.Phase2LeftGrid);
app.RecPanel.Enable = 'off';
app.RecPanel.Title = 'Acquisition Control';
app.RecPanel.Layout.Row = 2;
app.RecPanel.Layout.Column = 1;

% Create RecGrid
app.RecGrid = uigridlayout(app.RecPanel);
app.RecGrid.ColumnWidth = {50, '1x'};
app.RecGrid.RowHeight = {50, 50};

% Create RecStatusArea
app.RecStatusArea = uitextarea(app.RecGrid);
app.RecStatusArea.Editable = 'off';
app.RecStatusArea.FontAngle = 'italic'; % TODO: Pick a monospace font (system default)?
app.RecStatusArea.Enable = 'off';
app.RecStatusArea.Layout.Row = 2;
app.RecStatusArea.Layout.Column = [1 2];

% Create RecButton
app.RecButton = uibutton(app.RecGrid, 'state');
app.RecButton.IconAlignment = 'center';
app.RecButton.FontSize = 14;
app.RecButton.Enable = 'off';
app.RecButton.Interruptible = false;
app.RecButton.BusyAction = 'cancel';
app.RecButton.ValueChangedFcn = @app.onRecButtonValueChanged;
app.RecButton.Layout.Row = 1;
app.RecButton.Layout.Column = 1;
app.RecButton.Text = 'R';

% Create RecLabel
app.RecLabel = uilabel(app.RecGrid);
app.RecLabel.Enable = 'off';
app.RecLabel.Layout.Row = 1;
app.RecLabel.Layout.Column = 2;
app.RecLabel.Text = 'Start/pause recording (data acquisition)';

% Create IProcPanel
app.IProcPanel = uipanel(app.Phase2LeftGrid);
app.IProcPanel.Enable = 'off';
app.IProcPanel.Title = 'Image Processing and Analysis';
app.IProcPanel.Layout.Row = 3;
app.IProcPanel.Layout.Column = 1;

% Create IProcGrid
app.IProcGrid = uigridlayout(app.IProcPanel);
app.IProcGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', 80};
app.IProcGrid.RowHeight = {20, 25, 20, '1x'};

% Create PSBLabel
app.PSBLabel = uilabel(app.IProcGrid);
app.PSBLabel.VerticalAlignment = 'bottom';
app.PSBLabel.Enable = 'off';
app.PSBLabel.Layout.Row = 1;
app.PSBLabel.Layout.Column = [1 4];
app.PSBLabel.Text = 'Peak Search Bounds (L, R)';

% Create PSBLeftSpinner
app.PSBLeftSpinner = uispinner(app.IProcGrid);
app.PSBLeftSpinner.Limits = [1 Inf];
app.PSBLeftSpinner.Enable = 'off';
app.PSBLeftSpinner.Layout.Row = 2;
app.PSBLeftSpinner.Layout.Column = [1 2];
app.PSBLeftSpinner.Value = 1;
app.PSBLeftSpinner.Tag = '1';

% Create PSBRightSpinner
app.PSBRightSpinner = uispinner(app.IProcGrid);
app.PSBRightSpinner.Limits = [1 Inf];
app.PSBRightSpinner.Enable = 'off';
app.PSBRightSpinner.Layout.Row = 2;
app.PSBRightSpinner.Layout.Column = [3 4];
app.PSBRightSpinner.Value = 1;
app.PSBRightSpinner.Tag = '2';

% Create ReanalyzeButton
app.ReanalyzeButton = uibutton(app.IProcGrid, 'push');
app.ReanalyzeButton.Enable = 'off';
app.ReanalyzeButton.BusyAction = 'cancel';
app.ReanalyzeButton.Interruptible = true;
app.ReanalyzeButton.Layout.Row = 1;
app.ReanalyzeButton.Layout.Column = 6;
app.ReanalyzeButton.ButtonPushedFcn = @app.onReanalyzeButtonPushed;
app.ReanalyzeButton.Text = 'Reanalyze';

% Create DataNotesLabel
app.DataNotesLabel = uilabel(app.IProcGrid);
app.DataNotesLabel.VerticalAlignment = 'bottom';
app.DataNotesLabel.Enable = 'off';
app.DataNotesLabel.Layout.Row = 3;
app.DataNotesLabel.Layout.Column = [1 5];
app.DataNotesLabel.Text = 'Notes on Selected Datapoint';

% Create DataNotesTextarea
app.DataNotesTextarea = uitextarea(app.IProcGrid);
app.DataNotesTextarea.Enable = 'off';
app.DataNotesTextarea.Placeholder = 'Enter notes about datapoint here...';
app.DataNotesTextarea.Layout.Row = 4;
app.DataNotesTextarea.Layout.Column = [1 6];

% Create SaveNotesButton
app.SaveNotesButton = uibutton(app.IProcGrid, 'push');
app.SaveNotesButton.Enable = 'off';
app.SaveNotesButton.Layout.Row = 3;
app.SaveNotesButton.Layout.Column = 6;
app.SaveNotesButton.Text = 'Save Notes';

% Create Phase2CenterGrid
app.Phase2CenterGrid = uigridlayout(app.Phase2Grid);
app.Phase2CenterGrid.ColumnWidth = {320, '1x'};
app.Phase2CenterGrid.RowHeight = {'fit', 60, '2x'};
app.Phase2CenterGrid.Padding = [10 0 10 0];
app.Phase2CenterGrid.Layout.Row = 1;
app.Phase2CenterGrid.Layout.Column = 2;

% Create DataImageAxes
app.DataImageAxes = uiaxes(app.Phase2CenterGrid);
app.DataImageAxes.Toolbar.Visible = 'off';
app.DataImageAxes.CameraUpVector = [0 1 0];
app.DataImageAxes.CameraViewAngle = 6.86726051912591;
app.DataImageAxes.DataAspectRatio = [3264 2448 1];
app.DataImageAxes.PlotBoxAspectRatio = [3264 2448 1];
app.DataImageAxes.Layer = 'top';
app.DataImageAxes.XTick = [];
app.DataImageAxes.XTickLabel = '';
app.DataImageAxes.XMinorTick = 'on';
app.DataImageAxes.YTick = [];
app.DataImageAxes.YTickLabel = '';
app.DataImageAxes.YMinorTick = 'on';
app.DataImageAxes.NextPlot = 'add';
app.DataImageAxes.Box = 'on';
app.DataImageAxes.Layout.Row = 1;
app.DataImageAxes.Layout.Column = [1 2];
app.DataImageAxes.Interruptible = true;
app.DataImageAxes.BusyAction = 'cancel';
app.DataImageAxes.HitTest = 'off';
app.DataImageAxes.Visible = 'off';
colormap(app.DataImageAxes, 'gray')

% Create DataNavGrid
app.DataNavGrid = uigridlayout(app.Phase2CenterGrid);
app.DataNavGrid.ColumnWidth = {'1x', '1x', '1x', 30, 30, 15, 45, 20, 45, '1x', 70, 10, 50, '1x'};
app.DataNavGrid.RowHeight = {30, 15};
app.DataNavGrid.ColumnSpacing = 0;
app.DataNavGrid.RowSpacing = 5;
app.DataNavGrid.Padding = [10 0 10 0];
app.DataNavGrid.Layout.Row = 2;
app.DataNavGrid.Layout.Column = [1 2];

% Create AutoReanalysisToggleButton
app.AutoReanalysisToggleButton = uibutton(app.DataNavGrid, 'state');
app.AutoReanalysisToggleButton.Enable = 'off';
app.AutoReanalysisToggleButton.Tooltip = {'Auto-reanalysis on/off'};
app.AutoReanalysisToggleButton.Text = 'R';
app.AutoReanalysisToggleButton.Interruptible = true;
app.AutoReanalysisToggleButton.BusyAction = 'cancel';
app.AutoReanalysisToggleButton.Layout.Row = 1;
app.AutoReanalysisToggleButton.Layout.Column = 2;

% Create LeftArrowButton
app.LeftArrowButton = uibutton(app.DataNavGrid, 'push');
app.LeftArrowButton.Enable = 'off';
app.LeftArrowButton.Tooltip = {'Prev. datapoint (shift for prev. bookmark, ctrl+shift for first)'};
app.LeftArrowButton.Layout.Row = 1;
app.LeftArrowButton.Layout.Column = 4;
app.LeftArrowButton.Text = '<';
app.LeftArrowButton.Tag = '1';
app.LeftArrowButton.BusyAction = 'queue';
app.LeftArrowButton.Interruptible = true;
app.LeftArrowButton.ButtonPushedFcn = @app.onArrowButtonPushed;

% Create RightArrowButton
app.RightArrowButton = uibutton(app.DataNavGrid, 'push');
app.RightArrowButton.Enable = 'off';
app.RightArrowButton.Tooltip = {'Next datapoint (shift for next bookmark, ctrl+shift for last)'};
app.RightArrowButton.Layout.Row = 1;
app.RightArrowButton.Layout.Column = 5;
app.RightArrowButton.Text = '>';
app.RightArrowButton.Tag = '3';
app.RightArrowButton.BusyAction = 'queue';
app.RightArrowButton.Interruptible = true;
app.RightArrowButton.ButtonPushedFcn = @app.onArrowButtonPushed;

% Create DatapointIndexField
app.DatapointIndexField = uieditfield(app.DataNavGrid, 'text');
app.DatapointIndexField.Enable = 'off';
app.DatapointIndexField.InputType = 'digits';
app.DatapointIndexField.CharacterLimits = [0 inf]; % TODO: Adaptive character limits
app.DatapointIndexField.ValueChangedFcn = @app.onDatapointIndexFieldChanged;
app.DatapointIndexField.Layout.Row = 1;
app.DatapointIndexField.Interruptible = true;
app.DatapointIndexField.BusyAction = 'queue';
app.DatapointIndexField.Layout.Column = 7;

% Create ofLabel
app.ofLabel = uilabel(app.DataNavGrid);
app.ofLabel.HorizontalAlignment = 'center';
app.ofLabel.Enable = 'off';
app.ofLabel.Layout.Row = 1;
app.ofLabel.Layout.Column = 8;
app.ofLabel.Text = 'of';

% Create NumDatapointsField
app.NumDatapointsField = uieditfield(app.DataNavGrid, 'numeric');
app.NumDatapointsField.BusyAction = 'cancel'; % TODO: ???
app.NumDatapointsField.Editable = 'off';
app.NumDatapointsField.Enable = 'off';
app.NumDatapointsField.Interruptible = true;
app.NumDatapointsField.Layout.Row = 1;
app.NumDatapointsField.Layout.Column = 9;

% Create DatapointIndexLabel
app.DatapointIndexLabel = uilabel(app.DataNavGrid);
app.DatapointIndexLabel.HorizontalAlignment = 'center';
app.DatapointIndexLabel.VerticalAlignment = 'top';
app.DatapointIndexLabel.Enable = 'off';
app.DatapointIndexLabel.Layout.Row = 2;
app.DatapointIndexLabel.Layout.Column = [7 9];
app.DatapointIndexLabel.Text = 'Datapoint Index';

% Create DataImageDropdown
app.DataImageDropdown = uidropdown(app.DataNavGrid);
app.DataImageDropdown.Items = {'Y0', 'Yr', 'Yc', 'Y1'};
app.DataImageDropdown.Enable = 'off';
app.DataImageDropdown.Layout.Row = 1;
app.DataImageDropdown.Layout.Column = 13;
app.DataImageDropdown.Value = 'Y1';
app.DataImageDropdown.ValueChangedFcn = @app.onDataImageDropdownValueChanged;

% Create DataImageDropdownLabel
app.DataImageDropdownLabel = uilabel(app.DataNavGrid);
app.DataImageDropdownLabel.HorizontalAlignment = 'right';
app.DataImageDropdownLabel.Enable = 'off';
app.DataImageDropdownLabel.Layout.Row = 1;
app.DataImageDropdownLabel.Layout.Column = 11;
app.DataImageDropdownLabel.Text = 'Show image:';

% Create IProfPanel
app.IProfPanel = uipanel(app.Phase2CenterGrid);
app.IProfPanel.Enable = 'off';
app.IProfPanel.Title = 'Channel Intensity Profiles';
app.IProfPanel.Visible = 'off';
app.IProfPanel.Layout.Row = 3;
app.IProfPanel.Layout.Column = [1 2];
app.IProfPanel.BusyAction = 'cancel';
app.IProfPanel.ButtonDownFcn = @app.onIProfClicked;

% app.IProfContainerGrid = uigridlayout(app.IProfPanel);
% app.IProfContainerGrid.ColumnWidth = {'1x'};
% app.IProfContainerGrid.RowHeight = {'1x'};
% app.IProfContainerGrid.

% Create Phase2RightGridPanel
app.Phase2RightGridPanel = uipanel(app.Phase2Grid);
app.Phase2RightGridPanel.Title = 'Full-Profile Plots';
app.Phase2RightGridPanel.Layout.Row = 1;
app.Phase2RightGridPanel.Layout.Column = 3;
app.Phase2RightGridPanel.AutoResizeChildren = "on";
app.Phase2RightGridPanel.BusyAction = 'queue';
app.Phase2RightGridPanel.Interruptible = false;
app.Phase2RightGridPanel.ButtonDownFcn = @(~,~) toggleFPLegends(app);

% Create Phase2RightGrid
app.Phase2RightGrid = uigridlayout(app.Phase2RightGridPanel);
app.Phase2RightGrid.ColumnWidth = {'2x'};
app.Phase2RightGrid.RowHeight = {'1x', 'fit'};

% Create FPPlotsGrid
app.FPPlotsGrid = uigridlayout(app.Phase2RightGrid);
app.FPPlotsGrid.ColumnWidth = {'1x'}; % {'fit', '1x'}; % changed when removing Y panels
app.FPPlotsGrid.RowHeight = {'1x'};
app.FPPlotsGrid.Padding = [0 0 0 0];
app.FPPlotsGrid.Visible = 'off';
app.FPPlotsGrid.Layout.Row = 1;
app.FPPlotsGrid.Layout.Column = 1;

% Variable for space for X-axis label
% FProwHeights = {'1x', 20, '1x'};

% Create FPYSlidersGrid
% app.FPYSlidersGrid = uigridlayout(app.FPPlotsGrid);
% app.FPYSlidersGrid.ColumnWidth = {'1x'};
% app.FPYSlidersGrid.Padding = [0 0 0 0];
% app.FPYSlidersGrid.Layout.Row = 1;
% app.FPYSlidersGrid.Layout.Column = 1;
% app.FPYSlidersGrid.RowSpacing = 2;
% app.FPYSlidersGrid.RowHeight = {'1x', 12, '1x'}; % FProwHeights;
% 
% % Create FPPosPanel
% app.FPPosPanel = uipanel(app.FPYSlidersGrid);
% app.FPPosPanel.Enable = 'off';
% app.FPPosPanel.Visible = 'off';
% app.FPPosPanel.Layout.Row = 1;
% app.FPPosPanel.Layout.Column = 1;
% 
% % Create FPPosGrid
% app.FPPosGrid = uigridlayout(app.FPPosPanel);
% app.FPPosGrid.ColumnWidth = {30, 50};
% app.FPPosGrid.RowHeight = {'1x'};
% app.FPPosGrid.ColumnSpacing = 0;
% app.FPPosGrid.Padding = [0 0 0 0];
%
% % Create FPPosSlider
% app.FPPosSlider = uislider(app.FPPosGrid);
% app.FPPosSlider.Orientation = 'vertical';
% app.FPPosSlider.Enable = 'off';
% app.FPPosSlider.Visible = 'off';
% app.FPPosSlider.Layout.Row = 1;
% app.FPPosSlider.Layout.Column = 2;
% app.FPPosSlider.Value = 50;
%
% % Create FPPosSubgrid
% app.FPPosSubgrid = uigridlayout(app.FPPosGrid);
% app.FPPosSubgrid.ColumnWidth = {20};
% app.FPPosSubgrid.RowHeight = {'1x', 20};
% app.FPPosSubgrid.Padding = [5 10 5 5];
% app.FPPosSubgrid.Layout.Row = 1;
% app.FPPosSubgrid.Layout.Column = 1;
%
% % Create FPPosAutoButton
% app.FPPosAutoButton = uibutton(app.FPPosSubgrid, 'state');
% app.FPPosAutoButton.Enable = 'off';
% app.FPPosAutoButton.Visible = 'off';
% app.FPPosAutoButton.Tooltip = {'Auto Y'};
% app.FPPosAutoButton.Text = 'A';
% app.FPPosAutoButton.Layout.Row = 2;
% app.FPPosAutoButton.Layout.Column = 1;
%
% % Create FPPosLabel
% app.FPPosLabel = uilabel(app.FPPosSubgrid);
% app.FPPosLabel.HorizontalAlignment = 'center';
% app.FPPosLabel.FontWeight = 'bold';
% app.FPPosLabel.Enable = 'off';
% app.FPPosLabel.Visible = 'off';
% app.FPPosLabel.Layout.Row = 1;
% app.FPPosLabel.Layout.Column = 1;
% app.FPPosLabel.Text = {'P'; 'E'; 'A'; 'K'; ''; 'P'; 'O'; 'S'};
%
% % Create FPHgtPanel
% app.FPHgtPanel = uipanel(app.FPYSlidersGrid);
% app.FPHgtPanel.Enable = 'off';
% app.FPHgtPanel.Visible = 'off';
% app.FPHgtPanel.Layout.Row = 3; % 2;
% app.FPHgtPanel.Layout.Column = 1;
%
% % Create FPHgtGrid
% app.FPHgtGrid = uigridlayout(app.FPHgtPanel);
% app.FPHgtGrid.ColumnWidth = {30, 50};
% app.FPHgtGrid.RowHeight = {'1x'};
% app.FPHgtGrid.ColumnSpacing = 0;
% app.FPHgtGrid.Padding = [0 0 0 0];
%
% % Create FPHgtSlider
% app.FPHgtSlider = uislider(app.FPHgtGrid);
% app.FPHgtSlider.Orientation = 'vertical';
% app.FPHgtSlider.Enable = 'off';
% app.FPHgtSlider.Visible = 'off';
% app.FPHgtSlider.Layout.Row = 1;
% app.FPHgtSlider.Layout.Column = 2;
% app.FPHgtSlider.Value = 50;
%
% % Create FPHgtSubgrid
% app.FPHgtSubgrid = uigridlayout(app.FPHgtGrid);
% app.FPHgtSubgrid.ColumnWidth = {20};
% app.FPHgtSubgrid.RowHeight = {'1x', 20};
% app.FPHgtSubgrid.Padding = [5 10 5 5];
% app.FPHgtSubgrid.Layout.Row = 1;
% app.FPHgtSubgrid.Layout.Column = 1;
%
% % Create FPHgtAutoButton
% app.FPHgtAutoButton = uibutton(app.FPHgtSubgrid, 'state');
% app.FPHgtAutoButton.Enable = 'off';
% app.FPHgtAutoButton.Visible = 'off';
% app.FPHgtAutoButton.Tooltip = {'Auto Y'};
% app.FPHgtAutoButton.Text = 'A';
% app.FPHgtAutoButton.Layout.Row = 2;
% app.FPHgtAutoButton.Layout.Column = 1;
%
% % Create FPHgtLabel
% app.FPHgtLabel = uilabel(app.FPHgtSubgrid);
% app.FPHgtLabel.HorizontalAlignment = 'center';
% app.FPHgtLabel.FontWeight = 'bold';
% app.FPHgtLabel.Enable = 'off';
% app.FPHgtLabel.Visible = 'off';
% app.FPHgtLabel.Layout.Row = 1;
% app.FPHgtLabel.Layout.Column = 1;
% app.FPHgtLabel.Text = {'P'; 'E'; 'A'; 'K'; ''; 'H'; 'G'; 'T'};

% Create FPAxesGridPanel
app.FPAxesGridPanel = uipanel(app.FPPlotsGrid);
app.FPAxesGridPanel.BorderType = 'none';
app.FPAxesGridPanel.Title = '';
app.FPAxesGridPanel.Visible = 'off';
app.FPAxesGridPanel.Enable = 'off';
app.FPAxesGridPanel.AutoResizeChildren = 'on'; % 'on';
app.FPAxesGridPanel.Clipping = false; % TODO: ???
% app.FPAxesGridPanel.SizeChangedFcn = @app.onAxesPanelSizeChange;
app.FPAxesGridPanel.Layout.Row = 1;
app.FPAxesGridPanel.Layout.Column = 1; % 2; % changed when removing Y panels

% Create FPAxesGrid
app.FPAxesGrid = uigridlayout(app.FPAxesGridPanel);
app.FPAxesGrid.ColumnWidth = {'1x'};
app.FPAxesGrid.Padding = [0 0 0 0];
app.FPAxesGrid.Visible = 'off';
app.FPAxesGrid.RowHeight = {'1x', 12, '1x'};

%app.FPAxesGrid.Layout.Row = 1;
%app.FPAxesGrid.Layout.Column = 2;

% Create PosAxes
app.PosAxesPanel = uipanel(app.FPAxesGrid);
app.PosAxesPanel.BorderType = 'none';
app.PosAxesPanel.Title = '';
app.PosAxesPanel.Visible = 'off';
app.PosAxesPanel.Enable = 'off';
app.PosAxesPanel.AutoResizeChildren = 'off';
app.PosAxesPanel.Clipping = false;
app.PosAxesPanel.SizeChangedFcn = @(src,~) onAxesPanelSizeChange(app,src);
app.PosAxesPanel.Layout.Row = 1;
app.PosAxesPanel.Layout.Column = 1;

app.PosAxes = uiaxes(app.PosAxesPanel);
app.PosAxes.Toolbar.Visible = 'off';
%app.PosAxes.CameraUpVector = [0 1 0];
app.PosAxes.CameraViewAngleMode = 'auto';
app.PosAxes.DataAspectRatioMode = 'auto';
app.PosAxes.PlotBoxAspectRatioMode = 'auto';
%app.PosAxes.CameraViewAngle = 6.86726051912591;
%app.PosAxes.DataAspectRatio = [3264 2448 1];
%app.PosAxes.PlotBoxAspectRatio = [3264 2448 1];
app.PosAxes.Layer = 'top';
app.PosAxes.XTick = [];
app.PosAxes.XTickLabel = '';
app.PosAxes.XMinorTick = 'on';
app.PosAxes.YTick = [];
app.PosAxes.YTickLabel = '';
app.PosAxes.YMinorTick = 'on';
app.PosAxes.ClippingStyle = 'rectangle';
app.PosAxes.NextPlot = 'add';
app.PosAxes.Box = 'on';
app.PosAxes.BusyAction = 'cancel';
app.PosAxes.HitTest = 'on';
app.PosAxes.PickableParts = 'visible';
app.PosAxes.Visible = 'off';
app.PosAxes.XGrid = 'on';
app.PosAxes.XMinorGrid = 'on';
app.PosAxes.Interruptible = true;
app.PosAxes.BusyAction = 'queue';
app.PosAxes.ButtonDownFcn = {@app.onFPPlotClick};
app.PosAxesPanel.UserData = app.PosAxes; %{app.FPPosPanel app.PosAxes};
colormap(app.PosAxes, 'gray');

% Create HgtAxes
app.HgtAxesPanel = uipanel(app.FPAxesGrid);
app.HgtAxesPanel.BorderType = 'none';
app.HgtAxesPanel.Title = '';
app.HgtAxesPanel.Visible = 'off';
app.HgtAxesPanel.Enable = 'off';
app.HgtAxesPanel.AutoResizeChildren = 'off';
app.HgtAxesPanel.SizeChangedFcn = @(src,~) onAxesPanelSizeChange(app,src);
app.HgtAxesPanel.Layout.Row = 3; %2;
app.HgtAxesPanel.Layout.Column = 1;
app.HgtAxesPanel.Clipping = false;
app.HgtAxes = uiaxes(app.HgtAxesPanel);
app.HgtAxes.Toolbar.Visible = 'off';
%app.HgtAxes.CameraUpVector = [0 1 0];
app.HgtAxes.CameraViewAngleMode = 'auto';
app.HgtAxes.DataAspectRatioMode = 'auto';
app.HgtAxes.PlotBoxAspectRatioMode = 'auto';
%app.HgtAxes.CameraViewAngle = 6.86726051912591;
%app.HgtAxes.DataAspectRatio = [3264 2448 1];
%app.HgtAxes.PlotBoxAspectRatio = [3264 2448 1];
app.HgtAxes.Layer = 'top';
app.HgtAxes.XTick = [];
app.HgtAxes.XTickLabel = '';
app.HgtAxes.XMinorTick = 'on';
app.HgtAxes.YTick = [];
app.HgtAxes.YTickLabel = '';
app.HgtAxes.YMinorTick = 'on';
app.HgtAxes.ClippingStyle = 'rectangle';
app.HgtAxes.NextPlot = 'add';
app.HgtAxes.Box = 'on';
app.HgtAxes.BusyAction = 'cancel';
app.HgtAxes.HitTest = 'on';
app.HgtAxes.PickableParts = 'visible';
app.HgtAxes.Visible = 'off';
app.HgtAxes.XGrid = 'on';
app.HgtAxes.XMinorGrid = 'on';
app.HgtAxes.Interruptible = true;
app.HgtAxes.BusyAction = 'queue';
app.HgtAxesPanel.UserData = app.HgtAxes; % {app.FPHgtPanel app.HgtAxes};
app.HgtAxes.ButtonDownFcn = {@app.onFPPlotClick};
colormap(app.HgtAxes, 'gray')

% Create FPXAxisLabelsGridPanel
app.FPXAxisLabelsGridPanel = uipanel(app.FPAxesGrid);
app.FPXAxisLabelsGridPanel.Layout.Column = 1;
app.FPXAxisLabelsGridPanel.Layout.Row = 2;
app.FPXAxisLabelsGridPanel.BorderType = 'none';
app.FPXAxisLabelsGridPanel.BorderWidth = 0;
app.FPXAxisLabelsGridPanel.Title = '';
app.FPXAxisLabelsGridPanel.Clipping = false;
app.FPXAxisLabelsGridPanel.AutoResizeChildren = 'off';
subpan = uipanel(app.FPXAxisLabelsGridPanel, 'BorderType', 'none', 'Units', 'pixels', ...
    'Position', [0 0 1 1], 'UserData', app.HgtAxes, ...
    'AutoResizeChildren', 'off', 'Title', '', 'BorderWidth', 0, 'Clipping', false);
app.FPXAxisLabelsGridPanel.SizeChangedFcn = {@onSubpanParentSizeChanged};

% Create FPXAxisLabelsGrid
app.FPXAxisLabelsGrid = uigridlayout(subpan);
app.FPXAxisLabelsGrid.ColumnWidth = {'fit', '1x'}; %{'1x', 10, '1x'};
app.FPXAxisLabelsGrid.RowHeight = {'1x' 5 'fit' 5 '1x'};
app.FPXAxisLabelsGrid.Padding = [0 0 0 0];
app.FPXAxisLabelsGrid.RowSpacing = 0;
app.FPXAxisLabelsGrid.ColumnSpacing = 5;

clear subpan;

app.FPXAxisLeftLabel = uilabel(app.FPXAxisLabelsGrid);
app.FPXAxisLeftLabel.Layout.Row = [2 4];
app.FPXAxisLeftLabel.Layout.Column = 1;
app.FPXAxisLeftLabel.Text = 'Left label';
app.FPXAxisLeftLabel.HorizontalAlignment = 'left';

app.FPXAxisRightLabel = uilabel(app.FPXAxisLabelsGrid);
app.FPXAxisRightLabel.Layout.Row = [2 4];
app.FPXAxisRightLabel.Layout.Column = 2;
app.FPXAxisRightLabel.Text = 'Right label';
app.FPXAxisRightLabel.HorizontalAlignment = 'right';

set([app.FPXAxisLeftLabel app.FPXAxisRightLabel], ...
    'Interpreter', 'none', 'VerticalAlignment', 'center', ...
    'FontWeight', 'normal', 'FontAngle', 'normal', ...
    'FontColor', [0 0 0], 'BackgroundColor', 'none', ...
    'FontName', 'Helvetica', 'FontSize', 11 ... % pixels
);

% Create FPNavGrid
app.FPNavGrid = uigridlayout(app.Phase2RightGrid);
%                               1    2   3   4   5       6       7   8     9     10    11  12  13         14  15   16
% app.FPNavGrid.ColumnWidth = {90, '2x', 5, 40, 20,     35,     10, 45,   40,    20,   35, 10, 45,         5, 20, '1x'};
% app.FPNavGrid.ColumnWidth = {90, '2x', 5, 40, 20,     35, 10, 10, 35,   '2x',  20,   35, 10, 10, 35,     5, 20, '1x'};
%                               1    2   3   4   5       6   7   8   9    10     11    12  13  14  15     16  17   18
%                               1    2   3   4   5       6   7   8   9          10    11  12  13  14  15     16  17   18
% app.FPNavGrid.ColumnWidth =   {90, '2x', 5, 40, 20,     35, 10, 10, 35, 15,    '2x',  10, 35, 10, 15, 35,     5, 10, '1x'};
%                               1    2   3   4   5       6   7   8   9  10      11    12  13  14  15  16     17  18   19

% app.FPNavGrid.ColumnWidth =   {90, '2x', 5, 40, 20,     35, 10, 10, 35, 15,    '2x',  10, 35, 10, 15, 35,     5, 10, '1x'};
% app.FPNavGrid.ColumnWidth =   {90, '2x', 5, 40, 20,     35, 15, 10, 35, 15,    '2x',  15, 35, 10, 15, 35,    10, '1x'};
% app.FPNavGrid.ColumnWidth =   {90, '2x', 5, 40, 20,     35, 15, 10, 35, 20,    '2x',  15, 35, 10, 20, 35,    '1x'};
app.FPNavGrid.ColumnWidth =   {90, '1x', 5, 40,   20,       35, 15, 10, 35, 20,    '3x',  15, 35, 10, 20, 35,    '2x'};

app.FPNavGrid.RowHeight = {15, '1x', 50, 35};
app.FPNavGrid.ColumnSpacing = 0;
app.FPNavGrid.RowSpacing = 5;
app.FPNavGrid.Padding = [10 0 10 0];
app.FPNavGrid.Layout.Row = 2;
app.FPNavGrid.Layout.Column = 1;

% Create FPXModeDropdownLabel
app.FPXModeDropdownLabel = uilabel(app.FPNavGrid);
app.FPXModeDropdownLabel.HorizontalAlignment = 'center';
app.FPXModeDropdownLabel.VerticalAlignment = 'bottom';
app.FPXModeDropdownLabel.Enable = 'off';
app.FPXModeDropdownLabel.Layout.Row = 1;
app.FPXModeDropdownLabel.Layout.Column = [1 4];
app.FPXModeDropdownLabel.Text = 'X Axis Type/Resolution';

% Create FPXModeDropdown
app.FPXModeDropdown = uidropdown(app.FPNavGrid);
app.FPXModeDropdown.Items = {'Datapoint index (>=1)', 'Absolute time (h:m:s)', 'Relative time (sec)'};
app.FPXModeDropdown.ItemsData = [1 2 3];
app.FPXModeDropdown.Enable = 'off';
app.FPXModeDropdown.Layout.Row = 2;
app.FPXModeDropdown.Layout.Column = [1 4];
app.FPXModeDropdown.Value = 1; % 'Datapoint index (>=1)';
app.FPXModeDropdown.ValueChangedFcn = @app.FPXModeDropdownChanged;
% app.FPXModeDropdown.ValueChangingFcn = @app.FPXModeDropdownChange;
app.FPXModeDropdown.Interruptible = false;
app.FPXModeDropdown.BusyAction = 'cancel';

% Create XResKnob
app.XResKnob = uiknob(app.FPNavGrid, 'continuous');
app.XResKnob.Limits = [0.001 900];
app.XResKnob.MajorTicks = [0.001 0.05 0.1 0.5 1 5 10 30 60 120 300 600 900];
app.XResKnob.ValueChangedFcn = createCallbackFcn(app, @XResKnobValueChange, true);
app.XResKnob.ValueChangingFcn = createCallbackFcn(app, @XResKnobValueChange, true);
app.XResKnob.MinorTicks = [0.001 0.002 0.005 0.01 0.025 0.05 0.1 0.2 0.25 0.5 1 1.5 2 5 10 15 20 30 120 300 600 900];
app.XResKnob.Enable = 'off';
app.XResKnob.Visible = 'off';
app.XResKnob.Layout.Row = [3 4];
app.XResKnob.Layout.Column = [1 2];
app.XResKnob.FontSize = 8;
app.XResKnob.Value = 0.001;
app.XResKnob.Interruptible = true;
app.XResKnob.BusyAction = 'cancel';

% TODO: Create more labels...

% Create FPXUnitsLabel
app.FPXUnitsLabel = uilabel(app.FPNavGrid);
app.FPXUnitsLabel.FontAngle = 'italic';
app.FPXUnitsLabel.Enable = 'off';
app.FPXUnitsLabel.Visible = 'off';
app.FPXUnitsLabel.Layout.Row = 4;
app.FPXUnitsLabel.Layout.Column = 4;
app.FPXUnitsLabel.Text = 'points';

% Create XMinLabel
app.XMinLabel = uilabel(app.FPNavGrid);
app.XMinLabel.HorizontalAlignment = 'center';
app.XMinLabel.VerticalAlignment = 'bottom';
app.XMinLabel.Enable = 'off';
app.XMinLabel.Layout.Row = 1;
app.XMinLabel.Layout.Column = [6 7]; % 6; %6;
app.XMinLabel.Text = 'Min X';

% Create XMaxLabel
app.XMaxLabel = uilabel(app.FPNavGrid);
app.XMaxLabel.HorizontalAlignment = 'center';
app.XMaxLabel.VerticalAlignment = 'bottom';
app.XMaxLabel.Enable = 'off';
app.XMaxLabel.Layout.Row = 1;
app.XMaxLabel.Layout.Column = [12 13]; %12; %11;
app.XMaxLabel.Text = 'Max X';

% Create FPXMinField
app.FPXMinField = uieditfield(app.FPNavGrid, 'text');
app.FPXMinField.Enable = 'off';
app.FPXMinField.Tag = '11';
app.FPXMinField.ValueChangedFcn = @app.onFPXFieldChange;
app.FPXMinField.Layout.Row = 2;
app.FPXMinField.Layout.Column = [6 7]; % 6; %6;

% Create FPXMinColonLabel
app.FPXMinColonLabel = uilabel(app.FPNavGrid);
app.FPXMinColonLabel.HorizontalAlignment = 'center';
app.FPXMinColonLabel.Enable = 'off';
app.FPXMinColonLabel.Visible = 'off';
app.FPXMinColonLabel.Layout.Row = 2;
app.FPXMinColonLabel.Layout.Column = 8; %8; %7;
app.FPXMinColonLabel.Text = ':';

% Create FPXMinSecsField
app.FPXMinSecsField = uieditfield(app.FPNavGrid, 'numeric');
app.FPXMinSecsField.Editable = 'on';
app.FPXMinSecsField.Enable = 'off';
app.FPXMinSecsField.Visible = 'off';
app.FPXMinSecsField.Tag = '12';
app.FPXMinSecsField.ValueChangedFcn = @app.onFPXFieldChange;
app.FPXMinSecsField.Layout.Row = 2;
app.FPXMinSecsField.Layout.Column = [9 10]; %9; %8;

% Create FPXMaxField
app.FPXMaxField = uieditfield(app.FPNavGrid, 'text');
app.FPXMaxField.Enable = 'off';
app.FPXMaxField.ValueChangedFcn = @app.onFPXFieldChange;
app.FPXMaxField.Tag = '21';
app.FPXMaxField.Layout.Row = 2;
app.FPXMaxField.Layout.Column = [12 13]; %[12 13]; %11;

% Create FPXMaxColonLabel
app.FPXMaxColonLabel = uilabel(app.FPNavGrid);
app.FPXMaxColonLabel.HorizontalAlignment = 'center';
app.FPXMaxColonLabel.Enable = 'off';
app.FPXMaxColonLabel.Visible = 'off';
app.FPXMaxColonLabel.Layout.Row = 2;
app.FPXMaxColonLabel.Layout.Column = 14; %12;
app.FPXMaxColonLabel.Text = ':';

% Create FPXMaxSecsField
app.FPXMaxSecsField = uieditfield(app.FPNavGrid, 'numeric');
app.FPXMaxSecsField.Editable = 'on';
app.FPXMaxSecsField.Enable = 'off';
app.FPXMaxSecsField.Visible = 'off';
app.FPXMaxSecsField.Tag = '22';
app.FPXMaxSecsField.ValueChangedFcn = {@app.onFPXFieldChange};
app.FPXMaxSecsField.Layout.Row = 2;
app.FPXMaxSecsField.Layout.Column = [15 16]; % 15; %13;

% Create XNavSlider
app.XNavSlider = uislider(app.FPNavGrid);
app.XNavSlider.Enable = 'off';
app.XNavSlider.Layout.Row = 3;
app.XNavSlider.Layout.Column = [5 17]; % [6 15]; % [6 13];
app.XNavSlider.Value = 84.0604264215128;
app.XNavSlider.ValueChangingFcn = {@app.onXNavSliderMove};
app.XNavSlider.ValueChangedFcn = {@app.onXNavSliderMove};
app.XNavSlider.BusyAction = 'cancel';
app.XNavSlider.Interruptible = true;

% Create LockLeftButton
app.LockLeftButton = uibutton(app.FPNavGrid, 'state');
app.LockLeftButton.Enable = 'off';
app.LockLeftButton.Text = {'Lock'; 'Min'};
app.LockLeftButton.Layout.Row = 4;
app.LockLeftButton.Layout.Column = 6;
app.LockLeftButton.Tag = 'L';
app.LockLeftButton.BusyAction = 'cancel';
app.LockLeftButton.ValueChangedFcn = @(src,ev) app.navLockButtonValueChanged(src,ev);

% Create LockRangeButton
app.LockRangeButton = uibutton(app.FPNavGrid, 'state');
app.LockRangeButton.Enable = 'off';
app.LockRangeButton.Tooltip = {'Double-click for auto'};
app.LockRangeButton.Text = {'Lock Rng'; '[Auto X]'};
app.LockRangeButton.Layout.Row = 4;
app.LockRangeButton.Layout.Column = [11 12]; %[10 11]; %[9 10];
app.LockRangeButton.Tag = 'N';
app.LockRangeButton.BusyAction = 'cancel';
app.LockRangeButton.ValueChangedFcn = {@app.navLockButtonValueChanged};
app.LockRangeButton.Interruptible = true;

% Create LockRightButton
app.LockRightButton = uibutton(app.FPNavGrid, 'state');
app.LockRightButton.Enable = 'off';
app.LockRightButton.Text = {'Lock'; 'Max'};
app.LockRightButton.Layout.Row = 4;
app.LockRightButton.Layout.Column = 16; % 15; %13;
app.LockRightButton.Tag = 'R';
app.LockRightButton.BusyAction = 'cancel';
app.LockRightButton.ValueChangedFcn = {@app.navLockButtonValueChanged};

% set(pdlg, 'Message', 'Creating Phase III components...', 'Value', 0.1);
waitbar(0.1, app.wbar, 'Creating Phase III components...');

% Create Phase3Tab
app.Phase3Tab = uitab(app.MainTabGroup);
app.Phase3Tab.Title = 'Phase III - Export Data and Plots';
app.Phase3Tab.Tag = '3';

% Create GridLayout4
app.GridLayout4 = uigridlayout(app.Phase3Tab);
app.GridLayout4.ColumnWidth = {'1x'};
app.GridLayout4.RowHeight = {'1x'};
app.GridLayout4.Padding = [0 0 0 0];

% Create ExportTabGroup
app.ExportTabGroup = uitabgroup(app.GridLayout4);
app.ExportTabGroup.TabLocation = 'left';
app.ExportTabGroup.Layout.Row = 1;
app.ExportTabGroup.Layout.Column = 1;

% Create DataTab
app.DataTab = uitab(app.ExportTabGroup);
app.DataTab.Title = 'Data';

% Create GridLayout25
app.GridLayout25 = uigridlayout(app.DataTab);
app.GridLayout25.ColumnWidth = {300, '1x'};
app.GridLayout25.RowHeight = {'1x'};

% Create ExportConfigurationPanel
app.ExportConfigurationPanel = uipanel(app.GridLayout25);
app.ExportConfigurationPanel.Enable = 'off';
app.ExportConfigurationPanel.Title = 'Export Configuration';
app.ExportConfigurationPanel.Layout.Row = 1;
app.ExportConfigurationPanel.Layout.Column = 1;
app.ExportConfigurationPanel.Scrollable = 'on';

% Create GridLayout26
app.GridLayout26 = uigridlayout(app.ExportConfigurationPanel);
app.GridLayout26.ColumnWidth = {'1x'};
app.GridLayout26.RowHeight = {120, 100, '1x', '1x'};

% Create PresetSelectionButtonGroup
app.PresetSelectionButtonGroup = uibuttongroup(app.GridLayout26);
app.PresetSelectionButtonGroup.Enable = 'off';
app.PresetSelectionButtonGroup.BorderType = 'none';
app.PresetSelectionButtonGroup.Title = 'Preset Selection';
app.PresetSelectionButtonGroup.Layout.Row = 1;
app.PresetSelectionButtonGroup.Layout.Column = 1;

% Create AllDataButton
app.AllDataButton = uiradiobutton(app.PresetSelectionButtonGroup);
app.AllDataButton.Enable = 'off';
app.AllDataButton.Text = 'All Data';
app.AllDataButton.Position = [11 75 64 22];
app.AllDataButton.Value = true;

% Create AllNonChannelSpecificDataButton
app.AllNonChannelSpecificDataButton = uiradiobutton(app.PresetSelectionButtonGroup);
app.AllNonChannelSpecificDataButton.Enable = 'off';
app.AllNonChannelSpecificDataButton.Text = 'All Non-Channel-Specific Data';
app.AllNonChannelSpecificDataButton.Position = [11 53 184 22];

% Create ChannelSpecificDataOnlyButton
app.ChannelSpecificDataOnlyButton = uiradiobutton(app.PresetSelectionButtonGroup);
app.ChannelSpecificDataOnlyButton.Enable = 'off';
app.ChannelSpecificDataOnlyButton.Text = 'Channel-Specific Data Only';
app.ChannelSpecificDataOnlyButton.Position = [11 31 170 22];

% Create IntensityProfilesOnlyButton
app.IntensityProfilesOnlyButton = uiradiobutton(app.PresetSelectionButtonGroup);
app.IntensityProfilesOnlyButton.Enable = 'off';
app.IntensityProfilesOnlyButton.Text = 'Intensity Profiles Only';
app.IntensityProfilesOnlyButton.Position = [11 8 138 22];

% Create OrganizationSchemePanel
app.OrganizationSchemePanel = uipanel(app.GridLayout26);
app.OrganizationSchemePanel.Enable = 'off';
app.OrganizationSchemePanel.BorderType = 'none';
app.OrganizationSchemePanel.Title = 'Organization Scheme';
app.OrganizationSchemePanel.Layout.Row = 2;
app.OrganizationSchemePanel.Layout.Column = 1;

% Create GridLayout27
app.GridLayout27 = uigridlayout(app.OrganizationSchemePanel);
app.GridLayout27.ColumnWidth = {90, '1x'};
app.GridLayout27.RowHeight = {25, 25};

% Create NaNRowsDropDownLabel
app.NaNRowsDropDownLabel = uilabel(app.GridLayout27);
app.NaNRowsDropDownLabel.HorizontalAlignment = 'right';
app.NaNRowsDropDownLabel.Enable = 'off';
app.NaNRowsDropDownLabel.Layout.Row = 2;
app.NaNRowsDropDownLabel.Layout.Column = 1;
app.NaNRowsDropDownLabel.Text = 'NaN Rows';

% Create NaNRowsDropDown
app.NaNRowsDropDown = uidropdown(app.GridLayout27);
app.NaNRowsDropDown.Items = {'Include', 'Exclude'};
app.NaNRowsDropDown.Enable = 'off';
app.NaNRowsDropDown.Layout.Row = 2;
app.NaNRowsDropDown.Layout.Column = 2;
app.NaNRowsDropDown.Value = 'Include';

% Create GroupcolsbyDropDownLabel
app.GroupcolsbyDropDownLabel = uilabel(app.GridLayout27);
app.GroupcolsbyDropDownLabel.HorizontalAlignment = 'right';
app.GroupcolsbyDropDownLabel.Enable = 'off';
app.GroupcolsbyDropDownLabel.Layout.Row = 1;
app.GroupcolsbyDropDownLabel.Layout.Column = 1;
app.GroupcolsbyDropDownLabel.Text = 'Group cols. by:';

% Create GroupcolsbyDropDown
app.GroupcolsbyDropDown = uidropdown(app.GridLayout27);
app.GroupcolsbyDropDown.Items = {'Channel number', 'Variable'};
app.GroupcolsbyDropDown.Enable = 'off';
app.GroupcolsbyDropDown.Layout.Row = 1;
app.GroupcolsbyDropDown.Layout.Column = 2;
app.GroupcolsbyDropDown.Value = 'Channel number';

% Create FieldSelectionPanel_2
app.FieldSelectionPanel_2 = uipanel(app.GridLayout26);
app.FieldSelectionPanel_2.Enable = 'off';
app.FieldSelectionPanel_2.BorderType = 'none';
app.FieldSelectionPanel_2.Title = 'Field Selection';
app.FieldSelectionPanel_2.Layout.Row = 3;
app.FieldSelectionPanel_2.Layout.Column = 1;

% Create GridLayout27_2
app.GridLayout27_2 = uigridlayout(app.FieldSelectionPanel_2);
app.GridLayout27_2.ColumnWidth = {'1x'};
app.GridLayout27_2.RowHeight = {'1x'};
app.GridLayout27_2.Padding = [0 10 0 10];

% Create Tree
app.Tree = uitree(app.GridLayout27_2, 'checkbox');
app.Tree.Enable = 'off';
app.Tree.Layout.Row = 1;
app.Tree.Layout.Column = 1;

% Create FullProfileDataNode
app.FullProfileDataNode = uitreenode(app.Tree);
app.FullProfileDataNode.Text = 'Full-Profile Data';

% Create DatapointIndexNode
app.DatapointIndexNode = uitreenode(app.FullProfileDataNode);
app.DatapointIndexNode.Text = 'Datapoint Index';

% Create TimeNode
app.TimeNode = uitreenode(app.FullProfileDataNode);
app.TimeNode.Text = 'Time';

% Create EstimatedLaserIntensityELINode
app.EstimatedLaserIntensityELINode = uitreenode(app.FullProfileDataNode);
app.EstimatedLaserIntensityELINode.Text = 'Estimated Laser Intensity (ELI)';

% Create FullProfilePeakEstimationNode
app.FullProfilePeakEstimationNode = uitreenode(app.FullProfileDataNode);
app.FullProfilePeakEstimationNode.Text = 'Full-Profile Peak Estimation';

% Create EstimatedPeakPositionfullprofileNode
app.EstimatedPeakPositionfullprofileNode = uitreenode(app.FullProfilePeakEstimationNode);
app.EstimatedPeakPositionfullprofileNode.Text = 'Estimated Peak Position (full-profile)';

% Create EstimatedPeakHeightfullprofileNode
app.EstimatedPeakHeightfullprofileNode = uitreenode(app.FullProfilePeakEstimationNode);
app.EstimatedPeakHeightfullprofileNode.Text = 'Estimated Peak Height (full-profile)';

% Create EstimatedcurvefitparametersfullprofileNode
app.EstimatedcurvefitparametersfullprofileNode = uitreenode(app.FullProfilePeakEstimationNode);
app.EstimatedcurvefitparametersfullprofileNode.Text = 'Estimated curve fit parameters (full-profile)';

% Create ChannelDataNode
app.ChannelDataNode = uitreenode(app.Tree);
app.ChannelDataNode.Text = 'Channel Data';

% Create IntensityProfileNode
app.IntensityProfileNode = uitreenode(app.ChannelDataNode);
app.IntensityProfileNode.Text = 'Intensity Profile';

% Create PeakHeightLorABNode
app.PeakHeightLorABNode = uitreenode(app.ChannelDataNode);
app.PeakHeightLorABNode.Text = 'Peak Height (Lor. "A/B")';

% Create PeakPositionLorx0Node
app.PeakPositionLorx0Node = uitreenode(app.ChannelDataNode);
app.PeakPositionLorx0Node.Text = 'Peak Position (Lor. "x0")';

% Create LorfitparameterANode
app.LorfitparameterANode = uitreenode(app.ChannelDataNode);
app.LorfitparameterANode.Text = 'Lor. fit parameter "A"';

% Create LorfitparameterBNode
app.LorfitparameterBNode = uitreenode(app.ChannelDataNode);
app.LorfitparameterBNode.Text = 'Lor. fit parameter "B"';

% Create ChannelsToIncludeinExportPanel
app.ChannelsToIncludeinExportPanel = uipanel(app.GridLayout26);
app.ChannelsToIncludeinExportPanel.Enable = 'off';
app.ChannelsToIncludeinExportPanel.BorderType = 'none';
app.ChannelsToIncludeinExportPanel.Title = 'Channels To Include in Export';
app.ChannelsToIncludeinExportPanel.Layout.Row = 4;
app.ChannelsToIncludeinExportPanel.Layout.Column = 1;

% Create GridLayout27_3
app.GridLayout27_3 = uigridlayout(app.ChannelsToIncludeinExportPanel);
app.GridLayout27_3.ColumnWidth = {'1x'};
app.GridLayout27_3.RowHeight = {'1x'};
app.GridLayout27_3.Padding = [0 10 0 10];

% Create ListBox
app.ListBox = uilistbox(app.GridLayout27_3);
app.ListBox.Items = {'Channel 1'};
app.ListBox.Multiselect = 'on';
app.ListBox.Enable = 'off';
app.ListBox.Layout.Row = 1;
app.ListBox.Layout.Column = 1;
app.ListBox.Value = {'Channel 1'};

% Create GridLayout28
app.GridLayout28 = uigridlayout(app.GridLayout25);
app.GridLayout28.ColumnWidth = {'1x'};
app.GridLayout28.RowHeight = {'1x', 75};
app.GridLayout28.Padding = [0 0 0 0];
app.GridLayout28.Layout.Row = 1;
app.GridLayout28.Layout.Column = 2;

% Create PreviewPanel
app.PreviewPanel = uipanel(app.GridLayout28);
app.PreviewPanel.Enable = 'off';
app.PreviewPanel.Title = 'Preview';
app.PreviewPanel.Layout.Row = 1;
app.PreviewPanel.Layout.Column = 1;

% Create GridLayout28_2
app.GridLayout28_2 = uigridlayout(app.PreviewPanel);
app.GridLayout28_2.ColumnWidth = {'1x'};
app.GridLayout28_2.RowHeight = {'1x'};

% Create UITable
app.UITable = uitable(app.GridLayout28_2);
app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
app.UITable.RowName = {};
app.UITable.Enable = 'off';
app.UITable.Visible = 'off';
app.UITable.Layout.Row = 1;
app.UITable.Layout.Column = 1;

% Create Panel_2
app.Panel_2 = uipanel(app.GridLayout28);
app.Panel_2.Layout.Row = 2;
app.Panel_2.Layout.Column = 1;

% Create GridLayout29
app.GridLayout29 = uigridlayout(app.Panel_2);
app.GridLayout29.ColumnWidth = {'1x', '1x', '1x', '1x'};
app.GridLayout29.RowHeight = {'1x'};

% Create ExportFormatDropDownLabel
app.ExportFormatDropDownLabel = uilabel(app.GridLayout29);
app.ExportFormatDropDownLabel.HorizontalAlignment = 'right';
app.ExportFormatDropDownLabel.Enable = 'off';
app.ExportFormatDropDownLabel.Layout.Row = 1;
app.ExportFormatDropDownLabel.Layout.Column = 1;
app.ExportFormatDropDownLabel.Text = 'Export Format';

% Create ExportFormatDropDown
app.ExportFormatDropDown = uidropdown(app.GridLayout29);
app.ExportFormatDropDown.Items = {'MS Excel file (.xsl)', 'CSV', 'MAT file'};
app.ExportFormatDropDown.Enable = 'off';
app.ExportFormatDropDown.Layout.Row = 1;
app.ExportFormatDropDown.Layout.Column = 2;
app.ExportFormatDropDown.Value = 'MS Excel file (.xsl)';

% Create ExportButton
app.ExportButton = uibutton(app.GridLayout29, 'push');
app.ExportButton.Interruptible = 'off';
app.ExportButton.BusyAction = 'cancel';
app.ExportButton.Enable = 'off';
app.ExportButton.Layout.Row = 1;
app.ExportButton.Layout.Column = 4;
app.ExportButton.Text = 'EXPORT';

% Create ImagesTab
app.ImagesTab = uitab(app.ExportTabGroup);
app.ImagesTab.Title = 'Image(s)';

% Create GridLayout25_2
app.GridLayout25_2 = uigridlayout(app.ImagesTab);
app.GridLayout25_2.ColumnWidth = {300, '1x'};
app.GridLayout25_2.RowHeight = {'1x'};

% Create ExportConfigurationPanel_2
app.ExportConfigurationPanel_2 = uipanel(app.GridLayout25_2);
app.ExportConfigurationPanel_2.Enable = 'off';
app.ExportConfigurationPanel_2.Title = 'Export Configuration';
app.ExportConfigurationPanel_2.Layout.Row = 1;
app.ExportConfigurationPanel_2.Layout.Column = 1;
app.ExportConfigurationPanel_2.Scrollable = 'on';

% Create GridLayout26_2
app.GridLayout26_2 = uigridlayout(app.ExportConfigurationPanel_2);
app.GridLayout26_2.ColumnWidth = {'1x'};
app.GridLayout26_2.RowHeight = {185, 120, '1x'};

% Create ChannelsToIncludeinExportPanel_2
app.ChannelsToIncludeinExportPanel_2 = uipanel(app.GridLayout26_2);
app.ChannelsToIncludeinExportPanel_2.Enable = 'off';
app.ChannelsToIncludeinExportPanel_2.BorderType = 'none';
app.ChannelsToIncludeinExportPanel_2.Title = 'Channels To Include in Export';
app.ChannelsToIncludeinExportPanel_2.Layout.Row = 3;
app.ChannelsToIncludeinExportPanel_2.Layout.Column = 1;

% Create GridLayout27_6
app.GridLayout27_6 = uigridlayout(app.ChannelsToIncludeinExportPanel_2);
app.GridLayout27_6.ColumnWidth = {'1x'};
app.GridLayout27_6.RowHeight = {'1x'};
app.GridLayout27_6.Padding = [0 10 0 10];

% Create ListBox_2
app.ListBox_2 = uilistbox(app.GridLayout27_6);
app.ListBox_2.Items = {'Channel 1'};
app.ListBox_2.Multiselect = 'on';
app.ListBox_2.Enable = 'off';
app.ListBox_2.Layout.Row = 1;
app.ListBox_2.Layout.Column = 1;
app.ListBox_2.Value = {'Channel 1'};

% Create ImageCategorytoExportButtonGroup
app.ImageCategorytoExportButtonGroup = uibuttongroup(app.GridLayout26_2);
app.ImageCategorytoExportButtonGroup.Enable = 'off';
app.ImageCategorytoExportButtonGroup.BorderType = 'none';
app.ImageCategorytoExportButtonGroup.Title = 'Image Category to Export';
app.ImageCategorytoExportButtonGroup.Layout.Row = 1;
app.ImageCategorytoExportButtonGroup.Layout.Column = 1;

% Create Button_2
app.Button_2 = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.Button_2.Enable = 'off';
app.Button_2.Text = 'Peak Position(s)';
app.Button_2.Position = [11 140 109 22];
app.Button_2.Value = true;

% Create PeakHeightswithELIButton
app.PeakHeightswithELIButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.PeakHeightswithELIButton.Enable = 'off';
app.PeakHeightswithELIButton.Text = 'Peak Height(s) with ELI';
app.PeakHeightswithELIButton.Position = [11 118 147 22];

% Create PeakHeightswithoutELIButton
app.PeakHeightswithoutELIButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.PeakHeightswithoutELIButton.Enable = 'off';
app.PeakHeightswithoutELIButton.Text = 'Peak Height(s) without ELI';
app.PeakHeightswithoutELIButton.Position = [11 96 164 22];

% Create ChannelIntensityProfilesButton
app.ChannelIntensityProfilesButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.ChannelIntensityProfilesButton.Enable = 'off';
app.ChannelIntensityProfilesButton.Text = 'Channel Intensity Profiles';
app.ChannelIntensityProfilesButton.Position = [11 73 158 22];

% Create CompositeImageButton
app.CompositeImageButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.CompositeImageButton.Enable = 'off';
app.CompositeImageButton.Text = 'Composite Image';
app.CompositeImageButton.Position = [11 50 116 22];

% Create YrimageButton
app.YrimageButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.YrimageButton.Enable = 'off';
app.YrimageButton.Text = 'Yr image';
app.YrimageButton.Position = [11 27 70 22];

% Create YcimageButton
app.YcimageButton = uiradiobutton(app.ImageCategorytoExportButtonGroup);
app.YcimageButton.Enable = 'off';
app.YcimageButton.Text = 'Yc image';
app.YcimageButton.Position = [11 4 72 22];

% Create DatapointIndexIndicesPanel
app.DatapointIndexIndicesPanel = uipanel(app.GridLayout26_2);
app.DatapointIndexIndicesPanel.Enable = 'off';
app.DatapointIndexIndicesPanel.BorderType = 'none';
app.DatapointIndexIndicesPanel.Title = 'Datapoint Index/Indices';
app.DatapointIndexIndicesPanel.Layout.Row = 2;
app.DatapointIndexIndicesPanel.Layout.Column = 1;

% Create GridLayout30
app.GridLayout30 = uigridlayout(app.DatapointIndexIndicesPanel);
app.GridLayout30.ColumnWidth = {60, '1x'};

% Create FirstIndexSliderLabel
app.FirstIndexSliderLabel = uilabel(app.GridLayout30);
app.FirstIndexSliderLabel.HorizontalAlignment = 'right';
app.FirstIndexSliderLabel.Enable = 'off';
app.FirstIndexSliderLabel.Layout.Row = 1;
app.FirstIndexSliderLabel.Layout.Column = 1;
app.FirstIndexSliderLabel.Text = 'First Index';

% Create FirstIndexSlider
app.FirstIndexSlider = uislider(app.GridLayout30);
app.FirstIndexSlider.Limits = [0 1];
app.FirstIndexSlider.Enable = 'off';
app.FirstIndexSlider.Layout.Row = 1;
app.FirstIndexSlider.Layout.Column = 2;

% Create LastIndexSliderLabel
app.LastIndexSliderLabel = uilabel(app.GridLayout30);
app.LastIndexSliderLabel.HorizontalAlignment = 'right';
app.LastIndexSliderLabel.Enable = 'off';
app.LastIndexSliderLabel.Layout.Row = 2;
app.LastIndexSliderLabel.Layout.Column = 1;
app.LastIndexSliderLabel.Text = 'Last Index';

% Create LastIndexSlider
app.LastIndexSlider = uislider(app.GridLayout30);
app.LastIndexSlider.Limits = [0 1];
app.LastIndexSlider.Enable = 'off';
app.LastIndexSlider.Layout.Row = 2;
app.LastIndexSlider.Layout.Column = 2;

% Create GridLayout28_3
app.GridLayout28_3 = uigridlayout(app.GridLayout25_2);
app.GridLayout28_3.ColumnWidth = {'1x'};
app.GridLayout28_3.RowHeight = {'1x', 75};
app.GridLayout28_3.Padding = [0 0 0 0];
app.GridLayout28_3.Layout.Row = 1;
app.GridLayout28_3.Layout.Column = 2;

% Create PreviewPanel_2
app.PreviewPanel_2 = uipanel(app.GridLayout28_3);
app.PreviewPanel_2.Enable = 'off';
app.PreviewPanel_2.Title = 'Preview';
app.PreviewPanel_2.Layout.Row = 1;
app.PreviewPanel_2.Layout.Column = 1;

% Create GridLayout28_4
app.GridLayout28_4 = uigridlayout(app.PreviewPanel_2);
app.GridLayout28_4.ColumnWidth = {'1x'};
app.GridLayout28_4.RowHeight = {'1x', 50};
app.GridLayout28_4.Visible = 'off';

% Create Panel_3
app.Panel_3 = uipanel(app.GridLayout28_3);
app.Panel_3.Enable = 'off';
app.Panel_3.Layout.Row = 2;
app.Panel_3.Layout.Column = 1;

% Create GridLayout29_2
app.GridLayout29_2 = uigridlayout(app.Panel_3);
app.GridLayout29_2.ColumnWidth = {85, 80, '1x', 130, 120, '2x', '2x', 150};

% Create ExportFormatDropDown_2Label
app.ExportFormatDropDown_2Label = uilabel(app.GridLayout29_2);
app.ExportFormatDropDown_2Label.HorizontalAlignment = 'right';
app.ExportFormatDropDown_2Label.Enable = 'off';
app.ExportFormatDropDown_2Label.Layout.Row = 1;
app.ExportFormatDropDown_2Label.Layout.Column = 1;
app.ExportFormatDropDown_2Label.Text = 'Export Format';

% Create ExportFormatDropDown_2
app.ExportFormatDropDown_2 = uidropdown(app.GridLayout29_2);
app.ExportFormatDropDown_2.Items = {'PNG', 'JPG'};
app.ExportFormatDropDown_2.Enable = 'off';
app.ExportFormatDropDown_2.Layout.Row = 1;
app.ExportFormatDropDown_2.Layout.Column = 2;
app.ExportFormatDropDown_2.Value = 'PNG';

% Create EXPORTButton_2
app.EXPORTButton_2 = uibutton(app.GridLayout29_2, 'push');
app.EXPORTButton_2.Enable = 'off';
app.EXPORTButton_2.Layout.Row = 1;
app.EXPORTButton_2.Layout.Column = 8;
app.EXPORTButton_2.Text = 'EXPORT';

% Create ResolutionEditFieldLabel
app.ResolutionEditFieldLabel = uilabel(app.GridLayout29_2);
app.ResolutionEditFieldLabel.HorizontalAlignment = 'right';
app.ResolutionEditFieldLabel.Enable = 'off';
app.ResolutionEditFieldLabel.Layout.Row = 2;
app.ResolutionEditFieldLabel.Layout.Column = 1;
app.ResolutionEditFieldLabel.Text = 'Resolution (%)';

% Create ResolutionEditField
app.ResolutionEditField = uieditfield(app.GridLayout29_2, 'numeric');
app.ResolutionEditField.Enable = 'off';
app.ResolutionEditField.Layout.Row = 2;
app.ResolutionEditField.Layout.Column = 2;

% Create FilenamePrefixEditFieldLabel
app.FilenamePrefixEditFieldLabel = uilabel(app.GridLayout29_2);
app.FilenamePrefixEditFieldLabel.HorizontalAlignment = 'right';
app.FilenamePrefixEditFieldLabel.Enable = 'off';
app.FilenamePrefixEditFieldLabel.Layout.Row = 1;
app.FilenamePrefixEditFieldLabel.Layout.Column = 4;
app.FilenamePrefixEditFieldLabel.Text = 'Filename Prefix';

% Create FilenamePrefixEditField
app.FilenamePrefixEditField = uieditfield(app.GridLayout29_2, 'text');
app.FilenamePrefixEditField.Enable = 'off';
app.FilenamePrefixEditField.Layout.Row = 1;
app.FilenamePrefixEditField.Layout.Column = [5 6];

% Create FilenameSuffixFormatDropDownLabel
app.FilenameSuffixFormatDropDownLabel = uilabel(app.GridLayout29_2);
app.FilenameSuffixFormatDropDownLabel.HorizontalAlignment = 'right';
app.FilenameSuffixFormatDropDownLabel.Enable = 'off';
app.FilenameSuffixFormatDropDownLabel.Layout.Row = 2;
app.FilenameSuffixFormatDropDownLabel.Layout.Column = 4;
app.FilenameSuffixFormatDropDownLabel.Text = 'Filename Suffix Format';

% Create FilenameSuffixFormatDropDown
app.FilenameSuffixFormatDropDown = uidropdown(app.GridLayout29_2);
app.FilenameSuffixFormatDropDown.Items = {'plot type, channel num., index', 'plot type, index, channel num.', 'channel num., plot type, index', 'channel num., index, plot type', 'index, channel num., plot type', 'index, plot type, channel num.'};
app.FilenameSuffixFormatDropDown.Enable = 'off';
app.FilenameSuffixFormatDropDown.Layout.Row = 2;
app.FilenameSuffixFormatDropDown.Layout.Column = [5 6];
app.FilenameSuffixFormatDropDown.Value = 'plot type, channel num., index';

% Create PrefixwithsessionnameCheckBox
app.PrefixwithsessionnameCheckBox = uicheckbox(app.GridLayout29_2);
app.PrefixwithsessionnameCheckBox.Enable = 'off';
app.PrefixwithsessionnameCheckBox.Text = 'Prefix with session name';
app.PrefixwithsessionnameCheckBox.Layout.Row = 2;
app.PrefixwithsessionnameCheckBox.Layout.Column = 8;
app.PrefixwithsessionnameCheckBox.Value = true;

% Create AnimationTab
app.AnimationTab = uitab(app.ExportTabGroup);
app.AnimationTab.Title = 'Animation';

% Create GridLayout25_3
app.GridLayout25_3 = uigridlayout(app.AnimationTab);
app.GridLayout25_3.ColumnWidth = {300, '1x'};
app.GridLayout25_3.RowHeight = {'1x'};

% Create ExportConfigurationPanel_3
app.ExportConfigurationPanel_3 = uipanel(app.GridLayout25_3);
app.ExportConfigurationPanel_3.Enable = 'off';
app.ExportConfigurationPanel_3.Title = 'Export Configuration';
app.ExportConfigurationPanel_3.Layout.Row = 1;
app.ExportConfigurationPanel_3.Layout.Column = 1;
app.ExportConfigurationPanel_3.Scrollable = 'on';

% Create GridLayout26_3
app.GridLayout26_3 = uigridlayout(app.ExportConfigurationPanel_3);
app.GridLayout26_3.ColumnWidth = {'1x'};
app.GridLayout26_3.RowHeight = {185, 120, '1x'};

% Create ChannelsToIncludeinExportPanel_3
app.ChannelsToIncludeinExportPanel_3 = uipanel(app.GridLayout26_3);
app.ChannelsToIncludeinExportPanel_3.Enable = 'off';
app.ChannelsToIncludeinExportPanel_3.BorderType = 'none';
app.ChannelsToIncludeinExportPanel_3.Title = 'Channels To Include in Export';
app.ChannelsToIncludeinExportPanel_3.Layout.Row = 3;
app.ChannelsToIncludeinExportPanel_3.Layout.Column = 1;

% Create GridLayout27_7
app.GridLayout27_7 = uigridlayout(app.ChannelsToIncludeinExportPanel_3);
app.GridLayout27_7.ColumnWidth = {'1x'};
app.GridLayout27_7.RowHeight = {'1x'};
app.GridLayout27_7.Padding = [0 10 0 10];

% Create ListBox_3
app.ListBox_3 = uilistbox(app.GridLayout27_7);
app.ListBox_3.Items = {'Channel 1'};
app.ListBox_3.Multiselect = 'on';
app.ListBox_3.Enable = 'off';
app.ListBox_3.Layout.Row = 1;
app.ListBox_3.Layout.Column = 1;
app.ListBox_3.Value = {'Channel 1'};

% Create DatapointIndexIndicesPanel_2
app.DatapointIndexIndicesPanel_2 = uipanel(app.GridLayout26_3);
app.DatapointIndexIndicesPanel_2.Enable = 'off';
app.DatapointIndexIndicesPanel_2.BorderType = 'none';
app.DatapointIndexIndicesPanel_2.Title = 'Datapoint Index/Indices';
app.DatapointIndexIndicesPanel_2.Layout.Row = 2;
app.DatapointIndexIndicesPanel_2.Layout.Column = 1;

% Create GridLayout30_2
app.GridLayout30_2 = uigridlayout(app.DatapointIndexIndicesPanel_2);
app.GridLayout30_2.ColumnWidth = {60, '1x'};

% Create FirstIndexSlider_2Label
app.FirstIndexSlider_2Label = uilabel(app.GridLayout30_2);
app.FirstIndexSlider_2Label.HorizontalAlignment = 'right';
app.FirstIndexSlider_2Label.Enable = 'off';
app.FirstIndexSlider_2Label.Layout.Row = 1;
app.FirstIndexSlider_2Label.Layout.Column = 1;
app.FirstIndexSlider_2Label.Text = 'First Index';

% Create FirstIndexSlider_2
app.FirstIndexSlider_2 = uislider(app.GridLayout30_2);
app.FirstIndexSlider_2.Limits = [0 1];
app.FirstIndexSlider_2.Enable = 'off';
app.FirstIndexSlider_2.Layout.Row = 1;
app.FirstIndexSlider_2.Layout.Column = 2;

% Create LastIndexSlider_2Label
app.LastIndexSlider_2Label = uilabel(app.GridLayout30_2);
app.LastIndexSlider_2Label.HorizontalAlignment = 'right';
app.LastIndexSlider_2Label.Enable = 'off';
app.LastIndexSlider_2Label.Layout.Row = 2;
app.LastIndexSlider_2Label.Layout.Column = 1;
app.LastIndexSlider_2Label.Text = 'Last Index';

% Create LastIndexSlider_2
app.LastIndexSlider_2 = uislider(app.GridLayout30_2);
app.LastIndexSlider_2.Limits = [0 1];
app.LastIndexSlider_2.Enable = 'off';
app.LastIndexSlider_2.Layout.Row = 2;
app.LastIndexSlider_2.Layout.Column = 2;

% Create FieldSelectionPanel_3
app.FieldSelectionPanel_3 = uipanel(app.GridLayout26_3);
app.FieldSelectionPanel_3.Enable = 'off';
app.FieldSelectionPanel_3.BorderType = 'none';
app.FieldSelectionPanel_3.Title = 'Field Selection';
app.FieldSelectionPanel_3.Layout.Row = 1;
app.FieldSelectionPanel_3.Layout.Column = 1;

% Create GridLayout27_8
app.GridLayout27_8 = uigridlayout(app.FieldSelectionPanel_3);
app.GridLayout27_8.ColumnWidth = {'1x'};
app.GridLayout27_8.RowHeight = {'1x'};
app.GridLayout27_8.Padding = [0 10 0 10];

% Create Tree_2
app.Tree_2 = uitree(app.GridLayout27_8, 'checkbox');
app.Tree_2.Enable = 'off';
app.Tree_2.Layout.Row = 1;
app.Tree_2.Layout.Column = 1;

% Create CompositeimageNode
app.CompositeimageNode = uitreenode(app.Tree_2);
app.CompositeimageNode.Text = 'Composite image';

% Create YcImageNode
app.YcImageNode = uitreenode(app.Tree_2);
app.YcImageNode.Text = 'Yc Image';

% Create YrimageNode
app.YrimageNode = uitreenode(app.Tree_2);
app.YrimageNode.Text = 'Yr image';

% Create ChannelintensityprofilesNode
app.ChannelintensityprofilesNode = uitreenode(app.Tree_2);
app.ChannelintensityprofilesNode.Text = 'Channel intensity profiles';

% Create PeakHeightPlotNode
app.PeakHeightPlotNode = uitreenode(app.Tree_2);
app.PeakHeightPlotNode.Text = 'Peak Height Plot';

% Create PeakLocPlotNode
app.PeakLocPlotNode = uitreenode(app.Tree_2);
app.PeakLocPlotNode.Text = 'Peak Loc. Plot';

% Create EstimatedLaserIntensityPlotNode
app.EstimatedLaserIntensityPlotNode = uitreenode(app.Tree_2);
app.EstimatedLaserIntensityPlotNode.Text = 'Estimated Laser Intensity Plot';

% Create GridLayout28_5
app.GridLayout28_5 = uigridlayout(app.GridLayout25_3);
app.GridLayout28_5.ColumnWidth = {'1x'};
app.GridLayout28_5.RowHeight = {'1x', 75};
app.GridLayout28_5.Padding = [0 0 0 0];
app.GridLayout28_5.Layout.Row = 1;
app.GridLayout28_5.Layout.Column = 2;

% Create PreviewPanel_3
app.PreviewPanel_3 = uipanel(app.GridLayout28_5);
app.PreviewPanel_3.Enable = 'off';
app.PreviewPanel_3.Title = 'Preview';
app.PreviewPanel_3.Layout.Row = 1;
app.PreviewPanel_3.Layout.Column = 1;

% Create GridLayout28_6
app.GridLayout28_6 = uigridlayout(app.PreviewPanel_3);
app.GridLayout28_6.ColumnWidth = {'1x'};
app.GridLayout28_6.RowHeight = {'1x', 50};
app.GridLayout28_6.Visible = 'off';

% Create Panel_4
app.Panel_4 = uipanel(app.GridLayout28_5);
app.Panel_4.Enable = 'off';
app.Panel_4.Layout.Row = 2;
app.Panel_4.Layout.Column = 1;

% Create GridLayout29_3
app.GridLayout29_3 = uigridlayout(app.Panel_4);
app.GridLayout29_3.ColumnWidth = {'1x', '1x', '1x', '1x'};
app.GridLayout29_3.RowHeight = {'1x'};

% Create ExportFormatDropDown_3Label
app.ExportFormatDropDown_3Label = uilabel(app.GridLayout29_3);
app.ExportFormatDropDown_3Label.HorizontalAlignment = 'right';
app.ExportFormatDropDown_3Label.Enable = 'off';
app.ExportFormatDropDown_3Label.Layout.Row = 1;
app.ExportFormatDropDown_3Label.Layout.Column = 1;
app.ExportFormatDropDown_3Label.Text = 'Export Format';

% Create ExportFormatDropDown_3
app.ExportFormatDropDown_3 = uidropdown(app.GridLayout29_3);
app.ExportFormatDropDown_3.Items = {'PNG', 'JPG'};
app.ExportFormatDropDown_3.Enable = 'off';
app.ExportFormatDropDown_3.Layout.Row = 1;
app.ExportFormatDropDown_3.Layout.Column = 2;
app.ExportFormatDropDown_3.Value = 'PNG';

% Create EXPORTButton_3
app.EXPORTButton_3 = uibutton(app.GridLayout29_3, 'push');
app.EXPORTButton_3.Enable = 'off';
app.EXPORTButton_3.Layout.Row = 1;
app.EXPORTButton_3.Layout.Column = 4;
app.EXPORTButton_3.Text = 'EXPORT';

% Create CustomTab
app.CustomTab = uitab(app.ExportTabGroup);
app.CustomTab.Title = 'Custom';

% set(pdlg, 'Message', 'Creating statusbar components...', 'Value', 0.15);
waitbar(0.15, app.wbar, 'Creating statusbar components...');

% Create AlertArea
app.AlertArea = uitextarea(app.MainGridLayout);
app.AlertArea.Editable = 'off';
app.AlertArea.Layout.Row = 2;
app.AlertArea.Layout.Column = 1;

% Create StatusbarGrid
app.StatusbarGrid = uigridlayout(app.MainGridLayout);
app.StatusbarGrid.ColumnWidth = {25, 'fit', '3x', '1x', 'fit', '2x', '1x', 'fit', '3x', '1x', 'fit', '4x', '1x', 'fit', '3x', 25};
app.StatusbarGrid.RowHeight = {15};
app.StatusbarGrid.ColumnSpacing = 5;
app.StatusbarGrid.RowSpacing = 0;
app.StatusbarGrid.Padding = [0 0 0 0];
app.StatusbarGrid.Layout.Row = 3;
app.StatusbarGrid.Layout.Column = 1;

% Create StatusRefFileLabelLabel
app.StatusRefFileLabelLabel = uilabel(app.StatusbarGrid);
app.StatusRefFileLabelLabel.HorizontalAlignment = 'right';
app.StatusRefFileLabelLabel.FontWeight = 'bold';
app.StatusRefFileLabelLabel.Layout.Row = 1;
app.StatusRefFileLabelLabel.Layout.Column = 2;
app.StatusRefFileLabelLabel.Text = 'Ref. img. filename:';

% Create StatusRefFileLabel
app.StatusRefFileLabel = uilabel(app.StatusbarGrid);
app.StatusRefFileLabel.Layout.Row = 1;
app.StatusRefFileLabel.Layout.Column = 3;
app.StatusRefFileLabel.Text = '---';

% Create StatusResolutionLabelLabel
app.StatusResolutionLabelLabel = uilabel(app.StatusbarGrid);
app.StatusResolutionLabelLabel.HorizontalAlignment = 'right';
app.StatusResolutionLabelLabel.FontWeight = 'bold';
app.StatusResolutionLabelLabel.Layout.Row = 1;
app.StatusResolutionLabelLabel.Layout.Column = 5;
app.StatusResolutionLabelLabel.Text = 'Analysis image resolution:';

% Create StatusResolutionLabel
app.StatusResolutionLabel = uilabel(app.StatusbarGrid);
app.StatusResolutionLabel.Layout.Row = 1;
app.StatusResolutionLabel.Layout.Column = 6;
app.StatusResolutionLabel.Text = '---';

% Create StatusPgmStatusLabelLabel
app.StatusPgmStatusLabelLabel = uilabel(app.StatusbarGrid);
app.StatusPgmStatusLabelLabel.HorizontalAlignment = 'right';
app.StatusPgmStatusLabelLabel.FontWeight = 'bold';
app.StatusPgmStatusLabelLabel.Layout.Row = 1;
app.StatusPgmStatusLabelLabel.Layout.Column = 8;
app.StatusPgmStatusLabelLabel.Text = 'Pgm. status:';

% Create StatusPgmStatusLabel
app.StatusPgmStatusLabel = uilabel(app.StatusbarGrid);
app.StatusPgmStatusLabel.Layout.Row = 1;
app.StatusPgmStatusLabel.Layout.Column = 9;
app.StatusPgmStatusLabel.Text = '---';

% Create UserActionLabelLabel
app.UserActionLabelLabel = uilabel(app.StatusbarGrid);
app.UserActionLabelLabel.HorizontalAlignment = 'right';
app.UserActionLabelLabel.FontWeight = 'bold';
app.UserActionLabelLabel.Layout.Row = 1;
app.UserActionLabelLabel.Layout.Column = 11;
app.UserActionLabelLabel.Text = 'User action:';

% Create UserActionLabel
app.UserActionLabel = uilabel(app.StatusbarGrid);
app.UserActionLabel.Layout.Row = 1;
app.UserActionLabel.Layout.Column = 12;
app.UserActionLabel.Text = '---';

% Create StatusDatapointIndexLabelLabel
app.StatusDatapointIndexLabelLabel = uilabel(app.StatusbarGrid);
app.StatusDatapointIndexLabelLabel.HorizontalAlignment = 'right';
app.StatusDatapointIndexLabelLabel.FontWeight = 'bold';
app.StatusDatapointIndexLabelLabel.Layout.Row = 1;
app.StatusDatapointIndexLabelLabel.Layout.Column = 14;
app.StatusDatapointIndexLabelLabel.Text = 'Selected datapoint index:';

% Create StatusDatapointIndexLabel
app.StatusDatapointIndexLabel = uilabel(app.StatusbarGrid);
app.StatusDatapointIndexLabel.Layout.Row = 1;
app.StatusDatapointIndexLabel.Layout.Column = 15;
app.StatusDatapointIndexLabel.Text = '---';


set([app.HgtAxes app.PosAxes], 'ContextMenu', app.PlotContextMenu);

% Create context menu for DataImageAxes
app.DataImageContextMenu = uicontextmenu(app.UIFigure, 'Interruptible', 'on');

app.DI_ShowChannelsToggleMenu = uimenu(app.DataImageContextMenu, ...
'Enable', 'on', 'Text', 'Show channel overlay?', ...
'Separator', 'on', 'Tooltip', 'TODO: Write tooltip text', ...
'MenuSelectedFcn', @app.dataImg_ToggleChannelOverlay, 'Tag', ' ');

app.DI_ShowMaskToggleMenu = uimenu(app.DataImageContextMenu, ...
'Enable', 'on', 'Text', 'Show mask overlay?', ...
'Separator', 'off', 'Tooltip', 'TODO: Write tooltip text', ...
'MenuSelectedFcn', @app.dataImage_FeatureToggle, 'Tag', '0');
app.DI_ShowMaskSelectionMenu = uimenu(app.DataImageContextMenu, ...
'Enable', 'on', 'Text', 'Choose mask overlay');
app.DI_ShowMask1ToggleMenu = uimenu(app.DI_ShowMaskSelectionMenu, ...
'Enable', 'off', 'Text', 'ROI mask', 'Tag', '00', ...
'MenuSelectedFcn', @app.dataImage_SelectFeature);
app.DI_ShowMask2ToggleMenu = uimenu(app.DI_ShowMaskSelectionMenu, ...
'Enable', 'off', 'Text', 'SampMask0', 'Tag', '01', ...
'MenuSelectedFcn', @app.dataImage_SelectFeature);
app.DI_ShowMask3ToggleMenu = uimenu(app.DI_ShowMaskSelectionMenu, ...
'Enable', 'off', 'Text', 'SampMask', 'Tag', '02', ...
'MenuSelectedFcn', @app.dataImage_SelectFeature);

% app.DI_ShowPeakLineToggleMenu = uimenu(app.DataImageContextMenu, ...
% 'Enable', 'off', 'Text', 'Mark image with index number?', 'Tag', '1', ...
% 'Separator', 'on', 'MenuSelectedFcn', @app.quickExport_FeatureToggle);
% app.DI_ShowDPNumPosMenu = uimenu(app.DataImageContextMenu, ...
% 'Enable', 'on', 'Text', 'Choose index number position');
% app.DI_ShowDPNumLeftToggleMenu = uimenu(app.DI_ShowDPNumPosMenu, ...
% 'Enable', 'off', 'Text', 'Write idx # on left edge', 'Tag', '10', ...
% 'MenuSelectedFcn', @app.quickExport_SelectFeature);
% app.DI_ShowDPNumRightToggleMenu = uimenu(app.DI_ShowDPNumPosMenu, ...
% 'Enable', 'off', 'Text', 'Write idx # on right edge', 'Tag', '11', ...
% 'MenuSelectedFcn', @app.quickExport_SelectFeature);

set([app.DI_ShowMaskToggleMenu, ...
    app.DI_ShowMask1ToggleMenu, app.DI_ShowMask2ToggleMenu, ...
    app.DI_ShowMask3ToggleMenu], 'UserData', app.DI_ShowMaskSelectionMenu);

% set([app.DI_ShowDPNumToggleMenu, app.DI_ShowDPNumLeftToggleMenu, ...
%     app.DI_ShowDPNumRightToggleMenu], 'UserData', app.DI_ShowDPNumPosMenu);


uimenu(app.DataImageContextMenu, 'Text', 'Copy image to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'diC', 'Separator', 'on');
uimenu(app.DataImageContextMenu, 'Text', 'Save image to file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'diF');

app.DataImageAxes.ContextMenu = app.DataImageContextMenu;


app.IProfPanel.ContextMenu = uicontextmenu(app.UIFigure);
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Copy IP plot images to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'PiC');
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Save IP plot images to file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'PiF');
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Copy all IP plot data to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'PdC', 'Separator', 'on');
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Save all IP plot data to new Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'PdFn');
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Save all IP plot data to existing Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'PdFo');
uimenu(app.IProfPanel.ContextMenu, 'Text', 'Open IP plots in new Figure window', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportFigure, ...
    'Tag', 'P', 'Separator', 'on');


app.HgtAxes.ContextMenu = uicontextmenu(app.UIFigure);
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Copy plot image to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'FiC');
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Save plot image to file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'FiF');
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Copy plot data to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdC', 'Separator', 'on');
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Save plot data to new Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdFn');
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Save plot data to existing Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdFo');
uimenu(app.HgtAxes.ContextMenu, 'Text', 'Open plot in new Figure window', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportFigure, ...
    'Tag', 'F', 'Separator', 'on');

app.PosAxes.ContextMenu = uicontextmenu(app.UIFigure);
uimenu(app.PosAxes.ContextMenu, 'Text', 'Copy plot image to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'FiC');
uimenu(app.PosAxes.ContextMenu, 'Text', 'Save plot image to file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportImage, ...
    'Tag', 'FiF');
uimenu(app.PosAxes.ContextMenu, 'Text', 'Copy plot data to clipboard', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdC', 'Separator', 'on');
uimenu(app.PosAxes.ContextMenu, 'Text', 'Save plot data to new Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdFn');
uimenu(app.PosAxes.ContextMenu, 'Text', 'Save plot data to existing Excel file...', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportData, ...
    'Tag', 'FdFo');
uimenu(app.PosAxes.ContextMenu, 'Text', 'Open plot in new Figure window', ...
    'Enable', 'on', 'MenuSelectedFcn', @app.ctx_ExportFigure, ...
    'Tag', 'F', 'Separator', 'on');

% Show the figure after all components are created
% app.UIFigure.Visible = 'on';
end