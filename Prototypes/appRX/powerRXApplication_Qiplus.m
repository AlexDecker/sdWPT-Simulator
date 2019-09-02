%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%making the RX setup resonating with the operational frequency

classdef powerRXApplication_Qiplus < powerRXApplication
    properties
    	dt
    	imax %maximum acceptable current
		L %self inductance (for tunning the varicap)
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
           	
		   	%gets the inductance of the coil
			obj = getSelfInductance(obj,WPTManager);

			%change its own capacitancy in order to ressonate at the operatonal frequency
			WPTManager = updateCapacitance(obj,WPTManager,0);
			
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

			%change its own capacitancy in order to ressonate at the operatonal frequency
			WPTManager = updateCapacitance(obj,WPTManager,GlobalTime);

			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

		%Some useful functions

		%gets the inductance of the coil
		function obj = getSelfInductance(obj,WPTManager)
			%get any environment (we assume the self inductances being constant
			env = WPTManager.ENV.envList(1);
			%For Qi, there are only 2 groups (the first for TX and the second for RX)
			[~,L,~] = getParameters(env,2);
			%the equivalent inductance of the paralell coils
			obj.L = 1/sum(1./L);
		end

		function WPTManager = updateCapacitance(obj,WPTManager,GlobalTime)
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);
			C = 1/(w^2*obj.L);%calculates the value for the resonance capacitor
			%applies the calculated value to the varcap
			%disp(['RX: ',num2str(C),' F']);
			WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C);
		end
    end
end
