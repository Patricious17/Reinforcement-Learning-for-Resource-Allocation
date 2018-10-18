classdef RLterm < handle
    
    properties

    end
    
    methods
        function obj = RLterm()
            
        end
        
        %% quad z'*A*W*B*z = vec(W)'*kron(B,A')*kron(z,z) || lin z'*A*W = vec(W)'*(kron(I,A'))*(kron(I,z))        
        function coeff = genQuadCoeff(obj,A,B)
            coeff = kron(B,A);
        end
        
        function coeff = genLinCoeff(obj,A)
            coeff = genQuadCoeff(A,eye(size(A,1)));
        end
        
    end
end

