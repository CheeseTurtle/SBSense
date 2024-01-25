function P = makeProfile(numDatapoints, numChannels, profileDim, opts)
arguments(Input)
numDatapoints (1,1) {mustBeNumeric, mustBeInteger, mustBeFinite, mustBePositive};
numChannels (1,1) uint8 {mustBePositive};
profileDim (1,1) {mustBeNumeric, mustBeInteger, mustBeFinite, mustBePositive};
opts.Order (1,3) char {mustBeMember(opts.Order, {'nCL' 'nLC' 'LnC' 'LCn' 'CLn' 'CnL'})} = 'nLC';
opts.Style (1,1) string {mustBeMember(opts.Style, ["cell" "number" "string"])} = "cell";
end
S = struct('n', 1:numDatapoints, 'L', 1:profileDim, 'C', 1:numChannels);
vecs = {S.(opts.Order(1)), S.(opts.Order(2)), S.(opts.Order(3))};
% disp(vecs);

% Produces 1xlength(vecs{2}) cell vector;
% each cell contains [0 0 i].
rowBase = arrayfun(@(i) [0 0 i], vecs{2}, 'UniformOutput', false);
% Produces horizontal length(vecs{1})x1 cell vector.
rowAdd = arrayfun(@(i) [0 i 0], vecs{1}', 'UniformOutput', false);

layerBase = cellfun(@(a,b) a+b, repmat(rowBase, vecs{1}(end), 1), ...
    repmat(rowAdd, 1, vecs{2}(end)), 'UniformOutput', false);
layerSize = double(size(layerBase));
P = arrayfun(@(i) cellfun(@(a,b) a+b, repmat({double([i 0 0])}, layerSize), layerBase, ...
    'UniformOutput', false), vecs{3}, 'UniformOutput', false);
P = cat(3, P{:});

switch(opts.Style)
    case "string"
        P = cellfun(@stringFun, P, 'UniformOutput', true);
    case "number"
        info = fliplr([1/(vecs{2}(end)+1), 1, log10(vecs{1}(end))]);
        ic =  ceil(info(1));
        info(1) = 10^(ic + (ic == info(1)));
        P = cellfun(@numberFun, P, 'UniformOutput', true);
    % otherwise
end

function num = numberFun(A)
    num = sum(double(A).*info);
end
end

function str = stringFun(A)
str = strjoin(string(A), ':');
end