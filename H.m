classdef H < handle
    
    properties
        v; u_pu; pu_pu; d_pd; pd_pd;
        features;
        M;
        parH; % learning parameters (originate from IRL object)
        nx; nu; nd;
        n1; n2; n3;
        m1; m2; m3; m4; m5;
        NNv; NNu; NNd;
        val;
    end
    
    methods
        function obj = H(irl)
            obj.val = [];
            obj.parH = irl;
            obj.parH.gamma2 = irl.gamma * irl.gamma;
            obj.nx = obj.parH.sm.nx; obj.nu = obj.parH.sm.nu; obj.nd = obj.parH.sm.nd;
            
            obj.NNv = NN(obj.nx, obj.nx, 'S' ); % P matrix is symmetric, redundant weights, avoiding singularity
            obj.NNu = NN(obj.nx, obj.nu, 'NS');
            obj.NNd = NN(obj.nx, obj.nd, 'NS');
            
            % make sure all features are properly initialized at this point
            v0     = kron(irl.sm.x0, irl.sm.x0); v0 = v0(obj.NNv.bMask);
            pu0    = zeros(obj.nx, 1);
            pd0    = zeros(obj.nx, 1);
            u_pu0  = zeros(obj.nx * obj.nu, 1);
            pu_pu0 = zeros(obj.nx * obj.nx, 1);
            d_pd0  = zeros(obj.nx * obj.nd, 1);
            pd_pd0 = zeros(obj.nx * obj.nx, 1);
            
            Mv     =                                                   eye(length( v0 ));
            Mu_pu  =   2 * kron(obj.parH.R,                            eye(length(pu0)));
            Mpu_pu = - 2 * kron(obj.parH.R * irl.Wu0',                 eye(length(pu0)));
            Md_pd  = - 2 * obj.parH.gamma2 * kron(eye(length(obj.nd)), eye(length(pd0)));
            Mpd_pd =   2 * obj.parH.gamma2 * kron(irl.Wd0',            eye(length(pd0)));
            
            obj.n1 = size(Mv, 1); obj.n2 = size(Mu_pu, 1); obj.n3 = size(Md_pd, 1);
            obj.m1 = size(Mv, 2); obj.m2 = size(Mu_pu, 2); obj.m3 = size(Mpu_pu, 2); obj.m4 = size(Md_pd, 2); obj.m5 = size(Mpd_pd, 2);
            
            obj.M = [        Mv          , zeros(obj.n1, obj.m2), zeros(obj.n1, obj.m3), zeros(obj.n1, obj.m4), zeros(obj.n1, obj.m5) ;...
                    zeros(obj.n2, obj.m1),        Mu_pu         ,       Mpu_pu         , zeros(obj.n2, obj.m4), zeros(obj.n2, obj.m5) ;...
                    zeros(obj.n3, obj.m1), zeros(obj.n3, obj.m2), zeros(obj.n3, obj.m3),        Md_pd         ,        Mpd_pd        ];
            
            obj.v     = Feature(v0, Mv);            
            obj.u_pu  = Feature( u_pu0,  Mu_pu);
            obj.pu_pu = Feature(pu_pu0, Mpu_pu);            
            obj.d_pd  = Feature( d_pd0,  Md_pd);
            obj.pd_pd = Feature(pd_pd0, Mpd_pd);
            
            obj.features = [obj.v.val; obj.u_pu.val; obj.pu_pu.val; obj.d_pd.val; obj.pd_pd.val];
        end
        
        function updateAproximators(obj, W)
            obj.NNv.updateWeights(W(1:obj.NNv.nW));
            obj.NNu.updateWeights(W(obj.NNv.nW + 1 : obj.NNv.nW + obj.nx*obj.nu));
            obj.NNd.updateWeights(W(obj.NNv.nW + obj.nx*obj.nu + 1 : obj.NNv.nW + obj.nx*obj.nu + obj.nx*obj.nd));
        end
        
        function updateFeatures(obj, v, u_pu, pu_pu, d_pd, pd_pd)
            obj.v.val     =     v;
            obj.u_pu.val  =  u_pu;
            obj.pu_pu.val = pu_pu;
            obj.d_pd.val  =  d_pd;
            obj.pd_pd.val = pd_pd;
            
            if obj.it > obj.N
                obj.features = [obj.features, [obj.v.val; obj.u_pu.val; obj.pu_pu.val; obj.d_pd.val; obj.pd_pd.val]];
            else
                obj.features = [obj.features(:, 2:end), [obj.v.val; obj.u_pu.val; obj.pu_pu.val; obj.d_pd.val; obj.pd_pd.val]];
            end
        end
        
        function updateM(obj, Wu, Wd)
            % Wu and Wd may be matrices (in fact they usually are)
            obj.pu_pu.W = - 2 *        kron(obj.lPar.R*Wu', eye(obj.pu_pu.n));
            obj.pd_pd.W =   2 * obj.lPar.gamma2 * kron(Wd', eye(obj.pd_pd.n));
            
            obj.M(obj.n1 + 1          : obj.n1 + obj.n2,...
                  obj.m1 + obj.m2 + 1 : obj.m1 + obj.m2 + obj.m3) = obj.pu_pu.W;
            
            obj.M(obj.n1 + obj.n2 + 1                   : obj.n1 + obj.n2 + obj.n3,...
                  obj.m1 + obj.m2 + obj.m3 + obj.m4 + 1 : obj.m1 + obj.m2 + obj.m3 + obj.m4 + obj.m5) = obj.pd_pd.W;
        end
        
        function updateH(obj)
            obj.val = obj.M * obj.features;
        end
    end
end