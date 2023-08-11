classdef (Sealed, ConstructOnLoad=true) GridLayout2 < ...
        matlab.ui.container.internal.model.LayoutContainer & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        ...% matlab.ui.internal.mixin.Scrollable & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer &...
        matlab.ui.container.internal.model.mixin.BackgroundColorableContainer
    % GridLayout2 is a container that lays out its children in a grid pattern
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        ColumnWidth
        RowHeight
        ColumnSpacing
        RowSpacing
        Padding
    end
    
    properties(Access = 'private')
        PrivateColumnWidth =  {'1x' '1x'};
        PrivateRowHeight = {'1x', '1x'};
        PrivateColumnSpacing = 10;
        PrivateRowSpacing = 10;
        PrivatePadding = [10,10,10,10];
        
        % Keep track of user's last explicitly set dimensions
        LastUserSetSizes;
    end
    
    properties(Transient, NonCopyable, Access='private')
        
        % Tracks how many components in each cell.
        % Size of the matrix is the size of the grid, or content driven
        % size if there are components outside the grid size
        %
        % This property is updated when components are added during load,
        % so it should not be saved. During load, it will get re-created.
        OccupancyCount;
    end

    properties(Transient,...
            SetAccess = {?appdesigner.internal.componentcontroller.DesignTimeGridLayoutController},...
            GetAccess = public)
        Position matlab.internal.datatype.matlab.graphics.datatype.Position = [1, 1, 100, 100];
    end

    properties(Dependent, Transient,...
            SetAccess = private,...
            GetAccess = public)
        OuterPosition matlab.internal.datatype.matlab.graphics.datatype.Position;
        InnerPosition matlab.internal.datatype.matlab.graphics.datatype.Position;
    end
    
    methods
        function obj = GridLayout2(varargin)
            obj.Type = 'uigridlayout';
            obj.BackgroundColor = obj.DefaultGray;
            % Initialize LastUserSetSizes dimensions to the default
            % ColumnWidth and RowHeight, as these values should always
            % start off the same
            obj.LastUserSetSizes = struct(...
                'ColumnWidth', {obj.ColumnWidth}, ...
                'RowHeight', {obj.RowHeight});
            
            obj.OccupancyCount = zeros(numel(obj.RowHeight), numel(obj.ColumnWidth));
            
            parsePVPairs(obj,  varargin{:});
        end
        
        function set.Position(obj, val)
            obj.Position = val;
            obj.updatePosition();
        end

        function value = get.OuterPosition(obj)
            value = obj.Position;
        end

        function value = get.InnerPosition(obj)
            horizontalPadding = obj.Padding(1) + obj.Padding(3);
            verticalPadding = obj.Padding(2) + obj.Padding(4);

            value = [obj.Position(1) + obj.Padding(1),... distance from left edge
                     obj.Position(2) + obj.Padding(2),... distance from bottom edge
                     max(0, obj.Position(3) - horizontalPadding),... width
                     max(0, obj.Position(4) - verticalPadding)... height
                                ];
        end
        
        function postSetBackgroundColor(obj)
            % This is needed to redraw axes, if present
            obj.redrawContents();
        end
        
        function set.RowHeight(obj, value)
            
            % Validation
            try
                value = obj.validateRowColumnSize(value);
                
            catch ME
                messageObj = message('MATLAB:ui:containers:invalidGridRowColumnSizes', ...
                    'RowHeight');
                
                % MnemonicField is last section of error id
                mnemonicField = 'InvalidRowHeight';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % User's last explicitly set RowHeight
            obj.LastUserSetSizes.RowHeight = value;
            
            % Compute and update number of rows
            [rows,cols] = obj.computeImplicitGridSize();
            
            obj.PrivateRowHeight = rows;
            
            % Update OccupancyCount
            obj.reshapeOccupancyCount(rows, cols);
            
            obj.markPropertiesDirty({'RowHeight'});
        end
        
        function value = get.RowHeight(obj)
            value = obj.PrivateRowHeight;
        end
        
        function set.ColumnWidth(obj, value)
            
            % Validation
            try
                value = obj.validateRowColumnSize(value);
                
            catch ME
                messageObj = message('MATLAB:ui:containers:invalidGridRowColumnSizes', ...
                    'ColumnWidth');
                
                % MnemonicField is last section of error id
                mnemonicField = 'InvalidColumnWidth';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            
            % User's last explicitly set ColumnWidth
            obj.LastUserSetSizes.ColumnWidth = value;
            
            % Compute and update number of cols
            [rows,cols] = obj.computeImplicitGridSize();
            
            obj.PrivateColumnWidth = cols;
            
            % Update OccupancyCount
            obj.reshapeOccupancyCount(rows, cols);
            
            
            obj.markPropertiesDirty({'ColumnWidth'});
        end
        
        function value = get.ColumnWidth(obj)
            value = obj.PrivateColumnWidth;
        end
        
        function set.ColumnSpacing(obj, value)
            
            % Validation
            isValid = matlab.ui.control.internal.model.PropertyHandling.isPositiveNumber(value);
            
            if(~isValid)
                messageObj = message('MATLAB:ui:containers:mustBeNonnegativeNumber', ...
                    'ColumnSpacing');
                
                % MnemonicField is last section of error id
                mnemonicField = 'InvalidColumnSpacing';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            obj.PrivateColumnSpacing = value;
            obj.markPropertiesDirty({'ColumnSpacing'});
        end
        
        function value = get.ColumnSpacing(obj)
            value = obj.PrivateColumnSpacing;
        end
        
        function set.RowSpacing(obj, value)
            
            % Validation
            isValid = matlab.ui.control.internal.model.PropertyHandling.isPositiveNumber(value);
            
            if(~isValid)
                messageObj = message('MATLAB:ui:containers:mustBeNonnegativeNumber', ...
                    'RowSpacing');
                
                % MnemonicField is last section of error id
                mnemonicField = 'InvalidRowSpacing';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            obj.PrivateRowSpacing = value;
            obj.markPropertiesDirty({'RowSpacing'});
        end
        
        function value = get.RowSpacing(obj)
            value = obj.PrivateRowSpacing;
        end
        
        function set.Padding(obj, value)
            
            % Validation
            isPositiveScalar = matlab.ui.control.internal.model.PropertyHandling.isPositiveNumber(value);
            isPositiveRow = matlab.ui.control.internal.model.PropertyHandling.isRowOf4PositiveNumbers(value);
            
            if(~isPositiveScalar && ~isPositiveRow)
                messageObj = message('MATLAB:ui:containers:mustBeNonnegativeNumberOr1x4Row', ...
                    'Padding');
                
                % MnemonicField is last section of error id
                mnemonicField = 'InvalidPadding';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Convert scalar to 1x4 of the same value
            if(isPositiveScalar)
                value = value * ones(1,4);
            end
            
            obj.PrivatePadding = value;
            obj.markPropertiesDirty({'Padding'});
        end
        
        function value = get.Padding(obj)
            value = obj.PrivatePadding;
        end
        
        % function scroll(this, varargin)
        %     %SCROLL API function to support programmatic scrolling for grid layouts with Scrollable = 'on'
        %     %
        %     %   SCROLL(G,EDGE) scrolls grid layout G to one edge of its scrollable range.
        %     %   EDGE is a string whose values may be 'top', 'bottom', 'left', or 'right'.
        %     %
        %     %   SCROLL(G,X,Y) scrolls grid layout G to scroll location (X,Y), where
        %     %   X and Y are given in MATLAB pixel coordinates.
        %     %
        %     %   Because grid cells are laid out from the top of the parent going down,
        %     %   it is possible for the bottom edge of a grid layout to lie on the negative
        %     %   side of MATLAB's y-axis. Other scrollable containers are bound at the bottom
        %     %   at MATLAB's y=1.
        %     %
        %     %   See also matlab.ui.Figure/scroll
        %     scroll@matlab.ui.internal.mixin.Scrollable(this, varargin{:});
        % end
    end
    
    methods(Access = 'protected')
        
        function handleChildAdded(obj, childAdded)
            handleChildAdded@matlab.ui.container.internal.model.CanvasContainerModel(obj, childAdded)
            
            if (~isprop(childAdded, 'Layout'))
                return;
            end
            
            obj.processChildAdded(childAdded);
            obj.addChildLayoutPropChangedListener(childAdded);
            
            % Update OccupancyCount
            %row = childAdded.Layout.Row;
            %col = childAdded.Layout.Column;
            [row,col] = getLayoutRC(obj, childAdded.Layout);
            obj.increaseOccupancyCount(row, col);
            
            % Update implicity grid size AFTER updating OccupancyCount since
            % it uses OccupancyCount to do the update
            obj.updateImplicitGridSize();
        end
        
        function handleChildRemoved(obj, childRemoved)
            
            if (~isprop(childRemoved, 'Layout'))
                return;
            end
            
            obj.removeChildLayoutPropChangedListener(childRemoved);
            obj.resetPositionReportStrategy(); 
            
            if (~obj.BeingDeleted)
                % Update the internal state only if the grid is not being
                % deleted
                
                % Update OccupancyCount
                %
                if (isa(childRemoved.Layout, 'matlab.ui.layout.GridLayoutOptions'))
                    % The Layout property was not changed (e.g. child was
                    % unparented) so we can use it to update OccupancyCount
                    row = childRemoved.Layout.Row;
                    col = childRemoved.Layout.Column;
                    obj.decreaseOccupancyCount(row, col);
                elseif isa(childRemoved.Layout, 'matlab.graphics.layout.TiledChartLayoutOptions')
                    % ADDED
                    [row,col] = ind2sub([numel(obj.RowHeight) numel(obj.ColumnWidth)], ...
                                childRemoved.Layout.Tile);
                    if childRemoved.Layout.TileSpan(1) > 1
                        row = row + 0:1:(childRemoved.Layout.TileSpan(1)-1);
                    end
                    if childRemoved.Layout.TileSpan(2) > 1
                        col = col + 0:1:(childRemoved.Layout.TileSpan(2)-1);
                    end
                    obj.decreaseOccupancyCount(row, col);
                else
                    % The Layout property was updated to another type and 
                    % is no longer a GridLayoutOptions object anymore
                    % (e.g. child was reparented to a panel or other
                    % non-grid container)
                    % We cannot use childRemoved.Layout to update
                    % OccupancyCount
                    %
                    % TODO: When reparenting a lot of components to other 
                    % non-grid containers, this will become a bottle neck.                     
                    % One option is to see if we can somehow get hold
                    % of the old Layout property of the child. 
                    % Another option could be for the grid to keep an 
                    % internal map of its children and corresponding Layout 
                    % property.
                    % Frequency of this use case seems low though. 
                    obj.recreateOccupancyCount(childRemoved);
                end
                
                % Update implicity grid size AFTER updating OccupancyCount since
                % it uses OccupancyCount to do the update
                obj.updateImplicitGridSize();
            end
        end
        
    end
    
    methods(Access = {?matlab.ui.container.GridLayout2,...
            ?matlab.ui.container.internal.model.CanvasContainerModel})
        % ---- Child added/removed ----------------------------------------
        
        function processChildAdded(obj, newChild)
            % A new child has been added to the container, figure out where
            % to place it in the grid
            %
            
            currentLayoutOptions = newChild.Layout;
            if obj.validateChildsLayoutOptions(currentLayoutOptions)
                return;
            end
            
            nextCell = obj.findNextAvailableCell();
            
            constraints = matlab.ui.layout.GridLayoutOptions;
            constraints.Row = nextCell(1);
            constraints.Column = nextCell(2);
            
            % Set Layout so the property can be marked dirty and
            % sent to the view
            newChild.setLayoutFromLayoutContainer(constraints);
            % Set the correct strategy for reporting position.
            % Not all components may use this strategy to report 
            % position. 
            obj.setupPositionReportStrategy(newChild);
        end
        
        function nextCell = findNextAvailableCell(obj)
            % Returns a 1x2 array representing the cell (row, column) where
            % to add the next component
            
            lastCell = obj.getLastOccupiedCell();
            
            numColumns = length(obj.PrivateColumnWidth);
            
            if(lastCell(2) == numColumns)
                % Last component is in the last column, so nextCell is the
                % first cell in the row below
                nextRow = lastCell(1) + 1;
                nextCell = [nextRow, 1];
                
            else
                % O/w, nextCell is the cell to the right on the same row
                nextCell = [lastCell(1), lastCell(2) + 1];
            end
            
        end
        
        
        function lastCell = getLastOccupiedCell(obj)
            % Returns a 1x2 array representing the last occupied cell (row,
            % col)
            %
            % This is different from getContentDrivenGridSize:
            % Here, we find the last component in the last row.
            % Therefore, the column of the last cell will often be
            % different from the number of columns returned by
            % getContentDrivenGridSize
            
            % Number of components per rows
            rowCount = sum(obj.OccupancyCount, 2);
            
            if (sum(rowCount) == 0)
                % empty grid
                lastCell = obj.getLastCellForEmptyGrid();
                return;
            end
            
            % The grid is non-empty, so no need to check for isempty after
            % 'find'
            
            % Find the last non-zero row
            occupiedRows = find(rowCount);
            lastOccupiedRow = occupiedRows(end);
            
            % Find the last non-zero column in the last row
            lastRow = obj.OccupancyCount(lastOccupiedRow, :);
            occupiedColumns = find(lastRow);
            lastOccupiedColumn = occupiedColumns(end);
            
            lastCell = [lastOccupiedRow, lastOccupiedColumn];
        end
        
        function initLastCell = getLastCellForEmptyGrid(obj)
            
            % Initialize in the last cell of the row above the first row.
            %
            % This is so we don't need to special case the scenarios where
            % - the grid has no children
            % - the grid is of size 0x0
            initLastCell = [0, length(obj.ColumnWidth)];
        end
        
        % ---- Update OccupancyCount --------------------------------------
        
        function recreateOccupancyCount(obj, childRemoved)
            % Create OccupancyCount based on the children's Layout property
            % This is used only when we cannot update the existing
            % OccupancyCount, e.g. when a child is removed.
            
            % Start with the explicit grid size
            obj.OccupancyCount = zeros(numel(obj.RowHeight), numel(obj.ColumnWidth));
            
            gridChildren = allchild(obj);
            if ~isempty(gridChildren)
                % Children can span multiple cells, so use the last spanned
                % cell.
                
                numChildren = length(gridChildren);
                for k = 1:numChildren
                    child = gridChildren(k);
                    
                    if childRemoved ~= child && isprop(child, 'Layout') && ...
                        isa(child.Layout, 'matlab.ui.layout.LayoutOptions')
                            % isa(child.Layout, 'matlab.ui.layout.GridLayoutOptions')
                        % Skip if:
                        % - it's the child that is being removed
                        % - the child is not laid out by the grid, since
                        % allchild returns internal objects like
                        % AnnotationPane, Legend, Colorbar
                        % - the child has a Layout property but is not laid
                        % out by the grid, e.g. Legend (g2275049) -- REMOVED/ALTERED
                        if isa(child.Layout, 'matlab.ui.GridLayoutOptions')                 
                            row = child.Layout.Row;
                            col = child.Layout.Column;
                        else
                            [row,col] = ind2sub([numel(obj.RowHeight) numel(obj.ColumnWidth)], ...
                                child.Layout.Tile);
                            if child.Layout.TileSpan(1) > 1
                                row = row + 0:1:(child.Layout.TileSpan(1)-1);
                            end
                            if child.Layout.TileSpan(2) > 1
                                col = col + 0:1:(child.Layout.TileSpan(2)-1);
                            end
                        end

                        obj.increaseOccupancyCount(row, col);
                    end
                end
            end
        end
        
        function increaseOccupancyCount(obj,row,col)
            % Increase occupancy count in the cell(s).
            % Inputs row,col are the cells occupied by the component.
            % They are 1x2 arrays in case of spanning
            
            [oldNumRows, oldNumCols] = size(obj.OccupancyCount);
            % If the cell to increase the count for is not in the grid, we
            % first need to increase the size of the OccupancyCount matrix.
            % Components can span multiple cels, so used last spanned cell.
            if (row(end) > oldNumRows)
                % add the extra rows with 0 count
                delta = row(end) - oldNumRows;
                obj.OccupancyCount(end+1: end+delta, :) = zeros(delta, oldNumCols);
            end
            if (col(end) > oldNumCols)
                % add the extra columns with 0 count
                delta = col(end) - oldNumCols;
                newNumRows = size(obj.OccupancyCount, 1);
                obj.OccupancyCount(:, end+1: end+delta) = zeros(newNumRows, delta);
            end
            % Increase count at that cell
            obj.OccupancyCount(row, col) = obj.OccupancyCount(row, col) + 1;
        end
        
        function decreaseOccupancyCount(obj,row, col)
            % Decrease occupancy count in the cell (row, col)
            % Inputs row,col are the cells occupied by the component.
            % They are 1x2 arrays in case of spanning
            
            obj.OccupancyCount(row, col) = obj.OccupancyCount(row, col) - 1;
        end
        
        function reshapeOccupancyCount(obj, implicitRows, implicitCols)
            % Update OccupancyCount by adding or removing zeros given the
            % implicit rows and cols.
            %
            % This is called after RowHeight or ColumnWidth is changed.
            % The components have been changed, so the OccupancyCount only
            % needs to be reshaped by adding or removing zeros to reflect
            % the new implicit grid size.
            
            % New occupancy matrix is as big as the implicit grid size
            newOccupancyCount = zeros(numel(implicitRows), numel(implicitCols));
            oldOccupancyCount = obj.OccupancyCount;
            
            % Both old and new OccupancyCount are at least as big as the
            % content driven size. The difference is only in the zeros.
            % So we can just take the smallest size in each direction and
            % apply the old to the new.
            numRows = min(size(oldOccupancyCount,1), size(newOccupancyCount,1));
            numCols = min(size(oldOccupancyCount,2), size(newOccupancyCount,2));
            newOccupancyCount(1:numRows, 1:numCols) = oldOccupancyCount(1:numRows, 1:numCols);
            
            obj.OccupancyCount = newOccupancyCount;
        end
        
        % ---- Implicit size ----------------------------------------------
        
        function implicitSize = computeImplicitSizeForSingleDirectionFromLength(obj, userSetSize, contentDrivenLength)
            
            % Number of rows or columns last set explicitly by user
            userSetLength = length(userSetSize);
            
            % Determine RowHeight or ColumnWidth
            if contentDrivenLength <= userSetLength
                % Use the user's explicitly set value
                implicitSize = userSetSize;
                
            elseif contentDrivenLength > userSetLength
                % Add implicit rows as needed to contain all components
                sizeDiff = contentDrivenLength - userSetLength;
                newSizes = repmat({'1x'},1,sizeDiff);
                implicitSize = [userSetSize, newSizes];
            end
            
            
        end
        
        function [rows,cols] = computeImplicitGridSize(obj)
            % Compute the number of rows and columns needed to fit all
            % components with as few implicit rows and columns as possible
            %
            % If there are more components than can fit in the user-set
            % dimensions (RowHeight, ColumnWidth), then this calculates
            % and returns the number of implicit rows and columns needed to
            % contain all the components
            %
            % Else, if the user dimensions are greater than or equal to the
            % content-driven dimensions, this returns the user dimensions
            %
            % Example: If a user has a 2x2 grid with 4 components, and then
            % adds a 5th component, the grid will add an implicit row to
            % make space for the new component. This will be reflected in
            % the RowHeight, and the grid dimensions will become 3x2.
            %
            % If the user removes the added component, the implicit row
            % will be removed, returning the grid to its last explicitly
            % set dimensions of 2x2.
            
            
            contentDrivenSize = obj.getContentDrivenGridSize();
            
            rows = obj.computeImplicitSizeForSingleDirectionFromLength(obj.LastUserSetSizes.RowHeight, contentDrivenSize(1));
            cols = obj.computeImplicitSizeForSingleDirectionFromLength(obj.LastUserSetSizes.ColumnWidth, contentDrivenSize(2));
        end
        
        function contentDrivenSize = getContentDrivenGridSize(obj)
            
            % Number of components per rows, and per columns
            rowCount = sum(obj.OccupancyCount, 2);
            colCount = sum(obj.OccupancyCount, 1);
            
            if (sum(rowCount) == 0)
                % empty grid
                contentDrivenSize = [0,0];
                return;
            end
            
            % The grid is non-empty, so no need to check for isempty after
            % 'find'
            
            % find the last non-zero row
            occupiedRows = find(rowCount);
            nRows = occupiedRows(end);
            
            % find the last non-zero column
            occupiedColumns = find(colCount);
            nCols = occupiedColumns(end);
            
            contentDrivenSize = [nRows, nCols];
        end
        
        function updateImplicitGridSize(obj)
            % Update Implicit Grid Size
            
            % Update the number of rows and columns in grid
            [rows,cols] = obj.computeImplicitGridSize();
            
            % Update object and send to the view
            if ~isequal(obj.PrivateRowHeight, rows)
                obj.PrivateRowHeight = rows;
                obj.markPropertiesDirty({'RowHeight'});
            end
            
            if ~isequal(obj.PrivateColumnWidth,cols)
                obj.PrivateColumnWidth = cols;
                obj.markPropertiesDirty({'ColumnWidth'});
            end
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Functions accessible by the controller
    % ---------------------------------------------------------------------
    methods (Access = {...
            ?matlab.ui.container.internal.controller.GridLayoutController
            })
        
        function setPositionFromClient(obj, newPosition)
            % Update model with new position
            obj.Position = newPosition;
        end
        
    end
    
    methods(Access = 'private', Static)
        
        function validateConstraintsPvPairs(pvPairs)
            % Validate that pvPairs has an even number of elements and that
            % all the property names are constraints that can be set for
            % the grid
            
            assert(mod(length(pvPairs), 2) == 0);
            
            propertyNames = pvPairs(1:2:end);
            
            % Get the cosntraints that are valid for the grid
            constraintsNames = properties('matlab.ui.layout.GridLayoutOptions');
            
            % Check that all property names are valid constraints
            isPropertyNameValid = ismember(propertyNames, constraintsNames);
            assert(all(isPropertyNameValid));
        end
        
        function output = validateRowColumnSize(input)
            % Validate that input is a valid RowHeight or ColumnWidth value
            %
            % Input must be a row cell array where each element is either:
            % - a positive number (pixel value)
            % - 'fit'
            % - 'Nx' where N is any positive number (weight)
            %
            % Strings are accepted and converted into char array
            % If the input is a column, it is accepted and converted into a
            % row
            %
            % e.g.
            % input = {10, 'fit'};
            % input = {'fit', '1x', '3x'};
            %
            % Arrays are accepted and converted into cells
            %
            % e.g.
            % ["1x", "2x", "fit"] is converted to {'1x', '2x', 'fit'}
            % [100, 200, 300] is converted to {100, 200, 300}
            
            
            if(iscell(input) && isempty(input))
                % Treat {} separately because it doesn't pass the test of
                % 'vector' in validateattribute
                output = input;
                return
            end
            
            % Convert string array to cell of chars
            if(isstring(input))
                input = cellstr(input);
            end
            
            % Convert numeric array to cell of numbers
            if(isnumeric(input))
                input = num2cell(input);
            end
            
            % Verify that it is a vector
            validateattributes(input, ...
                {'cell'}, ...
                {'vector'});
            
            % Reshape to row
            input = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(input, 'horizontal');
            
            % Validate each element of the cell
            output = input;
            isValid = true;
            
            for k = 1:length(input)
                el = input{k};
                
                isPositiveNumber = matlab.ui.control.internal.model.PropertyHandling.isPositiveNumber(el);
                
                if ~isPositiveNumber
                    
                    el = convertStringsToChars(el);
                    
                    isRowCharArray = ischar(el) && isrow(el);
                    if ~isRowCharArray
                        isValid = false;
                        break;
                    end
                    
                    isFit = strcmpi(el, 'fit');
                    if isFit
                        isValid = true;
                        el = 'fit';
                    else
                        % check for '1x', '2x', ...
                        doesEndWithX = length(el) >= 2 && (strcmpi(el(end), 'x'));
                        weight = str2double(el(1:end-1));
                        isWeightValid = matlab.ui.control.internal.model.PropertyHandling.isPositiveNumber(weight);
                        
                        isOfFormNx = doesEndWithX && isWeightValid;
                        if ~isOfFormNx
                            isValid = false;
                            break;
                        end
                        
                        % use weight directly to filter additional
                        % characters from the stored values:
                        % '+', leading zeros, trailing zeros
                        % Stored values will look like result of str2num
                        el = char(weight + "x");
                    end
                end
                
                % this element is valid, store it
                output{k} = el;
            end
            
            if ~isValid
                error('Invalid row/column size');
            end
        end
        
        
    end
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(~)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'RowHeight',...
                'ColumnWidth',...
                };
        end
        
        function str = getComponentDescriptiveLabel(~)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = '';
            
        end
        
    end
    
    methods(Static, ...
            Access = {?matlab.ui.internal.mixin.ComponentLayoutable, ...
            ?matlab.ui.container.internal.model.LayoutContainer})
        function layoutOptionsClass = getValidLayoutOptionsClassId()
            layoutOptionsClass = 'matlab.ui.layout.GridLayoutOptions';
        end
    end
    
    methods(Access = {?matlab.graphics.mixin.Layoutable, ...
            ?matlab.ui.container.internal.model.LayoutContainer})
        function handleChildLayoutPropChanged(obj, child, prevLayout)
            
            % Update OccupancyCount
            
            % Decrement the count for the previous cell
            %row = prevLayout.Row;
            %col = prevLayout.Column;
            [row,col] = getLayoutRC(obj, prevLayout);
            obj.decreaseOccupancyCount(row, col);
            
            % Increment the count for the new cell(s)
            %row = child.Layout.Row;
            %col = child.Layout.Column;
            [row,col] = getLayoutRC(obj, child.Layout);
            obj.increaseOccupancyCount(row, col);
            
            % AFter updating OccupancyCount
            obj.updateImplicitGridSize();
        end
    end

    methods(Access=private)
        function [row,col] = getLayoutRC(obj, layout)
            if (isa(layout, 'matlab.ui.layout.GridLayoutOptions'))
                % The Layout property was not changed (e.g. child was
                % unparented) so we can use it to update OccupancyCount
                row = layout.Row;
                col = layout.Column;
            elseif isa(layout, 'matlab.graphics.layout.TiledChartLayoutOptions')
                % ADDED
                [row,col] = ind2sub([numel(obj.RowHeight) numel(obj.ColumnWidth)], ...
                        layout.Tile);
                if layout.TileSpan(1) > 1
                    row = row + 0:1:(layout.TileSpan(1)-1);
                end
                if layout.TileSpan(2) > 1
                    col = col + 0:1:(layout.TileSpan(2)-1);
                end
            else
                % TODO: Error??
                row = []; col = [];
            end
        end
    end
end
