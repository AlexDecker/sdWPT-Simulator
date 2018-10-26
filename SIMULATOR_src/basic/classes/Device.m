%Deve ser utilizado como base para a modelagem de novos consumidores de energia
classdef Device
    properties(SetAccess = protected, GetAccess = public)
        working %bool, mostra quando o dispositivo está funcionando
		maxCurrent %corrente máxima para não danificar o dispositivo
		efficiency %eficiência de conversão da corrente
		bat
		
        chargeCurrent
        dischargeCurrent
        Vbatt
    end

    methods
        function obj = Device(working,maxCurrent,efficiency)
			obj.working = working;
			obj.maxCurrent = maxCurrent;
			obj.efficiency = efficiency;
			obj.bat.Q = 0;
			
            obj.chargeCurrent = 0;
            obj.dischargeCurrent = 0;
            obj.Vbatt = 0;
        end

        %only the prototype
        function r=check(obj)
            r=(length(obj.working)==1)&&(length(obj.maxCurrent)==1)...
            	&&(length(obj.efficiency)==1)&&(obj.maxCurrent>0)...
            	&&(obj.efficiency>0)&&(obj.efficiency<=1);
        end

        %returns the current expected according to the charging procedure
        %of the battery (prototype)
        function [obj,Ie] = expectedCurrent(obj)
            Ie = Inf;
        end
        
        %rerturns the static value for the actual load resistance.
        %if -1, calculateRL will estimate it. (prototype)
        function RL = getRL(obj)
        	RL = -1;
        end

        %-avgChargeCurrent_ac (A, phasor): mean input current for the time interval
        %-timeVariation (s): time interval
        function [obj,DEVICE_DATA] = updateDeviceState(obj, avgChargeCurrent_ac, timeVariation, DEVICE_DATA, time)
            
            %AC to DC
            avgChargeCurrent_dc = obj.efficiency * abs(avgChargeCurrent_ac);
            
            %limits the current in order to not damage the battery
            if(avgChargeCurrent_dc>obj.maxCurrent)
                avgChargeCurrent_dc = obj.maxCurrent;
                warningMsg('Very high current');
            end
            
            %Log--------------------------------------
            DEVICE_DATA = logCCData(DEVICE_DATA,avgChargeCurrent_dc,time);
            DEVICE_DATA = logDCData(DEVICE_DATA,0,time);
            DEVICE_DATA = logVBData(DEVICE_DATA,0,time);
            %Log--------------------------------------
            obj.chargeCurrent = avgChargeCurrent_dc;
            obj.dischargeCurrent = 0;
            obj.Vbatt = 0;
        end
    end
end
