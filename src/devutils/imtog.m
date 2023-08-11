function tim = imtog(parent, imgs, opts)
arguments(Input)
    parent (1,1) matlab.graphics.Graphics = matlab.graphics.GraphicsPlaceholder();
end
arguments(Input,Repeating)
    imgs;
end
arguments(Input)
    opts.Period = 0.5;
    opts.Delay = 0;
    opts.Colormap = [];
end
if(isa(parent, 'matlab.graphics.GraphicsPlaceholder'))
    parent = gca; % TODO: or gca? or gcf??
else
    assert(ishghandle(parent));
    if(~isa(parent,'matlab.graphics.axis.Axes'))
        parent = gca(parent);
    end
end
if(isempty(opts.Colormap))
    opts.Colormap = colormap(parent);
end

while(any(cellfun(@iscell, imgs)))
    imgs = [imgs{:}];
end
if(iscell(imgs))
    imgs = cellfun(@im2uint8, imgs, 'UniformOutput', false);
else
    im2uint8(imgs);
end

numImgs = length(imgs);
assert(numImgs > 1);

tims = timerfindall("Name", "imtog");
if(~isempty(tims))
    stop(tims);
    delete(tims);
end

if iscell(opts.Colormap)
    cmap1 = opts.Colormap{1};
    opts.Colormap = opts.Colormap(2:end);
else
    cmap1 = opts.Colormap;
end
startDelay = opts.Delay + opts.Period;
tim = timer("BusyMode", "drop", "ExecutionMode", "fixedSpacing", ...
    "TasksToExecute", numImgs - 1, "Period", opts.Period, ...
    "StartFcn", {@imtog_start, parent}, ...
    "StopFcn", {@imtog_stop, parent, imgs{1}, cmap1, startDelay}, ...
    "ErrorFcn", {@imtog_err}, "StartDelay", startDelay, ...
    "TimerFcn", {@imtog_tick, parent, imgs(2:end), opts.Colormap}, ...
    "Name", "imtog");
try
    imshow(imgs{1}, cmap1, "Parent", parent);
    start(tim);
catch ME
    delete(tim);
    if(ME.identifier ~= "images:imshow:invalidAxes")
        rethrow(ME);
    end
end
end

function imtog_tick(tobj, ~, fig, imgs, cmap)
if(ishghandle(fig))
    if(iscell(cmap))
        cmap = cmap{tobj.TasksExecuted};
    end
    try
        imshow(imgs{tobj.TasksExecuted}, cmap, "Parent", fig);
    catch ME
        if(ME.identifier == "images:imshow:invalidAxes")
            stop(tobj);
        else
            rethrow(ME);
        end
    end
    %fprintf('(tick %d)\n', tobj.TasksExecuted + 1); %tobj.UserData - 1);
else
    %fprintf('(tick %d) Stopping.\n', tobj.TasksExecuted + 1);
    stop(tobj);
    %delete(tobj);
end
end

function imtog_start(tobj, ~, fig)
%fprintf('(start)\n');
if(~ishghandle(fig))
    try
        stop(tobj);
    catch
        delete(tobj);
    end
end
end

function imtog_stop(tobj, ~, fig, img1, cmap1, startDelay)
if(ishghandle(fig))
    pause(startDelay);
    %fprintf('Showing image 1.\n');
    try
        imshow(img1, cmap1, "Parent", fig);
        start(tobj);
    catch ME
        if(ME.identifier == "images:imshow:invalidAxes")
            delete(tobj);
        else
            rethrow(ME);
        end
    end
    %tobj.StartDelay = startDelay;
    %fprintf('(stop) Starting again.\n');
else
    %fprintf('(stop) Stopping\n');
    delete(tobj);
end
end

function imtog_err(tobj,event)
fprintf('(imtog_err) AN ERROR OCCURRED:\n')
fprintf('Field nmes:\n');
disp(fieldnames(event));
fprintf('celldisp:\n');
celldisp(struct2cell(struct(event)));
stop(tobj);
delete(tobj);
end

% meta.class.fromName('matlab.graphics.Graphics').SuperclassList.Name

% [meta.package.getAllPackages{:}]
% isequal(meta.package.getAllPackages{2}.getAllPackages, meta.package.getAllPackages)

% msk = ([cs.Hidden] | ~[cs.isvalid()]'); 
% ps = [meta.package.getAllPackages{:}]; ps = ps(1:200)'; cs = {ps.ClassList}; cs = cat(1,cs{:}); msk = [cs.Hidden]; cs(msk) = []; cns = {cs.Name};

% fns = inmem(); [cfns, ~, cns] = inmem("-completenames");
% msk1 = ~cellfun(@contains, cfns, fns);
% msk2 = cellfun(@contains, cfns, repelem("@", length(cfns), 1));
% msk3 = msk1 & msk2; % sum: 777 = sum(msk1). sum(msk2) = 783.
% msk4 = ~msk1 & ~msk2; % sum: 1695
% msk5 = ~msk1 & msk2; % sum: 6 = sum(msk2) - sum(msk1)
% msk6 = msk1 & ~msk2; % sum: 0
% msk7 = cellfun(@contains,fns, repelem("\", length(fns), 1));
% % Note: sum(msk1 & msk7) = 0. sum(msk2 & ~msk7) = 777. 
% % sum(msk2 & msk7) = 6. sum(~msk2 & msk7) = 61.



% superiorto - MATLAB File Help		
% superiorto
%  superiorto Superior class relationship.
%     This function establishes a precedence that determines which object
%     method is called.  
%  
%     This function is used only from a constructor that uses the 
%     CLASS function to create an object (the only way to create MATLAB 
%     classes in versions prior to MATLAB Version 7.6).
%  
%     superiorto('CLASS1','CLASS2',...) invoked within a class
%     constructor method establishes that class as having precedence over
%     the classes in the function argument list for purposes of function
%     dispatching.
%  
%     For example, suppose that object A is of class 'CLASS_A', object B is 
%     of class 'CLASS_B' and object C is of class 'CLASS_C', and all three
%     classes contain a method named FUN.  Suppose also that constructor
%     method class_c.m contains the statement:
%        superiorto('CLASS_A');
%  
%     This establishes CLASS_C as taking precedence over CLASS_A for function
%     dispatching.  Therefore, either of the following two statements:
%         E = FUN(A,C);
%         E = FUN(C,A);
%     will invoke CLASS_C/FUN.
%  
%     If a function is called with two objects with an unspecified
%     relationship, then the two objects are considered to be of equal
%     precedence and the leftmost object's method is called.  So
%     FUN(B,C) calls CLASS_B/FUN, while FUN(C,B) calls CLASS_C/FUN.
% See also
% inferiorto, class.