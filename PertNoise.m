classdef PertNoise < handle

    properties
        arr;
        N;
        it;
    end
    
    methods
        function obj = PertNoise(n, m, range)
            obj.it = 1;
            obj.arr = (rand(n, m) - 0.5)*range;
            obj.N = m;
        end
        
        function s = sampleSines(obj, t)
            s = sum(sin(obj.arr*t),2)/obj.N;
        end
        
        function  s = sampleEl(obj)
            s = obj.arr(mod(obj.it, obj.N));
            obj.it = obj.it + 1;
        end
    end
end

