classdef (Abstract) Datastorable < matlab.mixin.indexing.RedefinesParen

    methods (Abstract, Access=public)
        % Concatenates the ContainedArray property of one or more instances of the class.
        obj3 = cat(obj,obj2);

        %  Returns an instance of the class with an empty ContainedArray.
        obj2 = empty(obj);

        % Returns the dimensions of ContainedArray.
        S = size(obj);
    end

    methods(Abstract,Hidden,Access=public)
        % Deletes parentheses-indexed elements of ContainedArray.
        obj = parenDelete(obj, indexOp);

        %  Determines the number of values to return from parentheses indexing operations on ContainedArray.
        n =  parenListlength(obj,indexOp,ctx);

        % Handles parentheses indexing into ContainedArray.
        % varargout = parenReference(obj,indexOp);

        [TF,idxDif] = isInMemory(obj, idx);
        [TF,idxDif] = isInDatastore(obj,idx);
    end

    methods(Abstract,Hidden,Access=protected)
        parenAssignMemory(obj, indices, val);
        parenAssignDatastore(obj, indices, val);
        varargout = parenReferenceMemory(obj, indices);
        varargout = parenReferenceDatastore(obj, indices);
    end

    properties (Abstract,SetAccess=private,GetAccess=public)
        Items;
        Datastore;
        EmptyItem;
        DatastoreIndexRange;
        MemoryIndexRange;
        MemorySize;
    end

    methods(Hidden,Access=public)
        % Assigns values to the indexed elements of ContainedArray. The right-hand side of the assignment expression must be an instance of ArrayWithLabel.
        function obj = parenAssign(obj, indexOp, varargin)
            for i = 1:(nargin-2)
                indices = indexOp.Indices{i};
                msk1 = isInMemory(obj, indices);
                
                if all(msk1)
                    parenAssignMemory(obj, indices, varargin{1});
                elseif any(msk1)
                    parenAssignMemory(obj, indices(msk1), varargin{1});
                    indices2 = indices(~msk1);
                    msk2 = isInDatastore(obj, indices2);
                    parenAssignDatastore(obj, indices2(msk2));
                else
                    parenAssignDatastore(obj, indices2);
                end
            end
        end

        function varargout = parenReference(obj, indexOp)
            [varargout{:}] = cellfun(@obj.parenRef, indexOp.Indices, ...
                'UniformOutput', false);
        end
    end
    
    methods (Hidden, Access=private)
        function varargout = parenRef(obj, indices)
            if indices==':'
                if obj.MemoryIndexRange(2) >= obj.DatastoreIndexRange(2)
                    if obj.DatastoreIndexRange(1) > 1
                        varargout{1:obj.DatastoreIndexRange(1)} = obj.EmptyItem;
                    end
                    [varargout{obj.DatastoreIndexRange(1):obj.DatastoreIndexRange(2)}] = ...
                            readall(obj.Datastore);
                    if obj.DatastoreIndexRange(2)+1<obj.MemoryIndexRange(1)
                        [varargout{obj.DatastoreIndexRange(2):end+1-obj.MemorySize}] = ...
                            obj.EmptyItem;
                    end
                    if iscell(obj.Items)
                        [varargout{end+1-obj.MemorySize}] = obj.Items{:};
                    else
                        [varargout{end+1-obj.MemorySize}] = deal(obj.Items);
                    end
                else
                    if obj.MemoryIndexRange(1)<obj.DatastoreIndexRange(1)
                        if obj.MemoryIndexRange(1)>1
                        end
                    else
                        if obj.DatastoreIndexRange(1) > 1
                            varargout{1:obj.DatastoreIndexRange(1)} = obj.EmptyItem;
                        end
                        if obj.DatastoreIndexRange(2) >= obj.MemoryIndexRange(1)
                        else
                        end
                        [varargout{obj.DatastoreIndexRange(1):obj.DatastoreIndexRange(2)}] = ...
                            readall(obj.Datastore);
                    end
                end
            else
                msk1 = isInMemory(obj, indices);
                if all(msk1)
                    
                elseif any(msk1)
                else
                    
                end
            end
        end
    end
end