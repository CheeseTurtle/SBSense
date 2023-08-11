function [fullname, fmt, args] = sbuiputfile(kind,varargin)
switch kind
    case 'image'
        filt = { '*.png', 'PNG file' ...
            ; '*.jpg;*.jpeg', 'JPEG file' ...
            ; '*.svg', 'Vector graphics file' ...
            ; '*.eps', 'PostScript file' ...
            ; '*.pdf', 'PDF file (pixel graphics)' ...
            ; '*.pdf', 'PDF file (vector graphics)' ...
            ... % ; '*.fig', 'MATLAB figure' ...
            ... %; '*.m', 'MATLAB figure + script' ...
            };
        %    ; '*.tiff', 'TIFF 24-bit, compressed' ...
        %    ; '*.tiff', 'TIFF 24-bit, noncompressed' };
        fmts = { 'png', 'jpeg', 'svg', 'epsc', 'pdf', 'pdf' };%'fig', 'm' };
        args = { 'image', 'image', 'vector', ...
            'vector', 'image', 'vector'}; % , 'saveas', 'saveas' };
    case 'data'
        filt = { '*.xls', 'MS Excel Spreadsheet File' };
        fmts = {'xls'};
        args = {};
    otherwise
        fmts = {};
        args = {};
        if iscell(kind)
            if ~isempty(kind) && iscell(kind{1})
                filt = kind{1};
                fmts = kind{2};
                if length(kind)>2
                    args = kind{3};
                end
            else
                filt = kind;
            end
        else
            filt = {'*.*', 'All files'};
        end
end

[file,path,idx] = uiputfile(filt, varargin{:});

if nargout
    if ~file
        fullname = file;
        fmt = [];
        args = [];
        return;
    elseif ~isempty(fmts)
        fmt = fmts{idx};
        if ~isempty(args) && (nargout==3)
            args = args{idx};
        else
            args = idx;
        end
        if ~isempty(fmt)
            ext = ['.' fmt];
            if ~endsWith(file, ext)
                file = sprintf('%s%s', file, ext);
            end
        end
    elseif bitget(nargout,2)
        fmt = idx;
    end
    fullname = fullfile(path,file);
end
end