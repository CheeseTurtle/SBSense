function setChannelHeightFieldsFromFut(app, idx, fut)
    %fprintf('[setChannelHeightFieldsFromFut] %d\n', idx);
    % display(fut.OutputArguments);
if isempty(fut.Error)
    [ht1,ht2] = fut.OutputArguments{:};
    %display([ht1 ht2]);
    app.ChanHgtFields(idx).Value = ht1;
    app.ChanHgtFields(idx+1).Value = ht2;
else
    fprintf('[setChannelHeightFieldsFromFut] Error: %s\n', getReport(fut.Error));
    rethrow(fut.Error);
end
end