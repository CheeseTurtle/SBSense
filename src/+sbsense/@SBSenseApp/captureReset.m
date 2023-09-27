function captureReset(app, ~, ~) % app, src, ev
    % try
        [vobj, vsrc, TF] = recreateVideoInput(app.vobj);
        if TF
            app.vobj = vobj;
            app.vsrc = vsrc;
        else
            fprintf("Could not recreate video input!\n");
        end
    % catch ME
    % % TODO
    % end
end