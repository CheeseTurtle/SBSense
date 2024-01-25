function [S, cns] = subclasses(obj, opts)
arguments(Input)
    obj = logical.empty();
    opts.ClassName {mustBeNonzeroLengthText} = '<>';
    opts.Abstract {mustBeMember(opts.Abstract, {'include', 'exclude', 'require'})} = 'include';
    opts.Hidden {mustBeMember(opts.Hidden, {'include', 'exclude', 'require'})} = 'include';
    opts.Sealed {mustBeMember(opts.Sealed, {'include', 'exclude', 'require'})} = 'include';
    opts.Enum {mustBeMember(opts.Enum, {'include', 'exclude', 'require'})} = 'include';
    opts.HandleCompat {mustBeMember(opts.HandleCompat, {'include', 'exclude', 'require'})} = 'include';
    opts.MinInferiors {mustBeNonnegative, mustBeInteger} = 0;
    opts.MinSuperiors {mustBeNonnegative, mustBeInteger} = 0;
    opts.SearchAllInMem logical = true;
    opts.RecursiveSubSearch logical = true;
    opts.IncludeExplicitInferiors = true;
    opts.MaxChildDistance {mustBeNonnegative, mustBeInteger} = 0;
end
if (opts.ClassName ~= "<>") && (islogical(obj) && isequal(obj, logical.empty()))
    classname = opts.ClassName;
    c = meta.class.fromName(classname);  % c.SuperclassList.Name
else
    % classname = class(obj);
    c = metaclass(obj);
end

ics0 = c.InferiorClasses;
if(isempty(ics0))
    icns0 = ics0;
else
    icns0 = {ics0.Name};
end

cs1a = [meta.class.getAllClasses{:}];
cns1a = {cs1a.Name};
[cns1b, ia] = setdiff(cns1a, icns0);
cs1b = cs1a(ia);

% [csn1, ia, ib] = setxor(icns0, cs1b);
cns1 = cat(2, icns0{:}, cns1b{:});
% cs1 = {ics0{:} cs1b{:}};
%disp(cs1b);
[cs,msk1b] = filterclasses(cs1b, opts.Abstract, opts.Hidden, ...
    opts.Sealed, opts.Enum, opts.HandleCompat, ...
    opts.MinInferiors, opts.MinSuperiors, opts.RecursiveSubSearch);
cns = cns1b(msk1b);

if opts.SearchAllInMem
    [~,~,cns2] = inmem();
    cns2 = setdiff(cns2, cns1, 'stable'); % cns2 = cns2';
    cs2 = cellfun(@meta.class.fromName, cns2, 'UniformOutput', false);
    [cs2, msk2] = filterclasses([cs2{:}], opts.Abstract, opts.Hidden, ...
        opts.Sealed, opts.Enum, opts.HandleCompat, ...
        opts.MinInferiors, opts.MinSuperiors, opts.RecursiveSubSearch);
    cns2 = cns2(msk2);
    cs = [cs cs2];
    cns = [ cns(:) ; cns2(:) ];
end


supernames = [classname ; c.Aliases(:)];
if (opts.MaxChildDistance && (opts.MaxChildDistance==1)) % TODO: Distance
    mask = ismember(cns, supernames);
    %subnames = cns(mask);
    cns = cns(mask);
    cs = cs(mask);
    S = cs;
else
    subsupers0 = {cs.SuperclassList};
    subsupers = cat(1, subsupers0{:});
    subsupernames = unique({subsupers.Name});
    %supermask  = false(size(supernames));
    subsupermask  = cellfun(@(supname) ...
        checkancestry(metaclass(supname), supernames), ...
        subsupernames, 'UniformOutput', true);
    subsupers = cellfun( ...
        @(sups) {sups.Name}, subsupers0, 'UniformOutput', false);
    subsupernames = subsupernames(subsupermask);
    csmask = cellfun(@(supnames) any(ismember(supnames, subsupernames)), ...
        subsupers, 'UniformOutput', true);
    cs = cs(csmask);
    cns = cns(csmask);
    S = cs;
end

end

function [cs,msk] = filterclasses(cs, abstr, hidd, seal, enum, handcomp, ...
    mininf, minsup, recurse)%, requiredSups, requiredInfs)

% msk = true(size(cs));
cs0 = cs;

filts = [abstr;hidd;seal;enum;handcomp];
filtMask = (strcmp(filts,"require"));
if(any(filtMask))
    filtNums = find(filtMask);
    for filtNum = filtNums
        switch filtNum
            case 1
                mask = [cs.Abstract];
            case 2
                mask = [cs.Hidden];
            case 3
                mask = [cs.Sealed];
            case 4
                mask = [cs.Enumeration];
            case 5
                mask = [cs.Enumeration];
        end
        cs = cs(mask);
        %msk = msk & mask;
    end
    filtNums = find(~filtMask);
else
    filtNums = [1 2 3 4 5];
end

if(~isempty(filtNums))
    for filtNum = filtNums
        switch filtNum
            case 1
                mask = [cs.Abstract];
            case 2
                mask = [cs.Hidden];
            case 3
                mask = [cs.Sealed];
            case 4
                mask = [cs.Enumeration];
            case 5
                mask = [cs.Enumeration];
        end
        if(filts(filtNum)~="exclude")
            mask = ~mask;
        end
        cs = cs(mask);
        %msk(mask) = msk & mask;
    end
end

if minsup
    supCounts = cellfun(@length, {cs1.SuperclassList}, ...
        'UniformOutput', true);
    mask = (supCounts >= minsup);
    cs = cs(mask);
    %msk = msk & mask;
end
if mininf
    infClasses = {cs1.InferiorClasses};
    infCounts = cellfun(@length, infClasses, ...
        'UniformOutput', true);
    if recurse
        infCounts = infCounts + ...
            cellfun(@(cname,ics) length(setdiff(...
            subclasses(cname, "SearchAllInMem", true).Name, ics)), ...
            {cs.Name}, infClasses, 'UniformOutput', true);
    end
    mask = (infCounts >= mininf);
    cs = cs(mask);
    %msk = msk & mask;
end
msk = ismember(cs0, cs);
end

function TF = checkancestry(cls, supnames)
subsupers = cls.SuperclassList;
[subsupernames, idxs] = unique({subsupers.Name});
% subsupers = subsupers(idxs);
numsubsupers = length(idxs);
if(any(ismember(subsupernames, supnames)))
    TF = true;
elseif numsubsupers
    TF = false;
    for i=idxs
        TF = checkancestry(subsupers{i}, supnames);
        if TF
            return;
        end
    end
else
    TF = false;
end
end

% [superclasses(fig)]''
% {metaclass(fig).SuperclassList.Name}'
% setxor({metaclass(fig).SuperclassList.Name}',[superclasses(fig)]'')
% cellfun(@(cn) isa(fig, cn), cat(1, {metaclass(fig).SuperclassList.Name}',[superclasses(fig)]''))

% cs(~isempty(cellfun(@isempty,{cs.InferiorClasses})))
% cs = [meta.class.getAllClasses{:}]
% cs(3).InferiorClasses
% msk = cellfun(@(x) ~isempty(x.InferiorClasses), meta.class.getAllClasses');
% find(msk)
% ics = {cs(find(msk,2)).InferiorClasses};
% ics1 = [ics{1}{:}]; ics2 = [ics{2}{:}];
% scs = {cs.SuperclassList}; scs = unique(cat(1, scs{:}));