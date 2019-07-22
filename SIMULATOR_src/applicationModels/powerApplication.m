classdef powerApplication
    properties(SetAccess = private, GetAccess = public)
        ID
        SEND_OPTIONS
        END_SIMULATION
    end
    properties(Access = protected)
    	CurrTime %last known moment
    end 
    properties(Access=public)
        APPLICATION_LOG %returned by Simulate function after executing the simulation
    end
    methods(Access=public)
        function obj = powerApplication(ID)
        	obj.END_SIMULATION = false;
            obj.ID = ID;
            obj.APPLICATION_LOG = applicationLOG();
            obj = setSendOptions(obj,0,1000,0);
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end
        
        function obj = endSimulation(obj)
        	obj.END_SIMULATION = true;
        end
    end
    %Auxiliary functions
    methods(Access=protected)
	%gets the operational frequency of the system
	function w = getOperationalFrequency(obj, WPTManager)
		w = WPTManager.ENV.w;
	end
        %define a timer triggered at 'vTime' seconds in the future
	%TODO: avoid the case where the user sets vTime<integration step
        function netManager = setTimer(obj,netManager,globalTime,vTime)
        	if(globalTime>obj.CurrTime)
        		error('powerApplication (setTimer): Inconsistent time value');
        	end
			if(vTime<=0)
				error('powerApplication (setTimer): Inconsistent vTime value');
			end
        	obj.CurrTime = globalTime;
            netManager = setTimer(netManager,obj.ID,globalTime,vTime);
        end
        %define configurações de comunicação
        %type: 0 para SWIPT, [# do canal] para RF
        %baudRate: em bits/s
        %power: apenas para o RF, em W. Para SWIPT, use qualquer valor
        function obj = setSendOptions(obj,type,baudRate,power)
            obj.SEND_OPTIONS.type = type;
            obj.SEND_OPTIONS.baudRate = baudRate;
            obj.SEND_OPTIONS.power = power;
        end
        %envia uma mensagem 'data' ao dispositivo de id 'dest'
        function netManager = send(obj,netManager,dest,data,dataLen,globalTime)
        	if(globalTime>obj.CurrTime)
        		error('powerApplication (send): Inconsistent time value');
        	else
        		obj.CurrTime = globalTime;
        	end
            [~,~,netManager] = send(netManager,obj.ID,dest,data,dataLen,...
                obj.SEND_OPTIONS,globalTime);
        end
        %envia uma mensagem 'data' a todos os dispositivos do sistema
        function netManager = broadcast(obj,netManager,data,dataLen,globalTime)
        	if(globalTime>obj.CurrTime)
        		error('powerApplication (broadcast): Inconsistent time value');
        	else
        		obj.CurrTime = globalTime;
        	end
            netManager = broadcast(netManager,obj.ID,data,dataLen,...
                obj.SEND_OPTIONS,globalTime);
        end
    end
end
