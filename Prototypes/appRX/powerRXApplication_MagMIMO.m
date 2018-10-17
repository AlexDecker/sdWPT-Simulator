classdef powerRXApplication_MagMIMO < powerRXApplication
    properties
    end
    methods
        function obj = powerRXApplication_MagMIMO(id)
            obj@powerRXApplication(id);%construindo a estrutura referente à superclasse
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end

    end
end
