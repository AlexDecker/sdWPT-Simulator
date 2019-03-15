%based on the model present on "Analysis and parameters optimization of 
%a contactless IPT system for EV charger", by Chen et al.

classdef genericDeviceWithBattery < Device
	properties(SetAccess = private, GetAccess = public)
		power_m %averege power consumption (W)
		power_sd %standard deviation of the consumption
		minV %minimal voltage for the device to operate
		minVTO %minimal voltage for the device to turn on
		err %acceptable percentual calculation error (between 0 e 1)
	end

	methods
		function obj = genericDeviceWithBattery(battery, power_m, power_sd,...
			minV, minVTO, err, efficiency)
			obj@Device(false,battery.constantCurrent_max,efficiency);%starts turned off
			obj.bat = battery;
			obj.power_m = power_m;
			obj.power_sd = power_sd;
			obj.minV = minV;
			obj.minVTO = minVTO;
			obj.err = err;
			obj.chargeCurrent = 0;
			obj.dischargeCurrent = 0;
			obj.Vbatt = getVBatt(obj.bat,0);

			if ~check(obj)
				error('genericDeviceWithBattery: parameter error');
			end
		end

		%verify if the parameters are ok
		function r=check(obj)
			r=(obj.power_m>=0)&&(obj.power_sd>=0)&&(obj.minV>=0)&&...
				(obj.minVTO>=obj.minV)&&(obj.err>0)&&(obj.err<1)&&check(obj.bat)&&...
				(obj.efficiency>=0)&&(obj.efficiency<=1);
		end

		%retorns the expected current according to the charging procedure of the battery
		function [obj,Ie] = expectedCurrent(obj)
			[obj.bat,Ie] = expectedCurrent(obj.bat);
			Ie = Ie/obj.efficiency;
		end
        
		%rerturns the statical value of the load resistance
		%if -1, calculateRL will estimate it.
		function RL = getRL(obj)
			RL = getRL(obj.bat);
		end

		%-avgChargeCurrent_ac (A, phasor): average input current for this time interval
		%-timeVariation (s): time interval
		function [obj,DEVICE_DATA] = updateDeviceState(obj, avgChargeCurrent_ac,...
			timeVariation, DEVICE_DATA, time)
 
			%AC to DC
			avgChargeCurrent_dc = obj.efficiency * abs(avgChargeCurrent_ac);
            
			%protects the battery from high currents
			if(avgChargeCurrent_dc>obj.bat.constantCurrent_max)
				avgChargeCurrent_dc = obj.bat.constantCurrent_max;
				warningMsg('Very high current');
			end
         
			%generates a value of power consumption
			if(obj.power_sd>0)
				P = normrnd(obj.power_m,obj.power_sd);
			else
				%if you don't want to intall statistics package, set power_ds=0
				P = obj.power_m;
			end

			V=0;
			if obj.working %if the device is turned on
				V = getVBattWithDischarge(obj.bat,avgChargeCurrent_dc,P,obj.err);
				if(V>=obj.minV)
					discharge_current = P/V;%power/voltage=current
				else
					discharge_current = 0;
					obj.working = false;%if low voltage, turn off
				end
			else
				V = getVBatt(obj.bat,avgChargeCurrent_dc);
				if(V>=obj.minVTO)%is it possible to turn on?
					V = getVBattWithDischarge(obj.bat,avgChargeCurrent_dc,P,obj.err);
					if(V>=obj.minV)%is it really possible to stay on?
						discharge_current = P/V;%power/voltage=current
						obj.working = true;%the voltage is nice. turn on
					else %the actual configuration is not enough to keep the device working
						discharge_current = 0;
						warningMsg('mintVTO is very small compared to minV');
					end
				else
					discharge_current = 0;
				end
			end
			[obj.bat,DEVICE_DATA] = updateCharge(obj.bat,avgChargeCurrent_dc,discharge_current,...
				timeVariation,DEVICE_DATA,time);
			%Log--------------------------------------
			DEVICE_DATA = logCCData(DEVICE_DATA,avgChargeCurrent_dc,time);
			DEVICE_DATA = logDCData(DEVICE_DATA,discharge_current,time);
			DEVICE_DATA = logVBData(DEVICE_DATA,V,time);
			%Log--------------------------------------
			obj.chargeCurrent = avgChargeCurrent_dc;
			obj.dischargeCurrent = discharge_current;
			obj.Vbatt = V;
		end
	end
end
