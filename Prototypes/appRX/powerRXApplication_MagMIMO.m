classdef powerRXApplication_MagMIMO < powerRXApplication
    properties
    	interval
		Rr %internal resistance (pre-parametrized)
    end
    methods
        function obj = powerRXApplication_MagMIMO(id,interval)
            obj@powerRXApplication(id);%building superclass structure
            obj.interval = interval;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT configurations, 300bps (fig 8 of the paper), 5W (dummie)
			[~,~,~,RL,WPTManager] = getBatteryParams(obj,WPTManager,0);
			Z = getCompleteLastZMatrix(WPTManager);
			obj.Rr = Z(end,end)-RL;
            obj = setSendOptions(obj,0,2048,5);
            netManager = setTimer(obj,netManager,0,1);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
			%send perodically the resistance of the load to the power transmitter
        	[~,~,~,RL,WPTManager] = getBatteryParams(obj,WPTManager,GlobalTime);
			%message assumed to have 32 bits
        	netManager = send(obj,netManager,0,RL+obj.Rr,32,GlobalTime);
			netManager = setTimer(obj,netManager,GlobalTime,obj.interval);
			%if it is fully charged, end the simulation
			SOC = getSOC(WPTManager.deviceList(obj.ID).obj.bat);
			if (SOC==1)
				obj = endSimulation(obj);
			else
				disp(['MagMIMO progress: ',num2str(100*SOC),...
					'%.(',num2str(GlobalTime/3600),'h of virtual time)']);
				disp(['Expected finishing time: ',num2str(GlobalTime/(3600*SOC)),'h']);
			end
        end

    end
end
