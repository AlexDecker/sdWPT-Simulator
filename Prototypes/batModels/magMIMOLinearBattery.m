classdef magMIMOLinearBattery < linearBattery

    properties
        rlLookupTable
    end

    methods
        function obj = magMIMOLinearBattery(rlFile,ocvFile,Rc,Rd,Q0,Qmax,Rmax,fase1Limit,...
            constantCurrent_min,constantCurrent_max,constantVoltage,...
            limitToBegin, plotData)
            
            %build the structure referent to the superclass
            obj@linearBattery(ocvFile,Rc,Rd,Q0,Qmax,Rmax,fase1Limit,...
		        constantCurrent_min,constantCurrent_max,constantVoltage,...
		        limitToBegin, plotData);
            
            %get the table that relates RL to SOC
            obj.rlLookupTable = LookupTable(rlFile,plotData);
        end

        %verify if the parameters are ok
        function r=check(obj)
            r = obj@check(obj) && check(obj.rlLookupTable);
        end
		
		%in this modeling, there is not notion of phases
        function [obj,fase] = getFase(obj)
            fase=1;
        end

        %in this modeling, there is not the notion of expected current
        function [obj,I] = expectedCurrent(obj)
            I = inf;
        end
        
        %returns the actual load resistance. -1 for adaptative calculation
        function RL = getRL(obj)
        	RL = getYFromX(obj.rlLookupTable,getSOC(obj));
        end

        %updates the charge based on the current (A) provided by the charger and on
        %the current (A) consumed by the device. The time variation must be in seconds.
        function [obj,DEVICE_DATA] = updateCharge(obj,charge_current,discharge_current,timeVariation,DEVICE_DATA,time)
            [obj,Fase] = getFase(obj);
            current = charge_current-discharge_current;
            
            obj.Q = obj.Q+current*timeVariation;
            if obj.Q>obj.Qmax%limits SOC to 100%
                obj.Q=obj.Qmax;
            end
            
            %log-------------------
            DEVICE_DATA = logSOCData(DEVICE_DATA,getSOC(obj),time);
            %log-------------------
        end
    end
end
