classdef Simulation < handle
    
    properties
        Z; u; d; t;
        nx; nu; nd;
        it; ix; ixx; ixu; ixd;
        Tsim; N
        irl;
        S;
        PNx; PNu; PNd;
        type;
    end
    
    methods
        function obj = Simulation(Tsim, type)
            obj.type = type;
            obj.Tsim = Tsim;
            obj.S = SystemModel(); obj.initIndexes();
            obj.irl = IRL(obj.S.parSM, obj.type);
            obj.Z =[]; obj.t = 0; obj.it = 0;
            obj.Z = [obj.S.x0; kron(obj.S.x0, zeros(obj.S.nx, 1)); kron(obj.S.x0, zeros(obj.S.nu, 1)); kron(obj.S.x0, zeros(obj.S.nd, 1))]';
            obj.N = obj.irl.N;
            obj.PNx = PertNoise(obj.S.nx, 1000, 100);
            obj.PNu = PertNoise(obj.S.nu, 1000, 100);
            obj.PNd = PertNoise(obj.S.nd, 1000, 100);
        end
        
        function step(obj)
            obj.it = obj.it + 1;
            if (mod(obj.it, obj.N + 1))
                obj.runEpisode();
                if (obj.type == "Linear")
                    obj.irl.updateData(kron(obj.Z(  1, obj.ix), obj.Z(  1, obj.ix))', obj.Z(  1, obj.ixx)', obj.Z(  1, obj.ixu)', obj.Z(  1, obj.ixx)', obj.Z(  1, obj.ixd)', obj.Z(  1, obj.ixx)',...
                                       kron(obj.Z(end, obj.ix), obj.Z(end, obj.ix))', obj.Z(end, obj.ixx)', obj.Z(end, obj.ixu)', obj.Z(  1, obj.ixx)', obj.Z(end, obj.ixd)', obj.Z(  1, obj.ixx)');
                elseif (obj.type == "Non-Linear")
                    obj.irl.updateData(kron(obj.Z(  1, obj.ix), obj.Z(  1, obj.ix))', obj.Z(  1, obj.ixx)', obj.Z(  1, obj.ixu)', obj.Z(  1, obj.ixx)', obj.Z(  1, obj.ixd)', obj.Z(  1, obj.ixx)',...
                                       kron(obj.Z(end, obj.ix), obj.Z(end, obj.ix))', obj.Z(end, obj.ixx)', obj.Z(end, obj.ixu)', obj.Z(  1, obj.ixx)', obj.Z(end, obj.ixd)', obj.Z(  1, obj.ixx)');
                end
                
            elseif (~mod(obj.it, obj.N + 1))
%                 obj.runEpisode();
%                 obj.irl.updateData(obj.Z(  1, obj.ix)', obj.Z(  1, obj.ixx)', obj.Z(  1, obj.ixu)', obj.Z(  1, obj.ixd)', ...
%                                    obj.Z(end, obj.ix)', obj.Z(end, obj.ixx)', obj.Z(end, obj.ixu)', obj.Z(end, obj.ixd)');
                obj.irl.learn();
            end
        end
        
        function runEpisode(obj)
            % if working with the real system, collect actual sensor
            % readings here
            [obj.t, obj.Z]=ode23(@obj.odeSys, [(obj.it-1)*obj.irl.T,obj.it*obj.irl.T], obj.Z(end, :));
        end
        
        function dZ = odeSys(obj, t, Z)
            x = Z(obj.ix);
            obj.irl.policyUpdate(x);
            obj.updateInput(t); obj.updateDisturbance(t);
            obj.irl.propagate(x, obj.u, obj.d, t, obj.it)
            if (obj.type == "Linear")
                dZ = [
                   obj.S.A*x + obj.S.B*obj.u + obj.S.D*obj.d + [80 0 0 0.1 0.1 0.1]'.*obj.PNx.sampleSines(t); % ###
                   obj.irl.dxx ;
                   obj.irl.duPu;
                   obj.irl.ddPd;
                 ];
            elseif (obj.type == "Non-Linear")
                dZ = [
                   obj.S.A*Z(obj.ix) + obj.S.B*obj.u + obj.S.D*obj.d + [80 0 0 0.1 0.1 0.1]'.*obj.PNx.sampleSines(t); % ###
                   obj.irl.dxx  ;
                   obj.irl.duPu ;
                   obj.irl.ddPd ;
                   obj.irl.dPuPu; % TODO add indexes to Z
                   obj.irl.dPdPd; % TODO add indexes to Z
                 ];
            end
            
            [80 0 0 0.1 0.1 0.1]'.*obj.PNx.sampleSines(t)
        end
        
        function updateInput(obj, t)
            obj.u = obj.irl.ui + 50*obj.PNu.sampleSines(t);
            obj.u = - [0 0 0.005 0 0 0.005] * obj.Z(obj.ix)' + 50*obj.PNu.sampleSines(t);
        end
        
        function updateDisturbance(obj, t)
            obj.d = 0.01 + obj.PNd.sampleSines(t);
        end
        
        function initIndexes(obj)
            obj.ix  = 1:obj.S.nx;
            obj.ixx = obj.ix(end)  + 1 : obj.ix(end)  + obj.S.nx*obj.S.nx;
            obj.ixu = obj.ixx(end) + 1 : obj.ixx(end) + obj.S.nx*obj.S.nu;
            obj.ixd = obj.ixu(end) + 1 : obj.ixu(end) + obj.S.nx*obj.S.nd;
        end
    end
end