function TF = updateChannelOverlayImage(app, varargin)
    % varargin: chkGenerate, DDVal

    if ~bitget(nargin,1) % nargin==2
        chkGenerate = varargin{1};
        val = app.DataImageDropdown.Value(2);
    elseif bitget(nargin,2) % nargin==3
        chkGenerate = varargin{1};
        val = varargin{2}(2);
    else
        chkGenerate = false;
        val = app.DataImageDropdown.Value(2);
    end
    
    if chkGenerate && isempty(app.dataimg.UserData)
        [img1,img2,TF] = generateChannelOverlayImages( ...
            colororder(app.UIFigure), app.AnalysisParams);
        if TF 
            app.overimg.UserData = { ...
                img1, img2, (val=='0') };
        else
            return;
        end
    else
        TF = true;
        if ~bitxor(app.overimg.UserData{3}, (val=='0'))
            return;
        end
    end
    try
        app.overimg.CData = app.overimg.UserData{ ...
            app.overimg.UserData{3}+1 };
    catch ME
        display(app.overimg.UserData);
        display(size(app.overimg.UserData{ ...
            app.overimg.UserData{3}+1 }));
        display(class(app.overimg.UserData{ ...
            app.overimg.UserData{3}+1 }));
        % rethrow(ME);
        fprintf('%s\n', getReport(ME));
    end
end