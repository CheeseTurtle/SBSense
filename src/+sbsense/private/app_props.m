classdef app_props
properties(GetAccess=public, Dependent, SetAccess=private)
    ConfirmStatus;
end
properties(GetAccess=public,SetAccess=immutable,Dependent)
    InZoomMode;
end

methods
    function value = get.ConfirmStatus(obj)
        value = obj.RecButton.Enable; % TODO: Object name
    end
    function set.ConfirmStatus(obj, value)
        if ~xor(obj.RecButton.Enable, value)
            return;
        end
        % TODO: Try/catch
        % TODO: Enable/disable rec controls
        obj.RecButton.Enable = value;
        if value
            set(obj.ConfirmLayoutButton, 'Enable', false, ...
            'Icon', []);
            % TODO: Other confirm stuff
            % TODO: Change tooltips
        else
            set(obj.ConfirmLayoutButton, 'Enable', true,
                'Icon', 'success');
            % TODO: Change tooltips
        end
    end

    function value = get.InZoomMode(app)
        value = logical(app.LockRangeButton.Value);
    end
end
end