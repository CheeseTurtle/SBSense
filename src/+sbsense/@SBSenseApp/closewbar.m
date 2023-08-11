function closewbar(app,varargin)
% matlab.ui.eventdata.WindowCloseRequestData
% celldisp(varargin);
try
    % figure(wbar);
    closereq;
    delete(app.wbar);
catch ME
    fprintf('Error "%s" occurred while trying to close wbar waitbar dialog: %s\n', ...
        ME.identifier, getReport(ME));
end
try
    delete(app);
catch ME
    fprintf('Error "%s" occurred while trying to delete app after closing waitbar dialog: %s\n', ...
        ME.identifier, getReport(ME));
end
end

% function closereq
% %CLOSEREQ  Figure close request function.
% %   CLOSEREQ deletes the current figure window.  By default, CLOSEREQ is
% %   the CloseRequestFcn for new figures.
% 
% %   Copyright 1984-2012 The MathWorks, Inc.
% 
% %   Note that closereq now honors the user's ShowHiddenHandles setting
% %   during figure deletion.  This means that deletion listeners and
% %   DeleteFcns will now operate in an environment which is not guaranteed
% %   to show hidden handles.
% if isempty(gcbf)
%     if length(dbstack) == 1
%         warning(message('MATLAB:closereq:ObsoleteUsage'));
%     end
%     close('force');
% else
%     delete(gcbf);
% end
% end