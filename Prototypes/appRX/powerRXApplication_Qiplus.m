%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency

classdef powerRXApplication_Qiplus < powerRXApplication
    properties
    	dt
    	imax %maximum acceptable current
    end
    methods
        function obj = powerRXApplication_Qiplus(id,dt,imax)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
			WPTManager = setCapacitance(obj,WPTManager,0,1.7023e-04);
            netManager = setTimer(obj,netManager,0,obj.dt/10);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
			
        	if(abs(I)>0)%if it is transmitting power
        		%sends its own current (continuing message)
		    	netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
			end

			%change its own capacitancy in order to ressonate at the operatonal frequency
			WPTManager = setCapacitance(obj,WPTManager,GlobalTime,1.7023e-04);
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt/10);
        end

    end
end
