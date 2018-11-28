classdef powerRXApplication_dummieCoils < powerRXApplication
    properties
    end
    methods
        function obj = powerRXApplication_dummieCoils(id)
            obj@powerRXApplication(id);%construindo a estrutura referente à superclasse
            obj.APPLICATION_LOG.DATA = 'Exemplo de log';
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	GlobalTime = 0;
        	timeInterval = 20+rand*80;%random interval between 20s and 100s
        	netManager = setTimer(obj,netManager,GlobalTime,timeInterval);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
            src = data(1);%remetente
            disp(['I have ID = ',num2str(obj.ID),' and I detected the device with ID = ',num2str(src)]);
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
            payload = obj.ID;
            payloadLen = 32;%bits
            %canal 1 de RF, 1000bps, 5W
            obj = setSendOptions(obj,1,1000,5);
            netManager = broadcast(obj,netManager,payload,payloadLen,GlobalTime);%faz um broadcast com seu id (0, 32 bits)
        end

    end
end
