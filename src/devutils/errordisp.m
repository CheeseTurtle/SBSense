
function errordisp(prefix, ME, context, maxdepth, opts)
arguments(Input)
    prefix;
    ME = MException.empty();
    context = '';
    maxdepth = 2;
    opts.FileID = 1;
    opts.JumpToBase logical = true; % stack
    opts.JumpToRoot logical = true; % cause
    opts.NoError logical = true;
    opts.IncludeCause logical = true;
    opts.IncludeCorrection logical = false;
    opts.IncludeStack logical = true;
    opts.IncludeReport logical = true;
    opts.MaxCauseDepth = maxdepth;
    opts.MaxStackDepth = maxdepth;
end
if isa(prefix, 'MException')
    if ~isempty(ME)
        context = ME;
    end
    ME = prefix;
    prefix = '';
elseif ~opts.NoError
    assert(isa(ME, 'MException'));
    assert(isempty(prefix) || isa(prefix, 'char') || isa(prefix, 'string'));
end % TODO: Option for what to do with invalid argument values
if ~opts.NoError
    assert(isempty(context) || isa(context, 'char') || isa(context, 'string'));
end
if ~isempty(prefix) && (isa(prefix, 'char') || logical(strlength(prefix)))
    prefix = sprintf("[%s]", prefix);
else
    prefix = '';
end
if ~isempty(context) && (isa(context, 'char') || logical(strlength(context)))
    context = sprintf("in context '%s'", context);
else
    context = '';
end


causeInfo = {};

if opts.IncludeStack
    stackDepth = length(ME.stack); % Structure arrayop
    stackInfo = struct('Depth', {}, 'Index', 'File', {}, 'Name', {}, 'Line', {});
    
else
    stackStr = '';
end

if opts.IncludeCause
else
    causeStr = '';
end

% 
% matlab.lang.correction.AppendArgumentsCorrection | matlab.lang.correction.ConvertToFunctionNotationCorrection | matlab.lang.correction.ReplaceIdentifierCorrection
if opts.IncludeCorrection
else
    corrStr = '';
end

if opts.IncludeReport
else
    reportStr = '';
end
end

function [S,TF,maxDepth] = getStackInfo(varargin)
narginchk(1,3);
ME = varargin{1};
assert(isa(ME, 'MException'));
numLevels = size(ME.stack,1);
%if ~numLevels
S = struct('depth', {}, 'file', {}, 'name', {}, 'line', {});
%end
if nargin>1
    maxDepth = varargin{2};
    assert(maxDepth >= 1);
else
    maxDepth = Inf;
end

jumpToEnd = ((nargin < 3) || logical(varargin{3}));
%S = struct('Depth', {}, 'File', {}, 'Name', {}, 'Line', {});
%S = struct.empty(0,maxDepth);
if (numLevels > (maxDepth+1)) && jumpToEnd
    dif = numLevels - maxDepth;
    if dif >= 2
        en1 = 1;
        st2 = numLevels - dif + 2;
    else
        en1 = 2;
        st2 = numLevels - (dif - 2) + 1;
    end
    i=1;
    for d=1:en1
        S(i) = setfield(ME.stack(d), 'depth', d);
        i = i+1;
    end
    for d=st2:numLevels
        S(i) = setfield(ME.stack(d), 'depth', d);
        i = i+1;
    end
else
    for i=1:min(maxDepth,numLevels)
        S(i) = setfield(ME.stack(i), 'depth', i);
    end
    TF = (maxDepth <= numLevels);
    if ~TF
        maxDepth = numLevels;
    end
end
end

function str = getStackString(stackInfo,baseIndentLvl,indentUnit,indentLead) % array
arguments(Input)
    stackInfo (:,1) struct;
    baseIndentLvl = 0;
    indentUnit = 2;
    indentLead = '';
end
N = size(stackInfo,1);
strs = strings(N,1);
indentStr = makeIndentString(baseIndentLvl,indentUnit,indentLead);
headerStr = sprintf("%1$sSTACK FRAMES (%2$d):\n", ...
    indentStr, N);
if ~isnumeric(indentUnit)
    indentUnit = max(2,strlength(indentUnit));
else
    indentUnit = max(2,indentUnit);
