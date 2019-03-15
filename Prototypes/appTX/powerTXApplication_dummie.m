%This application creates time events only for the simulation terminate at time-limit

classdef powerTXApplication_dummie < powerTXApplication
    properties
    	V %voltage vector (only sources)
    end
    methods
        function obj = powerTXApplication_dummie(V)
            obj@powerTXApplication();%building superclass structure
            obj.V = V;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,0,1000);
        	WPTManager = setSourceVoltages(obj,WPTManager,obj.V,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,GlobalTime,1000);
        end
    end
end
