% [Fs,fns,pns] or [Struct,fns,pns] -- Does NOT include methods defined in
% classes
function varargout = packfunctions(packnames, varargin)
if nargin > 1
    recurse = varargin{1};
    if nargin > 2
        includeInternal = varargin{2};
        groupByPackage = (nargin > 3) && varargin{3};
    else
        includeInternal = false;
        groupByPackage = false;
    end
else
    recurse = true;
    includeInternal = false;
    groupByPackage = false;
end
if ~iscell(packnames)
    packnames = cellstr(packnames);
end
if groupByPackage
    % vout0 = cell(1,1+(nargout>1));
    % args = varargin(1:min(nargin-1,2));
    % [vout0{:}] = packfunctions(args{:});
    % res = cellfun(@(pn) packfunctions({pn}, includeInternal, recurse), ...
    %    packnames, 'UniformOutput', false);
    % packs is an array of meta.package objects
    packs = getsubpacks_fcns(cellfun(@meta.package.fromName, packnames, ...
        'UniformOutput', false), includeInternal, recurse)';
    packFuncs = {packs.FunctionList};
    vout = {struct.empty(), cell.empty(), {packs.Name}};
    vout{1} = struct(packFuncs, vout{3});
    % Assumes that 1<=nargout<=3
    if ~bitxor(nargout,1) % nargout==1
        varargout = vout(1); % Range including first cell only
    else
        % cellfun(@(Fs) string({Fs.Name}'), packFuncs, 'UniformOutput', false)
        % is equivalent to
        % cellfun(@(Fs) {string({Fs.Name}')}, packFuncs, 'UniformOutput', true)
        vout{2} = cellfun(@(Fs) string({Fs.Name}'), packFuncs, ...
            'UniformOutput', false);
        % vertcat(vout{2}{:}) ==> string array
        varargout = vout(1:nargout);
    end
else
    packs = getsubpacks_fcns(cellfun(@meta.package.fromName, packnames, ...
        'UniformOutput', false), includeInternal, recurse)';
    varargout{1} = {packs.FunctionList};
    varargout{1} = vertcat(varargout{1}{:});
    if nargout>1
        varargout{2} = [varargout{1}.Name];
        if bitand(nargout,1) % nargout==3
            varargout{3} = {packs.Name}';
            % varargout{3} = vertcat(packs.Name); % Wrap in cellstr(...)?
        end
    end
end
end

function Ps = getsubpacks_fcns(packsCell, includeInternal, varargin)
%disp(packsCell);
if isempty(packsCell)
    Ps = [];
    return;
elseif iscell(packsCell)
    %celldisp(packsCell);
    subpacks = cellfun(@(p) p.PackageList, packsCell, 'UniformOutput', false);
    msk = cellfun(@isempty, subpacks);
    %fprintf('packsCell (%d): %s\n', sum(~msk), ...
    %    join(string(cellfun(@(x) x.Name, packsCell, 'UniformOutput', false)), ", "));
    % sps = vertcat(subpacks{:});
    %fprintf('packsCell (%d): %s (%s)\n', sum(~msk), ...
    %join(string(cellfun(@(x) x.Name, packsCell, 'UniformOutput', false)), ", "), ...
    %join(string({sps.Name}), ", "));
elseif isa(packsCell, 'meta.package')
    %display(packsCell);
    subpacks = {packsCell.PackageList};
    msk = cellfun(@(x) isempty({x.PackageList}), subpacks);
    % fprintf('Package (%d): %s\n', sum(~msk), packsCell.Name);
    % sps = vertcat(subpacks{:});
    %fprintf('Package (%d): %s (%s)\n', length(subpacks), ...
    %    packsCell.Name, ...
    %join(string({sps.Name}), ", "));
else
    error('Invalid packageCell class: %s\n', class(packageCell));
end
%celldisp(subpacks);

% msk = ~isempty([subpacks{:}]);
% disp(subpacks);
% subpacks2 = subpacks(msk);
if ((nargin>2) && ~varargin{1}) || all(msk) %isempty(subpacks2)
    if iscell(packsCell)
       if iscell(subpacks) && (isequal(size(subpacks), [1 1]) ...
            || any(cellfun(@iscell,subpacks)))
            %subpacks = subpacks{1};
            subpacks = [subpacks{:}];
        end
        if iscell(subpacks)
            if ~includeInternal %&& (nargin<3)
                %display(subpacks);
                subpacks = subpacks(~cellfun(@isempty,subpacks));
                subpacksMask = ~cellfun(...
                    @packfunctions_filterinternal, ...
                    subpacks, 'UniformOutput', true);
                subpacks = subpacks(subpacksMask);
            end
            Ps = vertcat(packsCell{:}, subpacks{:});
        else
            if ~includeInternal %&& (nargin<3)
                subpacksMask = ~contains({subpacks.Name}, '.internal');
                subpacks = subpacks(subpacksMask);
            end
            Ps = vertcat(packsCell{:}, subpacks);
        end
    elseif iscell(subpacks)
        subpacks = subpacks(~cellfun(@isempty,subpacks));
        if ~includeInternal %&& (nargin<3)
            subpacksMask = ~cellfun(@packfunctions_filterinternal, ...
            subpacks, 'UniformOutput', true);
            subpacks = subpacks(subpacksMask);
        end
        Ps = vertcat(packsCell, subpacks{:});
    else
        if ~includeInternal %&& (nargin<3)
            subpacksMask = ~contains({subpacks.Name}, '.internal');
            subpacks = subpacks(subpacksMask);
        end
        Ps = vertcat(packsCell, subpacks);
    end
    %if ~iscell(Ps)
    %    Ps = arrayfun(@(x) x, Ps, 'UniformOutput',false);
    %end
    % fprintf('[[Ps: %s]]', formattedDisplayText(Ps));
else
    %Ps = cellfun(@getsubpacks,subpacks2,'UniformOutput',false);
    % Ps = getsubpacks(subpacks2);
    % disp({size(subpacks), size(Ps)});
    %Ps0 = vertcat(packsCell{:}, subpacks{:});
    %Ps0 = arrayfun(@(x) x, Ps0, 'UniformOutput',false);
    if iscell(subpacks) && (isequal(size(subpacks), [1 1]) ...
            || any(cellfun(@iscell,subpacks)))
        subpacks = [subpacks{:}];
    end
    if iscell(subpacks)
        subpacks = subpacks(~cellfun(@isempty,subpacks));
        if ~includeInternal % && (nargin<3) % TODO: Remove second cond if not even first-child internal
            %celldisp(subpacks);
            %for i=1:length(subpacks)
            %    disp({subpacks{i}.Name});
            %end
            %disp(cellfun(@(sp) sp.Name, subpacks, 'UniformOutput', false));
            subpacksMask = ~cellfun(...
                @packfunctions_filterinternal, ...
                subpacks, 'UniformOutput', true);
            %if any(cellfun(@iscell, subpacks))
            %    subpacks = subpacks{:};
            %end
            %display(subpacks);
            %subpacksMask = ~contains({subpacks.Name}, '.internal');
            subpacks = subpacks(subpacksMask);
        end
        %Ps0 = cellfun(@getsubpacks, subpacks, 'UniformOutput', false);
        Ps0 = cellfun(@(p) getsubpacks_fcns(p, includeInternal), ...
            subpacks, 'UniformOutput', false);
        % disp(Ps0);
    else
        if ~includeInternal % && (nargin<3) % TODO: Remove second cond if not even first-child internal
            subpacksMask = ~contains({subpacks.Name}, '.internal');
            subpacks = subpacks(subpacksMask);
        end
        Ps0 =  getsubpacks_fcns(subpacks, includeInternal);
        if ~iscell(Ps0)
            Ps0 = arrayfun(@(x) x, Ps0, 'UniformOutput',false);
        end
    end
    if isa(packsCell, 'meta.package') && isscalar(packsCell)
        packsCell = {packsCell};
        Ps = vertcat(packsCell{:}, vertcat(Ps0{:}));
    else
        if iscell(packsCell)
            packsCell = packsCell(~cellfun(@isempty,packsCell));
        else
            packsCell = arrayfun(@(x) x, packsCell, 'UniformOutput', false);
        end
        Ps = vertcat(packsCell{:}, Ps0{:});
    end
end
end


function val = packfunctions_filterinternal(c) 
val = ~all(contains({c.Name}, '.internal'));
%return;
%if isempty(c)
%    val = logical.empty();
%else
%    val = contains({c.Name}, '.internal');
%end
end
% Cs = packclasses('imaq'); string({Cs.Name})'

% string({packclasses('matlab.ui').Name})';
% string({setdiff(packclasses('matlab.ui'), packclasses('matlab')).Name})'

% string({packclasses('matlab.ui.control').Name})'
% string({setdiff(packclasses('matlab.ui.control.internal'), packclasses('matlab.ui.control')).Name})'
% string({setdiff(packclasses('matlab.ui.control.internal.model'), packclasses('matlab.ui.control.internal.controller')).Name})'
% string({setdiff(packclasses('matlab.ui.control.internal'), packclasses('matlab.ui.control.internal.controller')).Name})'