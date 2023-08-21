classdef testclass
    properties(GetAccess=public,SetAccess=immutable)
        sz (1,1) double;
        dims (1,2) double;
    end

    properties(GetAccess=public,SetAccess=private)
        value;
    end

    methods
        function obj = testclass(sz,dims)
            obj.sz = sz;
            obj.dims = dims;
        end

        function setValue(obj, value)
            arguments(Input)
                obj;
                value (obj.sz, 1)
            end
        end
    end
end)