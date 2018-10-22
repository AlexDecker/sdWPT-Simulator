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
        	if(GlobalTime>obj.CurrTime)
        		error('powerRXApplication (getI): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            [~,~,cI_groups,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            I = cI_groups(WPTManager.nt_groups+obj.ID);
        end
        %obtém a corrente de recarga, a corrente de descarga e a tensão da bateria
        function [Ir,Id,Vb,RL,WPTManager] = getBatteryParams(obj,WPTManager,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerRXApplication (getBatteryParams): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end	
        		
            [~,~,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            
            Ir = WPTManager.deviceList(obj.ID).obj.chargeCurrent;
            Id = WPTManager.deviceList(obj.ID).obj.dischargeCurrent;
            Vb = WPTManager.deviceList(obj.ID).obj.Vbatt;
			RL = WPTManager.previousRL(obj.ID);
        end
    end
end
