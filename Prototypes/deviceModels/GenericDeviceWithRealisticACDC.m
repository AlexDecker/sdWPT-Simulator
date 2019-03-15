classdef GenericDeviceWithRealisticACDC < Device
    properties(SetAccess = protected, GetAccess = public)
        currentConverter %AC/DC converter instantiated from CurrentConverter class
    end

    methods
        function obj = GenericDeviceWithRealisticACDC(working,maxCurrent,currentConverter)
		obj@Device(working,maxCurrent,1);
		obj.currentConverter = currentConverter;
        end

        %only the prototype
        function r=check(obj)
            r=(length(obj.working)==1)&&(length(obj.maxCurrent)==1)...
            	&&(length(obj.efficiency)==1)&&(obj.maxCurrent>0)...
            	&&(obj.efficiency>0)&&(obj.efficiency<=1)...
            	&&check(obj.currentConverter);
        end

        %returns the expected current according to the charging procedure of the battery
        %(only the function prototype here)
        function [obj,Ie] = expectedCurrent(obj)
            Ie = Inf;
        end

        %-avgChargeCurrent_ac (A, phasor): averege input current at this time interval
        %-timeVariation (s): time interval
        function [obj,DEVICE_DATA] = updateDeviceState(obj, avgChargeCurrent_ac, timeVariation, DEVICE_DATA, time)
            
            %AC to DC
            avgChargeCurrent_dc = getDCFromAC(obj.currentConverter,avgChargeCurrent_ac);
            
            %limits the current in order to not damage the bettery and the rest of the circuit
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
