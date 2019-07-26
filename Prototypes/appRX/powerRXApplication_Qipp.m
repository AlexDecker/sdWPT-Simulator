%Qi++
%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%optimizing the resistance and the capacitance of the recever's setup

classdef powerRXApplication_Qipp < powerRXApplication
    properties
		%Application parameters
    	dt
    	imax %maximum acceptable current
		greedy %if true, always ask for the maximum current
		%pre-parametrized parameters
		Lr %self inductance
		Rt %transmitter's internal resistance
		Ct %transmitter's internal capacitance
		Lt %transmitter's self inductance
		V %peak voltage
		%operational parameters
		Rr %last used resistance
		Cr %last used capacitance
    end
    methods
        function obj = powerRXApplication_Qipp(id,dt,imax,greedy)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
			obj.greedy = greedy;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        
			%SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
           	
		   	%gets the inductance of the coil
			obj = getPreParameters(obj,WPTManager);

			%change its own capacitancy in order to ressonate at the operatonal frequency
			WPTManager = getResCapacitance(obj,WPTManager,0);
			
			netManager = setTimer(obj,netManager,0,obj.dt);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	%gets the phasor notation receiving current
			[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);

        	if(abs(I)>0)%if it is transmitting power
        		%sends its own current (continuing message)
		    	netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
				
				%get the variable parammeters from constants, I and w
				WPTManager = estimateParameters(obj,I,w);

				%the following command is used for checking the peak voltage
				if obj.V~=WPTManager.ENV,Vt_group(1)
					error('Please use a Qi v1 transmitter');
				end
			end

			%change its own capacitancy in order to optimize the received current
			WPTManager = updateImpedance(obj,WPTManager,GlobalTime);

			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

		%Some useful functions

		function obj = getPreParameters(obj,WPTManager)
			%get any environment (we assume the self inductances being constant
			env = WPTManager.ENV.envList(1);
			%For Qi, there are only 2 groups (the first for TX and the second for RX)
			[obj.Rt,Lt,obj.Ct] = getParameters(env,1);
			[obj.Rr,Lr,obj.Cr] = getParameters(env,2);
			%the equivalent inductance of the paralell coils
			obj.Lr = 1/sum(1./Lr);
			obj.Lt = 1/sum(1./Lt);
			obj.V = 5;%Qi v1
		end

		function WPTManager = getResCapacitance(obj,WPTManager,GlobalTime)
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);
			C = 1/(w^2*obj.Lr);%calculates the value for the resonance capacitor
			%applies the calculated value to the varcap
			WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C);
		end
		
		%core functions
		
		function WPTManager = estimateParameters(obj,I,w)
		end

		function WPTManager = updateImpedance(obj,WPTManager,GlobalTime)
		end
    end
end
