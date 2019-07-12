%APPLICATION MODEL FOR RX DEVICES
classdef powerRXApplication < powerApplication
    properties
		lastCTime %last modification of capacitance
		lastRTime %last modification of resitance
    end
    methods(Access=public)
        function obj = powerRXApplication(id)
            obj@powerApplication(id);%bulding the superclass structure
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
		%get the current within the coil in phasor notation
        function [I,WPTManager] = getI(obj,WPTManager,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerRXApplication (getI): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end
            [~,~,cI_groups,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            I = cI_groups(WPTManager.nt_groups+obj.ID);
        end
		%get the charging current, the discharge current, the battery voltage and the
		%equivalent resistance of the device.
        function [Ir,Id,Vb,RL,WPTManager] = getBatteryParams(obj,WPTManager,GlobalTime)
        	if(GlobalTime>obj.CurrTime)
        		error('powerRXApplication (getBatteryParams): Inconsistent time value');
        	else
        		obj.CurrTime = GlobalTime;
        	end	
        		
            [~,~,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
			
            Ir = WPTManager.deviceList(obj.ID).obj.chargeCurrent;
            Id = WPTManager.deviceList(obj.ID).obj.dischargeCurrent;
            Vb = WPTManager.deviceList(obj.ID).obj.Vbatt;
			RL = WPTManager.previousRL(obj.ID);
        end
		%define the capacitance of the RLC circuits (non-negative scalar)
		function WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C)
			s = size(C);
			if (s(1)~=1)||(s(2)~=1)
		    	error('powerRXApplication (setCapacitance): C must be a scalar');
			else
				if(C<0)
		        	error('powerRXApplication (setCapacitance): C must be non-negative');
				end
			end
			if obj.lastCTime >= GlobalTime
				error('powerRXApplication (setCapacitance): GlobalTime conflict');
			end
			%dummie, only in order to not modify the past
			[~,WPTManager] = getI(obj,WPTManager,GlobalTime);
			WPTManager.ENV.C_group(WPTManager.nt_groups+obj.ID) = C;
		end
		%define the resistance of the RLC circuits (non-negative scalar)
		function WPTManager = setResistance(obj,WPTManager,GlobalTime,R)
			s = size(R);
			if (s(1)~=1)||(s(2)~=1)
		    	error('powerRXApplication (setResistance): R must be a scalar');
			else
				if(R<0)
		        	error('powerRXApplication (setResistance): R must be non-negative');
				end
			end
			if obj.lastRTime >= GlobalTime
				error('powerRXApplication (setResistance): GlobalTime conflict');
			end
			%dummie, only in order to not modify the past
			[~,WPTManager] = getI(obj,WPTManager,GlobalTime);
			WPTManager.ENV.R_group(WPTManager.nt_groups+obj.ID) = R;
		end

    end
end
