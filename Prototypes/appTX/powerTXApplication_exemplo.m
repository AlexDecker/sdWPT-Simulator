%Aplicação exemplo do TX

%Executa paralelamente duas funções:
%1-Faz a descoberta dos dispositivos ao redor
%2-Adapta gradativamente a tensão até 90% do máximo suportado pela fonte
classdef powerTXApplication_exemplo < powerTXApplication
    properties
        ifactor
        iVel
        timeSkip
        dV
        V
        vtBaseVector
    end
    methods
        function obj = powerTXApplication_exemplo(timeSkip,ifactor,iVel,vtBaseVector)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
            obj.APPLICATION_LOG.DATA = zeros(2,0);
            obj.timeSkip = timeSkip;
            obj.ifactor = ifactor;
            obj.iVel = iVel;
            obj.V = 0;
            obj.dV = iVel;
            obj.vtBaseVector = vtBaseVector;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
            %canal 1 de RF, 1000bps, 5W
            obj = setSendOptions(obj,1,1000,5);
            netManager = broadcast(obj,netManager,0,32,0);%faz um broadcast com seu id (0, 32 bits)
            netManager = setTimer(obj,netManager,0,obj.timeSkip);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
            src = data(1);%pega o remetente
            disp(['DEVICE ',num2str(src),' DETECTED!']);
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
            [WPTManager,P] = getPower(obj,WPTManager,GlobalTime);
            if (WPTManager.ENV.maxPower*0.9)<abs(P)
                obj.V = obj.V-obj.dV;
                obj.dV = obj.iVel;
            else
                obj.dV = obj.dV*obj.ifactor;
                obj.V = obj.V+obj.dV;
            end

            if obj.V>0
                tupla = [obj.V; GlobalTime];
                obj.APPLICATION_LOG.DATA = [obj.APPLICATION_LOG.DATA, tupla];
                WPTManager = setSourceVoltages(obj,WPTManager,obj.V*obj.vtBaseVector,GlobalTime);
            else
                obj.V=0;
            end
            
            netManager = setTimer(obj,netManager,GlobalTime,obj.timeSkip);
        end

        function [WPTManager,P] = getPower(obj,WPTManager,GlobalTime)
            [I,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);
            P = obj.V*(obj.vtBaseVector.')*I;
        end
    end
end
