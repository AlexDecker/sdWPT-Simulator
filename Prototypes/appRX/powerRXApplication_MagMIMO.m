classdef powerRXApplication_MagMIMO < powerRXApplication
    properties
    	interval
    end
    methods
        function obj = powerRXApplication_MagMIMO(id,interval)
            obj@powerRXApplication(id);%building superclass structure
            obj.interval = interval;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT, 2048bps, 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
            netManager = setTimer(obj,netManager,0,obj.interval);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
        	netManager = send(obj,netManager,0,[],128,GlobalTime);
			netManager = setTimer(obj,netManager,GlobalTime,obj.interval);
        end

    end
end
