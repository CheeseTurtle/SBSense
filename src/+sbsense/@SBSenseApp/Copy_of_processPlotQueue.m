function varargout = processPlotQueue(app, tobj)
%fprintf('[processPlotQueue] ...\n');
if ~app.PlotQueue.QueueLength
    %fprintf('[processPlotQueue] Empty queue.\n');
    return;
%else
    %idxs = zeros(1,app.PlotQueue.QueueLength, 'uint64');
end
fprintf('[processPlotQueue] Queue length: %u\n', app.PlotQueue.QueueLength);

try
    [idxReceived, TF] = poll(app.PlotQueue, 0);
    if TF && isempty(idxReceived)
        fprintf('[processPlotQueue] idxReceived is unexpectedly empty!\n');
    elseif TF
        fprintf('[processPlotQueue] idxReceived: %u\n', idxReceived);
    else
        fprintf('[processPlotQueue] TF = false :/\n');
        return;
    end
    % [idxReceived, TF] = poll(app.PlotQueue); % TODO: Timeout??

    %fprintf('[processPlotQueue] %d (%s) / %s', ...
    %    uint8(TF), formattedDisplayText(idxReceived'), formattedDisplayText(tobj));
    %if isempty(tobj)
    %    fprintf('\n');
    %end
    %if ~TF
    %    return;
    %end

    idxReceived = uint64(idxReceived);
    idxs = [{idxReceived} cell(1,app.PlotQueue.QueueLength)];
    %idxs = idxReceived;
    if isscalar(idxReceived)
        minIdxReceived = (idxReceived);
        maxIdxReceived = (idxReceived);
    else
        minIdxReceived = min(idxReceived);
        maxIdxReceived = max(idxReceived);
    end

    idxReceived = uint64.empty();
    maxIdxs = app.PlotQueue.QueueLength;
    TF = logical(maxIdxs);
    i = 2;
    while TF
        if ~isempty(idxReceived)
            idxReceived = uint64(idxReceived);
            i = i + 1; idxs{i} = idxReceived;
            %idxs = horzcat(idxs, idxReceived); %#ok<AGROW>
            if isscalar(idxReceived)
                if any(maxIdxReceived < idxReceived)
                    maxIdxReceived = idxReceived;
                elseif any(minIdxReceived > idxReceived)
                    minIdxReceived = idxReceived;
                end
            else
                maxIdxReceived = max(idxReceived, maxIdxReceived);
                minIdxReceived = min(idxReceived, minIdxReceived);
            end
        end
        maxIdxs = maxIdxs - 1;
        if ~maxIdxs
            break;
        end
        [idxReceived, TF] = poll(app.PlotQueue); % NO timeout
    end
    
    %fprintf('[processPlotQueue] idxs received: [ %s ]\n', ...
    %    num2str(idxs));
    idxs = horzcat(idxs{:});
    if nargout
        varargout = {processIndexes(app, tobj, idxs, minIdxReceived,maxIdxReceived)};
    else
        processIndexes(app,tobj, idxs, minIdxReceived,maxIdxReceived);
    end
    fprintf('[processPlotQueue] Returning from fcn.\n');
catch ME
    fprintf('[processPlotQueue] Error "%s": %s\n', ...
        ME.identifier, getReport(ME));
end
end

