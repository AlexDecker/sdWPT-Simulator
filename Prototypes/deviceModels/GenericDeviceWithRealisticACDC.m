classdef GenericDeviceWithRealisticACDC < Device
    properties(SetAccess = protected, GetAccess = public)
        currentConverter %AC/DC converter instantiated from CurrentConverter class
    end

    methods
        function obj = GenericDeviceWithRealisticACDC(working,maxCurrent,currentConverter)
			obj@Device(working,maxCurrent,1);
			obj.currentConverter = currentConverter;
        end

        %apenas o protótipo
        function r=check(obj)
            r=(length(obj.working)==1)&&(length(obj.maxCurrent)==1)...
            	&&(length(obj.efficiency)==1)&&(obj.maxCurrent>0)...
            	&&(obj.efficiency>0)&&(obj.efficiency<=1)...
            	&&check(obj.currentConverter);
        end

        %retorna a corrente esperada de acordo com o procedimento de
        %carregamento da bateria (protótipo)
        function [obj,Ie] = expectedCurrent(obj)
            Ie = Inf;
        end

        %-avgChargeCurrent_ac (A, phasor): média da corrente de entrada no intervalo de tempo
        %-timeVariation (s): intervalo de tempo
        function [obj,DEVICE_DATA] = updateDeviceState(obj, avgChargeCurrent_ac, timeVariation, DEVICE_DATA, time)
            
            %converte a corrente para DC
            avgChargeCurrent_dc = getDCFromAC(obj.currentConverter,avgChargeCurrent_ac);
            
            %limita a corrente para não danificar a bateria
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
