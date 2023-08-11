function quickExport_SelectFeature(app, src, ~)
    if src.Checked
        return; % TODO: Bell?
    end
    set(findobj(src.UserData.Children, ...
        '-not', 'Tag', src.Tag), 'Checked', false);
    src.Checked = true;
end