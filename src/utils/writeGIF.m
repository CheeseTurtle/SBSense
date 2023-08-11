function varargout = writeGIF(filename, images, Q, opts)
arguments(Input)
    filename {mustBeTextScalar,mustBeNonzeroLengthText};
    images   {mustBeA(images,'cell')};
    Q {mustBeInteger,mustBeInRange(Q, 1, 65536)} = [2 64 256];
    opts.LoopCount {mustBeNumeric,mustBeScalarOrEmpty,mustBeNonempty, ...
        mustBeNonnegative, mustBeReal} = Inf; % Todo: Must be positive integer or Inf...
    opts.DelayTime {mustBeNumeric, mustBeVector, ...
        mustBeNonnegative, mustBeReal, mustBeFinite} = 1;
    opts.DelayTimeMode {mustBeMember(opts.DelayTimeMode, ...
        {'Hold', 'Repeat', 'Reflect', 'Delay'})} = 'Hold';
    opts.CircularLoop {mustBeNumericOrLogical} = false;
end
nargoutchk(0,3);
nImages = numel(images);
nDelays = length(opts.DelayTime);
if(nDelays == 1)
    getDelayTime = @(~) opts.DelayTime;
elseif( nDelays < nImages)
    switch opts.DelayTimeMode
        case 'Hold'
            opts.DelayTime(end+1:nImages) = opts.DelayTime(end);
        case 'Repeat'
            % {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q}
            %  1,2,3,4,5 1,2,3,4,5 1,2,3,4,5 1,2
            rem = mod(nImages, nDelays);
            idx1 = nDelays - rem;
            rep = circshift(opts.DelayTime, -idx1);
            numReps = nDelays\(nImages - rem) - 1;
            opts.DelayTime(idx1:nImages) = repelem(rep, numReps);
        case 'Reflect'
            % {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q}
            %  1,2,3,4,5 5,4,3,2,1 1,2,3,4,5 5,4
            rem = mod(nImages, nDelays);
            numHalfPairs = fix(nImages / nDelays);
            if(bitand(numHalfPairs, 1))
                % Ends during descending ==> nHP: 1 3 5 7 ...
                % Shift start of sequence to end - (rem-1) + 1
                %                          = end - rem
                % Repeat (shifted) pair sequence starting from
                % first use of new start index,
                % which will be i = nDelays + (nDelays - rem)
                %                =  2*nDelays - rem
                %opts.DelayTime(end+1:nImages) = 0;
                opts.DelayTime(end+1:2*nDelays) = flip(nDelays);
                idx1 = 2*nDelays - rem;
                pair = circshift(opts.DelayTime(1:2*nDelays), -idx1);
                numReps = ceil((nImages - idx1) / (2*nDelays));
                opts.DelayTime(idx1:nImages) = ...
                    repelem(pair, numReps);
            else
                % Ends during ascending  ==> nHP: 0 2 4 6 ...
                % Shift start of sequence to 1 + (rem+1) - 1
                %                          = rem+1
                % Repeat (shifted) pair sequence starting from
                % first use of new start index.
                idx1 = rem+1;
                opts.DelayTime(end+1:2*nDelays) = flip(opts.DelayTime);
                pair = circshift(opts.DelayTime, -idx1);
                numReps = ceil((nImages - idx1) / (2*nDelays));
                opts.DelayTime(idx1:nImages) = ...
                    repelem(pair, numReps); 
            end
        case 'ReflectElide'
            % {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q}
            %  1,2,3,4,5,4,3,2,1,2,3,4,5,4,3,2,1
            nImages1 = nImages - nDelays;
            nDelays1 = nDelays - 1;
            nDelays2 = nDelays + nDelays1;
            rem = mod(nImages1, nDelays1);
            numHalfPairs = fix(nImages1/nDelays1);
            
            if(bitand(numHalfPairs, 1))
                % Ends during descending ==> nHP: 1 3 5 7 ...
                % Shift start of sequence to end - (rem-1) + 1
                %                          = end - rem
                % Repeat (shifted) pair sequence starting from
                % first use of new start index,
                % which will be i = nDelays + (nDelays - rem)
                %                =  2*nDelays - rem
                %opts.DelayTime(end+1:nImages) = 0;
                if(numHalfPairs < 2)
                    rev = flip(opts.DelayTime(2:end));
                    opts.DelayTime(end+1:nImages) = ...
                        rev(1:rem);
                else
                    opts.DelayTime(end:nDelays2) = flip(nDelays);
                    idx1 = nDelays2 - rem;
                    pair = circshift(opts.DelayTime(1:nDelays2), -idx1);
                    numReps = ceil(nImages1/nDelays2);
                    opts.DelayTime(idx1:nImages) = ...
                        repelem(pair, numReps);
                end
            else
                % Ends during ascending  ==> nHP: 0 2 4 6 ...
                % Shift start of sequence to 1 + (rem+1) - 1
                %                          = rem+1
                % Repeat (shifted) pair sequence starting from
                % first use of new start index.
                idx1 = rem+1;
                opts.DelayTime(end:nDelays2) = flip(opts.DelayTime);
                pair = circshift(opts.DelayTime, -idx1);
                numReps = ceil(nImages1/nDelays2);
                opts.DelayTime(idx1:nImages) = ...
                    repelem(pair, numReps);
            end
        case 'Delay'
            opts.DelayTime = horzcat(repelem(opts.DelayTime(1), ...
                nImages - nDelays), opts.DelayTime);
        otherwise
            error("Unknown DelayTimeMode specified.");
    end
    getDelayTime = @(i) opts.DelayTime(i);
else
    getDelayTime = @(i) opts.DelayTime(i);
end
maxdim = max(cellfun(@ndims, images),[],"all");
if(length(Q) < maxdim)
    Q(end+1:maxdim) = Q(end);
end

for idx = 1:nImages
    % Q specified as a positive integer that is less than or equal to 65536. 
    % The returned colormap cmap has Q or fewer colors.
    img = images{idx};
    qIdx = ndims(img) - islogical(img);
    if(~isa(img, 'uint8'))
        img = im2uint8(img);
    end
    if(qIdx < 3)
       [A, map] = gray2ind(img, Q(qIdx));
    else
        [A,map] = rgb2ind(img, Q(qIdx));
    end
    if idx == 1
        imwrite(A,map,filename,"gif", ...
            "LoopCount",opts.LoopCount, "DelayTime",opts.DelayTime(1));
    else
        imwrite(A,map,filename,"gif","WriteMode","append", ...
            "DelayTime", getDelayTime(idx));
    end
end
if(nargout)
    [varargout{1}, cmap] = imread(filename, "gif", "Frames", "all");
    if (nargout > 1)
        varargout{2} = cmap;
        if(nargout > 2)
            varargout{3} = immovie(varargout{1}, cmap);
        end
    end
end
end