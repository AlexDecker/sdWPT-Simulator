%Deve ser utilizado como base para a modelagem de novos consumidores de energia
classdef Device
    properties(SetAccess = protected, GetAccess = public)
        working %bool, mostra quando o dispositivo está funcionando
		maxCurrent %corrente máxima para não danificar o dispositivo
		
        chargeCurrent
        dischargeCurrent
        Vbatt
    end

    methods
        function obj = Device(working,maxCurrent)
			obj.working = working;
			obj.maxCurrent = maxCurrent;
			
            obj.chargeCurrent = 0;
            obj.dischargeCurrent = 0;
            obj.Vbatt = 0;
        end

        %apenas o protótipo
        function r=check(obj)
            r=true;
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
            avgChargeCurrent_dc = obj.efficiency * abs(avgChargeCurrent_ac);
            
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
