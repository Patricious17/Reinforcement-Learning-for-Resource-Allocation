classdef SystemModel < handle

    properties
        parSM;
        A; B; C; D;
        nx; nu; nd;
        x0;
    end
    
    methods
        function obj = SystemModel()
            obj.A = []; obj.B = []; obj.D = []; obj.C = [];
            
            A = [-1.01887,  0.90506, -0.00215;
                0.82225, -1.07741, -0.17555;
                0.0    ,  0.0    , -1.0     ];
            B = [0; 0; 5]; C = [0  0  0]; D = [1; 0; 0];
            
            Aref = zeros(3,3);
            
            obj.A = [  A  ,  A  ;
                     Aref , Aref];
            obj.B = [B; [0; 0; 0]];
            obj.D = [D; [0; 0; 0]];
            obj.C = [C [0 0 0]];
            
            obj.nx = size(obj.A, 1); obj.nu = size(obj.B, 2); obj.nd = size(obj.D, 2);
            obj.x0 = [2; 1; -2; 2; 3; 1];
            obj.parSM.nx = obj.nx; obj.parSM.nu = obj.nu; obj.parSM.nd = obj.nd; obj.parSM.x0 = obj.x0; obj.parSM.A = obj.A; obj.parSM.B = obj.B; obj.parSM.C = obj.C; obj.parSM.D = obj.D;
        end
    end
end

