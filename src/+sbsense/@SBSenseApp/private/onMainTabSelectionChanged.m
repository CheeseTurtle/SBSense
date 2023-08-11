function onMainTabSelectionChanged(app, src, event)
    % matlab.ui.eventdata.SelectionChangedData
%     SelectionChangedData with properties:
%     OldValue: [1×1 Tab]
%     NewValue: [1×1 Tab]
%       Source: [1×1 TabGroup]
%    EventName: 'SelectionChanged'
    % TODO: try/catch
    if (event.OldValue.Tag == '1') && ~app.ConfirmStatus
        if event.NewValue.Tag == '2'
            if ~app.hasBG
                issueStr = ['There is no REFERENCE IMAGE. Please capture or load a reference image ' ...
                    'and then configure and confirm the channel layout.'];
            elseif ~app.ConfirmStatus
                issueStr = ['Once you have performed the desired vertical cropping of the image ' ...
                    'and have set the channel quantity and the channel sizes/positions, ' ...
                    'please CONFIRM the channel layout by clicking the CONFIRM LAYOUT button ' ...
                    'in order to advance to Phase II.'];
            else
                issueStr = ['It is unclear what the problem is. It could be a bug. Please ' ...
                    'contact the developer.'];
            end
            if isGoBack(uiconfirm(app.UIFigure, ...
                { ['Phase II controls are inoperative until Phase I is complete. ', ...
                    'To advance to Phase II, ensure that you have captured ' ...
                    '(via connected camera device) or loaded (from file) a ' ...
                    'REFERENCE IMAGE, and that the channel layout (# of channels ' ...
                    ' and their heights/positions) has been CONFIRMED.'] ...
                  'The program has detected the following missing precondition for Phase II:' ...
                  issueStr, ...
                  '', ...
                  ['To return to the Phase I tab to complete the necessary preparations, ' ...
                    'click "OK, GO BACK". To visit the Phase II tab anyway, ' ...
                    'click "NO, I KNOW WHAT I''M DOING". (Remember, you cannot collect data ' ...
                    'until Phase I is complete.)'] ...
                }, ...
                'Phase I is still incomplete!', 'DefaultOption', 2, 'CancelOption', 2, ...
                'Options', {'No, I Know What I''m Doing', 'OK, Go Back'}, ...
                'Icon', 'warning'))
                src.SelectedTab = event.OldValue;
            end
        elseif event.NewValue.Tag == '3'
            if isGoBack(uiconfirm(app.UIFigure, ...
                { ['You cannot use any Phase III (Export) functionalities until ' ...
                  'data has been collected. Please complete Phase I and Phase II ' ...
                  'before proceeding to Phase III.'] ...
                  ['To return to the Phase I tab to complete the necessary preparations, ' ...
                    'click "OK, GO BACK". To temporarily visit the Phase III tab anyway, ' ...
                    'click "NO, I KNOW WHAT I''M DOING". (Remember, you must complete Phase I ' ...
                    'in order to be able to collect data to export.)'] ...
                }, ...
                'Phase I and II are still incomplete!', 'DefaultOption', 2, ...
                'CancelOption', 2, 'Icon', 'warning', ...
                'Options', {'No, I Know What I''m Doing', 'OK, Go Back'}))
                src.SelectedTab = event.OldValue;
            end
        end
    elseif (event.NewValue.Tag=='3') && (~app.LargestIndexReceived ...
        || (max(size(app.DataTable{2},1), size(app.DataTable{1},1)) < 2))
        if event.OldValue.Tag == '2'
            line2str = ['To return to the Phase II tab to record/import data for exporting, ' ...
            'click "OK, GO BACK". To temporarily visit the Phase III tab anyway, ' ...
            'click "NO, I KNOW WHAT I''M DOING". (Remember, you cannot export ' ...
            'data until after data has been recorded or imported.)'];
        else
            line2str = ['To go back, click "OK, GO BACK". To temporarily visit the Phase III tab anyway, ' ...
            'click "NO, I KNOW WHAT I''M DOING". (Remember, you cannot export ' ...
            'data until after data has been recorded or imported.)'];
        end

        if isGoBack(uiconfirm(app.UIFigure, ...
            { ['You cannot use any Phase III (Export) functionalities until ' ...
            'data has been collected. Please RECORD some data (Phase II tab, left panel) ' ...
            'before proceeding to Phase III. Alternatively, IMPORT data from a '...
            'from a previously-recorded session (upper-left corner menu: File>Import).'] ...
             line2str ...
            }, 'No exportable data present!', 'DefaultOption', 2, ...
            'CancelOption', 2, 'Icon', 'warning', ...
            'Options', {'No, I Know What I''m Doing', 'OK, Go Back'}))
            src.SelectedTab = event.OldValue;
        end

    elseif (event.NewValue.Tag=='2') && (app.LargestIndexReceived>1) ...
        && (app.LeftArrowButton.Enable || app.RightArrowButton.Enable)
            % app.propListeners(end).Enabled = true;
    else
        % app.propListeners(end).Enabled = false;
    end
end

function TF = isGoBack(x)
TF = startsWith(x, 'OK');
end
