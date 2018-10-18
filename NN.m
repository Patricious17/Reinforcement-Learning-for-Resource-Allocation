classdef NN < handle
        
    properties
        W; P;
        n; m;
        nW;
        mask; bMask;
        type;
        Pold;
    end
    
    methods
        function obj = NN(n, m, string)
            obj.type = string;
            obj.n = n; obj.m = m;
            obj.mask = zeros(obj.n, obj.m);
            
            if string == "S"
                obj.mask = (triu(ones(n, m)) == 1) + (triu(ones(n, m), 1) == 1);
                obj.bMask = logical((obj.mask ~= 0));
                obj.mask(obj.bMask) = obj.mask(obj.bMask).^-1;
            elseif string == "NS"
                obj.mask = ones(n, m);
                obj.bMask = logical((obj.mask ~= 0));
            else
                disp('unknown NN string input');
                pause(100);
            end
            
            obj.nW = sum(sum(obj.bMask));
            obj.W = rand(obj.nW, 1);
            obj.P = zeros(obj.m, obj.n);
            obj.W2P();
            obj.Pold = [];
        end
        
        function updateWeights(obj, W)
            obj.W = W;
            obj.W2P();
        end
        
        function W2P(obj)
            obj.P = zeros(size(obj.P));
            obj.P(obj.bMask) = obj.W.*obj.mask(obj.bMask);
            
            if (obj.type == "S")
                obj.P = obj.P +(triu(obj.P,1))';
            elseif (obj.type == "NS")                
            end
            obj.Pold = [obj.Pold; obj.P];
        end
    end
end