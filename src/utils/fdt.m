function y = fdt(x)
    % TODO: Allow 'NumericFormat' option to pass to...?
    if isempty(x)
        switch class(x)
            case 'char'
                y = '''''';
            case 'cell'
                y = '{}';
            case {'table','timetable'}
                y = ['<empty ' class(x) '>'];
            otherwise
                y = '[]';
        end
    elseif istable(x) || istimetable(x)
        y = strip(formattedDisplayText(x, 'SuppressMarkup', true), newline);
    elseif ~isscalar(x) && ~ischar(x)
        if isstring(x)
            y = compose("""%s""", arrayfun(@(s) regexprep(strip(erase(formattedDisplayText(s, 'SuppressMarkup', true), newline)), '\s+', ' '), x));
            y = strjoin(y, ' ');
            y = "[" + y + "]";
        else
            if iscell(x)
                % y = strjoin(cellfun(@(s) strrep(strip(erase(formattedDisplayText(s), newline)), '  ', ' '), x), ' ');
                % y = "{" + y + "}";
                y = regexprep(strip(erase(formattedDisplayText(x, 'SuppressMarkup', true), newline)), '\s+', ' ');
            elseif isvector(x)
                if iscolumn(x)
                    x = x';
                end
                if isnumeric(x) % TODO: Take 'NumericFormat' argument into account?
                    y = strjoin(compose('%g', x), ' ');
                else
                    y = strjoin(arrayfun(@(s) regexprep(strip(erase(formattedDisplayText(s, 'SuppressMarkup', true, 'LineSpacing', 'compact'), newline)), '\s+', ' '), x), ' ');
                end
                y = "[" + y + "]";
            elseif ismatrix(x)
                nrows = size(x, 1);
                if isnumeric(x) % TODO: Take 'NumericFormat' argument into account?
                    y = strjoin(arrayfun(@(rn) strjoin( compose('%g', x(rn,:)), ','), 1:nrows), ' ; ');
                else
                    y = strjoin(arrayfun(@(rn) ...
                        strjoin(arrayfun(@(s) regexprep(strip(erase(formattedDisplayText(s, 'SuppressMarkup', true, 'LineSpacing', 'compact'), newline)), '\s+', ','), x(rn,:)), ' '), ...
                        1:rn), ' ; ');
                end
                y = "[" + y + "]";
            else
                y = regexprep(strip(erase(formattedDisplayText(x, 'SuppressMarkup', true, 'LineSpacing', 'compact'), newline)), '\s+', ' ');
            end
        end
    else
        y = regexprep(strip(erase(formattedDisplayText(x, 'SuppressMarkup', true, 'LineSpacing', 'compact'), newline)), '\s+', ' ');
        if ischar(x)
            y =  "'" + y + "'";
        elseif isstring(x)
            y = """" + y + """";
        end
    end
end