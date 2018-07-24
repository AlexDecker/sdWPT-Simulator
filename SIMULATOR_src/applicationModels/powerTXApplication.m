%MODELO DE APLICAÇÃO DO TX
classdef powerTXApplication < powerApplication
    properties
    end
    methods(Access=public)
        function obj = powerTXApplication()
           obj@powerTXApplication(0);%construindo a estrutura referente à superclasse (ID=0)
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
        %obtém um vetor 'I' de correntes em fasores.
        function [It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime)
            [Current,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            It = Current(1:WPTManager.nt);
        end
        %define as tensões 'Vt' das fontes dos transmissores em fasores
        function WPTManager = setSourceVoltages(obj,WPTManager,Vt,GlobalTime)
            WPTManager = setVt(WPTManager, Vt, GlobalTime);
        end
    end
end