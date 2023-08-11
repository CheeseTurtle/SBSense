function quickExport_FeatureToggle(app, src. ~)
src.Checked = ~src.Checked;
set(src.Children, 'Enable', src.Checked);
if src.Checked
    checkedItem = findobj(src.UserData.Children, 'Checked', 'on');
    if isempty(checkedItem)
        % checkedItem = src.UserData.Children(1);
        % checkedTag = checkedItem.Tag;
        % checkedItem.Checked = 'on';
        src.UserData.Children(1).Checked = true;
    elseif ~isscalar(checkedItem)
        set(checkedItem(2:end), 'Checked', 'off');
        % checkedTag = checkedItem(1).Tag;
        % checkedItem(1) = [];
        % set(checkedItem, 'Checked', 'off');
    end
    % clear checkedItem;
end
end