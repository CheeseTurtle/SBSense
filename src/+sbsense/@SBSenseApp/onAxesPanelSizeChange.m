function onAxesPanelSizeChange(~,src,~)%app, src, event)
%arguments(Input)
    %app sbsense.SBSenseApp;
    %src matlab.ui.container.Panel;
    %event matlab.ui.eventdata.SizeChangedData;
    % NOT matlab.graphics.eventdata.SizeChanged or matlab.graphics.eventdata.GridSizeChanged 
%end
% app.PosAxes.InnerPosition([1 3]) = app.HgtAxes.InnerPosition([1 3]);
%set([app.PosAxes app.HgtAxes], 'InnerPosition', ...
%    [0 0 app.FPAxesGridPanel.InnerPosition([3 4])]);
%leftInset = max(src.OuterPosition([1 3]) - src.InnerPosition([1 3]));
%src.Children(1).InnerPosition = [1+leftInset 1 ...
%    (src.InnerPosition([3 4]) - [leftInset 0])];

% persistent fut;
% if ~isempty(fut)
%     cancel(fut);
% end

ax1 = src.UserData; %src.UserData{2}; %src.Children(2);
ax1.OuterPosition = [0 0 src.InnerPosition([3 4])];
% 
% if ax1.UserData{3}.Visible
%     ax1.UserData{3}.Visible = false;
% end

% ax1.OuterPosition([2 4]) = [0 src.InnerPosition(4)+1];


ax2 = ax1.UserData{2}; ax2.OuterPosition = [0 0 ax2.Parent.InnerPosition([3 4])];

% difp = ax2.InnerPosition(1) - ax1.InnerPosition(1);
% if difp > 0 % This axis has wider left margin and needs to be moved to the right
%     % ax1.InnerPosition([1 3]) = ax1.InnerPosition([1 3]) + [difp -difp];
%     ax1.InnerPosition(1) = ax1.InnerPosition(1) + difp;
% elseif difp < 0 % This axis has narrower left margin; the other one needs to be moved to the right
%     % ax2.InnerPosition([1 3]) = ax1.InnerPosition([1 3]);
%     ax2.InnerPosition(1) = ax1.InnerPosition(1);
% end

[p,pIdx] = max([ax1.InnerPosition(1) ax2.InnerPosition(1)], [], 2);
fs = sum([ ax1.InnerPosition([1 3]) ; ax2.InnerPosition([1 3])], 2);
[f,fIdx] = min(fs);
w = f - p + 1;

% pw = [p, f-p+1];
%ax1.InnerPosition([1 3]) = pw;
%ax2.InnerPosition([1 3]) = pw;

% posChanged = false; % TODO??

if bitget(pIdx,1)
    ax2.InnerPosition([1 3]) = [p w];
    if fIdx ~= pIdx
        ax1.InnerPosition(3) = w;
    end
else
    ax1.InnerPosition([1 3]) = [p w];
    if fIdx ~= pIdx
        ax2.InnerPosition(3) = w;
    end
end


% fut = parfeval(backgroundPool, @() pause(2), 0);
% fut = [fut afterEach(fut, @() set(ax1.UserData{3}, 'Visible', true), 0)];
ax1.UserData{3}.Position([1 3]) ...
    = ax2.InnerPosition([1 3]) + [-2 4];

% if ~isempty(ax1.Legend)
%     try
%        % Get panel position
%        panpos = src.UserData{1}.InnerPosition; % (relative to parent of Y panel -- also parent of src panel)


%     catch ME
%         fprintf('[onAxesPanelSizeChange] Error occurred while attempting to update legend position: %s\n', getReport(ME));
%     end 
% end

drawnow nocallbacks;

end