end
indentStr2 = makeIndentString(0, ...
    repelem(' ',min(4,(baseIndentLvl+1)), indentStr);
indentUnit = max(2,2\indentUnit);
indentStr3 = indentStr2 + repelem(' ', indentUnit);
indentStr1 = indentStr2(1:end-4);
lastLvl = 1;
for i=1:N
    stk = stackInfo(i);
    str = sprintf("%s%02d) %s", ...
        indentStr1, i, ...
        getStackFrameString(stk,indentStr2, indentStr3,true));
    thisLvl = stk.depth;
    lvlDif = thisLvl - lastLvl;
    if lvlDif > 1
        str = str + sprintf("\n%s ...", indentStr1);
    end
    strs(i) = str;
end
str = headerStr + join(strs, "\n");
end

function str = getStackFrameString(stackInfo,indentLead1,indentLead2,dontindentfirst) % scalar
len1 = 80 - strlength(indentLead1);
len2 = 80 - strlength(indentLead2);
stackInfo.file = "file: " + stackInfo.file;
stackInfo.name = "name: " + stackInfo.name;
stackInfo.line = sprintf("line: %d", stackInfo.line);
stackInfo.file = partitionstring(stackInfo.file, len1, len2);
stackInfo.name = partitionstring(stackInfo.name, len1, len2);
stackInfo.file = join(stackInfo.file, "\n"+indentLead2);
stackInfo.name = join(stackInfo.name, "\n"+indentLead2);
str = sprintf("%2$s\n%1$s%2$s\n%1$sline: %3$d", ...
    indentLead1, stackInfo.file, stackInfo.name, stackInfo.line);
if ~dontindentfirst
    str = indentLead1 + str;
end
end

function str = makeIndentString(baseIndentLvl,indentUnit,indentLead)
arguments(Input)
    baseIndentLvl = 1;
    indentUnit = 2;
    indentLead = '';
end
if isnumeric(indentUnit)
    indentUnitLen = indentUnit;
    indentUnit = ' ';%repelem(' ', indentUnitLen);
    baseIndentLvl = baseIndentLvl*indentUnitLen;
else%if ischar(indentUnit) || isstring(indentUnit)
    indentUnitLen = strlength(indentUnit);
end
indentAmount = baseIndentLvl*indentUnitLen;
if ~isempty(indentLead)
    if isnumeric(indentLead)
        indentLeadLen = indentLead;
        indentLead = repelem(' ', indentLead);
    else
        indentLeadLen = strlength(indentLead);
    end
    if indentAmount > indentLeadLen
        indentAmount = indentAmount - indentLeadLen;
    else
        indentLead = indentLead(1:indentAmount);
        indentAmount = 0;
    end 
end
if indentAmount
    if indentUnit == " "
        str = indentLead + repelem(' ', indentAmount);
    else
        numReps = idivide(uint8(indentAmount) / uint8(indentUnitLen), "fix");
        numRem  = mod(indentAmount, indentUnitLen);
        str = indentLead + repelem(indentUnit,numReps) + ...
            indentUnit(1:numRem);
    end
else
    str = indentLead;
end
end

function getCauseString(causeInfos, baseIndentLvl,indentUnit,indentLead) % array
arguments(Input)
    causeInfos cell;
    baseIndentLvl = 0;
    indentUnit = 2;
    indentLead = '';
end

end

function causeInfos = getCauseInfo(varargin)
narginchk(1,4);
MEs = varargin{1};
if iscell(MEs)
    % assert(isa(MEs, 'MException'));
    MEs = {MEs};
end
numCauses = size(MEs.cause,1);
%if ~numLevels
causeInfos = cell(1,numCauses);
%causeInfos(:) = {S};
%end
if nargin>1
    maxDepth = varargin{2};
    assert(maxDepth >= 1);
    if nargin > 3
        currDepth = varargin{4};
    else
        currDepth = 1;
    end
else
    maxDepth = Inf;
    currDepth = 1;
end
jumpToEnd = ((nargin < 3) || logical(varargin{3}));
nextDepth = currDepth + 1;
for idx=1:numCauses
    ME = MEs{idx};
    if isempty(ME.cause)%(currDepth >= maxDepth) || isempty(ME.cause)
        causeInfos{idx} = struct('depth', currDepth, 'index', idx, ...
            'identifier', ME.identifier, 'message', ME.message, ...
            'stack', getStackInfo(ME.stack,maxDepth,true));
    else
        causeInfos{idx} = getCauseInfo(ME.cause, maxDepth, ...
            jumpToEnd, nextDepth);
    end
end
end


% tm = timer('Period', 10, 'TasksToExecute', 100, 'ExecutionMode', 'fixedRate', 'TimerFcn', @(tobj,e) disp(setfield(setfield(e.Data, 'UserData', tobj.UserData), 'EventType', e.Type)))
%start(tm);
%tm.UserData = @disp;
%tm.StopFcn = tm.TimerFcn;
%stop(tm);