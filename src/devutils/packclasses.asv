function [Cs, cns] = packclasses(packnames, varargin)
if nargin > 1
    recurse = varargin{1};
    includeInternal = (nargin>3) && varargin{2};
else
    recurse = true;
    includeInternal = false;
end
if ~iscell(packnames)
    packnames = cellstr(packnames);
end
packs = getsubpacks(cellfun(@meta.package.fromName, cellstr(packnames), ...
    'UniformOutput', false), includeInternal, recurse)';
%fprintf('Packs:\n');
% disp(packs);
% packs = vertcat(packs{:});
Cs = {packs.ClassList};%cellfun(@(x) x.ClassList, packs, 'UniformOutput', false);
%disp(Cs);
Cs = vertcat(Cs{:});
if nargout>1
    cns = [Cs.Name];
end
end

function Ps = getsubpacks(packsCell, includeInternal, varargin)
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
                    @packclasses_filterinternal, ...
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
            subpacksMask = ~cellfun(@packclasses_filterinternal, ...
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
                @packclasses_filterinternal, ...
                subpacks, 'UniformOutput', true);
            %if any(cellfun(@iscell, subpacks))
            %    subpacks = subpacks{:};
            %end
            %display(subpacks);
            %subpacksMask = ~contains({subpacks.Name}, '.internal');
            subpacks = subpacks(subpacksMask);
        end
        %Ps0 = cellfun(@getsubpacks, subpacks, 'UniformOutput', false);
        Ps0 = cellfun(@(p) getsubpacks(p, includeInternal), ...
            subpacks, 'UniformOutput', false);
        % disp(Ps0);
    else
        if ~includeInternal % && (nargin<3) % TODO: Remove second cond if not even first-child internal
            subpacksMask = ~contains({subpacks.Name}, '.internal');
            subpacks = subpacks(subpacksMask);
        end
        Ps0 =  getsubpacks(subpacks, includeInternal);
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


function val = packclasses_filterinternal(c) 
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