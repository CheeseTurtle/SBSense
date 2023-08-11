function updateReanalysisState(app, chk, relTime)
    arguments(Input)
        app; chk = true; relTime = [];
    end
    error('Dont use this!');
    if ~chk || ~app.SelectedIndex || ~ismember(app.ChunkTable.Index
    if app.SelectedIndex && app.ChunkTable
        app.ChunkTable.IsChanged(app.SelectedIndex) ...
            = logical(app.ChunkTable.ChangeFlags(app.SelectedIndex));
end