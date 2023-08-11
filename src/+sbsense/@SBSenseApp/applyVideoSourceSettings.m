function applyVideoSourceSettings(app,allprops)
arguments(Input)
    app; allprops = false;
end
if allprops
    pnames = properties(app.vdev)';
    msk = cellfun(@(x) isprop(app.vsrc, x), pnames);
    pnames = pnames(msk);
    pvals = get(app.vsrc, pnames);
    pargs = reshape(vertcat(pnames,pvals), 1, []);
    set(app.vdev, pargs{:});
else
    set(app.vdev, 'Exposure', ...
        app.vsrc.Exposure, 'Brightness', ...
        app.vsrc.Brightness, 'Gamma', ...
        app.vsrc.Gamma);
end
end