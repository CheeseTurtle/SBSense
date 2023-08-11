function onSubpanParentSizeChanged(src, ~) %ev)
    %if ~isequal(src.Children.InnerPosition, [0 0 1 1]) % ~isequal(src.Children.InnerPosition([2 4]), src.InnerPosition([2 4]))
        % src.Children.Position([2 4]) = src.InnerPosition([2 4]);
        % src.Children.Position = [0 0 1 1];
    %end

    src.Children.Units = 'normalized';
    src.Children.Position([2 4]) = [0 1];
    src.Children.Units = 'pixels';
    src.Children.Position([1 3]) = src.Children.UserData.InnerPosition([1 3]);
    

    % maxChildWd = src.InnerPosition(3) ...
    %     + src.InnerPosition(1) - src.Children.Position(1);
    % set(src.Children, 'Position', ...
    %     [   src.Children.Position(1) 0 ...
    %         min(maxChildWd, src.Children.Position(3)) ...
    %         src.InnerPosition(4) ...
    %     ]);
    end