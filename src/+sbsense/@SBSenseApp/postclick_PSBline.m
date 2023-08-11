function postclick_PSBline(app, src, eventData)
    if strcmp(eventData.SelectionType,"ctrl")
        set(app.PSBLines, 'Selected', false);
    else
        src.Selected = true;
        app.PSBLines(bitxor(3, uint8(src.Tag)-48)).Selected = false;
    end
end