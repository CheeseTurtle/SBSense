function showcwtresult(varargin)
narginchk(1,2);
if(nargin > 1)
    parent = varargin{1};
    cfs = varargin{2};
else
    parent = gcf;
    cfs = varargin{1};
end

numScales = size(cfs,4);
numAngles = size(cfs,5);

if(numAngles > numScales)
    numRows = numScales;
    numCols = numAngles;
else
    numRows = numAngles;
    numCols = numScales;
    cfs = permute(cfs, [1 2 3 5 4]);
end

numTiles = numRows;
if(~isprime(numTiles) && (numTiles <= 5) && (numCols <= 5))
    fs = factor(numTiles);
    f1 = 1; f2 = 1;
    for f = fs
        if(f1 < f2)
            f1 = f1 * f;
        else
            f2 = f2 * f;
        end
    end
    numTileRows = max(f1,f2);
    numTileCols = min(f1,f2);
else
    numTileRows = numRows;
    numTileCols = 1;
end

tl = tiledlayout(parent, numTileRows, numTileCols, ...
    "TileIndexing", "rowmajor", ...
    "TileSpacing", "tight", "Padding", "compact");

sizeX = size(cfs,1);
sizeY = size(cfs,2);
onez = ones(1, numCols);
for rowNum = 1:numRows
    ax = nexttile(tl, [1 1]);
    rowCplx = cfs(:,:,1,rowNum,:);
%     rowAbs  = abs(rowCplx);
%     %rowAng  = normalize(angle(rowCplx), 3, "range");
%     rowReal = real(rowCplx);
%     rowImag = imag(rowCplx);
%     %mat2cell(rowCplx,sizeX,sizeY,1,1,onez);
%     %imgs = squeeze(cat(3, rowAbs, rowReal, rowImag));
%     %imgs = squeeze(mat2cell(imgs, sizeX, sizeY, 3, onez))';
    rowCplx = squeeze(mat2cell(rowCplx,sizeX,sizeY,1,1,onez));
    rowAbs  = cellfun(@rowabsfun, rowCplx, 'UniformOutput', false);
    rowReal  = cellfun(@rowrealfun, rowCplx, 'UniformOutput', false);
    rowImag  = cellfun(@rowimagfun, rowCplx, 'UniformOutput', false);
    rowAbs = cat(3, rowAbs{:});
    rowReal = cat(3, rowReal{:});
    rowImag = cat(3, rowImag{:});
    %imgs = [rowAbs rowReal rowImag];
    %imgs = [imgs{:}];
    %imgs = cat(3, rowAbs,rowReal,rowImag);
    %montage(imgs, colormap("jet"), "Size", [3 numCols], "Parent", ax);
    
    montage({ ...
        imtile(rowAbs, colormap("jet"), "GridSize", [1 numCols]), ...
        imtile(rowReal, colormap("parula"), "GridSize", [1 numCols]), ...
        imtile(rowImag, colormap("prism"), "GridSize", [1 numCols]) ...
        }, 'Size', [3 1], "Parent", ax);
    
    
    %celldisp(imgs);
    %montage(histeq(imgs{1}(:,:,1)), colormap("gray"), "Parent", ax, "Size", [1 numCols]);
    %surf(ax,imgs{1}(:,:,1));
    
    %img = imtile(cat(3, rowAbs, rowReal, rowImag), ...
    %    colormap("gray"), "GridSize", [4 numCols]);
    %imshow(img, colormap("gray"), 'Parent', ax);
    %shading interp; axis tight;
    %view(0,90);
end

end

function x = rowabsfun(x)
x = abs(x);
x = im2uint8(imadjust(x, stretchlim(x, [0 1])));
end

function x = rowrealfun(x)
x = real(x);
x = im2uint8(imadjust(x, stretchlim(x, [0 1])));
end

function x = rowimagfun(x)
x = imag(x);
x = im2uint8(imadjust(x, stretchlim(x, [0 1])));
end

