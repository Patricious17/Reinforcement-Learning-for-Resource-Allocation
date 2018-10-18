classdef IRL < handle
    
    properties
        
        %% system specific
        nx; nu; nd;

        %% RL specific
        alpha; T; gamma; N; it;
        Pi; ui; di; Pu; Pd;
        errorP;
        Q; R; Popt;
        parRL;
        Wu; Wd
        
        %% features
        dE_xx; dE_ux; dE_dx;
        Dxx; DIxx; DIuPu; DIPuPu; DIdPd; DIPdPd;
        H; Y;
        dxx; duPu; dPuPu; ddPd; dPdPd;
        f;
        %%
        data;
        %%
        type;
    end
    
    methods
        function obj = IRL(sm, type)
            %% init, instantiate NNs
             obj.Q = [20 0 0 0 0 0;
                       0 0 0 0 0 0;
                       0 0 0 0 0 0;
                       0 0 0 0 0 0;
                       0 0 0 0 0 0;
                       0 0 0 0 0 0];
            obj.R = eye(sm.nu);
            obj.N = 200; %3*(nx*nx+nx*nu+nx*nd+1);
            obj.alpha = 0.01; obj.T = 0.1; obj.gamma = 10; obj.it = 0; obj.errorP = [];
            %% optimal solution
            obj.Popt = care(sm.A-0.5*obj.alpha*eye(sm.nx), sm.B, obj.Q, obj.R); 
            obj.parRL.sm = sm; obj.nx = obj.parRL.sm.nx; obj.nu = obj.parRL.sm.nu; obj.nd = obj.parRL.sm.nd;
            obj.parRL.Q = obj.Q; obj.parRL.R = obj.R; obj.parRL.alpha = obj.alpha; obj.parRL.T = obj.T; obj.parRL.gamma = obj.gamma; obj.parRL.N = obj.N;
            %% policy matrices
            obj.Wu = zeros(obj.nx, obj.nu); obj.Wd = zeros(obj.nx, obj.nd);
            obj.parRL.Wu0 = obj.Wu; obj.parRL.Wd0 = obj.Wd;
            %% features
            obj.f.Pd = []; obj.f.Pu = []; obj.f.Pv = []; obj.updateFeatures(sm.x0);
            obj.H = H(obj.parRL); obj.Y = Y(obj.parRL);
            %%
            obj.type = type;
        end
        
        function learn(obj)
            obj.generateDataMatrices();
            W = obj.H.val'\obj.Y.val; %(obj.H*obj.H')^-1*obj.H*obj.Y;
            obj.updateWeights(W);
        end
        
        function propagate(obj, x, u, d, t, it)
            %% used to propagate through ode (replace with good numerical integration in the real system)
            e = exp(-obj.alpha*(t - (it-1)*obj.T));
            obj.updateFeatures(x);
            obj.duPu  = e * kron(u, obj.f.Pu);
            obj.ddPd  = e * kron(d, obj.f.Pd);
            obj.dxx   = e * kron(x, x);
            
            if (obj.type == "Linear")
                obj.dPuPu = obj.dxx;
                obj.dPdPd = obj.dxx;
            elseif (obj.type == "Non-Linear")
                obj.dPuPu = e * kron(obj.f.Pu, obj.f.Pu);
                obj.dPdPd = e * kron(obj.f.Pd, obj.f.Pd);
            end
        end
        
        function updateData(obj, Pv0, Ixx0, IuPu0, IPuPu0, IdPd0, IPdPd0,...
                                 PvT, IxxT, IuPuT, IPuPuT, IdPdT, IPdPdT)
            obj.it = obj.it + 1;
            e = exp(-obj.alpha*obj.T);
            obj.Dxx   = e * PvT - Pv0;
            obj.DIxx  = IxxT  - Ixx0;
            obj.DIuPu = IuPuT - IuPu0;
            obj.DIdPd = IdPdT - IdPd0;
            
            if (obj.type == "Linear")
                obj.DIPuPu = obj.DIxx;
                obj.DIPdPd = obj.DIxx;
            elseif (obj.type == "Non-Linear")
                obj.DIPuPu = IPuPuT - IPuPu0;
                obj.DIPdPd = IPdPdT - IPdPd0;
            end
            
            obj.H.updateFeatures( obj.Dxx, obj.obj.DIuPu, obj.DIPuPu, obj.DIdPd, obj.DIPdPd);
            obj.Y.updateFeatures(obj.DIxx, obj.DIxx, obj.DIxx); % need to generalize for different features like already done for H
        end
        
        function updateFeatures(obj, x)
            obj.f.Pu = x; obj.f.Pd = x;
            obj.f.Pv = kron(x, x);
        end
        
        function policyUpdate(obj, x)
            obj.updateFeatures(x);
            obj.ui = obj.Wu' * obj.f.Pu; obj.di = obj.Wd' * obj.f.Pd;
        end
        
        function generateDataMatrices(obj)
            obj.H.updateM(obj.Wu, obj.Wd); obj.Y.updateM(obj.Wu, obj.Wd);
            obj.H.updateH(); obj.Y.updateY();
        end
        
        function updateWeights(obj, W)
            obj.H.updateAproximators(W);
            obj.Wu = obj.H.NNu.P; obj.Wd = obj.H.NNd.P;
            obj.errorP = [obj.errorP; norm(obj.NN1.P - obj.Popt)];
        end
    end
end