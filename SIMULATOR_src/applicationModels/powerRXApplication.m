%MODELO DE APLICAÇÃO DO RX
classdef powerRXApplication < powerApplication
    properties
    end
    methods(Access=public)
        function obj = powerRXApplication(id)
            obj@powerApplication(id);%construindo a estrutura referente à superclasse
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)           
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end
    end
    %Funções auxiliares
    methods(Access=protected)
        %obtém um escalar 'I' da corrente em fasor.
        function [I,WPTManager] = getI(obj,WPTManager,GlobalTime)
            [Current,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            I = Current(WPTManager.nt+obj.id);
        end
    end
end