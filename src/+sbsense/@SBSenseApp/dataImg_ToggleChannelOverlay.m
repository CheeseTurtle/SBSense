function dataImg_ToggleChannelOverlay(app, src, event)
    src.Checked = ~src.Checked;
    if src.Checked && isempty(app.overimg.UserData)
        updateChannelOverlayImg(app);
        % if ~updateChannelOverlayImg(app)
        %     return;
        % end
    end
    app.overimg.Visible = src.Checked;
    drawnow;
end