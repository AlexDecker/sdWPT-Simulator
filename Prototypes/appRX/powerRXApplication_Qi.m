%Aplicação de acordo com o protocolo Qi v1.0

classdef powerRXApplication_Qi < powerRXApplication
    properties
    	dt
    	timerOn %apenas para evitar uma inundação de eventos de timer
    	imax %corrente maxima aceitavel
    end
    methods
        function obj = powerRXApplication_Qi(id,dt,imax)
            obj@powerRXApplication(id);%construindo a estrutura referente à superclasse
            obj.dt = dt;
            obj.timerOn = false;
            obj.imax = imax;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT, 2048bps (segundo o datasheet do CI), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
        	if(abs(I)>0)%se existir transmissão de energia
	        	%envia seu ID e a corrente maxima (mensagem de solicitacao de energia)
		    	netManager = send(obj,netManager,0,[obj.ID,obj.imax],32,GlobalTime);
		    	if(~obj.timerOn)
		    		obj.timerOn = true;
		    		netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
		    	end
		    end
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
        	if(abs(I)>0)%se existir transmissão de energia
        		%envia sua corrente (mensagem de continuidade)
		    	netManager = send(obj,netManager,0,I,32,GlobalTime);
		    	netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
		    else
		    	obj.timerOn = false;
		    end
        end

    end
end
