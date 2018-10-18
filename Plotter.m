classdef Plotter < handle
    
    properties
        mode;
        postPlots;
        RTPlots; % real time plots

    end
    
    methods
        function obj = Plotter(mode)
            obj.mode = mode;
            obj.postPlots = [];
            obj.RTPlots = [];
        end
        
        function rtPlot(obj)
            
        end
        
        function postPlot(obj, data)
            for i = 1 : length(data)
                obj.postPlots = [obj.postPlots, obj.singlePlot(data(i))]; % store the handle on plots in an array 
            end
        end
        
        function p = singlePlot(obj, X)
            p = plot(X.t, X.data);
        end
    end
end

