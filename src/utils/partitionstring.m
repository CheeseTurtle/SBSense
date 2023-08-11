function A = partitionstring(str, N0, N, opts)
arguments(Input)
    str (1,:) char;
    N0 uint16;
    N uint16 = N0;
    opts.OutputFormat {mustBeMember(opts.OutputFormat, {'cell', 'array'})} = 'array';
end
% arrayfun(@(x,y) string(str(x:y)), 1:5:10, 11:5:20, 'UniformOutput', true)
len = uint16(strlength(str));
if len <= N0
    if opts.OutputFormat == "cell"
        A = {str};
    else
        A = string(str);
    end
    return;
end


%restLen = mod(len,N);
%if restLen
%    rest = str(end-restLen+1:end);
%else
%    rest = '';
%end
head = str(1:N0);
str = str(N0+1:end);
len = len - N0;
maxReps = idivide(len, N, "fix") - 1;
rest = str((end-mod(len,N)+1):end);

if maxReps
    idxs1 = 1:N:(1+N*maxReps);
    idxs2 = idxs1 + N - 1;
    if opts.OutputFormat == "cell"
        A = arrayfun(@(x,y) str(x:y), idxs1, idxs2, 'UniformOutput', false);
        if isempty(rest)
            A = [ {head} ; A(:) ]';
        else
            A = [ {head} ; A(:) ; {rest} ]';
        end
    else
        A = [ head ...
            arrayfun(@(x,y) string(str(x:y)), idxs1, idxs2, 'UniformOutput', true) ];
        if ~isempty(rest)
            A = [A rest];
        end
    end
elseif opts.OutputFormat == "array"
    A = head + string(rest);
elseif isempty(rest)
    A = {head};
else
    A = { head rest };
end
end