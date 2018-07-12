function [LOG_dev_list,LOG_app_list] = Simulate(ENV_LIST_FILE,NTX,R,W,TOTAL_TIME,MAX_ERR,R_MAX,...
    IFACTOR,DFACTOR,INIT_VEL,MAX_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,...
	powerTX,powerRX,LATENCIA,sdLAT)
    
	GlobalTime = 0;
	
	%Gera um envList baseado no arquivo especificado
	load(ENV_LIST_FILE);
 
    %Os objetos abaixo cuidam de aspactos físicos de WPT
	elManager = envListManager(envList,zeros(NTX,1),W,R,TOTAL_TIME,MAX_ERR,...
              R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_POWER);
	Manager = envListManagerBAT(elManager,DEVICE_LIST,STEP,SHOW_PROGRESS);
	
	Manager = setVt(Manager, zeros(NTX,1), 0);
    
    %O objeto abaixo cuida dos aspectos eventos em redes
    network = networkManager(length(envList(1).Coils)-NTX,LATENCIA,sdLAT);
    
    %É executada a função de inicialização do TX
    [powerTX,network,Manager] = init(powerTX,network,Manager);
    
    %São executadas as funções de inicialização dos RX
    for i=1:length(powerRX);
        [powerRX(i),network,Manager] = init(powerRX(i),network,Manager);
    end

    while(true)%enquanto ainda existirem eventos agendados
		if (emptyEnventList(network))
			disp('No more events to compute');
            break;
		end
        
		[GlobalTime, owner, isMsg, data, network] = nextEvent(network);

        if(GlobalTime>TOTAL_TIME)
			disp('TOTAL_TIME achieved');
            break;
        end
        
        if(owner==0)%TX
            if(isMsg)
                [powerTX, network, Manager] = handleMessage(powerTX,data,GlobalTime,network,Manager);
            else                
                [powerTX, network, Manager] = handleTimer(powerTX,GlobalTime,network,Manager);
            end
        else%RX
            if(isMsg)
                [powerRX(owner), network, Manager] = handleMessage(powerRX(owner),data,GlobalTime,network,Manager);
            else
                [powerRX(owner), network, Manager] = handleTimer(powerRX(owner),GlobalTime,network,Manager);
            end
        end
        %Resultados desta execução (acesso direto a medições, com
        %onisciência)
        [~,~,~,Manager] = getSystemState(Manager,GlobalTime);%atualiza o sistema a cada evento
        cleanWarningMsg();%permite que mensagens se acumulem apenas a cada evento
    end
    
	LOG_dev_list = [];
	for i=1:length(Manager.DEVICE_DATA)
		LOG_dev_list = [LOG_dev_list endDataAquisition(Manager.DEVICE_DATA(i))];
	end
	
	LOG_app_list = powerTX.APPLICATION_LOG;
	for i=1:length(powerRX)
		LOG_app_list = [LOG_app_list powerRX(i).APPLICATION_LOG];
	end
	
    disp(['Simulation ended at time ', num2str(GlobalTime)]);
end