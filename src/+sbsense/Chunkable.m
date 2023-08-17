classdef (Abstract, ConstructOnLoad=false) Chunkable
    properties (Abstract, Access=private)
        ChunkSize;
    end

    properties(Abstract, Dependent, SetAccess=public, GetAccess=public)
    end

    methods (Abstract, Access=private,Hidden=true)
    end

    methods(Abstract, Access=public)
    end
end