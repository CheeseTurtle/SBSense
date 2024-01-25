function A = avgframes(varargin)
if((nargin > 1) ...
        && (isa(varargin{end}, "string") || isa(varargin{end}, "char")))
    assert(ismember(varargin{end}, ...
        {'uint8', 'uint16', 'uint32', 'int8', 'int16', 'int32', 'single', 'double'}));
    % TODO: Check and throw type error instead.
    outputClass = varargin{end};
    varargin(end) = [];
    nargs = nargin - 1;
else
    outputClass = [];
    nargs = nargin;
end
if(nargs > 1)
    I = varargin(1:nargs);
else
    I = varargin{1};
    %disp(I);
end

if(iscell(I))
    %if(length(I)==1)
    %    I = I{1};
    %    numImgs = size(I,3);
    %    nthImgFcn = @(n) I(:,:,n);
    %else
    %    numImgs = length(I);
    %    nthImgFcn = @(n) I{n};
    %end
    while(any(cellfun(@iscell,I,'UniformOutput',true)))
        I = [I{:}];
    end
    while iscell(I)
        %while(any(cellfun(@iscell,I,'UniformOutput',true)))
        %    I = [I{:}];
        %end
        %fprintf('I at beg. of loop: %s', formattedDisplayText(I));
        nds = cellfun(@ndims, I, 'UniformOutput', true);
        %fprintf('nds: %s', formattedDisplayText(nds));
        if(~any(nds>2))
            break;
        end
        I = cellfun(@sbsense.utils.im2cell, I, 'UniformOutput', false);
        %disp(I);
        %celldisp(I);
        %I = I(:);
        %fprintf('I{1}:\n'); disp(I{1});
        %fprintf('I{2}:\n'); disp(I{2});
        if any(cellfun(@iscell,I,'UniformOutput',true))
            I = sbsense.utils.collapsecell(I, false);
        end
        % I = permute(I, circshift(1:ndims(I), -1));
        I = reshape(I, 1, prod(size(I), "all"));
        %fprintf('I at end of loop: %s', formattedDisplayText(I));
        %celldisp(I);
    end
    %disp(I);
    %while iscell(I) && any(cellfun(@iscell,I)) % TODO: More efficient check?
    %    I = I{:};
    %    %disp(I);
    %end
    numImgs = length(I);
    nthImgFcn = @(n) I{n};
else % Not a cell -- single image
    numImgs = size(I,3);
    nthImgFcn = @(n) I(:,:,n);
end
%fprintf('Size of I (%s): %s', class(I), formattedDisplayText(size(I)));
%fprintf('numImgs: %d\n', numImgs);
K = numImgs\1.0;
row1 = cellfun(@(~) K, cell(1,numImgs), 'UniformOutput', false);
row2 = cellfun(nthImgFcn, num2cell(1:numImgs), 'UniformOutput', false);
rows = vertcat(row1, row2);
args = reshape(rows, 1, []);
if(isempty(outputClass))
    A = imlincomb(args{:});
else
    A = imlincomb(args{:}, outputClass);
end
%disp(size(A));
end

% ca = {{randi(10,2,2), randi(10,2,2),randi(10,2,2)}, randi(10,3,3), randi(10,2,2), {randi(10,2,2), randi(10,2,2)}}
% ca2 = [ca{:}];
% ca = {{randi(10,2,2), randi(10,2,2),randi(10,2,2)}, randi(10,2,2), randi(10,2,2), {randi(10,2,2), randi(10,2,2)}}
% ca2 = [ca{:}]; ca3 = [ca2{:}]; ca4 = [ca3(:)']; ca4 == ca3(:)'

% avgframes({frames_Y0_7a(1:2,1:2,1:2), frames_Y0_7b(1:2,1:2,1:2), frames_Y0_7c(1:2,1:2,1:2)})
% avgframes({frames_Y0_7a(1:2,1:2,1:2), frames_Y0_7b(1:2,1:2,1:2), frames_Y0_7c(1:2,1:2,1:2)}, 'double')
% 6\sum(cat(3,frames_Y0_7a(1:2,1:2,1:2), frames_Y0_7b(1:2,1:2,1:2), frames_Y0_7c(1:2,1:2,1:2)), 3)

function y = imorcell2cell(x)
if(iscell(x))
    y = cellfun(@imorcell2cell, x, 'UniformOutput', false);
else
    y = sbsense.utils.im2cell(x);
end
end