classdef IRL < handle
    
    properties
        
        %% system specific
        nx; nu; nd;

        %% RL specific
        alpha; T; gamma; N;
        NN1; NN2; NN3;
        Pi; ui; di;
        
        %% features        
        xox0; E_ux0; E_dx0; cost0
        xoxT; E_uxT; E_dxT; costT
        dE_ux; dE_dx; dc;
        H; Y;
    end
    
    methods
        function obj = IRL(nx, nu, nd, alpha, gamma, T)
            %% init, instantiate NNs, 
            obj.nx = nx; obj.nu = nu; obj.nd = nd;
            obj.alpha = alpha; obj.T = T; obj.gamma = gamma;
            obj.NN1 = NN(nx*nx); obj.NN2 = NN(nx*nu); obj.NN3 = NN(nx*nd);
            obj.H = []; obj.Y = [];
        end
        
        function propagate(obj, x, u, d, t)
            % update will depend on the basis set (if non-linear, then actiavtion funtion for x should be non-linear)
            % the change of approximator NN should be reflected through this
            % fucntion, other parts of code would not change much
            e = exp(-obj.alpha*t);
            obj.dE_ux = e*kron((u-obj.ui), x); 
            obj.dE_dx = e*kron((d-obj.di), x);
            obj.dc = e*(-x'*obj.Q*x - obj.ui'*obj.R*obj.ui + obj.gamma^2*obj.di'*obj.di);
        end
        
        function updateData(obj, x, E_ux, E_dx, cost)
            obj.updateNewFeatures(x, E_ux, E_dx, cost);
            obj.updateH();
            obj.updateY();
            obj.storeOldFeatures();
        end
        
        function updateH(obj)

            h = [exp(-obj.alpha*obj.T)*obj.xoxT-obj.xox0;
                        -(obj.E_uxT - obj.E_ux0)        ;
                        -(obj.E_dxT - obj.E_dx0)        ];
            obj.H = [obj.H, h];
        end
        
        function updateY(obj)
            y = obj.costT - obj.cost0;
            obj.Y = [obj.Y; y];
        end
        
        function updateNewFeatures(obj, x, E_uxT, E_dxT, cost)
            obj.xoxT = kron(x,x); obj.E_uxT = E_uxT; obj.E_dxT = E_dxT; obj.costT = cost;
        end
        
        function storeOldFeatures(obj)
            obj.xox0 = obj.xoxT; obj.E_ux0 = obj.E_uxT; obj.E_dx0 = obj.E_dxT; obj.cost0 = obj.costT;
        end
    end
end