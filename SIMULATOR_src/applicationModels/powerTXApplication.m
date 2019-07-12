%APPLICATION MODEL FOR TX 
classdef powerTXApplication < powerApplication
    properties(Access=private)
		lastCTime %last modifications for capacitance or resistance
		lastRTime
    end
    methods(Access=public)
        function obj = powerTXApplication()
           obj@powerApplication(0);%building superclass structure (ID=0)
		   obj.lastCTime = -1;%Any time is allowed
		   obj.lastRTime = -1;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end
    end
    %Auxiliary functions
    methods(Access=protected)
        %get the current vector in phasor notation
        function [It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerTXApplication (getCurrents): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            [~,~,cI_groups,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            It = cI_groups(1:WPTManager.nt_groups);
        end
        %define the phasor voltages across the TX groups
        function WPTManager = setSourceVoltages(obj,WPTManager,Vt,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerTXApplication (setSourceVoltages): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            WPTManager = setVt(WPTManager, Vt, GlobalTime);
        end
        %define the operational angular frequency
        function WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,w)
        	if w<=0
        		error('powerTXApplication (setOperationalFrequency): w must be positive');
        	end
        	[~,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);%dummie, only in order to not modify the past
        	WPTManager.ENV.w = w;
        end
		%define the capacitance of the RLC circuits (column vector)
        function WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C)
			s = size(C);
        	if (s(1)~=WPTManager.nt_groups)||(s(2)~=1)
        		error('powerTXApplication (setCapacitance): C must be a nt_groups-sized column vector');
			else
				if(sum(R<=0)>0)
					error('powerTXApplication (setCapacitance): C must be positive');
				end
        	end
			if obj.lastCTime >= GlobalTime
				error('powerTXApplication (setCapacitance): GlobalTime conflict');
			end
        	[~,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);%dummie, only in order to not modify the past
        	WPTManager.ENV.C_group(1:WPTManager.nt_groups) = C;
        end
		%define the resistance of the RLC circuits (column vector)
        function WPTManager = setResistance(obj,WPTManager,GlobalTime,R)
			s = size(R);
        	if (s(1)~=WPTManager.nt_groups)||(s(2)~=1)
        		error('powerTXApplication (setResistance): R must be a nt_groups-sized column vector');
			else
				if(sum(R<=0)>0)
					error('powerTXApplication (setResistance): R must be positive');
				end
        	end
			if obj.lastRTime >= GlobalTime
				error('powerTXApplication (setResistance): GlobalTime conflict');
			end
        	[~,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);%dummie, only in order to not modify the past
        	WPTManager.ENV.R_group(1:WPTManager.nt_groups) = R;
        end
    end
end
