%This algorithm is centralized to the transmitting part and is constituted by two stages.
%The first one is responsible for obtaining the magnectic channel between the receiver and
%each transmitting coil. The second one, in turn, calculates the beamforming currents and 
%charges the receiver in fact.

classdef powerTXApplication_MagMIMO < powerTXApplication
    properties
		interval1 %time interval used to measure the channel for one coil (stage 1)
		interval2 %time that a beamform value is assumed to keep valid (stage 2)
		rV %reference voltage, used for channel estimation
		%coil which channel will be individually measured
		%(stage 1->target=1..nt,stage2->target=nt+1)
		target
		RL %load resistance, got from messages form the power receiver
    end
    methods
        function obj = powerTXApplication_MagMIMO(referenceVoltage, interval1, interval2)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
			obj.interval1 = interval1;
			obj.interval2 = interval2;
			obj.rV = referenceVoltage;
			obj.RL = 0;%dummie
			obj.m = [];%magnetic channel
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
			%setting a dummie first magnetic channel vector
			obj.m = zeros(WPTManager,1);
        	%appy the reference voltage for the next measurements
			WPTManager = setSourceVoltages(obj,WPTManager,[obj.rV;zeros(WPTManager.nt-1,1)],GlobalTime);
			%keep the voltage to measure the results next round
			netManager = setTimer(obj,netManager,GlobalTime,obj.interval1);
			target = 2;
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
			%measure current for target-1
			if obj.target>1
				[It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);
				Isi = It(obj.target-1);
				%TODO
			end
			%set voltage for the measurement of target
			if target==WPTManager.nt+1
				%no more target, next is simply stage 2
				%calculate the optimum values
				I = calculateBeamformingCurrents(obj);
				V = voltagesFromCurrents(obj,I);
				%appy the calculated voltages
				WPTManager = setSourceVoltages(obj,WPTManager,V,GlobalTime);
				%keep the calculated voltage to charge the device
				netManager = setTimer(obj,netManager,GlobalTime,obj.interval2);
				%next stage will be 1 again
				target = 1;
			else
				%appy the reference voltage for the next measurements
				WPTManager = setSourceVoltages(obj,WPTManager,[zeros(target-1,1);obj.rV;zeros(WPTManager.nt-target,1)],GlobalTime);
				%keep the voltage to measure the results next round
				netManager = setTimer(obj,netManager,GlobalTime,obj.interval1);
				target = target + 1;
			end			
        end
		
		%utils---------------------------------------
		function I = calculateBeamformingCurrents(obj)
			%TODO
		end
		
		function V = voltagesFromCurrents(obj,I)
			%TODO
		end
    end
end
