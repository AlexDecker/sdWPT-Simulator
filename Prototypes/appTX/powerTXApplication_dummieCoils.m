classdef powerTXApplication_dummieCoils < powerTXApplication
    properties
    end
    methods
        function obj = powerTXApplication_dummieCoils()
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	WPTManager = setSourceVoltages(obj,WPTManager,0,0); %turn off the WPT system
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end
    end
end
