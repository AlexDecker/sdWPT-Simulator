%Aplicação de acordo com o protocolo Qi v1.0

classdef powerRXApplication_Qi < powerRXApplication
    properties
    	dt
    	imax %corrente maxima aceitavel
    end
    methods
        function obj = powerRXApplication_Qi(id,dt,imax)
            obj@powerRXApplication(id);%construindo a estrutura referente à superclasse
            obj.dt = dt;
            obj.imax = imax;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        %SWIPT, 2048bps (segundo o datasheet do CI), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
            netManager = setTimer(obj,netManager,0,obj.dt);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
        	if(abs(I)>0)%se existir transmissão de energia
        		%envia sua corrente (mensagem de continuidade)
		    	netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
		    	netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
		    end
        end

    end
end
