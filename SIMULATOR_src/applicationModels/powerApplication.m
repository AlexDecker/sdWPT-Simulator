%MODELO DE APLICAÇÃO DO TX
classdef powerApplication
    properties(SetAccess = private, GetAccess = public)
        ID
        SEND_OPTIONS
    end
    properties(Access = protected)
    	CurrTime %Ultimo momento que se tem conhecimento
    end 
    properties(Access=public)
        APPLICATION_LOG %retornado pela função Simulate ao término da execução
    end
    methods(Access=public)
        function obj = powerApplication(ID)
            obj.ID = ID;
            obj.APPLICATION_LOG = applicationLOG();
            setSendOptions(obj,0,1000,0);
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        end
    end
    %Funções auxiliares
    methods(Access=protected)
        %define um timer para um período 'vTime' no futuro
        function netManager = setTimer(obj,netManager,globalTime,vTime)
        	if(globalTime>obj.CurrTime)
        		error('powerApplication (setTimer): Inconsistent time value');
        	else
        		obj.CurrTime = globalTime;
        	end
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
