function setAnnotationLabels(labs, strs)
    try 
        [labs.String] = strs{:};
        fprintf('[setAnnotationLabels] strs is CELL.\n');
    catch ME
        try
            [labs.String] = deal(strs);
            fprintf('[setAnnotationLabels] strs is VECTOR.\n');
        catch
            rethrow(ME);
        end
    end
end