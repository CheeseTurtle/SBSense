function onSPFFieldChange(app, src, event)
    persistent lastVal;
    fprintf('[onSPFFieldChange]:? event.EventName: ''%s''\n', event.EventName);
    try
        changing = (event.EventName(end) == 'g');
        if changing
            if isempty(event.Value) 
                lastVal = '';
                return;
            elseif isequal(event.Value, lastVal)
                return;
                %         elseif ~isempty(src.UserData)
                %             cancel(src.UserData);
            end
            % 1/30, 1/29, 1/28 ... 1/1
            % [1-9]+
            matchStr = regexp(event.Value, ...
                '^(?:(?:[1-9]\d*(?:[.]\d?\d?)?)|(?:1(?:/(?:(?:[12]\d?)|(?:30?)|(?:[4-9])?)?)?))(?=.*$)', ...
                ...%'^(?:1(?:/(?:(?:[12]\d?)|(?:30?)|(?:[4-9]))?)|(?:\d{1,3}(?:\.\d{1,2})?))(?=.*$)', ...
                'match', 'once', 'warnings');
            fprintf('[onSPFFieldChange]:changing matchStr: ''%s''\n', matchStr);
            if ~isempty(matchStr)
                %if ~strcmp(matchStr, event.Value)
                src.Value = matchStr;
                lastVal = matchStr; %event.Value;
                %end
                newSPF = str2num(src.Value); %#ok<ST2NM>
                if ~isempty(newSPF)
                    % FPPSpinner, (FPSField), (SPPField)
                    src.NumericValue = newSPF;
                    %display(1/newSPF);
                    app.FPSField.Value = double(1/newSPF);
                    app.SPPField.Value = double(newSPF * app.FPPSpinner.Value);
                end
            end
        else
            %if contains(event.Value, '/')
            %else
            %    src.Value = num2str(str2num(event.Value), '%1.2f')
            %end
            %if ~isequal(event.Value, lastVal)
                matchStr = regexp(event.Value, ...
                    '^(?:(?:[1-9]\d*[.]\d?\d?)|(?:1(?:/(?:(?:[12]\d?)|(?:30?)|(?:[4-9]?))?)?))(?=.*$)', ...
                    ...%'^(?:(?:1(?:/(?:(?:[12]\d?)|(?:30?)|(?:[4-9]))?))|(?:\d{1,3}(?:\.\d{1,2})?))(?=.*$)', ...
                    'match', 'once', 'warnings');
                fprintf('[onSPFFieldChange]:changed matchStr: ''%s''\n', matchStr);
                if isempty(matchStr)
                    src.Value = '1';
                else
                    src.Value = matchStr;
                end
                lastVal = src.Value;
            %end
            fprintf('[onSPFFieldChange]:changed src.Value: ''%s''\n', src.Value);
            newSPF = str2num(src.Value); %#ok<ST2NM>
            if isempty(newSPF)
                src.Value = '1';
                lastVal = 1;
                src.NumericValue = 1;
                newSPF = 1;
            else
                % FPPSpinner, (FPSField), (SPPField)
                src.NumericValue = newSPF;
                %display(1/newSPF);
            end
            app.FPSField.Value = double(1/newSPF);
            app.SPPField.Value = double(newSPF * app.FPPSpinner.Value);
        end
    catch ME 
        fprintf('[onSPFFieldChange] Error "%s": %s\n', ...
            ME.identifier, getReport(ME));
        rethrow(ME);
    end
end


% function TF = isValidSPF(str)
%     persistent pat;
%     if isempty(pat)
%         pat = RegexpPattern(')
%     TF = matches()
% end