classdef testt
   

    properties
         a;

    end
    
    methods
        function obj = testt()
            obj.a.b = 1;
            obj.a.c = [1 1 1];

        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

