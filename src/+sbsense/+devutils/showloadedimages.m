fig = findobj('Type','Figure', 'Name', 'Loaded Images Window');
if(isempty(fig) || isa(fig, 'matlab.graphics.GraphicsPlaceholder class'))
    fig = figure("Visible", "off", "Name", "Loaded Images Window", "NumberTitle", "off", ...
        "WindowState", "normal", "WindowStyle", "normal", "GraphicsSmoothing", "on", ...
        "Scrollable", "true", "Clipping", "off", "DockControls", "on", "HandleVisibility", "on", ...
        "Resize", "on", "Interruptible", "on", "IntegerHandle", "on", ...
        "Pointer", "crosshair", "InvertHardcopy", "on", "PaperUnits", "inches", ...
        "PaperType","usletter", "Units", "normalized", "MenuBar", "figure", ...
        "BusyAction", "queue", "SelectionType", "alt", ...
        "ToolBar", "none", 'NextPlot', 'replacechildren');
    %clf('reset');
    %tl = tiledlayout(fig, 8, 8, "PositionConstraint", "innerposition");
else
%     if(length(fig) > 1)
%         figs = fig;
%         fig  = figs(1);
%         for i=2:length(figs)
%             delete(figs(i));
%         end
%         %figs(1) = [];
%         %delete(figs);
%         clearvars("figs");
%         % set(fig, 'Visible', 'off');
%     end
end
disp(fig.Name);
tl = findobj(get(fig,'Children'), 'Type', 'TiledChartLayout', 'Tag', 'mainTL');
if(isempty(tl))
    tl = findobj(get(fig,'Children'), 'Type', 'tiledlayout', 'Tag', 'mainTL');
end
disp(fig.Name);
if(isempty(tl))
    fprintf('Could not find tl.\n');
    tl = tiledlayout(fig, 'flow', ...
        'Tag', 'mainTL', ...
        'TileSpacing', 'tight', ...
        'Padding', 'tight', ...
        'BusyAction', 'queue', ...
        'Units', 'normalized', ...
        'TileIndexing', 'rowmajor', ...
        'Interruptible', 'on');
        %'PositionConstraint', 'outerposition');%, ...
        %'Title', matlab.graphics.layout.Text("String", "Title"), ...
        %'Subtitle', matlab.graphics.layout.Text("String", "Subtitle"));
else
    delete(tl.Children);
    if(length(tl)>1)
    %fprintf('Found tl.\n');
    %tls = tl;
    %tl  = tls(1);
    %for i=2:length(tls)
    %    %delete(tls(i));
    %end
    %tls(1) = [];
    %delete(tls);
    %clearvars("tls");
    end
end
%set(fig, 'NextPlot', 'add');
%cla('reset');
set(tl, 'TileSpacing', 'compact', 'Padding', 'tight');

tl1 = tiledlayout(tl, 2, numImgs+2);
tl1.Layout.Tile = 1;
tl1.Layout.TileSpan = [5 3];
set(tl1, 'TileSpacing', 'none', 'Padding', 'tight');

ax = nexttile(tl1, 1, [1 2]);
otherBG = {'BGimga', 'BGimgb', 'BGimg', 'BGimgf'}; % 'BGimg_5', 'BGimg_6'
numImgs = length(otherBG);
image(ax,imtile(frames_bg, colormap("hot")), 'CDataMapping', 'direct');%,...
   % 'BackgroundColor', 'green', 'Frames', 1:2));
% montage(frames_bg, colormap("hot"), "Indices", 1:2, "Parent", ax, "Interpolation","nearest");
title(ax, 'frames_bg', 'Interpreter','none');

box(ax, "on");
set(ax, 'LineWidth', 1);
set(ax, 'GridAlpha', 0.2);
set(ax, 'XGrid', 'on');
set(ax, 'YGrid', 'on');

for i=1:numImgs
    ax = nexttile(tl1, i+2, [1 1]);
    cla;
    image(ax, eval(otherBG{i}), 'CDataMapping', 'direct');
    colormap(ax,"hot");
    %set(ax.XAxis, 'Visible', 'off');
    %set(ax.YAxis, 'Visible', 'off');
    box(ax, "on");
    set(ax, 'LineWidth', 1);
    set(ax, 'GridAlpha', 0.2);
    set(ax, 'XGrid', 'on');
    set(ax, 'YGrid', 'on');
    title(ax,otherBG{i}, 'Interpreter','none');
end

%numImgs = size(frames_s1, 3);
%tl2 = tiledlayout(tl, 3, 2);
ax = nexttile(tl, [3 2]);
%imshow(imtile(frames_s1, colormap("gray"), "GridSize", [3 10]), colormap("gray"));%, "Parent", ax);
montage(frames_s1, colormap("gray"), "Size", [3 10], "Parent", ax);
title(ax, "frames_s1", 'Interpreter','none');
%[r,c] = tilerowcol(tl, til-enum(ax));

%tl3 = tiledlayout(tl, 2, 1);
%ax = nexttile(tl, tilenum(tl, r+3, c), [2 2]);
% ax = nexttile(tl, [2 2]);
tl2 = tiledlayout(tl, 8, 5);
tl2.Layout.Tile = 3;
tl2.Layout.TileSpan = [5 5];
ax = nexttile(tl2, 1, [2 5]);
montage(frames_s2_5, colormap("gray"), "Size", [2 10], "Parent", ax);
ylabel(ax, "s2_5", 'Interpreter', 'none');
ax = nexttile(tl2, [2 5]);
%imshow(imtile(frames_s2_6, colormap("gray"), "GridSize", [2 10]), colormap("gray"), "Parent", ax);
montage(frames_s2_6, colormap("gray"), "Size", [2 10], "Parent", ax);
ylabel(ax, "2_6", 'Interpreter', 'none');
ax = nexttile(tl2, [2 5]);
%imshow(imtile(frames_s2_7, colormap("gray"), "GridSize", [2 10]), colormap("gray"), "Parent", ax);
montage(frames_s2_7, colormap("gray"), "Size", [2 10], "Parent", ax);
ylabel(ax, "s2_7", 'Interpreter', 'none');
ax = nexttile(tl2, [2 5]);
%imshow(imtile(frames_s2_8, colormap("gray"), "GridSize", [2 10]), colormap("gray"), "Parent", ax);
montage(frames_s2_8, colormap("gray"), "Size", [2 10], "Parent", ax);
% title(ax, "Hello", "Rotation", 90);
ylabel(ax, "s2_8", 'Interpreter', 'none');


ax = nexttile(tl, [1 3]);
montage({S2imgc,S2imga,S2imgb, S2img_blur, S2imga_blur, S2imgb_blur}, ...
    colormap("hsv"), ...
    'Size', [2 3], 'Parent', ax);
title(ax, "S2(c), S2a, S2b");
ylabel(ax, "blur / original");
ax = nexttile(tl, [1 2]);
montage({S2img_blura, S2img_blur}, colormap("hsv"), ...
    'Size', [1 2], 'Parent', ax, 'BorderSize', 8, 'BackgroundColor', 'green');
title("S2: blura, blurb");

% tl3 = tiledlayout(tl, 3, 5);
% tl3.Layout.Tile = 4;
% tl3.Layout.TileSpan = [3 5];
% title(tl3, "S2img");
% 
% ax = nexttile(tl3, [3 1]);
% title(ax, "a");
% 
% 
% ax = nexttile(tl3, [3 1]);
% title(ax, "b");
% 
% ax = nexttile(tl3, [3 1]);
% title(ax, "blur");

drawnow limitrate;

set(fig, 'Visible', 'on');