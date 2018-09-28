%MODELO DE APLICAÇÃO DO TX
classdef powerTXApplication < powerApplication
    properties
    end
    methods(Access=public)
        function obj = powerTXApplication()
           obj@powerApplication(0);%construindo a estrutura referente à superclasse (ID=0)
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
        	if(GlobalTime>obj.CurrTime)
        		error('powerTXApplication (getCurrents): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            [~,~,cI_groups,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            It = cI_groups(1:WPTManager.nt_groups);
        end
        %define as tensões 'Vt' das fontes dos transmissores em fasores
        function WPTManager = setSourceVoltages(obj,WPTManager,Vt,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerTXApplication (setSourceVoltages): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            WPTManager = setVt(WPTManager, Vt, GlobalTime);
        end
        %define a frequencia angular operacional
        function WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,w)
        	if w<=0
        		error('powerTXApplication (setOperationalFrequency): w must be positive');
        	end
        	[~,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);%dummie, apenas para nao afetar o passado
        	WPTManager.ENV.w = w;
        end
    end
end
