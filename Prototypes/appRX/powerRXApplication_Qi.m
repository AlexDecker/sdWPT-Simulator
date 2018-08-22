%Aplicação de acordo com o protocolo Qi v1.0

classdef powerRXApplication_Qi < powerRXApplication
    properties
    end
    methods
        function obj = powerRXApplication_exemplo(id)
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
