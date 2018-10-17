classdef powerTXApplication_MagMIMO < powerTXApplication
    properties
    	V %tensão
    end
    methods
        function obj = powerTXApplication_MagMIMO(V)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
            obj.V = V;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,0,1000);
        	WPTManager = setSourceVoltages(obj,WPTManager,obj.V,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,GlobalTime,1000);
        end
    end
end
