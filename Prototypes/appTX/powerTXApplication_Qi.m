%Aplicação de acordo com o protocolo Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
    properties
    	d0
        vel
        zone1Limit
        zone2Limit
        mi1
        mi2
    end
    methods
        function obj = powerTXApplication_Qi(d0,vel,zone1Limit,zone2Limit,mi1,mi2)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
            obj.d0 = d0;
            obj.vel = vel;
            obj.zone1Limit = zone1Limit;
            obj.zone2Limit = zone2Limit;
            obj.mi1 = mi1;
            obj.mi2 = mi2;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,0,100);
        	WPTManager = setSourceVoltages(obj,WPTManager,5,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
        	netManager = setTimer(obj,netManager,GlobalTime,100);
        	WPTManager = dealEffectivePermeability(obj,GlobalTime,WPTManager);
        end
        
        function WPTManager = dealEffectivePermeability(obj,GlobalTime,WPTManager)
        	distance = obj.d0 + obj.vel*GlobalTime;%estima a distância das bobinas baseado nos parâmetros e no tempo
        	if(distance<obj.zone1Limit)
        		%zona 1 (alta proximidade)
        		WPTManager.ENV.miEnv = obj.mi1;
        	else
        		if(distance<obj.zone2Limit)
        			%zona 2 (proximidade média)
        			WPTManager.ENV.miEnv = (distance-obj.zone1Limit)/(obj.zone2Limit-obj.zone1Limit)*obj.mi2+...
        				(obj.zone2Limit-distance)/(obj.zone2Limit-obj.zone1Limit)*obj.mi2;
        		else
        			%zona 3 (término da influência do atrator)
        			WPTManager.ENV.miEnv = obj.mi2;
        		end
        	end 
        end
    end
end
