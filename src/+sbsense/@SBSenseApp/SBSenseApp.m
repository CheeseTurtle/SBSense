classdef SBSenseApp < matlab.apps.AppBase
    %% AppDesigner Properties
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        PlotContextMenu                 matlab.ui.container.ContextMenu
        LiveImageContextMenu            matlab.ui.container.ContextMenu
        DataImageContextMenu            matlab.ui.container.ContextMenu
        DI_ShowChannelsToggleMenu       matlab.ui.container.Menu
        DI_ShowMaskToggleMenu           matlab.ui.container.Menu
        DI_ShowMaskSelectionMenu        matlab.ui.container.Menu
        DI_ShowMask1ToggleMenu          matlab.ui.container.Menu
        DI_ShowMask2ToggleMenu          matlab.ui.container.Menu
        DI_ShowMask3ToggleMenu          matlab.ui.container.Menu
        DI_ShowPeakLineToggleMenu       matlab.ui.container.Menu
        DI_ShowDPNumPosMenu             matlab.ui.container.Menu
        DI_ShowDPNumLeftToggleMenu      matlab.ui.container.Menu
        DI_ShowDPNumRightToggleMenu     matlab.ui.container.Menu
        IP_ShowDebugPlotToggleMenu      matlab.ui.container.Menu;
        IP_ShowDebugPlotSelectionMenu   matlab.ui.container.Menu;
        IP_ShowDebugPlot1ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot2ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot3ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot4ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot5ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot6ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot7ToggleMenu     matlab.ui.container.Menu;
        IP_ShowDebugPlot8ToggleMenu     matlab.ui.container.Menu;
        FileMenu                        matlab.ui.container.Menu
        FileSaveSessionMenu             matlab.ui.container.Menu
        FileLoadSessionMenu             matlab.ui.container.Menu
        ImportReferenceImageMenu        matlab.ui.container.Menu
        ExportReferenceImageMenu        matlab.ui.container.Menu
        FileQuickExportMenu             matlab.ui.container.Menu
        ExportNotesMenu                 matlab.ui.container.Menu
        ExportConfigSummaryMenu         matlab.ui.container.Menu
        ExportPrimaryDataMenu           matlab.ui.container.Menu
        ExportChannelIPsMenu            matlab.ui.container.Menu
        ExportImagesMenu                matlab.ui.container.Menu
        ExportCompositesMenu            matlab.ui.container.Menu
        ExportYcsMenu                   matlab.ui.container.Menu
        ExportYrsMenu                   matlab.ui.container.Menu
        ExportWithMaskToggleMenu        matlab.ui.container.Menu
        ExportWithMaskSelectionMenu     matlab.ui.container.Menu
        ExportWithMask1ToggleMenu       matlab.ui.container.Menu
        ExportWithMask2ToggleMenu       matlab.ui.container.Menu
        ExportWithMask3ToggleMenu       matlab.ui.container.Menu
        ExportWithPeakLineToggleMenu    matlab.ui.container.Menu
        ExportWithDPNumToggleMenu       matlab.ui.container.Menu
        ExportWithDPNumPosMenu          matlab.ui.container.Menu
        ExportWithDPNumLeftToggleMenu   matlab.ui.container.Menu
        ExportWithDPNumRightToggleMenu  matlab.ui.container.Menu
        ImageViewMenu                   matlab.ui.container.Menu
        DisplayresolutionMenu           matlab.ui.container.Menu
        ColormapMenu                    matlab.ui.container.Menu
        MonochromeMenu                  matlab.ui.container.Menu
        grayMenu                        matlab.ui.container.Menu
        boneMenu                        matlab.ui.container.Menu
        pinkMenu                        matlab.ui.container.Menu
        copperMenu                      matlab.ui.container.Menu
        TwoPoleMenu                     matlab.ui.container.Menu
        parulaMenu                      matlab.ui.container.Menu
        springMenu                      matlab.ui.container.Menu
        summerMenu                      matlab.ui.container.Menu
        autumnMenu                      matlab.ui.container.Menu
        winterMenu                      matlab.ui.container.Menu
        coolMenu                        matlab.ui.container.Menu
        SpectrumMenu                    matlab.ui.container.Menu
        hotMenu                         matlab.ui.container.Menu
        jetMenu                         matlab.ui.container.Menu
        turboMenu                       matlab.ui.container.Menu
        hsvMenu                         matlab.ui.container.Menu
        FPPlotsMenu                     matlab.ui.container.Menu
        IPPlotsMenu                     matlab.ui.container.Menu
        MainGridLayout                  matlab.ui.container.GridLayout
        StatusbarGrid                   matlab.ui.container.GridLayout
        StatusDatapointIndexLabel       matlab.ui.control.Label
        StatusDatapointIndexLabelLabel  matlab.ui.control.Label
        UserActionLabel                 matlab.ui.control.Label
        UserActionLabelLabel            matlab.ui.control.Label
        StatusPgmStatusLabel            matlab.ui.control.Label
        StatusPgmStatusLabelLabel       matlab.ui.control.Label
        StatusResolutionLabel           matlab.ui.control.Label
        StatusResolutionLabelLabel      matlab.ui.control.Label
        StatusRefFileLabel              matlab.ui.control.Label
        StatusRefFileLabelLabel         matlab.ui.control.Label
        AlertArea                       matlab.ui.control.TextArea
        MainTabGroup                    matlab.ui.container.TabGroup
        Phase1Tab                       matlab.ui.container.Tab
        Phase1Grid                      matlab.ui.container.GridLayout
        Phase1LeftGrid                  matlab.ui.container.GridLayout
        VInputSetupPanel                matlab.ui.container.Panel
        VInputSetupGrid                 matlab.ui.container.GridLayout
        VInputDeviceDropdown            matlab.ui.control.DropDown
        VInputResolutionDropdown        matlab.ui.control.DropDown
        VInputResolutionDropdownLabel   matlab.ui.control.Label
        VInputDeviceDropdownLabel       matlab.ui.control.Label
        RefCapturePanel                 matlab.ui.container.Panel
        RefCaptureGrid                  matlab.ui.container.GridLayout
        RefCaptureNoteLabel             matlab.ui.control.Label
        RefCaptureSyncLamp              matlab.ui.control.Lamp
        RefCaptureSyncLabel             matlab.ui.control.Label
        RefExposureSpinner              matlab.ui.control.Spinner
        RefBrightnessSpinner            matlab.ui.control.Spinner
        RefGammaSpinner                 matlab.ui.control.Spinner
        RefExposureCheckbox             matlab.ui.control.CheckBox
        RefBrightnessCheckbox           matlab.ui.control.CheckBox
        RefGammaCheckbox                matlab.ui.control.CheckBox
        RefExposureLabel                matlab.ui.control.Label
        RefGammaLabel                   matlab.ui.control.Label
        RefBrightnessLabel              matlab.ui.control.Label
        SessionInfoPanel                matlab.ui.container.Panel
        SessionInfoGrid                 matlab.ui.container.GridLayout
        SessionCustomFieldsGrid         matlab.ui.container.GridLayout
        SessionCustomField4Label        matlab.ui.control.Label
        SessionCustomField1             matlab.ui.control.EditField
        SessionCustomField2             matlab.ui.control.EditField
        SessionCustomField3             matlab.ui.control.EditField
        SessionCustomField3Label        matlab.ui.control.Label
        SessionCustomField2Label        matlab.ui.control.Label
        SessionCustomField4             matlab.ui.control.EditField
        SessionCustomField1Label        matlab.ui.control.Label
        SessionCustomFieldsLabel        matlab.ui.control.Label
        SessionNotesTextarea            matlab.ui.control.TextArea
        SessionNotesLabel               matlab.ui.control.Label
        SessionInfoHeaderGrid           matlab.ui.container.GridLayout
        SessionTitleField               matlab.ui.control.EditField
        SessionTitleLabel               matlab.ui.control.Label
        SessionDatepicker               matlab.ui.control.DatePicker
        SessionDatepickerLabel          matlab.ui.control.Label
        Phase1CenterGrid                matlab.ui.container.GridLayout
        PreviewAxesGridPanel            matlab.ui.container.Panel
        PreviewAxesGrid                 matlab.ui.container.GridLayout
        PreviewAxes                     matlab.ui.control.UIAxes
        RefDisplayControlsGrid          matlab.ui.container.GridLayout
        BGPreviewSwitch                 matlab.ui.control.Switch
        BGPreviewSwitchLabel            matlab.ui.control.Label
        CaptureBGButtonLabel            matlab.ui.control.Label
        RefCaptureButtonGrid            matlab.ui.container.GridLayout
        CaptureBGButton                 matlab.ui.control.Button
        RefImportExportGrid             matlab.ui.container.GridLayout
        ImportBGButton                  matlab.ui.control.Button
        ExportBGButton                  matlab.ui.control.Button
        BGImportExportLabel             matlab.ui.control.Label
        BGStatsPanel                    matlab.ui.container.Panel
        BGStatsGrid                     matlab.ui.container.GridLayout
        BGMinValueLabel                 matlab.ui.control.Label
        BGMinValueField                 matlab.ui.control.NumericEditField
        BGMaxValueLabel                 matlab.ui.control.Label
        BGMaxValueField                 matlab.ui.control.NumericEditField
        BGMinCountLabel                 matlab.ui.control.Label
        BGMinCountField                 matlab.ui.control.NumericEditField
        BGMaxCountField                 matlab.ui.control.NumericEditField
        BGMaxCountLabel                 matlab.ui.control.Label
        Phase1RightGrid                 matlab.ui.container.GridLayout
        ChLayoutConfirmButtonGrid       matlab.ui.container.GridLayout
        ChLayoutConfirmButton           matlab.ui.control.Button
        CropRangePanel                  matlab.ui.container.Panel
        CropRangeGrid                   matlab.ui.container.GridLayout
        CropRangeMinMaxGrid             matlab.ui.container.GridLayout
        MaxYSpinner                     matlab.ui.control.Spinner
        MaxYSpinnerLabel                matlab.ui.control.Label
        MinYSpinner                     matlab.ui.control.Spinner
        MinYSpinnerLabel                matlab.ui.control.Label
        CropRangeHeightGrid             matlab.ui.container.GridLayout
        CroppedHeightField              matlab.ui.control.NumericEditField
        CroppedHeightLabel              matlab.ui.control.Label
        ChLayoutPanel                   matlab.ui.container.Panel
        ChLayoutGrid                    matlab.ui.container.GridLayout
        ChLayoutGrid1                   matlab.ui.container.GridLayout
        ChLayoutExportButton            matlab.ui.control.Button
        ChLayoutImportButton            matlab.ui.control.Button
        ChLayoutResetButton             matlab.ui.control.Button
        NumChSpinner                    matlab.ui.control.Spinner
        NumChSpinnerLabel               matlab.ui.control.Label
        ChLayoutSubpanel                matlab.ui.container.Panel
        ChLayoutGrid2                   matlab.ui.container.GridLayout
        ChHeightsLabel                  matlab.ui.control.Label
        ChHeightsGrid                   matlab.ui.container.GridLayout
        Ch6HeightField                  matlab.ui.control.NumericEditField
        Ch6HeightFieldLabel             matlab.ui.control.Label
        Ch5HeightField                  matlab.ui.control.NumericEditField
        Ch5HeightFieldLabel             matlab.ui.control.Label
        Ch4HeightField                  matlab.ui.control.NumericEditField
        Ch4HeightFieldLabel             matlab.ui.control.Label
        Ch3HeightField                  matlab.ui.control.NumericEditField
        Ch3HeightFieldLabel             matlab.ui.control.Label
        Ch2HeightField                  matlab.ui.control.NumericEditField
        Ch2HeightFieldLabel             matlab.ui.control.Label
        Ch1HeightField                  matlab.ui.control.NumericEditField
        Ch1HeightFieldLabel             matlab.ui.control.Label
        ChDivPositionsLabel             matlab.ui.control.Label
        ChDivPositionHeightsLabel       matlab.ui.control.Label
        ChDivPositionsGrid              matlab.ui.container.GridLayout
        ChDiv56Spinner                  matlab.ui.control.Spinner
        ChDiv56SpinnerLabel             matlab.ui.control.Label
        ChDiv45Spinner                  matlab.ui.control.Spinner
        ChDiv45SpinnerLabel             matlab.ui.control.Label
        ChDiv34Spinner                  matlab.ui.control.Spinner
        ChDiv34SpinnerLabel             matlab.ui.control.Label
        ChDiv23Spinner                  matlab.ui.control.Spinner
        ChDiv23SpinnerLabel             matlab.ui.control.Label
        ChDiv12Spinner                  matlab.ui.control.Spinner
        ChDiv12SpinnerLabel             matlab.ui.control.Label
        ChDiv12HeightSpinner            matlab.ui.control.Spinner
        ChDiv23HeightSpinner            matlab.ui.control.Spinner
        ChDiv34HeightSpinner            matlab.ui.control.Spinner
        ChDiv45HeightSpinner            matlab.ui.control.Spinner
        ChDiv56HeightSpinner            matlab.ui.control.Spinner
        Phase2Tab                       matlab.ui.container.Tab
        Phase2Grid                      matlab.ui.container.GridLayout
        Phase2RightGridPanel            matlab.ui.container.Panel
        Phase2RightGrid                 matlab.ui.container.GridLayout
        FPNavGrid                       matlab.ui.container.GridLayout
        LockRightButton                 matlab.ui.control.StateButton
        LockRangeButton                 matlab.ui.control.StateButton
        LockLeftButton                  matlab.ui.control.StateButton
        XNavSlider                      matlab.ui.control.Slider
        FPXMaxSecsField                 matlab.ui.control.NumericEditField
        FPXMaxColonLabel                matlab.ui.control.Label
        FPXMaxField                     matlab.ui.control.EditField
        FPXMinSecsField                 matlab.ui.control.NumericEditField
        FPXMinColonLabel                matlab.ui.control.Label
        FPXMinField                     matlab.ui.control.EditField
        XMaxLabel                       matlab.ui.control.Label
        XMinLabel                       matlab.ui.control.Label
        FPXUnitsLabel                   matlab.ui.control.Label
        XResKnob                        matlab.ui.control.Knob
        FPXModeDropdown                 matlab.ui.control.DropDown
        FPXModeDropdownLabel            matlab.ui.control.Label
        FPPlotsGrid                     matlab.ui.container.GridLayout
        FPAxesGridPanel                 matlab.ui.container.Panel
        FPAxesGrid                      matlab.ui.container.GridLayout
        HgtAxesPanel                    matlab.ui.container.Panel
        PosAxesPanel                    matlab.ui.container.Panel
        HgtAxes                         matlab.ui.control.UIAxes
        PosAxes                         matlab.ui.control.UIAxes
        % FPYSlidersGrid                  matlab.ui.container.GridLayout
        % FPHgtPanel                      matlab.ui.container.Panel
        % FPHgtGrid                       matlab.ui.container.GridLayout
        % FPHgtSubgrid                    matlab.ui.container.GridLayout
        % FPHgtLabel                      matlab.ui.control.Label
        % FPHgtAutoButton                 matlab.ui.control.StateButton
        % FPHgtSlider                     matlab.ui.control.Slider
        % FPPosPanel                      matlab.ui.container.Panel
        % FPPosGrid                       matlab.ui.container.GridLayout
        % FPPosSubgrid                    matlab.ui.container.GridLayout
        % FPPosLabel                      matlab.ui.control.Label
        % FPPosAutoButton                 matlab.ui.control.StateButton
        % FPPosSlider                     matlab.ui.control.Slider
        FPXAxisLabelsGridPanel          matlab.ui.container.Panel
        FPXAxisLabelsGrid               matlab.ui.container.GridLayout
        FPXAxisLeftLabel                matlab.ui.control.Label
        FPXAxisRightLabel               matlab.ui.control.Label
        FPXAxisCenterLabel              matlab.ui.control.Label
        Phase2CenterGrid                matlab.ui.container.GridLayout
        IProfPanel                      matlab.ui.container.Panel
        DataNavGrid                     matlab.ui.container.GridLayout
        DataImageDropdownLabel          matlab.ui.control.Label
        DataImageDropdown               matlab.ui.control.DropDown
        DatapointIndexLabel             matlab.ui.control.Label
        NumDatapointsField              matlab.ui.control.NumericEditField
        ofLabel                         matlab.ui.control.Label
        DatapointIndexField             matlab.ui.control.EditField
        RightArrowButton                matlab.ui.control.Button
        LeftArrowButton                 matlab.ui.control.Button
        AutoReanalysisToggleButton      matlab.ui.control.StateButton
        DataImageAxes                   matlab.ui.control.UIAxes
        Phase2LeftGrid                  matlab.ui.container.GridLayout
        IProcPanel                      matlab.ui.container.Panel
        IProcGrid                       matlab.ui.container.GridLayout
        SaveNotesButton                 matlab.ui.control.Button
        DataNotesTextarea               matlab.ui.control.TextArea
        DataNotesLabel                  matlab.ui.control.Label
        ReanalyzeButton                 matlab.ui.control.Button
        PSBRightSpinner                 matlab.ui.control.Spinner
        PSBLeftSpinner                  matlab.ui.control.Spinner
        PSBLabel                        matlab.ui.control.Label
        RecPanel                        matlab.ui.container.Panel
        RecGrid                         matlab.ui.container.GridLayout
        RecLabel                        matlab.ui.control.Label
        RecButton                       matlab.ui.control.StateButton
        RecStatusArea                   matlab.ui.control.TextArea
        RatePanel                       matlab.ui.container.Panel
        RateGrid                        matlab.ui.container.GridLayout
        SPPField                        matlab.ui.control.NumericEditField
        SPPLabel                        matlab.ui.control.Label
        FPPSpinner                      matlab.ui.control.Spinner
        FPPLabel                        matlab.ui.control.Label
        FPSField                        matlab.ui.control.NumericEditField
        FPSLabel                        matlab.ui.control.Label
        SPFField                        matlab.ui.control.EditField
        SPFLabel                        matlab.ui.control.Label
        Phase3Tab                       matlab.ui.container.Tab
        GridLayout4                     matlab.ui.container.GridLayout
        ExportTabGroup                  matlab.ui.container.TabGroup
        DataTab                         matlab.ui.container.Tab
        GridLayout25                    matlab.ui.container.GridLayout
        GridLayout28                    matlab.ui.container.GridLayout
        Panel_2                         matlab.ui.container.Panel
        GridLayout29                    matlab.ui.container.GridLayout
        ExportButton                    matlab.ui.control.Button
        ExportFormatDropDown            matlab.ui.control.DropDown
        ExportFormatDropDownLabel       matlab.ui.control.Label
        PreviewPanel                    matlab.ui.container.Panel
        GridLayout28_2                  matlab.ui.container.GridLayout
        UITable                         matlab.ui.control.Table
        ExportConfigurationPanel        matlab.ui.container.Panel
        GridLayout26                    matlab.ui.container.GridLayout
        ChannelsToIncludeinExportPanel  matlab.ui.container.Panel
        GridLayout27_3                  matlab.ui.container.GridLayout
        ListBox                         matlab.ui.control.ListBox
        FieldSelectionPanel_2           matlab.ui.container.Panel
        GridLayout27_2                  matlab.ui.container.GridLayout
        Tree                            matlab.ui.container.CheckBoxTree
        FullProfileDataNode             matlab.ui.container.TreeNode
        DatapointIndexNode              matlab.ui.container.TreeNode
        TimeNode                        matlab.ui.container.TreeNode
        EstimatedLaserIntensityELINode  matlab.ui.container.TreeNode
        FullProfilePeakEstimationNode   matlab.ui.container.TreeNode
        EstimatedPeakPositionfullprofileNode  matlab.ui.container.TreeNode
        EstimatedPeakHeightfullprofileNode  matlab.ui.container.TreeNode
        EstimatedcurvefitparametersfullprofileNode  matlab.ui.container.TreeNode
        ChannelDataNode                 matlab.ui.container.TreeNode
        IntensityProfileNode            matlab.ui.container.TreeNode
        PeakHeightLorABNode             matlab.ui.container.TreeNode
        PeakPositionLorx0Node           matlab.ui.container.TreeNode
        LorfitparameterANode            matlab.ui.container.TreeNode
        LorfitparameterBNode            matlab.ui.container.TreeNode
        OrganizationSchemePanel         matlab.ui.container.Panel
        GridLayout27                    matlab.ui.container.GridLayout
        GroupcolsbyDropDown             matlab.ui.control.DropDown
        GroupcolsbyDropDownLabel        matlab.ui.control.Label
        NaNRowsDropDown                 matlab.ui.control.DropDown
        NaNRowsDropDownLabel            matlab.ui.control.Label
        PresetSelectionButtonGroup      matlab.ui.container.ButtonGroup
        IntensityProfilesOnlyButton     matlab.ui.control.RadioButton
        ChannelSpecificDataOnlyButton   matlab.ui.control.RadioButton
        AllNonChannelSpecificDataButton  matlab.ui.control.RadioButton
        AllDataButton                   matlab.ui.control.RadioButton
        ImagesTab                       matlab.ui.container.Tab
        GridLayout25_2                  matlab.ui.container.GridLayout
        GridLayout28_3                  matlab.ui.container.GridLayout
        Panel_3                         matlab.ui.container.Panel
        GridLayout29_2                  matlab.ui.container.GridLayout
        PrefixwithsessionnameCheckBox   matlab.ui.control.CheckBox
        FilenameSuffixFormatDropDown    matlab.ui.control.DropDown
        FilenameSuffixFormatDropDownLabel  matlab.ui.control.Label
        FilenamePrefixEditField         matlab.ui.control.EditField
        FilenamePrefixEditFieldLabel    matlab.ui.control.Label
        ResolutionEditField             matlab.ui.control.NumericEditField
        ResolutionEditFieldLabel        matlab.ui.control.Label
        EXPORTButton_2                  matlab.ui.control.Button
        ExportFormatDropDown_2          matlab.ui.control.DropDown
        ExportFormatDropDown_2Label     matlab.ui.control.Label
        PreviewPanel_2                  matlab.ui.container.Panel
        GridLayout28_4                  matlab.ui.container.GridLayout
        ExportConfigurationPanel_2      matlab.ui.container.Panel
        GridLayout26_2                  matlab.ui.container.GridLayout
        DatapointIndexIndicesPanel      matlab.ui.container.Panel
        GridLayout30                    matlab.ui.container.GridLayout
        LastIndexSlider                 matlab.ui.control.Slider
        LastIndexSliderLabel            matlab.ui.control.Label
        FirstIndexSlider                matlab.ui.control.Slider
        FirstIndexSliderLabel           matlab.ui.control.Label
        ImageCategorytoExportButtonGroup  matlab.ui.container.ButtonGroup
        YcimageButton                   matlab.ui.control.RadioButton
        YrimageButton                   matlab.ui.control.RadioButton
        CompositeImageButton            matlab.ui.control.RadioButton
        ChannelIntensityProfilesButton  matlab.ui.control.RadioButton
        PeakHeightswithoutELIButton     matlab.ui.control.RadioButton
        PeakHeightswithELIButton        matlab.ui.control.RadioButton
        Button_2                        matlab.ui.control.RadioButton
        ChannelsToIncludeinExportPanel_2  matlab.ui.container.Panel
        GridLayout27_6                  matlab.ui.container.GridLayout
        ListBox_2                       matlab.ui.control.ListBox
        AnimationTab                    matlab.ui.container.Tab
        GridLayout25_3                  matlab.ui.container.GridLayout
        GridLayout28_5                  matlab.ui.container.GridLayout
        Panel_4                         matlab.ui.container.Panel
        GridLayout29_3                  matlab.ui.container.GridLayout
        EXPORTButton_3                  matlab.ui.control.Button
        ExportFormatDropDown_3          matlab.ui.control.DropDown
        ExportFormatDropDown_3Label     matlab.ui.control.Label
        PreviewPanel_3                  matlab.ui.container.Panel
        GridLayout28_6                  matlab.ui.container.GridLayout
        ExportConfigurationPanel_3      matlab.ui.container.Panel
        GridLayout26_3                  matlab.ui.container.GridLayout
        FieldSelectionPanel_3           matlab.ui.container.Panel
        GridLayout27_8                  matlab.ui.container.GridLayout
        Tree_2                          matlab.ui.container.CheckBoxTree
        CompositeimageNode              matlab.ui.container.TreeNode
        YcImageNode                     matlab.ui.container.TreeNode
        YrimageNode                     matlab.ui.container.TreeNode
        ChannelintensityprofilesNode    matlab.ui.container.TreeNode
        PeakHeightPlotNode              matlab.ui.container.TreeNode
        PeakLocPlotNode                 matlab.ui.container.TreeNode
        EstimatedLaserIntensityPlotNode  matlab.ui.container.TreeNode
        DatapointIndexIndicesPanel_2    matlab.ui.container.Panel
        GridLayout30_2                  matlab.ui.container.GridLayout
        LastIndexSlider_2               matlab.ui.control.Slider
        LastIndexSlider_2Label          matlab.ui.control.Label
        FirstIndexSlider_2              matlab.ui.control.Slider
        FirstIndexSlider_2Label         matlab.ui.control.Label
        ChannelsToIncludeinExportPanel_3  matlab.ui.container.Panel
        GridLayout27_7                  matlab.ui.container.GridLayout
        ListBox_3                       matlab.ui.control.ListBox
        CustomTab                       matlab.ui.container.Tab
    end
    % matlab.ui.eventdata.internal.AbstractEventData

    %% Properties: App State/Status Variables
    properties(GetAccess=public, SetAccess=private)
        numDatapoints;
        numAllocatedRows;
    end
    properties(GetAccess=public,SetAccess=private,SetObservable)
        LargestIndexReceived (1,1) uint64 = 0;
        LatestTimeReceived (1,1) duration = seconds(0);
        SelectedIndex (1,1) uint64 = 0;
        IPPanelActive = false;
        IPPlotSelection = uint8(1);
        SelectedIndexImages (:,3) cell = cell.empty(0, 3);
    end
    %% Properties: Constant Variables
    properties (Access=private, Constant)
        plotColors = {'r','b','g','c','m','k'};
        minFrameInterval=0.714; % TODO
        WindowTitleBase = "SBSense v000.0010";
        %XResTimeItems = {'1ms',    '',   '',   '',   '',  '50ms', ...
        %    '0.1s','','','0.5s','1s',
        %    };
        %XResTimeItemsData = [0.001 0.002 0.005 0.010 0.025 0.050 ...
        %    0.1 0.2 0.25 0.5 1.0 1.5 2.0 5.0 10 15 20 30 ...
        %    60 120 300 600 900];
        XResTimeMinorTicks = log2([0.001 0.002 0.005 0.010 0.025 0.050 ...
            0.1 0.2 0.25 0.5 1.0 1.5 2.0 5.0 10 15 20 30 ...
            60 120 300 600 900]);
        XResTimeMajorTicks = log2([0.001 0.050 0.1 0.5 1.0 5.0 10 30 60 ...
            120 300 600 900]);
        XResTimeMajorTickLabels = [ "1ms" "50ms" "0.1s" "0.5s" "1s" ...
            "5s" "10s" "30s" "1m" "2m" "5m" "10m" "15m"];
        XResTimeRange = log2([0.001 900]);
        XResFPHsMinorTicks = log2([ 1 2 5 10 15 20 25 50 100 200 250 400 500 800 1000]);
        XResFPHsMajorTicks = log2([ 1   5 10       25 50 100 200         500     1000]);
        XResFPHsMajorTickLabels = [ "1" "5" "10" "20" "25" "50" "100" "200" "500" "1000" ];
        XResFPHsRange = log2([1 1000]);

        MinChanHeightDenom = uint16(20);
        MinPSBWidth = uint16(4);
    end
    properties(GetAccess=private,SetAccess=private)
        MaxMaxNumChs;
    end
    %% Properties: Convenience Variables
    properties(Access=public)%private)
        fdf (1,2) double
        fdm (1,2) double

        ImageDataPlaceholderRows;
        ChannelDataPlaceholderRows;
        ChannelIPsPlaceholderRows;

        RefImageFilepath = char.empty();

        oldBGRes (1,2) uint16 = [0 0];
        PreviewFramerate (1,2) single = [1 15];
        AcquisitionFramerate (1,2) single = [1 2];
    end
    properties(Access=private, SetObservable)
        hasBG logical = false;
        ShiftDown = false;
        CtrlDown = false;
        % PreviewActive logical = false;
    end
    properties(Dependent, Access=public, SetObservable)%, AbortSet)
        hasCamera logical; %= false;
    end
    %% Properties: Object Variables
    properties(GetAccess=public, SetAccess=private, Transient, NonCopyable)
        vobj; %videoinput;
        vsrc;% videosource;
        vdev;% imaq.VideoDevice; % = imaq.VideoDevice.empty();

        Analyzer; % sbsense.Analyzer;
        AnalysisParams; % sbsense.AnalysisParameters;
        % acq sbsense.AcquisitionFacilitator; % TODO: Transfer stuff
        % lfit; %sbsense.LorentzFitter;
        VReader;

        PreviewTimer timer;
        PlotTimer timer;
        RFFTimer timer;
        RFFObject; % VideoReader object

        %HCqueue parallel.pool.DataQueue;
        %APqueue parallel.pool.DataQueue;
        ResQueue parallel.pool.DataQueue;
        PlotQueue parallel.pool.PollableDataQueue;
    end

    %% Properties: Data Storage Variables
    properties(GetAccess=public, SetAccess=public) % ???
        TimeZero (1,1) datetime = NaT;
        RefImage (:,:); % uint8;
        RefImageCropped (:,:); % uint8;
        RefImageScaled (:,:) ; % uint8;

        % TODO: Store in mat instead?
        Composites (1,:) cell;
        Yrs        (1,:) cell;
        Ycs        (1,:) cell;
        SampMask0s; % (:,:) cell;
        SampMasks; %  (:,:) cell;
        ROIMasks;  %  (:,:) cell;

        %ImageDataTable table;
        %PeakDataTimeTable timetable;
        DataTable (1,3) cell = {table.empty(), timetable.empty(), timetable.empty()};
        ResTable table; % resolution unit information
        ChunkTable timetable;
        BinFileCollection = logical.empty(); % (1,1); % sbsense.BinFileCollection;

        CurrentChunkInfo;

        ChannelIPs (:,:,:) single; % was double
        ChannelFPs (:,:,:) single; % was double
        ChannelHeights (:,1) uint16;
        ChannelDivHeights (:,1) uint16;

        ChannelFBs (:,2,:) uint16;
        ChannelWgts (:,:) cell;
        ChannelWPs (:,:,:) cell;
        ChannelXData(:,:) cell;
        % ChannelDivPositions (1,:) uint16;
        % PeakSearchBounds (:,2) uint16; % TODO: Remove

        % XResUnit (1,1) double;
        XResUnitVals (3,2) cell = { double.empty() uint64.empty() ; ...
            double.empty() datetime.empty() ; ...
            double.empty() duration.empty() };
        XResValue  (1,1) double;
        XResMajorInfo (1,5) cell;


        % tab = table([0.1 0.5]', [1 5]', [1 1]', ['abc' ; 'def'], ["ghi" ; "jkl"])
        % tab{2,[2 3]}
        % tab{2,[2 4]}
        % tab{2,[2 5]}
        % tab{2,[2 3 5]}
        % tab{2,[2 3 4]}
    end
    %% Properties: Misc Parameter Variables
    properties (GetAccess=public, SetAccess=private)
        MemoryIdx0 uint64 = 1;
        MemoryLen uint64 = 0;

        AnalysisScale (1,1) single = 1;

        lockXMin logical = false;
        lockXMax logical = false;
        lockXRng logical = false;
        autoXRng logical = true;

        % ChannelYBounds (1,:) uint16;
        ChBoundsPositions (:,2) uint16;

        RootDirectory;
        SessionName;
        SessionDirectory;

        ImageStore;
        ProfileStore;
        % ChannelOverlayImage = [];
        % MaskOverlayImage = [];
    end
    %% Properties: Set-Observable Variables
    %properties(Access=protected, SetObservable)
    % end

    %% Properties: Set-Observable, Abort-Set Variables
    properties(GetAccess=public, SetAccess=private, SetObservable, AbortSet)
        NumChannels uint16 = 1;
        EffHeight uint16;

        LockLeftValue = false;
        LockRightValue = false;
        LockRangeValue = false;
    end
    properties(GetAccess=public, SetAccess=private)
        PSBIndices (1,2) uint16; % NOTE: Should usually set with PSBIndexes (observed) instead of PSBIndices!
    end

    properties(Dependent, GetAccess=private, SetAccess=private,SetObservable=true)
        PSBIndexes (1,2) uint16;
    end

    properties(GetAccess=protected, SetAccess=private, SetObservable)
        NominalChannelHeight uint16;
    end
    %     properties(Access=private, Hidden)
    %         topCB;
    %         botCB = 0;
    %     end
    properties(Dependent,SetAccess=private,GetAccess=public,SetObservable=true)
        CropBounds (1,2) uint16;
        TopCropBound (1,1) uint16;
        BotCropBound (1,1) uint16;

        PSBLeftIndex (1,1) uint16;
        PSBRightIndex (1,1) uint16;
    end
    properties(Dependent,SetAccess=private,GetAccess=public)
        ChDivPositions (:,2) uint16;
    end
    properties(Dependent,SetAccess=private,GetAccess=private)
        AxisLimitsCallbackEnabled;
    end

    properties(GetAccess=public,SetAccess=public)
        ReadFromFile (1,1) logical = true;
    end

    %% Properties: Transient Variables
    properties(GetAccess=public, SetAccess=private, Transient)
        PageLimitsVals (3,2) cell = { double.empty(0,2) uint64.empty(0,2) ; ...
            double.empty(0,2) datetime.empty(0,2) ; ...
            double.empty(0,2) duration.empty(0,2) };
        PageSize;
        %PageSizeVals (3,2) cell = { double.empty() uint64.empty() ; ...
        %    double.empty() datetime.empty() ; ...
        %    double.empty() duration.empty() };

        AxisLimitsCallbackCalculatesTicks (1,1) logical = true;
        AxisLimitsCallbackCalculatesPage (1,1) logical = false;
    end

    properties(GetAccess=public, SetAccess=private, Dependent)
        XResUnit;% (1,1);
        InputFormat; % = '';
    end
    properties(GetAccess=public, SetAccess=private, Dependent, SetObservable) % and transient?
        PageLimits;% (1,2);
        % PageSize;% (1,1);
    end

    properties(GetAccess=public,SetAccess=private,Transient)
        % pdlg;
        wbar = matlab.graphics.GraphicsPlaceholder.empty();
    end

    %% Properties: Transient, Non-Copyable Variables
    properties(SetAccess=private, GetAccess=public, Transient, NonCopyable)
        CropLines;
        CropSpins;
        ChanDivSpins;
        ChanDivLines;
        ChanDivHeightSpins;
        ChanHgtFields;
        ChanCtlGroups;
        MinChanHeight;
        MinCropHeight;
        MaxNumChannels;
        MinMinChanHeight;

        FPXFields;
        PSBSpins;
        PSBLines;
    end
    %% Properties: Dependent Variables
    properties(Access=protected,Dependent,Transient,NonCopyable)
        VideoResolution (1,2);
    end
    properties(Dependent, GetAccess=public, SetAccess=private, AbortSet=true, SetObservable=true)
        %LeftCropBound uint16;
        %RightCropBound uint16;
        EffTopY (1,1) uint16;
        EffBotY (1,1) uint16;
    end
    properties(Dependent, GetAccess=public, SetAccess=private)
        ReferenceImage;
    end
    properties(GetAccess=public,SetAccess=private)
        IsRecording (1,1) logical = false;
    end
    properties(GetAccess=public,SetAccess=public,Transient)
        DbgEchoOn = false;
    end
    properties(GetAccess=public,SetAccess=private,SetObservable=true)
        ConfirmStatus (1,1) logical = false;
        XAxisModeIndex (1,1) uint8 = 1;
    end
    properties(GetAccess=public,SetAccess=private,SetObservable=true,AbortSet=true)
        XNavZoomMode (1,1) logical = false;
        PreviewActive (1,1) logical = false;
    end
    properties(GetAccess=public,SetAccess=public,SetObservable=true)
        IPDebugPlotSelection uint8 = 0;
    end
    %% Properties: Graphics Object Handles
    properties(GetAccess=public, SetAccess=private)
        tl matlab.graphics.layout.TiledChartLayout;

        highRect (1,1) images.roi.Rectangle;
        shadRects (1,2) images.roi.Rectangle;

        leftPSBLine (1,1) images.roi.Line;
        rightPSBLine (1,1) images.roi.Line;
        topCropLine (1,1) images.roi.Line;
        botCropLine (1,1) images.roi.Line;

        channelDivLines (1,7) images.roi.Polygon;

        channelDataIndicators images.roi.Circle; %(2,8) images.roi.Circle;  %matlab.graphics.shape.Ellipse;
        peakPosIndicator matlab.graphics.chart.decoration.ConstantLine; %matlab.graphics.primitive.Line;

        eliPlotLine matlab.graphics.primitive.Line;

        FPSelPatches;
        FPPagePatches;

        channelPeakPosLines (:,:) matlab.graphics.primitive.Line;
        channelPeakHgtLines (:,:) matlab.graphics.primitive.Line;

        IPdataLines matlab.graphics.primitive.Line;
        IPfitLines matlab.graphics.chart.primitive.Area;
        IPpatches matlab.graphics.primitive.Patch; % matlab.graphics.primitive.Polygon;
        IPzoneRects; % images.roi.Rectangle;
        IPpeakLines matlab.graphics.chart.decoration.ConstantLine;

        liveimg matlab.graphics.primitive.Image;
        dataimg matlab.graphics.primitive.Image;
        overimg matlab.graphics.primitive.Image;
        maskimg matlab.graphics.primitive.Image;

        NRulers (1,2) matlab.graphics.axis.decorator.NumericRuler;
        TRulers (1,2) matlab.graphics.axis.decorator.DatetimeRuler;
        DRulers (1,2) matlab.graphics.axis.decorator.DurationRuler;

        FPRulers (3,2) cell; %matlab.graphics.axis.decorator.ScalableAxisRuler;
    end
    %% Properties: Listeners and Links
    properties(Access=public, Transient, NonCopyable)
        propListeners (1,:) event.proplistener;

        rectListener event.listener = event.listener.empty();
        leftLineListener event.listener = event.listener.empty();
        rightLineListener event.listener = event.listener.empty();
        topLineListener event.listener = event.listener.empty();
        botLineListener event.listener = event.listener.empty();

        roiClickListener event.listener = event.listener.empty();
        divLineListeners (:,7) event.listener = event.listener.empty(0,7);
        divLineListeners2 (:,7) event.listener = event.listener.empty(0,7);
        divLineListeners3 (:,7) event.listener = event.listener.empty(0,7);

        chHeightFut;
    end

    properties(GetAccess=public,SetAccess=private,Transient,NonCopyable)
        propLinks (1,:) matlab.graphics.internal.LinkProp;
        RulerLinks (1,:) matlab.graphics.internal.LinkProp;
        FPAxisLink (1,:) matlab.graphics.internal.LinkProp;

        ZoomFutures = parallel.Future.empty();
        PanFutures = parallel.Future.empty();
    end

    %% Methods: Initialization Functions
    methods (Access = private)
        initialize(app,reinit,camenable);
        function initializeFromSavefile(app) %#ok<MANU>
        end

        TF = populateVInputDeviceDropdown(app,currDeviceName,doreset);
        populateVFormatsDropdown(app, currDeviceName);
        setSourceDefaultSettings(app, includeConfigurable);
        applyVideoSourceSettings(app,allprops);
    end

    methods(Access=public)
        changeFrameRate(app, newSPF);

        function updateDiscoTable(app)
            updateDiscontinuityTable(app);
        end
    end


    methods(Access=public,Static)
        onAcquisitionTrigger(vobj, event);
    end

    %% Methods: Static Utility Functions
    methods(Access=private,Static)
        [vobj, vsrc,TF] = newVideoInput(vformat, vobj, vsrc, varargin);

        showhier(handles,show,varargin);
        enablehier(handles,enable,varargin);

        onLegendClick(hSrc, ev);

        % (NOT YET FULLY IMPLEMENTED)
        %sethier(handles,lvl,varargin);%, prop, val);

        [devnames, devinfos] = getAvailableInputDevices();


    end
    %% Methods: Post-Set Functions
    methods(Access=protected)
        varargout = recalcChannelHeightInfo(app,setEH);

        postset_hasX(app, src, ~);
        postset_PreviewActive(app, ~, ~);
        postset_CropBound(app, src, ~); % TODO: Not used?!

        postset_NumChannels(app,~,~);
        postset_EffSize(app, varargin);
        postset_ConfirmStatus(app,src,event);
        pxset_XNavZoomMode(app,src,event);

        toggleFPLegends(app);
    end


    methods(Access=private,Static)

        % [img1,img2,TF] = generateChannelOverlayImages(co, params);
        % function readNextFrame(tobj, event, HCqueue, resQueue)
        function readNextFrame(varargin) % tobj, ~, HCqueue)
            persistent datapointIndex frames frameCount;
            if nargin < 3
                datapointIndex = 0;
                frames = {}; frameCount = 0;
                return;
            end

            [tobj,event,HCqueue,resQueue,fph] = varargin{:};
            if ~(isa(tobj, 'timer') && isvalid(tobj) && (tobj.Running(2)=='n'))
                fprintf('[readNextFrame] RFFTimer is no longer a running valid timer.\n');
                display(tobj);
                if isa(tobj, 'timer')
                    stop(tobj);
                end
                return;
            end


            if isempty(datapointIndex)
                datapointIndex = 0;
                frameCount = 0;
                frames = cell(1,fph);
                dt = datetime(event.Data.time);
                fprintf('[readNextFrame] DATAPOINT INDEX IS 0. datetime: %s\n', ...
                    string(dt, 'HH:mm:ss.SSSSSSSSS'));
                send(resQueue, dt);
                return;
            end

            if ~hasFrame(tobj.UserData) % && tobj.TasksExecuted <= 21
                fprintf('On tick no. %d, there were no frames left.\n', ...
                    tobj.TasksExecuted);
                if isempty(tobj.UserData.UserData)
                    tobj.UserData.CurrentTime = 0;
                else
                    tobj.UserData.CurrentTime = tobj.UserData.UserData;
                end
            end
            % fprintf('Reading frame no. %d\n', tobj.TasksExecuted);
            if ~frameCount
                frames = {readFrame(tobj.UserData)};
                frameCount = 1;
            else
                frameCount = frameCount + 1;
                frames{frameCount} = readFrame(tobj.UserData);
            end
            if frameCount >= fph
                frameCount = 0;
                dt = datetime(event.Data.time);
                fprintf('[readNextFrame] DATAPOINT INDEX IS %d. datetime: %s\n', ...
                    datapointIndex, string(dt, 'HH:mm:ss.SSSSSSSSS'));
                send(HCqueue, { datapointIndex, [dt dt], ...
                    frames});
                datapointIndex = datapointIndex + 1;
            end

            % HC = im2double(HC);
            % fprintf('HC class, min, max: %s, %0.4g, %0.4g\n', ...
            % class(HC), min(HC,[],"all","omitnan"), max(HC,[],"all", "omitnan"));
            % HCdata: {datapointIndex, HCtimeRange, frames}
            %if (tobj.TasksExecuted < 2)
            %    send(resQueue, datetime(event.Data.time));
            %else
            % if ~datapointIndex
            %     datapointIndex = datapointIndex + 1;
            %     fprintf('[readNextFrame] DATAPOINT INDEX IS 1. datetime: %s\n', ...
            %         datetime(string(event.Data.time, 'HH:mm:ss.SSSSSSSSS')));
            % elseif ~isempty(prevHC)
            %     datapointIndex = datapointIndex + 1;
            %     % dt = datetime('now'); % datetime(event.Data.time);
            %     % dt = datetime(event.Data.time);
            %     send(HCqueue,...
            %         {datapointIndex, [dt dt], cat(3, prevHC, HC)});
            % end
            % prevHC = HC;
        end

        function stopReadingFrames(~,~,~) % tobj, event, HCqueue)
        end
    end
    %% Methods: Event Callback Functions
    methods(Access=private)
        % To be called whenever camera connection is established or changed
        %         function onCameraConnection(app, hadConnection)
        %             arguments(Input)
        %                 app sbsense.SBSenseApp;
        %                 hadConnection logical;
        %             end
        %         end

        function TF = startReadingFromFile(app,fileName)
            try
                if isa(app.VReader, 'VideoReader') && ...
                        strcmp(mmfileinfo(fileName).Path, app.VReader.Path) ...
                        && strcmp(fileName, app.VReader.Name)
                    fprintf('Continuing to read from file "%s".\n', ...
                        fullfile(app.VReader.Path, app.VReader.Name));
                    app.RFFTimer.UserData = app.VReader;
                else
                    app.VReader = VideoReader(fileName);
                    app.VReader.UserData = app.VReader.CurrentTime;
                    fprintf('Beginning to read from file "%s".\n', ...
                        fullfile(app.VReader.Path, app.VReader.Name));
                    app.RFFTimer.UserData = app.VReader;
                end
            catch ME
                fprintf('Cannot access file "%s" due to error "%s": %s\n', ...
                    fileName, ME.identifier, getReport(ME));
                TF = false;
                return;
            end
            if ~app.VReader.NumFrames
                fprintf('Cannot read from file "%s" because it contains no frames.\n', ...
                    fileName);
                TF = false;
                return;
            end
            % send(app.ResQueue, datetime('now'));
            start(app.RFFTimer);
            TF = true;
        end

        % To be called just before recording begins.
        function onRecordStart(app) %#ok<MANU>

        end

        % To be called just after recording ends.
        function onRecordStop(app) %#ok<MANU>

        end

        function onDatapointClick(app) %#ok<MANU>
            % TODO: Args?
        end
    end
    %% Methods: Misc Interaction Functions
    methods(Access=private)
        function activateDatapoint(app) %#ok<MANU>
            % TODO: Args
        end
    end
    %% Methods: Image Display-Related Functions
    methods(Access=protected)
        restorePreviewOrder(app, divlines);
    end

    methods(Access=protected)
        function setHasCamera(app, value)
            app.hasCamera = value;
        end
    end
    %% Methods: Plot-Related Functions
    methods(Access=private)
        modifyPreviewSwitchTrueability(app,TF);
    end
    %% Methods: Get/Set Methods
    methods
        %% Property Set Functions
        function set.SelectedIndex(app, value)
            if value < 0
                app.SelectedIndex = 0;
            else
                app.SelectedIndex = value;
            end
        end

        function set.VideoResolution(app, vr)
            app.PreviewAxes.XLim = [ 1 vr(1) ];
            app.PreviewAxes.YLim = [ 1 vr(2) ];
            app.fdm = fliplr(vr); %[min(vr) max(vr)];
            app.fdf = vr;
            app.liveimg.XData = app.PreviewAxes.XLim; %[1 app.fdm(2)];
            app.liveimg.YData = app.PreviewAxes.YLim; %[1 app.fdm(1)];
        end

        % TODO: Eliminate redundancy?
        function set.ReferenceImage(app, newBG)
            % setBG(app, value);
            if (class(newBG)=="double") || (class(newBG)=="single")
                newBG(newBG==0) = realmin(class(newBG));
            else
                newBG(newBG==0) = 1;
            end
            app.RefImage = newBG;
            app.liveimg.UserData = newBG;
            hadBG = app.hasBG;
            clearBG = isempty(newBG);
            if clearBG
                % newBGres = size(newBG);%size(app.RefImage); % TODO: Input format
                app.BGPreviewSwitch.Enable = false;
                if app.hasCamera
                    if ~app.BGPreviewSwitch.Value
                        app.BGPreviewSwitch.Value = true;
                        BGPreviewSwitchValueChanged(app, app.BGPreviewSwitch, ...
                            struct('Value', true, 'PreviousValue', false));
                    end
                    app.hasBG = false;
                    app.ExportBGButton.Enable = false;
                    set([app.topCropLine app.botCropLine, app.shadRects], 'Visible', false);
                    set([app.MinYSpinner, app.MaxYSpinner], 'Enable', false);
                end
            else
                newBGres = size(newBG);%size(app.RefImage);
                if hadBG
                    hadBG = isequal(newBGres, app.oldBGRes);
                else
                    fprintf("Previously not have BG image. --> " ...
                        + "Enabling stats,crop,channel layout/confirm after setup.\n");
                    if isa(app.vobj, 'videoinput') && isvalid(app.vobj) %isa(app.vdev, 'imaq.VideoDevice') && isvalid(app.vdev)
                        fprintf('vobj is valid --> Enabling preview switch.\n');
                        app.BGPreviewSwitch.Enable = true;
                    else
                        fprintf('vobj is invalid --> Disabling preview switch and displaying the new BG image after additional setup.\n');
                        app.BGPreviewSwitch.Value = false;
                        % app.liveimg.CData = newBG;
                    end
                end

                if ~hadBG
                    fprintf("Previously did not have BG of this size. " ...
                        + "--> Updating control/display ranges and " ...
                        + "enabling and unhiding capture-related ROIs " ...
                        + "and preview-related grids/panels/axes.\n");

                    if app.NumChannels < 1
                        app.NumChannels = 1;
                        app.NumChSpinner.Value = 1;
                        % TODO: Why would this happen??
                    end

                    app.propListeners(1).Enabled = false;
                    app.EffHeight = newBGres(1);
                    app.propListeners(1).Enabled = true;
                    app.MinMinChanHeight = idivide(uint16(newBGres(1)), ...
                        app.MinChanHeightDenom, "ceil");
                    app.MinChanHeight = app.MinMinChanHeight;
                    app.MinCropHeight = ...
                        app.NumChannels*(app.MinMinChanHeight+1) - 1;
                    app.MaxNumChannels = max(min(app.MaxMaxNumChs, ...
                        floor((newBGres(1)+1)/(app.MinMinChanHeight + 1))),...
                        1);

                    set(app.CroppedHeightField, 'Value', ...
                        double(app.MaxYSpinner.Value - app.MinYSpinner.Value - 1));
                    buf = 1+double(app.MinCropHeight);
                    % if clearBG
                    %    set([app.topCropLine app.botCropLine], 'Visible', false);
                    %    set([app.MinYSpinner, app.MaxYSpinner], 'Enable', false);
                    %else
                    set(app.topCropLine, 'DrawingArea', ...
                        [0 buf (fliplr(newBGres)+[1 2-buf])], 'Position', ...
                        [0 (newBGres(1)+1) ; (fliplr(newBGres)+1)], ...
                        'Visible', false);%, 'Selected', false);
                    set(app.botCropLine, 'DrawingArea', ...
                        [0 0 fliplr(newBGres)] + [0 0 1 2-buf], ...
                        'Position', [0 0 ; newBGres(2)+1 0], ...
                        'Visible', false);%, 'Selected', false);
                    app.MinYSpinner.Limits = [ 0, max(1,newBGres(1)+1-buf)];
                    app.MinYSpinner.Value = 0;
                    app.MaxYSpinner.Limits = [ buf, max(2,newBGres(1)+1)];
                    app.MaxYSpinner.Value = newBGres(1)+1;
                    set([app.MinYSpinner, app.MaxYSpinner], 'Enable', true);

                    for divline = app.ChanDivLines
                        if isempty(divline.Position)
                            continue;
                        end
                        divline.Position(:,1) = ...
                            double([1 ; newBGres(2) ; newBGres(2) ; 1]);
                        divline.DrawingArea([1 3]) = ...
                            double([1 newBGres(2)]);
                    end
                    % end

                    fprintf('MinCropHeight: %0.4g, MMCH: %0.4g\n', ...
                        app.MinCropHeight, app.MinMinChanHeight);
                    fprintf('topCropLine position: %0.4g %0.4g ; %0.4g %0.4g\n', ...
                        app.topCropLine.Position(1,1), app.topCropLine.Position(1,2), ...
                        app.topCropLine.Position(2,1), app.topCropLine.Position(2,2));
                    fprintf('topCropLine DrawingArea: %0.4g %0.4g %0.4g %0.4g\n', ...
                        app.topCropLine.DrawingArea(1), app.topCropLine.DrawingArea(2), ...
                        app.topCropLine.DrawingArea(3), app.topCropLine.DrawingArea(4));
                    fprintf('topCropLine DrawingArea vert. "limits": %0.4g %0.4g\n', ...
                        app.topCropLine.DrawingArea(2), ...
                        app.topCropLine.DrawingArea(2) + app.topCropLine.DrawingArea(4) - 1);
                    fprintf('MaxYSpinner Limits: %0.4g %0.4g\n', ...
                        app.MaxYSpinner.Limits(1), app.MaxYSpinner.Limits(2));
                    fprintf('botCropLine position: %0.4g %0.4g %0.4g %0.4g\n', ...
                        app.botCropLine.Position(1,1), app.botCropLine.Position(1,2), ...
                        app.botCropLine.Position(2,1), app.botCropLine.Position(2,2));
                    fprintf('botCropLine DrawingArea: %0.4g %0.4g %0.4g %0.4g\n', ...
                        app.botCropLine.DrawingArea(1), app.botCropLine.DrawingArea(2), ...
                        app.botCropLine.DrawingArea(3), app.botCropLine.DrawingArea(4));
                    fprintf('botCropLine DrawingArea vert. "limits": %0.4g %0.4g\n', ...
                        app.botCropLine.DrawingArea(2), ...
                        app.botCropLine.DrawingArea(2) + app.botCropLine.DrawingArea(4) - 1);
                    fprintf('MinYSpinner Limits: %0.4g %0.4g\n', ...
                        app.MinYSpinner.Limits(1), app.MinYSpinner.Limits(2));

                    assert(isequal([app.topCropLine.DrawingArea(2), ...
                        app.topCropLine.DrawingArea(2) + app.topCropLine.DrawingArea(4) - 1], ...
                        app.MaxYSpinner.Limits));
                    assert(isequal([app.botCropLine.DrawingArea(2), ...
                        app.botCropLine.DrawingArea(2) + app.botCropLine.DrawingArea(4) - 1], ...
                        app.MinYSpinner.Limits));

                    set(app.shadRects(1), "Position", double([1 1 newBGres(2) 0]), ...
                        "Tag", "shadrect_top", "Color", [0 0 0], ...
                        "Visible", false);%"green");
                    set(app.shadRects(2), "Position", double([1 newBGres(1) newBGres(2) 0]), ...
                        "Tag", "shadrect_bot", "Color", [0 0 0], ...
                        "Visible", false); %"magenta");

                    set(app.PSBLeftSpinner, 'Limits', ...
                        [0 max(1,newBGres(2))], 'Value', 0);
                    set(app.PSBRightSpinner, 'Limits', ...
                        [1, max(2,newBGres(2)+1)], 'Value', newBGres(2)+1);


                    %setCropBounds(app, 0, newBGres(1)+1);

                    if (app.NumChannels<2)
                        app.ChBoundsPositions = repmat([0 ; newBGres(1)+1], 1, 2);
                    elseif size(app.ChBoundsPositions,1) <= 2
                        app.ChBoundsPositions = vertcat([0 0], ...
                            zeros(app.NumChannels-1,2), ...
                            repelem(newBGres+1,1,2));
                    else
                        app.ChBoundsPositions([1 end],:) = repmat([0 ; (newBGres(1)+1)], 1, 2);
                        assert(size(app.ChBoundsPositions,1)==(app.NumChannels+1));
                        % app.CropBounds = [0, newBGres(1)+1];
                    end

                    % TODO: Calc stats in parfeval Future
                    try
                        mm = minmax(newBG);
                        mm = minmax(mm(:)');
                        mincount = sum(newBG==mm(1), "all");
                        maxcount = sum(newBG==mm(2), "all");
                        disp({mm , mincount, maxcount});
                        app.BGMinValueField.Value = double(mm(1));
                        app.BGMaxValueField.Value = double(mm(2));
                        app.BGMinCountField.Value = double(mincount);
                        app.BGMaxCountField.Value = double(maxcount);
                    catch ME
                        fprintf('%s\n', getReport(ME));
                        [app.BGMinValueField.Value, ...
                            app.BGMaxValueField.Value, ...
                            app.BGMinCountField.Value, ...
                            app.BGMaxCountField.Value] = ...
                            deal(double(0));
                    end

                    app.liveimg.XData = [1 newBGres(2)];
                    app.liveimg.YData = [1 newBGres(1)];
                    app.PreviewAxes.XLim = app.liveimg.XData;
                    app.PreviewAxes.YLim = app.liveimg.YData;

                    set(app.liveimg, 'Visible', true);
                    set(app.ChanDivLines, 'Visible', true);
                    % restorePreviewOrder(app);
                    % drawnow limitrate;

                    sbsense.SBSenseApp.enablehier( ...
                        [app.BGStatsPanel, app.CropRangePanel]);
                    set([app.ChLayoutConfirmButton, ...
                        app.ChLayoutSubpanel, app.ChLayoutImportButton, ...
                        app.NumChSpinner, app.Ch1HeightField, ...
                        app.Ch1HeightFieldLabel], 'Enable', true);

                    %set(app.PreviewAxesGridPanel, 'Enable', true);
                    %set([app.PreviewAxes, app.PreviewAxesGrid, ...
                    %    app.PreviewAxesGridPanel], 'Visible', true);
                    app.oldBGRes = newBGres;
                    app.VideoResolution = fliplr(newBGres);
                    % recalcChannelHeightInfo(app);
                    % app.hasBG = true;
                    app.hasBG = true;
                end
                if ~app.PreviewActive
                    set(app.liveimg, 'CData', newBG, ...
                        'AlphaData', 255);
                    restorePreviewOrder(app);
                    set(app.CropLines, 'Visible', true, 'Selected', true);
                    % drawnow limitrate;
                end

            end
            % if hadBG == clearBG
            %     app.hasBG = ~clearBG;
            % end

            app.ConfirmStatus = false;

            fillData(app); % TODO: remove
        end
        %% Property Get Functions

        function value = get.PSBRightIndex(app)
            value = app.PSBIndices(2);
        end
        function value = get.PSBLeftIndex(app)
            value = app.PSBIndices(1);
        end

        function set.PSBRightIndex(app, value)
            if value
                app.PSBIndices(2) = value;
            else
                app.PSBIndices(2) = app.fdm(2);
            end
        end
        function set.PSBLeftIndex(app, value)
            app.PSBIndices(1) = max(1,value);
        end

        function set.PSBIndexes(app, value)
            if ~value(1)
                value(1) = 1;
            end
            if ~value(2)
                value(2) = app.fdm(2);
            end
            app.PSBIndices = value;
        end
        % function value = get.PSBIndexes(app)
        %     value = app.PSBIndices;
        % end

        %% Crop Bounds Set/Get Functions

        function set.TopCropBound(app, value)
            assert(size(app.ChBoundsPositions,1)==(app.NumChannels+1));
            app.ChBoundsPositions(end,:) = value;
        end
        function value = get.TopCropBound(app)
            value = app.ChBoundsPositions(end,1);
        end

        function set.BotCropBound(app, value)
            assert(size(app.ChBoundsPositions,1)==(app.NumChannels+1));
            app.ChBoundsPositions(1,:) = value;
        end
        function value = get.BotCropBound(app)
            value = app.ChBoundsPositions(1,1);
        end

        function set.CropBounds(app, value)
            assertz(length(value)==2);
            if size(app.ChBoundsPositions,1) <= 2
                app.ChBoundsPositions = repmat([value(1) ; value(2)], 1, 2);
            else
                app.ChBoundsPositions([1 end],:) = value;
            end
        end
        function value = get.CropBounds(app)
            assert(size(app.ChBoundsPositions,1)==(app.NumChannels+1));
            if size(app.ChBoundsPositions,1) <= 2
                value = app.ChBoundsPositions(:, 1);
            else
                value = app.ChBoundsPositions([1 end],1);
            end
        end

        function set.ChDivPositions(app, value)
            try
                assert(size(value,1)==(app.NumChannels-1));
                assert(size(value,2)==2);
            catch ME
                display(value);
                display(app.NumChannels);
                rethrow(ME);
            end
            if size(app.ChBoundsPositions,1)==(app.NumChannels+1)
                app.ChBoundsPositions(2:app.NumChannels,:) = value;
            else
                assert(size(app.ChBoundsPositions,1) >= 2);
                assert(size(app.ChBoundsPositions,2) == 2);
                app.ChBoundsPositions = ...
                    vertcat(app.ChBoundsPositions(1,:), ...
                    value, ...
                    app.ChBoundsPositions(end,:) ...
                    );
            end
        end

        function value = get.hasCamera(app)
            if isempty(app.vobj) || ~isscalar(app.vobj) ...
                    || ~isa(app.vobj, 'videoinput') ...
                    || ~isvalid(app.vobj)
                value = false;
            else
                value = true;
            end
            app.ReadFromFile = ~value;
        end

        function set.hasCamera(app, value)
            app.ReadFromFile = ~value;
        end


        function value = get.ChDivPositions(app)
            if size(app.ChBoundsPositions,1) <= 2
                value = uint16.empty(0,2);
            else
                value = app.ChBoundsPositions(2:end-1,:);
            end
        end

        function value = get.EffTopY(app)
            value = app.topCropLine.Position(1,2) - 1;
        end

        function value = get.EffBotY(app)
            value = app.botCropLine.Position(2) + 1;
        end

        function value = get.AxisLimitsCallbackEnabled(app)
            value = app.AxisLimitsCallbackCalculatesTicks ...
                || app.AxisLimitsCallbackCalculatesPage;
        end

        function set.AxisLimitsCallbackEnabled(app, value)
            app.AxisLimitsCallbackCalculatesTicks = value;
            app.AxisLimitsCallbackCalculatesPage = value;
            % if value
            %     set([app.FPRulers{:, 1}], ...
            %     'LimitsChangedFcn', @app.onAxisLimitsChange);
            % else
            %     set([app.FPRulers{:, 1}], ...
            %     'LimitsChangedFcn', function_handle.empty());
            % end
        end

        function value = get.XResUnit(app)
            value = app.XResUnitVals{app.XAxisModeIndex,1};
        end
        function set.XResUnit(app, value)
            if ~bitget(app.XAxisModeIndex, 2) % Index mode
                app.XResUnitVals(1, :) = {double(value), uint64(value)};
            elseif isduration(value) % Time mode, value is duration
                app.XResUnitVals(2, :) = {seconds(value), value};
                app.XResUnitVals(3, :) = app.XResUnitVals(2,:);
            else % Time mode, value is numeric
                app.XResUnitVals(2, :) = {value, seconds(value)};
                app.XResUnitVals(3, :) = app.XResUnitVals(2,:);
            end
        end

        function value = get.PageLimits(app)
            value = app.PageLimitsVals{app.XAxisModeIndex,2};
        end
        function set.PageLimits(app, value)
            % if app.LargestIndexReceived < 2
            %     return;
            % end
            if ~app.LargestIndexReceived
                return;
            end
            if ~bitget(app.XAxisModeIndex,2) % Index mode
                % if ~app.LargestIndexReceived
                %     value = uint64([1 2]);
                %     app.PageLimitsVals{1,:} = {double(value), uint64(value)};
                %     % TODO... ?
                %     return;
                % else
                value(1) = max(1, value(1));
                value(2) = min(value(2), app.LargestIndexReceived);
                idxs = [max(1, value(1)), min(value(2), app.LargestIndexReceived)];
                % end
                relTimes = app.DataTable{1}.RelTime(value);
                if isempty(relTimes)
                    return;
                else
                    relTimes = relTimes([1 end]);
                end
            else
                if ~bitget(app.XAxisModeIndex, 1) % Absolute time
                    value = value - app.TimeZero;
                end
                trng = timerange(value(1),value(2),'closed');
                relTimes = app.DataTable{2}.RelTime(trng);
                if isempty(relTimes)
                    return;
                else
                    relTimes = relTimes([1 end]);
                end
                idxs = app.DataTable{2}.Index(relTimes);
            end
            relSecsDbl = seconds(relTimes);
            app.PageLimitsVals = { ...
                double(idxs), uint64(idxs) ;
                relSecsDbl, relTimes+app.TimeZero ; ...
                relSecsDbl, relTimes ...
                };
            postset_Page(app);
        end

        function set.InputFormat(app, value)
            oldVal = app.BGPreviewSwitch.Value;
            oldEnab = app.BGPreviewSwitch.Enable;
            prevVal = app.VInputResolutionDropdown.Value;
            try
                % Disable while switching...
                app.BGPreviewSwitch.Enable = false;

                vinfo = imaqhwinfo(app.vobj);
                aName = vinfo.AdaptorName;
                if isempty(aName)
                    aName = 'winvideo';
                end
                % display(value);
                [app.vobj, app.vsrc, TF] = sbsense.SBSenseApp.newVideoInput(...
                    value, app.vobj, app.vsrc, aName, ...
                    'StartFcn', app.vobj.StartFcn, 'StopFcn', app.vobj.StopFcn, ...
                    'TimerFcn', app.vobj.TimerFcn, 'TriggerFcn', app.vobj.TriggerFcn, ...
                    'FramesAcquiredFcn', app.vobj.FramesAcquiredFcn, ...
                    'FrameGrabInterval', app.vobj.FrameGrabInterval, ...
                    'FramesAcquiredFcnCount', app.vobj.FramesAcquiredFcnCount, ...
                    'FramesPerTrigger', app.vobj.FramesPerTrigger, ...
                    'TriggerRepeat', app.vobj.TriggerRepeat, 'TimerPeriod', ...
                    app.vobj.TimerPeriod);%, 'UserData', false);
                if TF
                    app.VideoResolution = app.vobj.VideoResolution;
                else
                    fprintf('Creating new vobj failed.\n');
                    % TODO: "Reset=true" option to populate fcn
                    set(app.BGPreviewSwitch, 'Value', oldVal, 'Enable', oldEnab);
                    imaqreset();
                    populateVInputDeviceDropdown(app, char.empty());
                    app.PreviewActive = oldVal;
                    return;
                end
                %inf = imaqhwinfo(app.vdev);
                %app.VideoResolution = [inf.MaxHeight inf.MaxWidth];
                if oldVal
                    app.BGPreviewSwitch.Value = true;
                    start(app.vobj);
                    if ~get(app.vobj,'FramesAcquiredFcnCount')
                        fprintf('[resolutionvaluechanged] trigger\n');
                        trigger(app.vobj);
                    end
                end
            catch ME
                %app.BGPreviewSwitch.Enable = oldEnab;
                fprintf("Error occurred --cannot switch resolution" + ...
                    "to '%s'.\n", value);
                fprintf('Error ID: %s\nError message: %s', ...
                    ME.identifier, ME.message);
                fprintf('Error report: %s\n', getReport(ME));
                if any(cellfun(@(x) isequal(x, prevVal), app.VInputResolutionDropdown.Items))
                    app.VInputResolutionDropdown.Value = prevVal;
                else
                    msk = cellfun(@(x) isequal(x, prevVal), ...
                        app.VInputResolutionDropdown.ItemsData);
                    app.VInputResolutionDropdown.Value = app.VInputResolutionDropdown.Items{find(msk, 1)};
                end
            end
            if app.hasBG
                app.BGPreviewSwitch.Enable = oldEnab && app.hasCamera;
            else
                app.BGPreviewSwitch.Enable = false;
            end
        end

        % function value = get.PageSize(app)
        % end
    end
    %% Methods: Internal Callback Functions
    methods(Access=private)
        %% ROIMoved Callback Functions
        postmove_divline(app, src, event);
        postmove_cropline(app, varargin);
        %% ROIClicked Callback Functions
        postclick_divline(app,src,eventData);
        postclick_cropline(app, src, eventData);
        %% ValueChanging Callback Functions

        %% ValueChanged Callback Functions

        %% PostSet Callback Functions

        %% App Window Callback Functions
    end
    %% Methods: Property Object Callback Functions
    methods(Access=protected,Static)
        %% Video Object Callback Functions
        function getImageData(vobj,~,img)
            %fprintf('[getImageData] Frames available: %d\n', ...
            %    vobj.FramesAvailable);
            if vobj.FramesAvailable
                % fprintf('Getting image data.\n');
                imgdata = getdata(vobj, 1);
                %    %if isempty(imgdata) && isempty(img.CData)
                %    %    vobj.UserData = true; % Acquisition failed
                %    %    %set(vobj.UserData, ...
                %    %    %    setfield(vobj.UserData, 'AcquisitionFailed', true));
                %    %    stop(vobj);
                %    %    % TODO: Ask user what to do.
                %    %    % get(vobj,'UserData').SetHasCameraFcn(false);
                %    %else
                img.CData = imgdata(:,:,1);
                drawnow limitrate;
                %    %end
                %    % img.AlphaData = 0;
                %else
                %    img.CData = [];
            end
        end

        function onVideoStart(~, ~, img)
            % app.PreviewAxes.XLim = [ 1 vr(1) ];
            % app.PreviewAxes.YLim = [ 1 vr(2) ];
            % app.liveimg.XData = app.PreviewAxes.XLim; %[1 app.fdm(2)];
            % app.liveimg.YData = app.PreviewAxes.YLim; %[1 app.fdm(1)];
            %vr = vobj.VideoResolution;
            %img.XData = [1 vr(1)]; img.YData = [1 vr(2)];
            img.Visible = true;
            drawnow nocallbacks;
            %set(enabvis, 'Enable', true);
            %set([img enabvis vis], 'Visible', true);
        end

        %function onVideoTrigger(vobj, eventData)
        %end

        %function onVideoFramesAcquired(vobj,eventData)
        %end

        function onVideoTimerTick(vobj, ~)
            %fprintf('[onVideoTimerTick] trigger if not logging (Running: %d, Logging: %d)\n', ...
            %    logical(isrunning(vobj)), logical(vobj.Logging));
            if ~strcmp(vobj.Logging, "on")
                trigger(vobj);
            else
                % fprintf('[onVideoTimerTick] no trigger b/c logging.\n');
            end
            pause(0);
        end

        function onVideoStop(vobj, ~, img, swtch) %
            if vobj.UserData
                fprintf('[onVideoStop] Acquisition failed.\n');
                vobj.UserData = false;
                img.Visible = false;
                get(swtch, 'UserData').ChangeTrueabilityFcn(false);
            end
            %             if isempty(img.CData) % Data acquisition unsuccessful
            %                 if isempty(swtch)
            %                     img.Visible = false;
            %                 else
            %                     get(swtch, 'UserData').ChangeTrueabilityFcn(false);
            %                 end
            %             end
            pause(0);
        end

        function onVideoError(vobj,event,img,swtch)%,enabvis,vis, dd1, dd2) %#ok<INUSD>
            fprintf('event: %s\n', formattedDisplayText(event));
            eventData = event.Data;
            fprintf('event.Data: %s\n', formattedDisplayText(event.Data));
            fprintf('Error message: %s\n', eventData.Message);
            fprintf('vobj.EventLog: %s\n', formattedDisplayText(vobj.EventLog));
            if swtch.Value
                if isempty(img.UserData)
                    img.Visible = false;
                else
                    img.CData = img.UserData;
                    drawnow limitrate;
                end
                swtch.Value = false;
            end
            if ~isvalid(vobj)
                % TODO:
                % populateVInputDeviceDropdown(app, event.PreviousValue);
                % delete(vobj);
                % imaqreset();
                % swtch.Enable = false;
                % dd1.Value = [];
                % dd2.Items = {};
                % dd2.Enable = false;
                get(swtch, 'UserData').SetHasCameraFcn(false,true);
            end
            % set(enabvis, 'Enable', false);
            % set([enabvis vis], 'Visible', false);
        end
    end
    %% Methods: Timer Callback Functions
    methods(Access=protected)
        varargout = processPlotQueue(app,tobj);
    end
    %% Methods: Startup Helper Functions
    methods(Access=private)
        setupComponents(app);
        setupPropObjects(app);
        setupROIs(app);
        setupPropListeners(app);
        setupPreviewAxes(app);
        setupFPAxes(app);
    end

    methods(Access=public)
        closewbar(app);

        quickExport_ChannelIPs(app,varargin);
        quickExport_ComplementImages(app,varargin);
        quickExport_CompositeImages(app, varargin);
        quickExport_ConfigSummary(app,varargin);
        quickExport_FeatureToggle(app,varargin);
        quickExport_Notes(app, varargin);
        quickExport_PrimaryData(app, varargin);
        quickExport_SelectFeature(app, varargin);
        quickExport_RatioImages(app, varargin);

        dataImage_FeatureToggle(app,varargin);
        dataImage_SelectFeature(app,varargin);
    end

    %% Methods: Phase I control (non-graphics) callbacks
    methods(Access=private)
    end
    %% Methods: Phase II control (non-graphics) callbacks
    methods(Access=private)
        function horzAxisLimitsChanged(app, src, event)
            % event props: OldLimits,NewLimits,Source,EventName
            res = pow2(app.XResKnob.Value);
            if isa(src, 'matlab.graphics.axis.decorator.NumericRuler')
                res = round(res);
            else
                res = seconds(res);
            end
            minticks = colonspace(event.NewLimits(1), res, event.NewLimits(2));
            %if isa(src, 'matlab.graphics.axis.decorator.DatetimeRuler')
            %end
            set(src, 'MinorTickValues', minticks);
        end

        function [newNavMinLim, newNavMaxLim] = calcNavSliderLimits(app)
            % TODO: Set X axis minor tick from slider ItemsData
            % TODO: Set X nav slider major/minor ticks?
            if app.LockRangeButton.Value % Zooming
                if app.XAxisModeIndex == 1
                    entireRange = app.LargestIndexReceived; % TODO: Create prop
                else
                    entireRange = app.PeakDataTimeTable.RelTime(app.LargestIndexReceived);
                    if app.XAxisModeIndex == 2 % abs time mode
                        entireRange = entireRange + app.TimeZero;
                    end
                end
                newNavMinLim = 2\app.XResKnob.Value;
                newNavMaxLim = entireRange;
                if app.XAxisModeIndex == 1 % Index mode
                    newNavMinLim = ceil(newNavMinLim);
                end
            else % Panning
                zoomspan = diff(app.HgtAxes.XLim);
                if app.XAxisModeIndex == 1 % Panning, index mode
                    newNavMinLim = 1;
                    newNavMaxLim = max(1, app.LargestIndexReceived - zoomspan + 1);
                else
                    entireRange = app.PeakDataTimeTable.RelTime(app.LargestIndexReceived);
                    if app.XAxisModeIndex == 2 % abstime mode
                        newNavMinLim = app.TimeZero;
                        entireRange = entireRange + newNavMinLim;
                    else
                        newNavMinLim = seconds(0);
                    end
                    newNavMaxLim = max(newNavMinLim, entireRange - zoomspan);
                end
            end
        end

        function stopRecording(app,varargin)
            %if nargin>1
            app.RecButton.Enable = false;
            %end
            fprintf('%s (%03u) %d : ENTERED FUNCTION stopRecording. HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0, ...
                app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);

            if ~isempty(app.DataTable{1})
                try
                    if isempty(app.PosAxes.Legend) || ~isvalid(app.PosAxes.Legend)
                        legend(app.PosAxes, app.channelPeakPosLines, 'Location', 'best', 'ItemHitFcn', {@sbsense.SBSenseApp.onLegendClick}, ...
                            'AutoUpdate', false, ...
                            'Visible', false, 'UserData', app.channelPeakPosLines, 'ContextMenu', gobjects(0), 'Color', [1 1 1]);
                    end
                    if isempty(app.HgtAxes.Legend) || ~isvalid(app.HgtAxes.Legend)
                        legend(app.HgtAxes, [app.channelPeakHgtLines app.eliPlotLine], 'Location', 'best', 'ItemHitFcn', {@sbsense.SBSenseApp.onLegendClick}, ...
                            'AutoUpdate', false, ...
                            'Visible', false, 'UserData', [app.channelPeakHgtLines app.eliPlotLine], 'ContextMenu', gobjects(0), 'Color', [1 1 1]);
                    end
                catch ME
                    fprintf('[stopRecording] Error occurred while attempting to (re)create FP axis legend(s): %s\n', getReport(ME));
                end
            end

            % NOTE: Moved to end!!
            % app.IsRecording = false;

            %if app.ReadFromFile
            % display(app.RFFTimer);
            % TODO: Move this after setting IsRecording=false??
            try
                if ~isempty(app.RFFTimer) && isa(app.RFFTimer, 'timer') && isvalid(app.RFFTimer) && (app.RFFTimer.Running(2)=='n') % isa(app.RFFTimer, 'timer') && isvalid(app.RFFTimer)
                    stop(app.RFFTimer);
                elseif app.ReadFromFile
                    display(app.RFFTimer);
                    fprintf('[stopRecording] RFFTimer is unexpectedly not a valid, running timer object.\n');
                    display(app.RFFTimer);
                    if isa(app.RFFTimer, 'timer')
                        stop(app.RFFTimer);
                    end
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while trying to stop the read-from-file timer: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            %end
            try
                fprintf('[stopRecording] STOPPING VOBJ...\n');
                if isscalar(app.vobj) && isa(app.vobj, 'videoinput') ...
                        && isvalid(app.vobj) && isrunning(app.vobj)
                    stop(app.vobj); % TODO: Timeout?
                end
                fprintf('[stopRecording] DONE STOPPING VOBJ...\n');
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while trying to stop the videoinput object: %s\n', ...
                    ME.identifier, getReport(ME));
            end

            app.IsRecording = false;
            fprintf('[stopRecording] Set app.IsRecording = false.\n');

            if isscalar(app.Analyzer.APTimer) && isa(app.Analyzer.APTimer, 'timer') && isvalid(app.Analyzer.APTimer)
                fprintf('[stopRecording] STOPPING APTIMER...\n');
                app.Analyzer.APTimer.UserData = true;
                app.Analyzer.APTimer.TasksToExecute = 1;
                try
                    if app.Analyzer.APTimer.Running(2)=='n'
                        fprintf('[stopRecording] Stopping APTimer...\n');
                        stop(app.Analyzer.APTimer);
                        wait(app.Analyzer.APTimer);
                        fprintf('[stopRecording] Stopped APTimer.\n');
                    else
                        fprintf('[stopRecording] APTimer already stopped.\n');
                    end
                    app.Analyzer.APTimer.TasksToExecute = Inf;
                catch ME
                    fprintf('[stopRecording] Error "%s" encountered while trying to stop the analysis timer: %s\n', ...
                        ME.identifier, getReport(ME));
                    app.Analyzer.APTimer.TasksToExecute = Inf;
                end
                fprintf('[stopRecording] DONE STOPPING APTIMER.\n');
            end

            % Moved to end
