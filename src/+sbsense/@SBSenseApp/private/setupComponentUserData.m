function setupComponentUserData(app)
import('parallel.Future');
% Phase I

app.ChDiv12Spinner.UserData = 1;
app.ChDiv23Spinner.UserData = 2;
app.ChDiv34Spinner.UserData = 3;
app.ChDiv45Spinner.UserData = 4;
app.ChDiv56Spinner.UserData = 5;

app.SessionCustomField1.UserData = 1;
app.SessionCustomField2.UserData = 2;
app.SessionCustomField3.UserData = 3;
app.SessionCustomField4.UserData = 4;

app.SessionTitleField.UserData = 'title';
app.SessionDatepicker.UserData = 'date';
app.SessionNotesTextarea.UserData = 'notes';

app.RefExposureSpinner.UserData = 'Exposure';
app.RefBrightnessSpinner.UserData = 'Brightness';
app.RefGammaSpinner.UserData = 'Gamma';
app.RefExposureCheckbox.UserData = 1;
app.RefBrightnessCheckbox.UserData = 2;
app.RefGammaCheckbox.UserData = 3;

app.MinYSpinner.UserData = 1;
app.MaxYSpinner.UserData = 2;

app.BGPreviewSwitch.UserData = struct( ...
    'SetHasCameraFcn', @(x) app.setHasCamera);
%'ChangeTrueabilityFcn', @app.modifyPreviewSwitchTrueability);


% Phase II

app.SPFField.UserData = 'SPF';
app.FPPSpinner.UserData = 'FPP';

app.PSBLeftSpinner.UserData = 1;
app.PSBRightSpinner.UserData = 2;

app.LeftArrowButton.UserData = int8(-1);
app.RightArrowButton.UserData = int8(1);

% app.FPHgtSlider.UserData = 1;
% app.FPPosSlider.UserData = 2;

% app.FPPosAutoButton.UserData = ['auto', 1];
% app.FPHgtAutoButton.UserData = ['auto', 2];

app.LockLeftButton.UserData = 1;
app.LockRightButton.UserData = 2;
app.LockRangeButton.UserData = 3;

app.FPXMinField.UserData = [1 1];
app.FPXMinSecsField.UserData = [1 2];
app.FPXMaxField.UserData = [2 1];
app.FPXMaxSecsField.UserData = [2 2];

app.XNavSlider.UserData = Future.empty();
app.FPXModeDropdown.UserData = Future.empty();
app.XResKnob.UserData = Future.empty();

app.HgtAxes.UserData = {false, app.PosAxes, app.FPXAxisLabelsGrid.Parent};
app.PosAxes.UserData = {false, app.HgtAxes, app.FPXAxisLabelsGrid.Parent};
app.FPPlotsGrid.UserData = {Future.empty(), Future.empty()};
end