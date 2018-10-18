classdef Feature
    
    properties
        val;
        W;
    end
    
    methods
        function obj = Feature(val0, W0)
            obj.val = val0;
            obj.W   = W0;
        end
    end
end

