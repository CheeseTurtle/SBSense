classdef TestClass < handle
    %TESTCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1;
        publprop;
    end
    
    properties(SetAccess=private,GetAccess=public)
        VectorValue (1,:);
    end

    properties(Dependent,SetAccess=public,GetAccess=public,SetObservable)
        VectorEnds (1,2);
    end

    properties(Access=protected)
        protprop;
    end
    properties(Access=private)
        privprop;
    end

    methods(Access=public)
        function donothing1(~)
        end
        donothing2(~);
    end
    methods(Access=public,Static)
        function donothingstatic1()
        end
        donothingstatic2();
    end

    methods(Access=private,Static)
        prifun2();
    end
    methods(Access=private)
        function prifun3(obj,varargin)
            fprintf('[prifun3 in classdef file] Calling method in private folder.\n');
            prifun3(obj,varargin{:}); % Dot syntax will cause infinite recursion
        end
        %method2(obj, varargin);
    end
    methods(Access=protected)
        prifun4(obj,varargin);
    end
    
    methods
        function obj = TestClass(inputArg1,inputArg2)
            %TESTCLASS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
            obj.publprop = obj.Property1;
            obj.protprop = obj.Property1;
            obj.privprop = obj.Property1;

            addlistener(obj, 'VectorEnds', 'PostSet', @obj.postset_VectorEnds);
        end

        function insertVector(obj, varargin)
            if nargin < 3
                idx = 2;
                vec = varargin{1};
            else
                idx = varargin{1};
                assert(isscalar(idx));
                vec = varargin{2};
            end
            if idx < 1
                obj.VectorValue = [vec obj.VectorValue];
            end
            obj.VectorValue = [ obj.VectorValue(1:idx) vec ...
                obj.VectorValue(idx+1:end)];
        end

        function [h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12] = privtest(obj, varargin)
            try
                prifun1(length(varargin));
                ME1 = MException.empty();
            catch ME1
            end
            try
                prifun2(varargin{:});
                ME2 = MException.empty();
            catch ME2
            end
            try
                %disp(isequal(@prifun3, @obj.prifun3));
                % obj.prifun3(varargin{:}); % Not defined
                prifun3(obj,varargin{:});
                ME3 = MException.empty();
            catch ME3
            end
            if ~isempty(ME1)
                fprintf('prifun1 error: %s\n', getReport(ME1));
            end
            if ~isempty(ME2)
                fprintf('prifun1 error: %s\n', getReport(ME2));
            end
            if ~isempty(ME3)
                fprintf('prifun1 error: %s\n', getReport(ME3));
            end
            h1 = @prifun1; % Scoped function: in private folder, parentage: {'prifun1'}
            if ~isequal(h1, str2func('prifun1'))
                fprintf('%s:\n', func2str(str2func('prifun1')));
                disp(functions(str2func('prifun1')));
            end
            if ~isequal(h1, str2func('@obj.prifun1'))
                fprintf('%s:\n', func2str(str2func('@obj.prifun1')));
                disp(functions(str2func('@obj.prifun1')));
            end
            if ~isequal(h1, str2func('@TestObject.prifun1')) && ...
                    ~isequal(str2func('@TestObject.prifun1'), str2func('@obj.prifun1'))
                fprintf('%s:\n', func2str(str2func('@TestObject.prifun1')));
                disp(functions(str2func('@TestObject.prifun1')));
            end
            h2 = @prifun2; % scoped (local)
            h3 = @prifun3; % scoped (local)
            h4 = @obj.prifun2; % anonymous
            h5 = @obj.prifun3; % anonymous
            h6 = @TestClass.prifun2; % classsimple
            
            h7 = str2func('@obj.donothing1'); %classsimple  
            % @obj.donothing1;
            h8 = str2func('@obj.donothing2'); %classsimple
            % @() obj.donothing2; 
            % @obj.donothing2;
            h9 = str2func('@obj.donothingstatic1'); % classsimple
            %@obj.donothingstatic1;
            h10 = str2func('obj.donothingstatic2'); % classsimple
            %@obj.donothingstatic2;
            h11 = @TestClass.donothingstatic1; % classsimple
            h12 = @TestClass.donothingstatic2; % classsimple
            %disp(isequal(h4, h6));
        end
        
        function call3(obj, opt, varargin)
            switch opt
                case 1 % Calls the one in the private folder
                    prifun3(obj,varargin{:});
                case 2
                    TestClass.prifun3(obj,varargin{:}); % Error: fcn not defined
                case 3
                    prifun4(obj, varargin{:});
                case 4
                    obj.prifun4(varargin{:});
                otherwise
                    obj.prifun3(varargin{:}); % Calls the one in the classdef file
            end
        end
        
        function callmethod2(obj,varargin)
            method2(obj,varargin{:});
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function value = get.VectorEnds(obj)
            if isempty(obj.VectorValue)
                value = obj.VectorValue;
            elseif isscalar(obj.VectorValue)
                value = obj.VectorValue;
            else
                value = obj.VectorValue([1 end]);
            end
        end

        function set.VectorEnds(obj, value)
            if isempty(obj.VectorValue) || isscalar(obj.VectorValue)
                obj.VectorValue(1,1:2) = value;
            else
                obj.VectorValue(1,[1 end]) = value;
            end
        end
    end

    methods(Access=private)
        function postset_VectorEnds(~, src, event)
            fprintf('src / event: %s / %s\n', src.Name, event.EventName);
            disp(src);
            disp(event);
            disp(isequal(src,event.Source));
            val = event.AffectedObject.(src.Name);
            if isempty(val)
                fprintf('\tNew value: <empty %s>\n', class(val));
            else
                fprintf('\tNew value: %s', formattedDisplayText(val));
            end
        end
    end
end

