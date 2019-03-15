%Exemple of transmitting application

%Performs two functions in parallel
%1-Discovers the devices around
%2-Adaps gradatively the voltage until reach 90% of the maximum supported by the source
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
            obj@powerTXApplication();%building superclass structure
            obj.APPLICATION_LOG.DATA = zeros(2,0);
            obj.timeSkip = timeSkip;
            obj.ifactor = ifactor;
            obj.iVel = iVel;
            obj.V = 0;
            obj.dV = iVel;
            obj.vtBaseVector = vtBaseVector;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
            %channel 1 of RF, 1000bps, 5W
            obj = setSendOptions(obj,1,1000,5);
            netManager = broadcast(obj,netManager,0,32,0);%(myId=0, 32 bits)
            netManager = setTimer(obj,netManager,0,obj.timeSkip);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
            src = data(1);%catch the sender id
            disp(['DEVICE ',num2str(src),' DETECTED!']);
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
            [WPTManager,P] = getPower(obj,WPTManager,GlobalTime);
            if (WPTManager.ENV.maxAppPower*0.9)<P
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
            P = abs(obj.V*I'*obj.vtBaseVector);%calculates the apparent current
        end
    end
end
