function updateArrowButtonState(app)
    if (app.MainTabGroup.SelectedTab.Tag=='2') && (app.LargestIndexReceived>1)
        if app.ShiftDown
            % fprintf('hi');
            if app.CtrlDown
                set([app.LeftArrowButton app.RightArrowButton], ...
                    'BackgroundColor', 'magenta', 'FontColor', 'white');
                msk = logical(bitget(app.DataTable{3}.SplitStatus, 2));
                if ~any(msk)
                    set([app.LeftArrowButton app.RightArrowButton], 'Enable', false);
                elseif app.SelectedIndex
                    app.LeftArrowButton.Enable = ...
                        any(app.DataTable{3}.RelTime(msk) < app.DataTable{1}.RelTime(app.SelectedIndex));
                    app.RightArrowButton.Enable = ...
                        any(app.DataTable{3}.RelTime(msk) > app.DataTable{1}.RelTime(app.SelectedIndex));
                else % TODO: Enable left / right depending on location of boundary lines?
                    set([app.LeftArrowButton app.RightArrowButton], 'Enable', true);
                end
            else % Shift only
                set([app.LeftArrowButton app.RightArrowButton], ...
                    'BackgroundColor', 'magenta', 'FontColor', 'white');
                if isempty(app.DataTable{3})
                    set([app.LeftArrowButton app.RightArrowButton], 'Enable', false);
                elseif app.SelectedIndex
                    app.LeftArrowButton.Enable = ...
                        any(app.DataTable{3}.RelTime < app.DataTable{1}.RelTime(app.SelectedIndex));
                    app.RightArrowButton.Enable = ...
                        any(app.DataTable{3}.RelTime > app.DataTable{1}.RelTime(app.SelectedIndex));
                else % TODO: Enable left / right depending on location of boundary lines?
                    set([app.LeftArrowButton app.RightArrowButton], 'Enable', true);
                end
            end
        else % Shift is not down, or ctrl is down without shift
            set([app.LeftArrowButton app.RightArrowButton], ...
                'BackgroundColor', [0.96 0.96 0.96], ...
                'FontColor', [0 0 0], 'FontWeight', 'normal');
            if app.LargestIndexReceived > 1
                app.LeftArrowButton.Enable = ...
                    (~app.SelectedIndex || (app.SelectedIndex>1));
                app.RightArrowButton.Enable = ~app.SelectedIndex || ...
                    (app.SelectedIndex < app.LargestIndexReceived);
            else
                set([app.LeftArrowButton, app.RightArrowButton], 'Enable', false);
            end
        end
    %else
    %    return;
    end
end