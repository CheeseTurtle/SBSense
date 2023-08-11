function [h, gifFile, gifMovie] = imjuxtapose(imgs,filename,opts)
arguments(Input)
    imgs {mustBeA(imgs,'cell'),mustBeNonempty};
    filename = tempname() + ".gif";
    opts.Q {mustBeInteger,mustBeInRange(opts.Q, 1, 65536)} = [2 64 256];
    opts.LoopCount {mustBeNumeric,mustBeScalarOrEmpty,mustBeNonempty, ...
        mustBeNonnegative, mustBeReal} = Inf;
    opts.DelayTime {mustBeNumeric, mustBeVector, ...
        mustBeNonnegative, mustBeReal, mustBeFinite, mustBeNonempty} = 1;
    opts.DelayTimeMode {mustBeMember(opts.DelayTimeMode, ...
        {'Hold', 'Repeat', 'Reflect', 'Delay'})} = 'Hold';
    opts.CircularLoop {mustBeNumericOrLogical} = true;
    opts.imshowOptions {mustBeA(opts.imshowOptions,'cell')} = {};
    opts.FPS {mustBeScalarOrEmpty, mustBeNumeric, mustBePositive} = [];
    opts.FigID {mustBeTextScalar,mustBeNonzeroLengthText} = 'imjuxtapose';
end
%if(isempty(opts.DelayTime))
%    opts.DelayTime = 1;
%end
if(isscalar(opts.DelayTime))
    opts.DelayTime(2:length(imgs)) = opts.DelayTime(1); % 0.8*opts.DelayTime(1);
    opts.DelayTime(1) = 1.5 * opts.DelayTime(1);
end
[gifFile, ~, gifMovie] = writeGIF(filename, imgs, opts.Q, "DelayTime", opts.DelayTime, ...
    "DelayTimeMode", opts.DelayTimeMode, ...
    "CircularLoop", opts.CircularLoop, ...
    "LoopCount", opts.LoopCount);
% disp(size(gifFile));

%if(~strlength(opts.FigName))
%    opts.FigName = "imjuxtapose window";
%end
%fig = figure('Name', opts.FigName);

fig = findobj('Type', 'figure', 'Name', 'Movie Player', 'Tag', opts.FigID);
if(~isempty(fig))
    close(fig);
end

if(isempty(opts.FPS))
    h = implay(gifMovie);
else
    h = implay(gifMovie, opts.FPS);
end

set(0,'showHiddenHandles','on');
fig_handle = h.Parent;
set(fig_handle,  'Tag', opts.FigID);
% fig_handle.findobj % to view all the linked objects with the vision.VideoPlayer
ftw1 = fig_handle.findobj ('TooltipString', 'Maintain fit to window');   % this will search the object in the figure which has the respective 'TooltipString' parameter.
ftw2 = fig_handle.findobj('Text', '&Repeat');
% ftw3 = fig_handle.findobj('Text', 'Forward &play');
ftw3 = fig_handle.findobj('Text', 'AutoReverse pla&y');
%ftw4 = fig_handle.findobj('Text', '&Playback').Children(1);
ftw4 = fig_handle.findobj('Text', 'Play');
if(~ftw1.State)
    ftw1.ClickedCallback();  % execute the callback linked with this object
end
if(~ftw2.Checked)
    ftw2.MenuSelectedFcn();
end
if(~ftw3.Checked)
    ftw3.MenuSelectedFcn();
end
%if(ftw4.Text == "Play")
%    ftw4.MenuSelectedFcn();
%end
if(~isempty(ftw4))
    ftw4.MenuSelectedFcn();
end
% set(0,'showHiddenHandles','off'); % TODO