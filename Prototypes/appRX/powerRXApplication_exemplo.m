%Example application for the RX device
classdef powerRXApplication_exemplo < powerRXApplication
    properties
    end
    methods
        function obj = powerRXApplication_exemplo(id)
            obj@powerRXApplication(id);%building superclass structure
            obj.APPLICATION_LOG.DATA = 'Exemple of log';
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
            dst = data(1);
            payload = obj.ID;
            payloadLen = 32;%bits
            %channel 1 of RF, 1000bps, 5W
            obj = setSendOptions(obj,1,1000,5);
            netManager = send(obj,netManager,dst,payload,payloadLen,GlobalTime);%answares the remetent with this id
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end

    end
end