%             if isscalar(app.PlotTimer) && isa(app.PlotTimer, 'timer') && isvalid(app.PlotTimer)
%                 try
%                     fprintf('[stopRecording] Stopping PlotTimer...\n');
%                     stop(app.PlotTimer);
%                     fprintf('[stopRecording] PlotTimer stopped...\n');
%                 catch ME
%                     fprintf('[stopRecording] Error "%s" encountered while trying to stop the plot timer: %s\n', ...
%                         ME.identifier, getReport(ME));
%                 end
%             end
            % stop(app.Analyzer); % TODO: Wait for FinishedQueue to empty...

            fprintf('%s (%03u) %d : WAITING FOR QUEUES... (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u)\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);
            try
                if app.Analyzer.APQueue.QueueLength % || app.Analyzer.HCQueue.QueueLength %% TODO
                    fprintf('[stopRecording] WAITING FOR APQUEUE(1)...\n');
                    % ql0 = app.Analyzer.APQueue.QueueLength;
                    t0 = datetime('now');
                    ql = app.Analyzer.APQueue.QueueLength;
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Waiting for processing (APQueue) to finish...', ...
                        'Message', sprintf('Queue length: %d', ql), ...
                        'Cancelable', 'on', 'Indeterminate', 'on');
                    try
                        while ql && ~d.CancelRequested
                            % TODO: Also check for changing of AnalysisFutures / check if nonempty & status...
                            pause(0.25);
                            if d.CancelRequested || (datetime('now')-t0 >  minutes(1)) % TODO: Confirm dialog if still Processing
                                break;
                            elseif ql ~= app.Analyzer.APQueue.QueueLength
                                ql = app.Analyzer.APQueue.QueueLength;
                                d.Message = sprintf('Queue length: %d', ql);
                            end
                            % d.Value = 1 - app.Analyzer.APQueue.QueueLength/ql0;
                        end
                        fprintf('[stopRecording] Closing dialog after waiting for APQueue(1).\n');
                        close(d);
                    catch ME2
                        fprintf('[stopRecording] Error handler for waiting for APQueue(1) enetered due to error with identifier "%s".\n', ME2.identifier);
                        close(d);
                        rethrow(ME2);
                    end
                    fprintf('[stopRecording] DONE WAITING FOR APQUEUE1...\n');
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while waiting for the AP queue: %s\n', ...
                    ME.identifier, getReport(ME));
            end

            try
                % start(app.Analyzer.APTimer);
                app.Analyzer.APTimer.UserData = false;
                if app.Analyzer.APQueue2.QueueLength % || app.Analyzer.HCQueue.QueueLength %% TODO
                    fprintf('[stopRecording] WAITING FOR APQUEUE2...\n');
                    % ql0 = app.Analyzer.APQueue.QueueLength;
                    t0 = datetime('now');
                    ql = app.Analyzer.APQueue2.QueueLength;
                    ql0 = ql;
                    line1 = sprintf('APQueue2 length: %d', ql);
                    line2 = sprintf('APTimer running: %d', app.Analyzer.APTimer.Running(2)=='n');
                    line3 = splitlines(sprintf('%s', strip(formattedDisplayText(app.Analyzer.AnalysisFutures))));
                    line3 = line3(3:end);
                    if app.Analyzer.APTimer.Running(2)=='n'
                        fprintf('[stopRecording] Stopping APTimer to reset before waiting for APQueue2..\n');
                        app.Analyzer.APTimer.TasksToExecute = 1;
                        app.Analyzer.APTimer.UserData = true;
                        stop(app.Analyzer.APTimer);
                        wait(app.Analyzer.APTimer);
                        fprintf('[stopRecording] Stopped APTimer to reset before waiting for APQueue2.\n');
                        app.Analyzer.APTimer.TasksToExecute = Inf; % Restore original state
                    end
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Waiting for processing (APQueue2) to finish...', ...
                        'Message', vertcat({line1 ; line2}, line3), ...
                        'Cancelable', 'on', 'Indeterminate', 'off', 'Value', 0);
                    if app.Analyzer.APTimer.Running(2) == 'f'
                        app.Analyzer.APTimer.UserData = true;
                        fprintf('[stopRecording] %s (%03u) (RE)STARTING APTIMER TO CONTINUE/FINISH ANALYSIS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0);
                        app.Analyzer.APTimer.UserData = false;
                        % start(app.Analyzer.APTimer); % TODO: Why??
                    end

                    try
                        futIDs = [app.Analyzer.AnalysisFutures.ID];
                        futStates = [app.Analyzer.AnalysisFutures.State];
                        tel = seconds(0);
                        % app.Analyzer.APTimer.UserData = false;
                        while ql && ~d.CancelRequested
                            % TODO: Also check for changing of AnalysisFutures / check if nonempty & status...
                            % pause(0.5);
                            % pollAPQueue(app.Analyzer);
                            [APdata, TF] = poll(app.Analyzer.APQueue2, 0.5);
                            if TF
                                sbsense.improc.analyzeHCsParallel(app.Analyzer, app.AnalysisParams, ...
                                    [app.Analyzer.PSBL app.Analyzer.PSBR], ...
                                    APdata{:}, app.Analyzer.LastParams);
                            end

                            if d.CancelRequested || (tel > minutes(ceil(prod(app.fdm)/921600))) % TODO: Confirm dialog if still Processing
                                fprintf('[stopRecording] Cancellation or timeout while waiting for APQueue2.\n');
                                break;
                                % elseif app.Analyzer.APTimer.Running(2) == 'f'
                                % start(app.Analyzer.APTimer);
                                % line2 = sprintf('APTimer running: 1');
                                % fprintf('[stopRecording] Restarted timer.\n');
                                % else
                                % line2 = sprintf('APTimer running: %d', app.Analyzer.APTimer.Running(2)=='n');
                            end

                            if (app.Analyzer.APQueue2.QueueLength ~= ql)
                                ql = app.Analyzer.APQueue2.QueueLength;
                                line1 = sprintf('APQueue2 length: %d', ql);
                            end

                            if ~isequal([app.Analyzer.AnalysisFutures.ID], futIDs) || ~isequal(futStates, [app.Analyzer.AnalysisFutures.State])
                                futIDs = [app.Analyzer.AnalysisFutures.ID];
                                futStates = [app.Analyzer.AnalysisFutures.State];
                                line3 = splitlines(sprintf('%s', strip(formattedDisplayText(app.Analyzer.AnalysisFutures(~strcmp({app.Analyzer.AnalysisFutures.State}, "finished"))))));
                                line3 = line3(3:end);
                            end

                            line2 = sprintf('APTimer running: %d', app.Analyzer.APTimer.Running(2)=='n');
                            tel = datetime('now')-t0;
                            d.Message = vertcat({ ...
                                sprintf('Time elapsed: %s', string(tel, 'mm:ss.SSSSSS')) ; ...
                                line1;line2},line3);
                            d.Value = ql/ql0;
                            % d.Value = 1 - app.Analyzer.APQueue.QueueLength/ql0;
                        end
                        fprintf('[stopRecording] Closing dialog after waiting for APQueue2.\n');
                        app.Analyzer.APTimer.UserData = true;
                        close(d);
                    catch ME2
                        close(d);
                        rethrow(ME2);
                    end
                    fprintf('[stopRecording] DONE WAITING FOR APQUEUE2.\n');
                end
                if app.Analyzer.APTimer.Running(2)=='n'
                    fprintf('[stopRecording] Stopping APTimer after waiting for APQueue2...\n');
                    stop(app.Analyzer.APTimer);
                    fprintf('[stopRecording] APTimer stopped.\n');
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while waiting for the 2ndary AP queue: %s\n', ...
                    ME.identifier, getReport(ME));
                try
                    app.Analyzer.APTimer.UserData = true;
                    if app.Analyzer.APTimer.Running(2)=='n'
                        fprintf('[stopRecording] (in error handler) Stopping APTimer after waiting for APQueue2...\n');
                        stop(app.Analyzer.APTimer);
                        fprintf('[stopRecording] (in error handler) APTimer stopped.\n');
                    end
                catch
                end
            end

            try
                if (app.Analyzer.FinishedQueue.QueueLength>0) && any(ismember({app.Analyzer.AnalysisFutures.State}, {'running', 'queued'})) % || app.Analyzer.HCQueue.QueueLength %% TODO
                    % TODO: Check other futures too?? (bgp, etc)
                    fprintf('[stopRecording] WAITING FOR FINISHEDQUEUE...\n');
                    % ql0 = app.Analyzer.APQueue.QueueLength;
                    t0 = datetime('now');
                    ql = app.Analyzer.FinishedQueue.QueueLength;
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Waiting for processing to finish...', ...
                        'Message', sprintf('Queue length: %d', ql), ...
                        'Cancelable', 'on', 'Indeterminate', 'on');
                    try
                        while (ql>0) && ~d.CancelRequested % && any(strcmp("running", {app.Analyzer.AnalysisFutures.State}))
                            % TODO: Also check for changing of AnalysisFutures / check if nonempty & status...
                            if any(ismember({app.Analyzer.AnalysisFutures.State}, {'running', 'queued'}))
                                fprintf('[stopRecording] No Analysis Futures are running or queued. Not waiting for FinishedQueue anymore.\n');
                                break;
                            end
                            pause(0.1);
                            if d.CancelRequested || (datetime('now')-t0 > seconds(20*ceil(prod(app.fdm)/921600))) % TODO: Confirm dialog if still Processing
                                fprintf('[stopRecording] Cancel requested or timeout occurred wile waiting for FinishedQueue.\n');
                                break;
                            elseif ql ~= app.Analyzer.FinishedQueue.QueueLength
                                ql = app.Analyzer.FinishedQueue.QueueLength;
                                d.Message = sprintf('FinishedQueue length: %d', ql);
                            end
                            % d.Value = 1 - app.Analyzer.APQueue.QueueLength/ql0;
                        end
                        fprintf('[stopRecording] Closing dialog after waiting for FinishedQueue.\n');
                        close(d);
                    catch ME2
                        fprintf('[stopRecording] Entering error handler for waiting for FinishedQueue due to error with identifier "%s".\n', ME2.identifier);
                        close(d);
                        rethrow(ME2);
                    end
                    fprintf('[stopRecording] DONE WAITING FOR FINISHEDQUEUE.\n');
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while clearing the finished queue queue: %s\n', ...
                    ME.identifier, getReport(ME));
            end

            try
                if app.ResQueue.QueueLength % || app.Analyzer.HCQueue.QueueLength %% TODO
                    fprintf('[stopRecording] WAITING FOR RESQUEUE (1st pass)...\n');
                    % ql0 = app.Analyzer.APQueue.QueueLength;
                    t0 = datetime('now');
                    ql = app.ResQueue.QueueLength;
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Waiting for data storage to finish...', ...
                        'Message', sprintf('Queue length: %d', ql), ...
                        'Cancelable', 'on', 'Indeterminate', 'on');
                    if app.Analyzer.APTimer.Running(2) == 'f'
                        fprintf('[stopRecording] %s (%03u) STARTING APTIMER TO CONTINUE ANALYSIS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0);
                        start(app.Analyzer.APTimer);
                    end

                    try
                        while ql && ~d.CancelRequested
                            % TODO: Also check for changing of AnalysisFutures / check if nonempty & status...
                            pause(0.25);
                            % pollAPQueue(app.Analyzer);
                            if d.CancelRequested || (datetime('now')-t0 >  minutes(1)) % TODO: Confirm dialog if still Processing
                                break;
                            elseif app.Analyzer.APTimer.Running(2) == 'f'
                                start(app.Analyzer.APTimer);
                            elseif ql ~= app.ResQueue.QueueLength
                                ql = app.ResQueue.QueueLength;
                                d.Message = sprintf('ResQueue length: %d', ql);
                            end
                            % d.Value = 1 - app.Analyzer.APQueue.QueueLength/ql0;
                        end
                        fprintf('[stopRecording] Closing dialog after waiting for ResQueue (1st pass).\n');
                        close(d);
                        if app.Analyzer.APTimer.Running(2)=='n'
                            stop(app.Analyzer.APTimer);
                        end
                    catch ME2
                        fprintf('[stopRecording] Entered error handler for resqueue wait (1st pass) due to error with identifier "%s".\n', ME2.identifier);
                        close(d);
                        rethrow(ME2);
                    end
                    fprintf('[stopRecording] DONE WAITING FOR RESQUEUE (1st pass).\n');
                end
                if app.Analyzer.APTimer.Running(2)=='n'
                    fprintf('[stopRecording] Stopping APTimer after waiting for resqueue (1st pass)...\n');
                    stop(app.Analyzer.APTimer);
                    fprintf('[stopRecording] APTimer stopped.\n');
                end
            catch ME
                fprintf('[stopRecording] Entered waiting for resqueue error handler due to error with identifier "%s".\n', ME.identifier);
                try
                    if app.Analyzer.APTimer.Running(2)=='n'
                        fprintf('[stopRecording] (in error handler) Stopping APTimer after waiting for resqueue (1st pass)...\n');
                        stop(app.Analyzer.APTimer);
                        fprintf('[stopRecording] (in error handler) APTimer stopped.\n');
                    end
                catch
                end
                fprintf('[stopRecording] Error "%s" encountered while waiting for the ResQueue: %s\n', ...
                    ME.identifier, getReport(ME));
            end

            fprintf('[stopRecording] %s (%03u) %d : DONE WAITING FOR QUEUES (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u).\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);

            if app.Analyzer.APTimer.Running(2)=='n'
                fprintf('[stopRecording] Stopping APTimer after waiting for queues...\n');
                stop(app.Analyzer.APTimer);
                fprintf('[stopRecording] %s (%03u) %d : STOPPED APTIMER after waiting for queues.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0, app.IsRecording);
            else
                fprintf('[stopRecording] APTimer already stopped after waiting for queues.\n');
            end


            fprintf('[stopRecording] %s (%03u) %d : CANCELING FUTURES... (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u)\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);

            if ~isempty(app.Analyzer.AnalysisFutures)
                fprintf('[stopRecording] CANCELLING ANALYSISFUTURES...\n');
                try
                    % msk = isa(app.Analyzer.AnalysisFutures, 'parallel.Future');
                    % msk = msk && ~strcmp([app.Analyzer.AnalysisFutures.State], "unavailable");
                    % msk = ~ismember({app.Analyzer.AnalysisFutures.State}, {'unavailable', 'finished'});
                    msk = ~strcmp({app.Analyzer.AnalysisFutures.State}, "unavailable");
                    if any(msk)
                        futs = app.Analyzer.AnalysisFutures(msk);
                        display(futs);
                        fprintf('[stopRecording] Waiting another 30sec then canceling...\n');
                        wait(futs, "finished", 30); % TODO: timeout?
                        cancel(futs);
                        fprintf('[stopRecording] Canceled analysis futures.\n');
                    else
                        fprintf('[stopRecording] No AnalysisFutures require cancellation.\n');
                        display(app.Analyzer.AnalysisFutures);
                    end
                catch ME
                    fprintf('[stopRecording] Error "%s" encountered while trying to wait for the running analysis Futures: %s\n', ...
                        ME.identifier, getReport(ME));
                end
                fprintf('[stopRecording] DONE CANCELLING ANALYSISFUTURES.\n');
            end

            stopPollerFutures(app.Analyzer);

            try
                bgp = backgroundPool();
                rf = bgp.FevalQueue.RunningFutures;
                qf = bgp.FevalQueue.QueuedFutures;
                if ~isempty(rf) || ~isempty(qf)
                    fprintf('QF or RF running!! To be canceled now.\n');
                    display(rf);
                    display(qf);
                    % keyboard;
                    cancelAll(bgp.FevalQueue); % TODO
                end
                queueLengths = [ ...
                    ... % app.Analyzer.HCQueue.QueueLength, ...
                    ... % app.Analyzer.APQueue.QueueLength, ...
                    app.Analyzer.APQueue2.QueueLength ...
                    app.Analyzer.FinishedQueue.QueueLength ...
                    app.ResQueue.QueueLength ...
                    app.PlotQueue.QueueLength ...
                    ];
                objsRunning = [ ...
                    isrunning(app.vobj) ...
                    app.Analyzer.APTimer.Running(2)=='n' ...
                    app.PlotTimer.Running(2)=='n' ...
                    ];
                futs1 = app.Analyzer.AnalysisFutures;
                % try
                %     futs2 = [app.Analyzer.HCQFuture app.Analyzer.APQ1Future];
                % catch
                %     futs2 = parallel.Future.empty();
                % end
                % disp({queueLengths, objsRunning, futs1, futs2});
                if any(queueLengths) || any(objsRunning) ...
                        || any(ismember(string([futs1.State]), {'queued', 'running'})) % ...
                    % || any(ismember(string([futs2.State]), {'queued', 'running'}))
                    disp({queueLengths, objsRunning, futs1}); % , futs2});
                    % keyboard;
                else
                    fprintf('[stopRecording] All empty and stopped.\n');
                    % disp({queueLengths, objsRunning, futs1, futs2});
                end
            catch ME00
                fprintf('[stopRecording] Error "%s" occurred while checking status of queues and futures and timers: %s\n', ...
                    ME00.identifier, getReport(ME00));
            end
           
%             try
%                 if app.Analyzer.APTimer.Running(2)=='n'
%                     stop(app.Analyzer.APTimer);
%                 end
%             catch
%             end

            % clearFinishedQueue(app);

            fprintf('[stopRecording] %s (%03u) %d : DONE CANCELING FUTURES. (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u)\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);

            % NOTE: Moved from beginning!
            % app.IsRecording = false;
            % Moved to middle.


%             if ~isempty(app.Analyzer.AnalysisFutures) ...
%                     && any(ismember({app.Analyzer.AnalysisFutures.State}, {'queued', 'running'}))
%                 % && all(isa(app.Analyzer.AnalysisFutures,'parallel.Future')) % TODO: Unnecessary?
%                 try
%                     cancel(app.Analyzer.AnalysisFutures);
%                     fprintf('[stopRecording] Canceled analysis futures.\n');
%                     % display(app.Analyzer.AnalysisFutures);
%                 catch ME
%                     fprintf('[stopRecording] Error "%s" encountered while canceling analysis futures: %s.\n', ...
%                         ME.identifier, getReport(ME));
%                 end
%             end


            %             try
            %                 cancel(app.Analyzer.HCQueue);
            %             catch ME
            %                 fprintf('[stopRecording] Error "%s" encountered while trying to cancel the HC queue: %s\n', ...
            %                     ME.identifier, getReport(ME));
            %             end

            % try
            %     cancel(app.Analyzer.APQueue);
            % catch ME
            %     fprintf('[stopRecording] Error "%s" encountered while trying to cancel the AP queue: %s\n', ...
            %         ME.identifier, getReport(ME));
            % end

            % try
            %     if ~isempty(app.Analyzer.AnalysisFutures)
            %         msk = isa(app.Analyzer.AnalysisFutures, 'parallel.Future');
            %         msk = msk && ~strcmp([app.Analyzer.AnalysisFutures.Status], "unavailable");
            %         if any(msk)
            %             cancel(app.Analyzer.AnalysisFutures(msk));
            %         end
            %     end
            % catch ME
            %     fprintf('[stopRecording] Error "%s" encountered while trying to cancel the running analysis Futures: %s\n', ...
            %         ME.identifier, getReport(ME));
            % end

            % stopPollerFutures(app.Analyzer);

            try
                if app.ResQueue.QueueLength % || app.Analyzer.HCQueue.QueueLength %% TODO
                    fprintf('[stopRecording] WAITING FOR RESQUEUE (2nd pass)...\n');
                    % ql0 = app.Analyzer.APQueue.QueueLength;
                    t0 = datetime('now');
                    ql = app.ResQueue.QueueLength;
                    d = uiprogressdlg(app.UIFigure, 'Title', 'Waiting for data storage to finish (2nd pass)...', ...
                        'Message', sprintf('Queue length: %d', ql), ...
                        'Cancelable', 'on', 'Indeterminate', 'on');
                    % % if app.Analyzer.APTimer.Running(2) == 'f'
                    % %     fprintf('%s (%03u) STARTING APTIMER TO CONTINUE ANALYSIS.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0);
                    % %     start(app.Analyzer.APTimer);
                    % % else
                    try
                        while (ql || (~isempty(app.AnalyisFutures) && any(ismember([app.Analyzer.AnalysisFutures.State], {'queued', 'running'})))) &&  ~d.CancelRequested
                            % TODO: Also check for changing of AnalysisFutures / check if nonempty & status...
                            pause(0.25);
                            % pollAPQueue(app.Analyzer);
                            if d.CancelRequested || (datetime('now')-t0 >  minutes(1)) % TODO: Confirm dialog if still Processing
                                fprintf('[stopRecording] Cancellation or timeout while waiting for ResQueue.\n');
                                break;
                                % elseif app.Analyzer.APTimer.Running(2) == 'f'
                                %     start(app.Analyzer.APTimer);
                            elseif ql ~= app.ResQueue.QueueLength
                                ql = app.ResQueue.QueueLength;
                                d.Message = sprintf('ResQueue length: %d', ql);
                            end
                            % d.Value = 1 - app.Analyzer.APQueue.QueueLength/ql0;
                        end
                        fprintf('[stopRecording] Closing dialog after waiting for ResQueue.\n');
                        close(d); % Try/catch??
                        if app.Analyzer.APTimer.Running(2)=='n'
                            fprintf('[stopRecording] Stopping APTimer after waiting for ResQueue...\n');
                            stop(app.Analyzer.APTimer);
                            fprintf('[stopRecording] Stopped APTimer after waiting for ResQueue.\n');
                        end
                    catch ME2
                        fprintf('[stopRecording] Entered waiting for resqueue error handler due to error with identifier "%s".\n', ME2.identifier);
                        close(d); % Try/catch??
                        if app.Analyzer.APTimer.Running(2)=='n'
                            fprintf('[stopRecording] Stopping APTimer (in error handler) after waiting for ResQueue...\n');
                            stop(app.Analyzer.APTimer);
                            fprintf('[stopRecording] Stopped APTimer (in error handler) after waiting for ResQueue.\n');
                        end
                        rethrow(ME2);
                    end
                    fprintf('[stopRecording] DONE WAITING FOR RESQUEUE (2nd pass).\n');
                end
                if app.Analyzer.APTimer.Running(2)=='n'
                    fprintf('[stopRecording] Stopping APTimer after waiting for ResQueue...\n');
                    stop(app.Analyzer.APTimer); % TODO: Also wait?
                    fprintf('[stopRecording] Stopped APTimer after waiting for ResQueue.\n');
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while potentially waiting for the ResQueue: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            if isscalar(app.PlotTimer) && isa(app.PlotTimer, 'timer') && isvalid(app.PlotTimer)
                try
                    fprintf('[stopRecording] Stopping PlotTimer...\n');
                    stop(app.PlotTimer); % TODO: Also wait
                    fprintf('[stopRecording] PlotTimer stopped.\n');
                catch ME
                    fprintf('[stopRecording] Error "%s" encountered while trying to stop the plot timer: %s\n', ...
                        ME.identifier, getReport(ME));
                end
            end

            fprintf('[stopRecording] %s (%03u) %d : EMPTYING PLOT QUEUE... (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u)\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);
            try
                while(app.PlotQueue.QueueLength)
                    poll(app.PlotQueue,0);
                end
            catch ME
                fprintf('[stopRecording] Error "%s" encountered while trying to empty the plot queue: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            fprintf('[stopRecording] %s (%03u) %d : DONE EMPTYING PLOT QUEUE. (HC: %u, AP: %u, AP2: %u, RQ: %u, PQ: %u)\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), ...
                0, app.IsRecording, app.Analyzer.HCQueue.QueueLength, app.Analyzer.APQueue.QueueLength, app.Analyzer.APQueue2.QueueLength, app.Analyzer.ResQueue.QueueLength, ...
                app.PlotQueue.QueueLength);

            clearFinishedQueue(app);

            try
                fprintf('[stopRecording] CLOSING LOG FILE...\n');
                fclose(app.Analyzer.LogFile);
                fprintf('[stopRecording] %s (%03u) %d : CLOSED LOG FILE.\n', string(datetime('now'), 'HH:mm:ss.SSSSSSSSS'), 0, app.IsRecording);
            catch ME
                fprintf('[stopRecording] Closing LogFile failed due to error: %s\n', getReport(ME));
            end

            try
                fprintf('[stopRecording] Cleaning datatables...\n');
                cleanDataTables(app);
                fprintf('[stopRecording] Datatables cleaned. Updating datastores...\n');
                updateDatastores(app, app.AnalysisParams.dpIdx0+1,true);
                fprintf('[stopRecording] Updated datastores.\n');
            catch ME0
                fprintf('[stopRecording] Error "%s" occurred while writing to datastores: %s\n', ME0.identifier, getReport(ME0));
            end

            set([ app.FPXModeDropdown app.XResKnob app.FPXModeDropdown app.RatePanel], 'Enable', true);
            set([app.AutoReanalysisToggleButton ...
                app.LeftArrowButton app.RightArrowButton ...
                app.DatapointIndexField app.XNavSlider ...
                app.FPXMinField app.FPXMinSecsField ...
                app.FPXMinColonLabel app.FPXMaxColonLabel ...
                app.FPXMaxField app.FPXMaxSecsField ...
                app.IProfPanel ... % TODO: Enable whenever ANY data received (even if only one point) / if able to show IP
                ... % app.FPPosPanel app.FPHgtPanel ...
                ], 'Enable', (app.LargestIndexReceived>1));
            % app.propListeners(end).Enabled = app.LargestIndexReceived>1;
            %if nargin>1
            set(app.RecButton, 'Value', false, 'Text', 'R', 'Enable', true);
            %else
            %    app.RecButton.Enable = true;
            %end
        end

        function TF = startRecording(app)
            % fph(, analysisScale)

            if app.IPPanelActive
                app.IPPanelActive = false;
            end

            % TODO: Also include RecButton in disabled components list?
            set([app.ReanalyzeButton, app.AutoReanalysisToggleButton, ...
                app.LeftArrowButton app.RightArrowButton ...
                app.DatapointIndexField app.FPXModeDropdown ...
                app.XResKnob app.XNavSlider ...
                app.FPXMinField app.FPXMinSecsField ...
                app.FPXMinColonLabel app.FPXMaxColonLabel ...
                app.FPXMaxField app.FPXMaxSecsField ...
                app.FPXModeDropdown ... % app.FPPosPanel ...
                ... % app.FPHgtPanel ...
                ... %app.RatePanel ...
                ], 'Enable', false);
            % app.propListeners(end).Enabled = false;

            if (app.XAxisModeIndex ~= 1) || ~isa(app.HgtAxes.XAxis, 'matlab.graphics.axis.decorator.NumericRuler')
                % tc = matlab.uitest.TestCase.forInteractiveUse;
                % tc.choose(app.FPXModeDropdown, app.FPXModeDropdown.ItemsData(1));
                cl = class(app.HgtAxes.XAxis);
                switch cl(34) % 32:N/D/D, 33:u/a/u, 34:m/t/r
                    case 't' % DatetimeRuler
                        oldModeIndex = 2;
                    case 'r' % DurationRuler
                        oldModeIndex = 3;
                    otherwise
                        oldModeIndex = 1;
                end
                FPXModeDropdownChanged(app, app.FPXModeDropdown, ...
                    struct('Value', 1, 'PreviousValue', oldModeIndex));
            end

            % TODO: Move to postset_ConfirmStatus or prepareFirstRecord
            app.Analyzer.PSBL = app.PSBLeftSpinner.Value;
            app.Analyzer.PSBR = app.PSBRightSpinner.Value;
            prepare(app.Analyzer, app.LargestIndexReceived, app.ResQueue, 2\app.FPPSpinner.Value, app.AnalysisScale);
            app.vobj.UserData = setfield(app.vobj.UserData, 'HCQueue', app.Analyzer.HCQueue);

            %generateChannelOverlayImages(colororder(app.UIFigure), ...
            %    app.NumChannels, app.AnalysisParams, ...
            %    app.EffHeight, app.fdm(2));
            updateChannelOverlayImage(app, true);
            app.overimg.Visible = app.DI_ShowChannelsToggleMenu.Checked;
            % TODO: (end of section to move)

            if ~app.hasCamera || app.ReadFromFile % TODO: Remove redundancy
                if isequal(app.fdm, [2448 3264])
                    TF = startReadingFromFile(app, 'bigvideo.avi');
                else
                    TF = startReadingFromFile(app, 'YP_7_catF.avi');
                end
            else
                try
                    flushdata(app.vobj);
                    start(app.vobj);
                    if app.vobj.TriggerType=="manual" % || app.vobj.UserData.usingTimer
                        trigger(app.vobj);
                    end
                    set([app.RecPanel app.RecButton], 'Enable', true);
                    TF = true;
                catch ME
                    fprintf('[startRecording] Encountered error "%s" while starting video input: %s\n', ...
                        ME.identifier, getReport(ME));
                    TF = false;
                    set([app.FPXModeDropdown app.XResKnob app.FPXModeDropdown app.RecPanel app.RatePanel], 'Enable', true);
                    set([app.AutoReanalysisToggleButton ...
                        app.LeftArrowButton app.RightArrowButton ... % TODO: Arrow button enable status depends on current selection??
                        app.DatapointIndexField app.XNavSlider ...
                        app.FPXMinField app.FPXMinSecsField ...
                        app.FPXMinColonLabel app.FPXMaxColonLabel ...
                        app.FPXMaxField app.FPXMaxSecsField ...
                        ... % app.FPPosPanel app.FPHgtPanel
                        ], 'Enable', (app.LargestIndexReceived>1));
                    % app.propListeners(end).Enabled = (app.LargestIndexReceived>1);
                    % TODO: More nuanced enabling of nav controls?
                end
            end
            app.IsRecording = TF;
            if TF
                if app.PlotTimer.Running(2)=='f'
                    start(app.PlotTimer);
                end
                if app.Analyzer.APTimer.Running(2)=='f'
                    start(app.Analyzer.APTimer);
                end
            else
                if app.Analyzer.APTimer.Running(2)~='f'
                    stop(app.Analyzer.APTimer);
                end
                if app.PlotTimer.Running(2)~='f'
                    stop(app.PlotTimer);
                end
            end
            app.RecPanel.Enable = true;
        end
    end

    methods(Access=public)
        function cleanDataTables(app)
            try
                if ~issortedrows(app.DataTable{1}, 'Index')
                    app.DataTable{1} = sortrows(app.DataTable{1}, 'Index');
                else % TODO: Note sorting for index correction
                end
                sorted1 = true;
            catch ME
                fprintf('[cleanDataTables] Error "%s" encountered while trying to sort the index-based data table: %s\n', ...
                    ME.identifier, getReport(ME));
                sorted1 = false;
            end

            try
                if ~issortedrows(app.DataTable{2})%, 'RelTime')
                    app.DataTable{2} = sortrows(app.DataTable{2});%, 'RelTime');
                else % TODO: Note sorting for index correction
                end
                sorted2 = issortedrows(app.DataTable{2}, 'Index');
            catch ME
                fprintf('[cleanDataTables] Error "%s" encountered while trying to sort the time-based data table: %s\n', ...
                    ME.identifier, getReport(ME));
                sorted2 = false;
            end

            % celldisp(app.DataTable);
            % % TODO: Handle unequal sizes!!!
            % newIndices = (1:min(size(app.DataTable{2},1),size(app.DataTable{1},1)))';
            % try
            %     if ~isequal(newIndices, app.DataTable{2}.Index)
            %         app.DataTable{1}.Index = newIndices;
            %         app.DataTable{2}.Index = newIndices;
            %     elseif ~isequal(newIndices, app.DataTable{1}.Index)
            %         app.DataTable{1}.Index = newIndices;
            %     end
            % catch ME
            %     fprintf(getReport(ME));
            % end

            % % TODO: A better way to count skips...
            % app.LargestIndexReceived = min(app.LargestIndexReceived, newIndices(end));

            try
                if ~isempty(app.DataTable{1}) && (sorted1 || sorted2)
                    if sorted1
                        if sorted1 && sorted2 && (size(app.DataTable{1},1) > size(app.DataTable{2},1))
                            lookupIdxs = app.DataTable{2}.Index;
                            lookupIdxs = lookupIdxs(lookupIdxs>0);
                            msk = ~ismember(app.DataTable{1}.Index, lookupIdxs);
                            % disp(app.DataTable{1});
                            % % disp(app.DataTable{2});
                            % % display(app.DataTable{2}.Index');
                            fprintf('[cleanDataTables] Discard mask: %s\n', strip(formattedDisplayText(msk')));
                            app.DataTable{1}(msk, :) = [];
                        end
                        idxs_0 = app.DataTable{1}.Index;
                    elseif sorted2
                        idxs_0 = app.DataTable{2}.Index;
                    end
                    idxs_1 = (1:length(idxs_0))';

                    % fprintf('[stopRecording] idxs_0: %s\n', strip(formattedDisplayText(idxs_0')));
                    % fprintf('[stopRecording] idxs_1: %s\n', strip(formattedDisplayText(idxs_1')));

                    offset = uint64(min(idxs_0,[],'all') - 1);
                    % fprintf('[stopRecording] offset = %g\n', offset);
                    % TODO
                    % idxs2_0 = app.DataTable{2}.Index;
                    % idxs2_01 = 1:length(idxs2_0);

                    if ~isempty(app.DataTable{1}.Properties.UserData)
                        fprintf('[cleanDataTables] Checking for erroneous TimeZero...\n');
                        % celldisp(app.DataTable{1}.Properties.UserData);

                        if ~(isempty(app.DataTable{1}.Properties.UserData{1}) || ismissing(app.DataTable{1}.Properties.UserData{1}))...
                                && ~(isempty(app.DataTable{1}.Properties.UserData{2}) || ismissing(app.DataTable{1}.Properties.UserData{2})) ...
                                && (app.DataTable{1}.Properties.UserData{1} > app.DataTable{1}.Properties.UserData{1})
                            dif = app.DataTable{1}.Properties.UserData{2} - app.DataTable{1}.Properties.UserData{1};
                            app.DataTable{1}.RelTime = app.DataTable{1}.RelTime + dif;
                            app.DataTable{2}.RelTime = app.DataTable{1}.RelTime + dif;
                            app.TimeZero = app.DataTable{1}.Properties.UserData{2};
                            app.DataTable{1}.Properties.UserData = [];
                            fprintf('[cleanDataTables] Corrected erroneous TimeZero.\n');
                        else
                            fprintf('[cleanDataTables] TimeZero is not erroneous; no corrections needed.\n');
                        end
                    end

                    diffs_0 = diff(idxs_0);
                    msk = diffs_0 ~= 1;
                    if any(msk)
                        diffs_0 = diffs_0 - 1;
                        % fprintf('[stopRecording] diffs_0: %s\n', strip(formattedDisplayText(diffs_0')));
                        idxs_01 = idxs_0 - [0 ; cumsum(diffs_0)] - offset + 1;
                        % fprintf('[stopRecording] idxs_01: %s\n', strip(formattedDisplayText(idxs_01')));
                        msk = idxs_0(2:end) <= app.LargestIndexReceived;
                        % fprintf('[stopRecording] msk (2): %s\n', strip(formattedDisplayText(msk')));
                        numSkipped = sum(diffs_0(msk), 'all') + offset;
                        % idxs_01 = 1:length(idxs_0);
                        % idxs = find(msk);
                    else
                        idxs_01 = idxs_0 - offset + 1;
                        % fprintf('[stopRecording] idxs_01: %s\n', strip(formattedDisplayText(idxs_01')));
                        numSkipped = offset;
                    end
                    % fprintf('[stopRecording] numSkipped: %g ( = skips + offset = skips + %g)\n', numSkipped, offset);

                    if min(idxs_01, [], 'all')==0
                        idxs_01 = idxs_01 + 1;
                    end
                    if min(idxs_01, [], 'all')==2
                        idxs_01 = idxs_01 - 1;
                    end

                    if isequal(idxs_01, idxs_1)
                        if size(app.DataTable{1},1) == size(idxs_01,1)
                            app.DataTable{1}.Index = idxs_01;
                        else
                            fprintf('Unequal size of datatable 1: \n');
                            disp(size(app.DataTable{1}));
                            disp(size(idxs_01));
                        end

                        if size(app.DataTable{2},1) == size(idxs_01,1)
                            app.DataTable{2}.Index = idxs_01;
                        else
                            fprintf('Unequal size of datatable 2: \n');
                            disp(size(app.DataTable{2}));
                            disp(size(idxs_01));
                        end
                        app.LargestIndexReceived = app.LargestIndexReceived - numSkipped;
                        assert(isscalar(app.LargestIndexReceived));
                        assert(~isempty(app.LargestIndexReceived));
                    else
                        fprintf('Not equal!\n');
                        display(idxs_01');
                    end
                end
            catch ME
                fprintf('[cleanDataTables] Error "%s" while cleaning up datatables: %s', ME.identifier, getReport(ME));
            end

            try
                if sorted2
                    if  ~isempty(app.DataTable{3})
                        for relTime=app.DataTable{3}.RelTime
                            if ismember(relTime, app.DataTable{2}.RelTime)
                                app.DataTable{3}{relTime,'Index'} = app.DataTable{2}{relTime,'Index'};
                            else
                                fprintf('[cleanDataTables] WARNING: Could no longer find relTime "%s" in the datatable. Removing corresponding row from discontinuity table.', ...
                                    string(relTime, 'hh:mm:ss.SSSSSS'));
                                roiLine = app.DataTable{3}{relTime, 'ROI'};
                                if ~isempty(roiLine) && ishandle(roiLine) && isgraphics(roiLine) && isvalid(roiLine)
                                    delete(roiLine);
                                end
                                app.DataTable{3}(relTime,:) = [];
                            end
                        end
                    end
                    updateDiscontinuityTable(app, app.AnalysisParams.dpIdx0+1);
                end
            catch ME
                fprintf('[cleanDataTables] Error "%s" while updating discontinuity table: %s', ME.identifier, getReport(ME));
            end

            try
                updatePaging(app);
                %display(app.HgtAxes.XLim);
                % try
                %     if app.HgtAxes.XLim(1) ~= app.HgtAxes.XLim(2)
                %         setVisibleDomain(app, app.HgtAxes.XLim);
                %     end
            catch ME
                fprintf('[cleanDataTables] Error "%s" encountered while trying to update paging: %s\n', ...
                    ME.identifier, getReport(ME));
            end

            try
                app.SelectedIndex = app.LargestIndexReceived;
            catch ME
                fprintf('[cleanDataTables] Error "%s" encountered while trying to set selected index: %s\n', ...
                    ME.identifier, getReport(ME));
            end
        end
    end

    %% Methods: Phase III control (non-graphics) callbacks
    %% Methods: Auto-managed Callbacks
    % Callbacks that handle component events
    methods (Access = private, Static)
        [majorUnit, majorFormat, sfac] = chooseMajorResUnit(axisModeIndex, minorUnit);
        [h1,h2] = calcChannelHeightFromNthDiv(divBoundsPositions,j);
        [dom, idxs] = convertDomain(timeZero, dataTable, dom, oldModeIndex, newModeIndex);
        [dom, idxs] = convertAxisLimits(timeZero, dataTable, dom, oldModeIndex, newModeIndex, rightmostPos, minDomWd);
        lims = quantizeDomain(timeZero, axisModeIndex, zoomModeOn, resUnit, lims0);
        [minTicks,majTicks,majLabels] = calcAxisMajorAndMinorTicks(modeIndex, timeZero, resUnit, lims);

        % Todo: Also display format index for exponent, exponent displayfmt & value, etc...?
        [minTicks,majTicks,majLabels] = generateRulerTicks(timeZero, axisModeIndex, zoomModeOn, rulerLims, minUnit, majUnitInfo);
        [minTicks,majTicks,majLabels] = generateSliderTicks(timeZero, axisModeIndex, zoomModeOn, sliderLims, minUnit, majUnitInfo);
        [sliderLims, sliderValue, sliEnable] = calcSliderLimsValFromRulerLims(timeZero, axisModeIndex, zoomModeOn, resUnit, maxIdxOrRelTime, rulerLims);
        [rulerLims, newSliVal] = calcRulerLimsFromSliderValue(timeZero, axisModeIndex, zoomModeOn, rulerLims0, value, TF);
    end
    methods(Access=private)
        handleResData(app, data);
        applyVisibleYLims(app, hgtLims, posLims);
        calcAndApplyVisibleYLims(app, varargin);
        updateArrowButtonState(app);
        onFPPlotClick(app, src, ev);
    end
    methods(Access = public)
        setSelectedIndex(app, varargin);
        panToIndex(app, minBuffRU, varargin);
    end
    methods(Access=protected)
        futs = setXAxisModeAndResolution(app, resUnit, varargin);
    end
    methods (Access = private)
        startupFcn(app);

        onXNavSliderMove(app, src, event);

        setVisibleDomain(app, noaxis, lims, varargin);
        % updateNavSliderTicks(app);
        [TF, majTickInfo] = updateTicks(app, typeIdx, lims, ...
            axisModeIndex, zoomModeOn, resUnit, assumeChanged, varargin);

        % Clicked callback: VInputDeviceDropdown
        function VInputDeviceDropdownClicked(app, event)
            arguments(Input)
                app sbsense.SBSenseApp; %#ok<INUSA>
                event matlab.ui.eventdata.ClickedData; %#ok<INUSA>
            end
            % Called AFTER Opening and also AFTER ValueChanged.
            % Also called after DD item clicked **even if no value change
            % results**.
            % event.InteractionInformation has:
            %   Item, Location, ScreenLocation
            %   Item will be integer index or [] if clicking to open
            %     (ie, and not to choose an item)
            % item = event.InteractionInformation.Item;
        end

        % Drop down opening function: VInputDeviceDropdown
        function VInputDeviceDropdownDropDownOpening(app, event)
            arguments(Input)
                app sbsense.SBSenseApp; %#ok<INUSA>
                event matlab.ui.eventdata.DropDownOpeningData; %#ok<INUSA>
            end
            %numItems = length(event.Source.Items); % Assume nonzero & pos.
            %if isfuture(event.Source.UserData)
            %    cancel(event.Source.UserData);
            %end
            % futs = parallel.Future.empty(0,numItems);
            % afterEach(futs, @app.CheckItem,
            %for i=1:numItems
            %    futs(i) = parfeval(backgroundPool, @app.
            %end
        end

        % Value changed function: VInputDeviceDropdown
        function VInputDeviceDropdownValueChanged(app, event)
            arguments(Input)
                app sbsense.SBSenseApp;
                event matlab.ui.eventdata.ValueChangedData;
            end
            devinfo = event.Value; %app.VInputDeviceDropdown.Value;
            % DeviceID, DeviceName, VideoInputConstructor, ...
            % VideoDeviceConstructor, DefaultFormat, SupportedFormats, ...
            % AdaptorName

            fprintf('[DeviceDropdownChanged] Disabling capture-related controls.\n');
            set([app.VInputDeviceDropdown, ...
                app.VInputResolutionDropdown, ...
                app.ImportBGButton, ...
                app.RefCapturePanel, app.CaptureBGButton, ...
                app.BGPreviewSwitch, app.RefExposureCheckbox ...
                app.RefCaptureSyncLamp, app.RefCaptureSyncLabel, ...
                app.RefExposureSpinner, app.RefBrightnessSpinner, ...
                app.RefGammaSpinner, app.RefBrightnessCheckbox, ...
                app.RefGammaCheckbox], 'Enable', false);

            % TODO: TRY/CATCH!!

            if isa(app.vobj, 'videoinput')
                wasValid = isvalid(app.vobj);
                wasRunning = wasValid && isrunning(app.vobj);
                fprintf('[DeviceDropdownChanged] Deleting vobj (wasValid: %d, wasRunning: %d).\n', ...
                    uint8(wasValid), uint8(wasRunning));
                if wasRunning
                    stop(app.vobj);
                    wait(app.vobj, 15, 'running'); % TODO: Wait timeout, ask to keep waiting
                end
                delete(app.vobj);
                fprintf('[DeviceDropdownChanged] Deleted vobj.\n');
            else
                fprintf('[DeviceDropdownChanged] vobj is NOT a videoinput object.\n');
                wasRunning = false; %#ok<NASGU>
                wasValid = false;
            end
            if ~wasValid
                fprintf('[DeviceDropdownChanged] imaqreset.\n');
                imaqmex('feature','-limitPhysicalMemoryUsage',false);
                imaqreset();
            end

            if isempty(devinfo)
                %event.Source.Value = event.PreviousValue;
                fprintf('[DeviceDropdownChanged] devinfo is empty, so enabling import button and device dropdown and returning from function.\n');
                set([app.VInputDeviceDropdown, ...
                    app.ImportBGButton], 'Enable', true);
                set(app.VInputResolutionDropdown, 'Items', {}, ...
                    'ItemsData', {}, 'Enable', false);
                app.hasCamera = false;
                return;
            end

            try
                %if isa(app.vobj, 'videoinput') && isvalid(app.vobj)
                %    % TODO: spmd?? Or thread? How to prevent this from
                %    % hanging
                %    stop(app.vobj); delete(app.vobj);
                %end
                %app.vdev = imaq.VideoDevice(devinfo.AdaptorName, ...
                %    devinfo.DeviceID);
                %set(app.vdev, 'ReturnedColorSpace', 'rgb', ...
                %    'ReturnedDataType', 'uint8');%, ... % Default: 'single'
                %    %'ReadAllFrames', 'off');

                fprintf('[DeviceDropdownChanged] Creating and trig-configurig new vobj.\n');
                app.vobj = videoinput(devinfo.AdaptorName, ...
                    devinfo.DeviceID, ...%app.vdev.VideoFormat, ...
                    imaqhwinfo(devinfo.AdaptorName, devinfo.DeviceID).DefaultFormat, ...
                    'ReturnedColorSpace', 'rgb', ...
                    'Timeout', 15, 'LoggingMode', 'memory', ...
                    'StartFcn', { @sbsense.SBSenseApp.onVideoStart, ...
                    app.liveimg}, ...
                    'StopFcn', { @sbsense.SBSenseApp.onVideoStop, ...
                    app.liveimg, app.BGPreviewSwitch }, ...
                    'ErrorFcn', { @sbsense.SBSenseApp.onVideoError, ...
                    app.liveimg, app.BGPreviewSwitch } ...
                    );
                triggerconfig(app.vobj, 'immediate');
                fprintf('[DeviceDropdownChanged] Created and trig-configured new vobj.\n');
                app.vsrc = getselectedsource(app.vobj);
                fprintf('[DeviceDropdownChanged] Got source. Setting framerate.\n');
                changeFrameRate(app, app.PreviewFramerate);
                fprintf('[DeviceDropdownChanged] Set frame rate.\n');

                fprintf('[DeviceDropdownChanged] Setting app.VideoResolution.\n');
                app.VideoResolution = app.vobj.VideoResolution;
                fprintf('[DeviceDropdownChanged] Set app.VideoResolution.\n');

                % TODO: Move to "populateVInputResolutionDropdown" function
                fprintf('[DeviceDropdownChanged] Populating VInputResolutionDropdown.\n');

                populateVFormatsDropdown(app, app.vobj.VideoFormat);
                fprintf('[DeviceDropdownChanged] Populated VInputResolutionDropdown.\n');

                % Restoring from temporary disabling of components
                if app.hasBG
                    fprintf('[DeviceDropdownChanged] Enabling switch because hasBG.\n');
                    app.BGPreviewSwitch.Enable = true;
                else
                    fprintf('[DeviceDropdownChanged] Keeping switch disabled and setting to true because has no BG.\n');
                    app.BGPreviewSwitch.Value = true;
                end

                fprintf('[DeviceDropdownChanged] Setting hasCamera=true.\n');
                app.hasCamera = true;

                fprintf('[DeviceDropdownChanged] Setting PreviewActive=switchvalue=%d\n', ...
                    uint8(app.BGPreviewSwitch.Value));
                app.PreviewActive = app.BGPreviewSwitch.Value;

                fprintf('[DeviceDropdownChanged] Enabling capture-related controls and returning from function.\n');
                set([ app.VInputDeviceDropdown, ...
                    app.VInputResolutionDropdown, ...
                    app.ImportBGButton, ...
                    app.RefCapturePanel, app.CaptureBGButton, ...
                    app.BGPreviewSwitch, app.RefExposureCheckbox ...
                    app.RefCaptureSyncLamp, app.RefCaptureSyncLabel, ...
                    app.RefExposureSpinner, app.RefBrightnessSpinner, ...
                    app.RefGammaSpinner, app.RefBrightnessCheckbox, ...
                    app.RefGammaCheckbox], 'Enable', true);
                %set(app.PreviewAxesGridPanel, 'Enable', true);
                %set([app.PreviewAxes, app.PreviewAxesGrid, ...
                %    app.PreviewAxesGridPanel], 'Visible', true);
            catch ME
                fprintf('[DeviceDropdownChanged] Error occurred.\n');
                if ~isfield(devinfo, 'AdaptorName')
                    devinfo.("AdaptorName") = extract( ...
                        devinfo.VideoInputConstructor, ...
                        lookBehindPattern("'") + ...
                        alphanumericsPattern() + ...
                        lookAheadPattern("'"));
                end
                fprintf("[DeviceDropdownChanged] Error occurred --cannot establish connection" + ...
                    "to device named '%s' on adaptor '%s'.\n", ...
                    devinfo.DeviceName, devinfo.AdaptorName);
                fprintf('[DeviceDropdownChanged] Error ID: %s\nError message: %s', ...
                    ME.identifier, ME.message);
                fprintf('[DeviceDropdownChanged] Error report: %s\n', getReport(ME));
                % event.Source.Value = event.PreviousValue;

                %set(app.PreviewAxesGridPanel, 'Enable', true);
                %set([app.PreviewAxes, app.PreviewAxesGrid, ...
                %    app.PreviewAxesGridPanel], 'Visible', true);
                %set(app.VInputDeviceDropdown, 'Enable', true);
                fprintf('[DeviceDropdownChanged] Repopulating video device dropdown.\n');
                populateVInputDeviceDropdown(app, event.PreviousValue);
                fprintf('[DeviceDropdownChanged] Repopulated video device dropdown.\n');

                % TODO: What to enable?
                fprintf('[DeviceDropdownChanged] End of error catch, at end of function. Enabling device dropdown and import button.\n');
                set([ app.VInputDeviceDropdown, ...
                    app.ImportBGButton], 'Enable', true);
            end
        end

        % Value changed function: VInputResolutionDropdown
        function VInputResolutionDropdownValueChanged(app, event)
            arguments(Input)
                app sbsense.SBSenseApp;
                event matlab.ui.eventdata.ValueChangedData;
            end
            try
                if app.hasBG
                    str = extractAfter(event.Value, '_');
                    newDims = fliplr(str2double(split(str, 'x')));
                    if ~isequal(newDims, app.fdm)
                        if ~uiconfirm(app.UIFigure, ...
                                { sprintf(['Current reference image has dimensions HxW=%ux%u, which ' ...
                                'differs from the dimensions of the selected input format (%s), HxW=%ux%u.'], ...
                                app.fdm(1), app.fdm(2), newDims(1), newDims(2)) ...
                                sprintf(['Select "OK" to discard the current reference image ' ...
                                'and change the input format to "%s".'], event.Value) ...
                                sprintf(['Select "Cancel" to keep the current %ux%u reference image ' ...
                                ' and currrent input format "%s".'], app.fdm(1), app.fdm(2), event.PreviousValue);
                                }, ...
                                'Image dimension conflict', 'Icon', 'warning', ...
                                'DefaultOption', 2)
                            app.VInputDeviceDropdown.Value = event.PreviousValue;
                            return;
                        end
                        app.ReferenceImage = [];
                        % app.RefImageScaled = [];
                        % app.RefImageCropped = [];
                    end
                end
            catch ME
                fprintf('%s\n', getReport(ME));
                return;
            end

            app.InputFormat = event.Value;
        end

        % Value changed function: RefExposureSpinner
        function RefExposureSpinnerValueChanged(app, event) %#ok<INUSD>
            value = event.Value; %#ok<NASGU> %app.RefExposureSpinner.Value;
        end

        % Value changed function: RefExposureCheckbox
        function RefExposureCheckboxValueChanged(app, event) %#ok<INUSD>
            value = event.Value; %#ok<NASGU> %app.RefExposureCheckbox.Value;

        end

        % Value changed function: RefBrightnessSpinner
        function RefBrightnessSpinnerValueChanged(app, event) %#ok<INUSD>
            value = app.RefBrightnessSpinner.Value; %#ok<NASGU>

        end

        % Value changed function: RefBrightnessCheckbox
        function RefBrightnessCheckboxValueChanged(app, event) %#ok<INUSD>
            value = app.RefBrightnessCheckbox.Value; %#ok<NASGU>

        end

        % Value changed function: RefGammaSpinner
        function RefGammaSpinnerValueChanged(app, event) %#ok<INUSD>
            value = app.RefGammaSpinner.Value; %#ok<NASGU>

        end

        % Value changed function: RefGammaCheckbox
        function RefGammaCheckboxValueChanged(app, event) %#ok<INUSD>
            value = app.RefGammaCheckbox.Value; %#ok<NASGU>

        end

        % Value changed function: SessionCustomField1,
        % ...and 5 other components
        function SessionCustomField1ValueChanged(app, event) %#ok<INUSD>
            value = app.SessionCustomField1.Value; %#ok<NASGU>

        end

        % Button down function: PreviewAxes
        function PreviewAxesButtonDown(app, event) %#ok<INUSD>

        end

        % Value changed function: BGPreviewSwitch
        function BGPreviewSwitchValueChanged(app, ~)
            value = app.BGPreviewSwitch.Value;
            % TODO: try/catch
            if value % (preview on)
                %if isa(app.vdev, 'imaq.VideoDevice') && isvalid(app.vdev)
                %    start(app.PreviewTimer);
                if isa(app.vobj, 'videoinput') && isvalid(app.vobj)
                    set([app.CropLines app.shadRects], 'Visible', false);
                    if ~isrunning(app.vobj)
                        start(app.vobj);
                        if startsWith(app.vobj.TriggerType,'m')
                            trigger(app.vobj);
                        end
                    end
                    app.CaptureBGButton.Enable = true;
                else
                    app.BGPreviewSwitch.Value = false;
                    stop(app.vobj); % TODO: try/catch
                    % TODO: Also disable? Or just let it have an error
                    % instead of checking?
                    set([app.CropLines app.shadRects], 'Visible', app.hasBG);
                    if app.hasBG
                        %bringToFront(app.topCropLine);
                        %bringToFront(app.botCropLine);
                        restorePreviewOrder(app);
                    end
                    app.CaptureBGButton.Enable = false;
                end
            else % Value is false (preview off)
                % stop(app.PreviewTimer);
                stop(app.vobj);
                app.CaptureBGButton.Enable = false;
                if app.hasBG
                    app.liveimg.CData = app.RefImage;
                    set([app.CropLines app.shadRects], 'Visible', true);
                    restorePreviewOrder(app);
                    % drawnow limitrate;
                else
                    set([app.CropLines app.shadRects], 'Visible', false);
                    app.liveimg.Visible = false;
                end
            end
        end

        % Button pushed function: CaptureBGButton
        function CaptureBGButtonPushed(app, ~)
            try
                try
                    img = getsnapshot(app.vobj);
                catch ME
                    if ME.identifier=="MATLAB:class:InvalidHandle"
                        if isa(app.PreviewTimer, 'timer')
                            stop(app.PreviewTimer);
                        end
                        stop(app.vobj);
                    end
                    return;
                end
                %img = step(app.vdev);
                app.ReferenceImage = img(:,:,1);
                app.RefCaptureSyncLamp.Color = 'green';
                % app.hasBG = true;
            catch ME
                fprintf("Error occurred --could not capture " + ...
                    "reference image.\n");
                fprintf('Error ID: %s\nError message: %s', ...
                    ME.identifier, ME.message);
                fprintf('Error report: %s\n', getReport(ME));
            end
        end

        % Button pushed function: ImportBGButton
        function ImportBGButtonPushed(app, ~)
            % persistent pv;
            app.ImportBGButton.Enable = false;
            app.ExportBGButton.Enable = false;
            %if logical(pv)
            %    % TODO: Somehow bring uigetfile dialog to front??
            %    return;
            %end
            % pv = true;
            try
                [file,path,~] = uigetfile( ...
                    {   '*.sbref;*.jpg;*.png;*.jpeg', 'All Supported Files' ; ...
                    '*.sbref', 'SBSense Reference Image Data' ; ...
                    '*.jpg;*.png;*.jpeg', 'Image file' }, ...
                    'Select the file that contains the reference image to import', ...
                    '.', 'MultiSelect', 'off');
                % pv = false;
                if file
                    fullpath = fullfile(path, file);
                    fmtMatches = logical.empty();
                    isSBfile = endsWith(file, '.sbref');
                    if isSBfile
                        if isempty(who("-file", fullpath, "RefImg"))
                            uialert('Selected file does not contain any reference image data.', ...
                                'Error: Invalid or corrupt .sbref file');
                            app.ImportBGButton.Enable = true;
                            app.ExportBGButton.Enable = ~isempty(app.RefImage);
                            return;
                        end
                        varnames = who("-file", fullpath, ...
                            "AdaptorName", "Format", ...
                            "DeviceName");
                        if ~isempty(varnames)
                            S = load(fullpath, "RefImg", varnames{:}, "-mat");
                            if isfield(S, 'AdaptorName') && isfield(S, 'DeviceName')
                                % TODO: Check that it matches current, otherwise warn
                            end
                            if isfield(S, 'Format')
                                % TODO: Check that it matches current, otherwise warn
                            end
                        else
                            S = load(fullpath, "RefImg");
                        end
                        isMultiplePlanes = ndims(S.RefImg)>2; %#ok<ISMAT>
                        newRefImgFcn = @() S.RefImg;
                    else
                        info = imfinfo(fullpath);
                        hasMultipleFrames = ~isscalar(info);
                        if hasMultipleFrames
                            info = info(1);
                            newRefImgFcn = @() imread(fullpath, 'Frames', 1);
                        else
                            newRefImgFcn = @() imread(fullpath);
                        end
                        isMultiplePlanes = info.ColorType ~= "grayscale";
                        fmtMatches = isequal(app.fdm, ...
                            [info.Height info.Width]);
                    end
                    if ~isequal(fmtMatches, false) && isSBfile
                        fmtMatches = isequal(size(S.RefImg), app.fdm);
                    end
                    if isequal(fmtMatches, false)
                        % TODO: Warn / Confirm before replacing...
                        % TODO: Change selection of device and format;
                        %       delete vobj and disable stuffs;
                        %       override dimension variables if necessary
                    end
                    newRefImg = newRefImgFcn();
                    if isMultiplePlanes
                        newRefImg = newRefImg(:,:,1);
                    end
                    app.ReferenceImage = newRefImg;
                end
                app.ImportBGButton.Enable = true;
                app.ExportBGButton.Enable = ~isempty(app.RefImage);
            catch ME
                app.ImportBGButton.Enable = true;
                app.ExportBGButton.Enable = ~isempty(app.RefImage);
                rethrow(ME); % TODO: Display alert box instead of throwing error?
            end
        end

        % Button pushed function: ExportBGButton
        function ExportBGButtonPushed(app, ~)
            [file,path] = uiputfile( ...
                { '*.sbref', 'SBSense Reference Image Data' }, ...
                'Select where to save the reference image data', ...
                '');
            if ~file
                return;
            end
            if(~endsWith(file, '.sbref'))
                file = file + ".sbref";
            end
            fullpath = fullfile(path, file);
            if isa(app.vobj,'videoinput') && isvalid(app.vobj)
                % TODO: Try/catch?
                S = imaqhwinfo(app.vobj);
                S.('RefImg') = app.RefImage;
                S.('Format') = app.vobj.VideoFormat;
            else
                S = struct('RefImg', app.RefImage);
            end
            save(fullpath, "-struct", 'S', '-v7');
        end

        % Callback function
        function YCropSpinnerValueChanging(app, ~)
            % changingValue = event.Value;
            app.CroppedHeightField.Value = ...
                app.MaxYSpinner.Value - app.MinYSpinner.Value;
        end

        % Value changed function: NumChSpinner
        function NumChSpinnerValueChanged(app, ~)
            app.NumChannels = app.NumChSpinner.Value;
        end

        % Button pushed function: ChLayoutResetButton
        function ChLayoutResetButtonPushed(app, ~) %#ok<INUSD>

        end

        % Button pushed function: ChLayoutImportButton
        function ChLayoutImportButtonPushed(app, ~) %#ok<INUSD>

        end

        % Button pushed function: ChLayoutExportButton
        function ChLayoutExportButtonPushed(app, ~) %#ok<INUSD>

        end

        % Callback function: ChDiv12Spinner, ChDiv12Spinner,
        % ChDiv23Spinner,
        % ...and 7 other components
        %         function ChDiv12SpinnerValueChanging(app, event) %#ok<INUSD>
        %             changingValue = event.Value;
        %         end

        % Button pushed function: ChLayoutConfirmButton
        function ChLayoutConfirmButtonPushed(app, ~)

            % TODO: Try/catch; error dialog
            set(app.leftPSBLine, "DrawingArea", [0 0 , app.fdf] ...
                + [0 0 0 1], "Position", [0 0 ; 0 app.fdf(2)+1]...%, ...
                ); % "Visible", true);)
            app.PSBLeftSpinner.Limits = ...
                [ app.leftPSBLine.DrawingArea(1), ...
                sum(app.leftPSBLine.DrawingArea([1 3])) ];
            app.rightPSBLine.LineWidth = 2\app.rightPSBLine.LineWidth;
            set(app.rightPSBLine, ...%"Visible", true, ...
                "DrawingArea", [1 0 (app.fdf+1)], ...
                "Position", [(app.fdf(1)+1) 0 ; (app.fdf+1)]);
            app.PSBRightSpinner.Limits = ...
                [ app.rightPSBLine.DrawingArea(1), ...
                sum(app.rightPSBLine.DrawingArea([1 3])) ];
            app.PSBIndexes = [1 app.fdm(2)];
            app.PSBLeftSpinner.Value = 1;
            app.PSBRightSpinner.Value = double(app.fdm(2));
            try
                app.ConfirmStatus = true;
            catch ME
                fprintf('[ChLayoutConfirmButtonPushed] Error "%s": %s\n', ...
                    ME.identifier, getReport(ME));
                app.ConfirmStatus = false;
                rethrow(ME);
            end
        end

        function ConfirmLayoutValueChanged(app)
            % TODO: Initially default color, disabled, no
            %       Until enabled --then set to "false" version (below)
            if app.ConfirmLayoutButton.Value
                try
                    app.ConfirmStatus = true;
                    % TODO: Dull color, check icon
                    %       Enable relevant controls
                    %       Set up axes!
                    % Controls that depend on ConfirmStatus:
                    % Rec btn,, rec panel, rec btn tooltip,
                    % rec panel note, confirm button tooltip
                    app.ConfirmLayoutButton.Enable = false;
                catch % ME
                    % TODO: How to handle error?
                end
            else
                % TODO: This should not occur...
                % TODO: Bright color, enabled, no icon
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event) %#ok<INUSD>
            % TODO: Ask before canceling?
            delete(app);
        end
    end

    methods(Access=public)
        XResKnobValueChange(app, ~, event);
        onAxesPanelSizeChange(~,src,~);
        onAxisLimitsChange(app,varargin); % src,event);
        onArrowButtonPushed(app, src, varargin);

        ctx_ExportFigure(app, src, ~);
    end

    %% Methods: Component creation
    % Component initialization
    methods (Access = private)
        createComponents(app);
    end
    %% Methods: Class Constructor and Destructor
    % App creation and deletion
    methods (Access = public)

        function clearFinishedQueue(app)
            TF = true;
            if app.Analyzer.FinishedQueue.QueueLength>0
                xs = zeros(1, app.Analyzer.FinishedQueue.QueueLength);
                i = 1;
                while app.Analyzer.FinishedQueue.QueueLength && TF
                    [x,TF] = poll(app.Analyzer.FinishedQueue);
                    if TF
                        xs(i) = x;
                        i = i+1;
                    end
                end
                disp(xs);
            end
        end
        % Construct app
        function app = SBSenseApp

            try
                f = fopen("SBSense_log.txt", "w");
                fclose(f);
            catch ME
                fprintf('Error occurred while trying to clear logfile (%s): %s', ...
                    ME.identifier, ME.message);
            end
            runningApp = getRunningApp(app);
            if ~isempty(runningApp)
                if ...%~runningApp.CreateComponentsEnded || ...
                        runningApp.UIFigure.Visible~="on"
                    delete(runningApp);
                    runningApp = [];
                end
            end
            % Check for running singleton app
            if isempty(runningApp)

                try
                    % Create UIFigure and components
                    createComponents(app);

                    % registerApp is called immediately after createComponents() in
                    %   user generated code
                    % Register the app with App Designer
                    registerApp(app, app.UIFigure)

                    % If handle visibility is set to 'callback', turn it on until
                    %   finished with StartupFcn. This enables gcf and gca to work in
                    %   the StartupFcn and also allows exceptions from the StartupFcn
                    %   to be catchable.
                    % Execute the startup function
                    runStartupFcn(app, @startupFcn)
                catch ME
                    fprintf('Error "%s" occurred during SBSense startup: %s\n', ...
                        ME.identifier, getReport(ME));
                    try
                        % NOTE: strsplit is better than split and splitlines.
                        % split separates at whitespace (with collapse);
                        % splitlines separates at newline (without collapse);
                        % strsplit is more configurable (but still includes empty at beginning/end,
                        % so use strstrip/strip first!).

                        % regexptranslate
                        % erase vs deblank vs strip vs strstrip
                        % strfind vs regexp(i) vs contains
                        % matches vs strmatch vs str(n)cmp(i) vs vs startsWith vs validateString vs regexp
                        % eq vs isEqual
                        % replace vs strrep vs regexprep (strrep performs multiple replacements for overlapping patterns)
                        % strjust vs pad
                        % extract; replaceBetween; insertAfter/insertBefore
                        % strlength; count
                        % join vs strjoin

                        % fcn(fcn(compose('abc\n    def \n \t\t\tghi    \n    jkl\t\t\tmno    \t  \npqr  \t  \t\nstu')))
                        % fcn = @(x) regexprep(x, '(?!^)(?:[\t ]+(?=[ \t]|$))', '', 'all', 'dotall', 'warnings', 'lineanchors')

                        % getReport optional args:
                        % "extended" or "basic"
                        % "hyperlinks" can be "on", "default", or "off"
                        reportStrs = regexprep(splitlines(strip(getReport(ME, "extended", "hyperlinks", "off"))), ...
                            '(?!^)(?:[\t ]+(?=[ \t]|$))', 'all', 'preservecase', 'noemptymatch', ...
                            'lineanchors', 'literalspacing', 'nowarnings');
                        if isempty(ME.stack)
                            stackStrs = {};
                        elseif isscalar(ME.stack)
                            stackStrs = { ...
                                sprintf('File & line no.: %s::%d', ME.stack.file, ME.stack.line) ...
                                sprintf('Function/context name: %s', ME.stack.name) ...
                                };
                        else
                            stackSize = length(ME.stack);
                            stackStrs = { ...
                                sprintf('File & line no. (stack frame %d/%d): %s::%d', 1, stackSize, ME.stack(1).file, ME.stack(1).line) ...
                                sprintf('Function/context name (stack frame (%d/%d): %s', 1, stackSize, ME.stack(1).name) ...
                                sprintf('File & line no. (stack frame %d/%d): %s::%d', stackSize, stackSize, ME.stack(end).file, ME.stack(end).line) ...
                                sprintf('Function/context name (stack frame (%d/%d): %s', stackSize, stackSize, ME.stack(end).name) ...
                                };
                        end
                        dlg = errordlg( ...
                            [reshape({ 'SBSense encountered a fatal error during startup and cannot open.' ...
                            sprintf(['Please relay the error ID (in the titlebar of this dialog)' ...
                            ' along with the following information to the developer' ...
                            ' so that the issue can be resolved.']) ...
                            '' ...
                            sprintf('Error identifier: %s', ME.identifier) ...
                            sprintf('Error message: %s', ME.message) ...
                            }, 1, []), reshape(stackStrs, 1, []), ...
                            reshape({'', 'Error report:'}, 1, []), ...
                            reshape(reportStrs,1,[])], ...
                            sprintf('Error (ID: %s)', ME.identifier), ...
                            struct('WindowStyle', 'modal', 'Interpreter', 'none') ... % TODO: Interpreter='tex' for formatting and color
                            );
                        waitfor(dlg);
                        if ishghandle(dlg) && isvalid(dlg)
                            delete(dlg);
                        end
                        clear dlg;
                    catch ME2
                        fprintf('Error "%s" occurred when, after encountering startup error "%s", attempting to show startup error dialog: %s\n', ...
                            ME2.identifier, ME.identifier, getReport(ME2));
                    end
                    try
                        if isa(app.wbar, 'matlab.ui.Figure') && isvalid(app.wbar)
                            delete(app.wbar);
                        end
                        if ishghandle(app) && isvalid(app)
                            delete(app);
                        end
                        clear app;
                    catch ME2
                        fprintf('Error "%s" occurred when, after encountering startup error "%s", attempting to delete object "app": %s\n', ...
                            ME2.identifier, ME.identifier, getReport(ME2));
                    end
                    rethrow(ME);
                end
            else
                % TODO: Reinitialize??

                % Focus the running singleton app
                figure(runningApp.UIFigure);

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % TODO
            % Delete UIFigure when app is deleted
            % try
            %     close(app.UIFigure);
            % catch ME
            %     fprintf('Error "%s" occurred while trying to close app UIFigure window during app object deletion: %s\n', ...
            %         ME.identifier, getReport(ME));
            % end
            try
                if all(ishandle(app.Analyzer)) && ~any(isempty(app.Analyzer.AnalysisFutures))
                    cancel(app.Analyzer.AnalysisFutures);
                end
            catch ME
                fprintf('Error "%s" occurred when canceling Analyzer.AnalysisFutures while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            try
                if all(isa(app.RFFTimer, 'timer')) && all(isvalid(app.RFFTimer))
                    stop(app.RFFTimer);
                    delete(app.RFFTimer);
                end
            catch ME
                fprintf('Error "%s" occurred while stopping and deleting the RFFTimer while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            try
                if all(isa(app.vobj, 'videoinput')) && all(isvalid(app.vobj))
                    stop(app.vobj);
                end
            catch ME
                fprintf('Error "%s" occurred while stopping vobj while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            try
                delete(app.vobj);
            catch ME
                fprintf('Error "%s" occurred while deleting vobj while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            try
                if all(isa(app.PlotTimer, 'timer')) && all(isvalid(app.PlotTimer))
                    stop(app.PlotTimer);
                    delete(app.PlotTimer);
                end
            catch ME
                fprintf('Error "%s" occurred while stopping and deleting the PlotTimer while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            try
                if all(isa(app.PreviewTimer, 'timer')) && all(isvalid(app.PreviewTimer))
                    stop(app.PreviewTimer);
                    delete(app.PreviewTimer);
                end
            catch ME
                fprintf('Error "%s" occurred while stopping and deleting the PreviewTimer while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            %if isa(app.PreviewTimer, 'timer') && isvalid(app.PreviewTimer)
            %    app.PreviewTimer.StopFcn = {'delete'};
            %    stop(app.PreviewTimer);
            %end
            try
                delete(app.Analyzer);
            catch ME
                fprintf('Error "%s" occurred while trying to delete the Analyzer object while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
                keyboard;
            end
            try
                if isobject(app.BinFileCollection) && ishandle(app.BinFileCollection)
                    delete(app.BinFileCollection);
                end
            catch ME
                fprintf('Error "%s" occurred while trying to delete the BinFileCollection object while closing the app UIFigure window: %s\n', ...
                    ME.identifier, getReport(ME));
                keyboard;
            end

            try
                delete(app.Analyzer);
                delete(app.AnalysisParams);
                % if (class(app.AnalysisParams)=="parallel.Future") && all(ishandle(app.AnalysisParams)) && all(isvalid(app.AnalysisParams))
                %     delete(app.AnalysisParams);
                % end
            catch ME
                fprintf('Error "%s" occurred while trying to delete Analyzer and AnalysisParam(eter) objects during app object deletion: %s\n', ...
                    ME.identifier, getReport(ME));
            end
            delete(app.UIFigure)
        end
    end
end