%This algorithm is centralized to the transmitting part and is constituted by two stages.
%The first one is responsible for obtaining the magnectic channel between the receiver and
%each transmitting coil. The second one, in turn, calculates the beamforming currents and 
%charges the receiver in fact.

classdef powerTXApplication_MagMIMO < powerTXApplication
    properties
		interval1 %time interval used to measure the channel for one coil (stage 1)
		interval2 %time that a beamform value is assumed to keep valid (stage 2)
		
		rV %reference voltage, used for channel estimation
		
		m %vector used for the estimation of each magnetic channel
		
		%coil which channel will be individually measured
		%(stage 1->target=1..nt,stage2->target=nt+1)
		target
		
		RL %load resistance, got from messages form the power receiver
		
		ZT %impedance sub-matrix for the transmitting elements
		Rt %internal resistance of the transmitting RLCs
		
		P_active %maximum active power to be spent
		P_apparent %maximum apparent power (limits the maximum current)
    end
    methods
        function obj = powerTXApplication_MagMIMO(referenceVoltage, interval1, interval2, P_active, P_apparent)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
			obj.interval1 = interval1;
			obj.interval2 = interval2;
			obj.rV = referenceVoltage;
			obj.P_active = P_active;
			obj.P_apparent = P_apparent;
			
			%dummie values
			obj.RL = 0;
			obj.m = [];
			obj.ZT = [];
			obj.Rt = 0;		
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
			%SWIPT configurations, 300bps (fig 8 of the paper), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
			%getting the ZT sub-matrix (for a real life implementation, these values have to be
			%pre-parametrized)
			Z = getCompleteLastZMatrix(WPTManager);
			obj.ZT = Z(1:WPTManager.nt,1:WPTManager.nt);
			obj.Rt = mean(diag(obj.ZT));
			%setting a dummie first magnetic channel vector
			obj.m = zeros(WPTManager.nt,1);
        	%appy the reference voltage for the next measurements
			WPTManager = setSourceVoltages(obj,WPTManager,[obj.rV;zeros(WPTManager.nt-1,1)],0);
			%keep the voltage to measure the results next round
			netManager = setTimer(obj,netManager,0,obj.interval1);
			obj.target = 2;
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
			%the resistance of the load is sent by the power receiver periodically
			obj.RL = data;
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
			if obj.RL>0
				%measure current for target-1
				if obj.target>1
					[It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);
					Isi = It(obj.target-1);
					%equation 12 of the paper
					obj.m(obj.target-1) = -(1i)*sqrt((obj.rV/Isi-obj.Rt)/obj.RL);
				end
				%set voltage for the measurement of target
				if obj.target==WPTManager.nt+1
					%no more target, next is simply stage 2
					%calculate the optimum values
					I = calculateBeamformingCurrents(obj);
					IL = calculateIL(obj,I);
					V = voltagesFromCurrents(obj,I,IL);
					%close all circuits
					WPTManager = setResistance(obj,WPTManager,GlobalTime,obj.Rt*ones(WPTManager.nt,1));
					%appy the calculated voltages
					WPTManager = setSourceVoltages(obj,WPTManager,V,GlobalTime);
					%keep the calculated voltage to charge the device
					netManager = setTimer(obj,netManager,GlobalTime,obj.interval2);
					%next stage will be 1 again
					obj.target = 1;
				else
					%appy the reference voltage for the next measurements
					WPTManager = setSourceVoltages(obj,WPTManager,...
						[zeros(obj.target-1,1);obj.rV;zeros(WPTManager.nt-obj.target,1)],GlobalTime);
					%open all circuits but the target
					WPTManager = setResistance(obj,WPTManager,GlobalTime,...
						[WPTManager.ENV.maxResistance*ones(obj.target-1,1);obj.Rt;...
						WPTManager.ENV.maxResistance*ones(WPTManager.nt-obj.target,1)]);
					%keep the voltage to measure the results next round
					netManager = setTimer(obj,netManager,GlobalTime,obj.interval1);
					obj.target = obj.target + 1;
				end
			else
				netManager = setTimer(obj,netManager,GlobalTime,obj.interval2);
				warningMsg('Inconsistant data about the load resistance. Nothing to be done.');
			end
        end
		
		%utils---------------------------------------
		function I = calculateBeamformingCurrents(obj)
			%equation 8 of the paper
			beta = obj.m./sum(abs(obj.m).^2);
			%voltage considering only the base vector for the current
			Vbeta = voltagesFromCurrents(obj,beta,calculateIL(obj,beta));
			%limiting the active power spent
			k1 = sqrt(obj.P_active/real(beta'*Vbeta));
			%limiting the applarent power
			k2 = sqrt(obj.P_apparent/abs(beta'*Vbeta));
			%using the most limiting constant
			if k1<k2
				I = k1*beta;
			else
				I = k2*beta;
			end
		end
		
		function Vt = voltagesFromCurrents(obj,I,IL)
			%equation 13 of the paper
			Vt = [obj.ZT, obj.m*obj.RL]*[I;IL];
		end
		
		function IL = calculateIL(obj,I)
			IL = -(obj.m.')*I;
		end
    end
end
