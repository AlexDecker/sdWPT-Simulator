%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency

%TODO: fazer a tal modificacao

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
			disp('Ainda nao modificado!!!!!!!!');
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
            netManager = setTimer(obj,netManager,0,obj.dt);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
        	if(abs(I)>0)%if it is transmitting power
        		%sends its own current (continuing message)
		    	netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
		    end
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

    end
end
