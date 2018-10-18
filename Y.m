classdef Y < handle
    
    properties
        px; pu; pd;
        features;
        M;
        parY; % learning parameters (originate from IRL object)
        nx; nu; nd;
        m1; m2; m3;
        val;
    end
    
    methods
        function obj = Y(irl)
            obj.parY = irl;
            obj.parY.gamma2 = irl.gamma * irl.gamma;
            obj.nx = obj.parY.sm.nx; obj.nu = obj.parY.sm.nu; obj.nd = obj.parY.sm.nd;
            
            Mpx = -obj.parY.Q(:);
            Mpu = -obj.parY.Wu0 * obj.parY.R * obj.parY.Wu0'; Mpu = Mpu(:);
            Mpd =  obj.parY.Wd0 * obj.parY.Wd0'; Mpd = Mpd(:);
            
            obj.m1 = length(Mpx); obj.m2 = length(Mpu); obj.m3 = length(Mpd);
            
            obj.M = [Mpx; Mpu; Mpd]';
            
            obj.px = Feature(zeros(obj.nx.^2), Mpx); obj.pu = Feature(zeros(obj.nx.^2), Mpu); obj.pd = Feature(zeros(obj.nx.^2), Mpd);
            
            obj.features = [obj.px; obj.pu; obj.pd];
        end
        
        function updateFeatures(obj, px, pu, pd)
            obj.px = px; obj.pu = pu; obj.pd = pd;
            
            if obj.it > obj.N
                obj.features = [obj.features, [obj.px; obj.pu; obj.pd]];
            else
                obj.features = [obj.features(:, 2:end), [obj.px; obj.pu; obj.pd]];
            end
        end
        
        function updateM(obj, Wu, Wd)
            Mpu = -Wu * obj.lPar.R * Wu';
            Mpd =  Wd * Wd';
            
            obj.M(1, obj.m1 + 1          : obj.m1 + obj.m2)          = (Mpu(:))';
            obj.M(1, obj.m1 + obj.m2 + 1 : obj.m1 + obj.m2 + obj.m3) = (Mpd(:))';
        end
        
        function updateY(obj)
            obj.val = obj.M * obj.features;
        end
    end
end