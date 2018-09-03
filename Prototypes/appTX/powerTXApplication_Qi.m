%Aplicação de acordo com o protocolo Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
    properties
    end
    methods
        function obj = powerTXApplication_exemplo(timeSkip,ifactor,iVel,vtBaseVector)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(netManager,0,0,1000);
        	WPTManager = setSourceVoltages(obj,WPTManager,5,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
        	netManager = setTimer(netManager,0,0,1000); 
        end
    end
end
