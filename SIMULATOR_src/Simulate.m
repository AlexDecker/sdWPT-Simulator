function [LOG_TX,LOG_dev_list,LOG_app_list] = Simulate(ENV_LIST_FILE,NTX,R,C,W,TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,MAX_APP_POWER,DEVICE_LIST,STEP,...
	SHOW_PROGRESS,powerTX,powerRX,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,miEnv)
    
	LOG_TX = [];
	LOG_dev_list = [];
	LOG_app_list = [];
	GlobalTime = 0;
	
	%generates an environment list based on the informed file
	load(ENV_LIST_FILE);
	if exist('envList','var')
		if ~verifyEnvList(envList)
			error('Invalid envList.');
		end
	else
		error('EnvList not found.');
	end
	
	%insert new capacitance values if wanted. -1 if you want to disable this functionality
	if(length(envList(1).C_group)~=length(C))
		error('C dimension and the number of groups must agree');
	end
	for i=1:length(envList)
		envList(i).C_group = envList(i).C_group + (C~=-1).*(C-envList(i).C_group);
	end
	
	%The objects below manages the physical aspects of WPT
	if exist('miEnv','var')
		elManager = envListManager(envList,zeros(NTX,1),W,R,TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,MAX_APP_POWER,miEnv);
	else
		elManager = envListManager(envList,zeros(NTX,1),W,R,TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,MAX_APP_POWER);
	end
	
	Manager = envListManagerBAT(elManager,DEVICE_LIST,STEP,SHOW_PROGRESS);
	
	%initializing the voltage across the TX coils
	Manager = setVt(Manager, zeros(NTX,1), 0);
	
	%The object below manages network and timing envents
	network = networkManager(length(envList(1).R_group)-NTX);
	
	if(powerTX.ID~=0)
		%ID=0 means the application is attached to the transmitting device
		error('powerTX is not a powerTXApplication');
	end
	%Initializing the application of TX device
	[powerTX,network,Manager] = init(powerTX,network,Manager);
	
	%Initializing the other applications
	for i=1:length(powerRX);
		if(powerRX(i).obj.ID~=i)
			error('ID of powerRX(i) must be equals to its index in powerRX vector');
		end
		[powerRX(i).obj,network,Manager] = init(powerRX(i).obj,network,Manager);
	end
	
	while(true)
		%while there are still events to handle
		if (emptyEnventList(network))
			disp('No more events to compute');
			break;
		end
		
		%updates the global timer, get the messages that conflicts with the event of interest and get the event itself
		[GlobalTime, conflictingMsgs, event, network] = nextEvent(network);
		
		%other termination conditions
		
		if(GlobalTime>TOTAL_TIME)
			disp('TOTAL_TIME achieved');
			break;
		end
		
		if(powerTX.END_SIMULATION)
			disp('Simulation finished by powerTX');
			break;
		end
		
		END_SIMULATION = false;
		for i=1:length(powerRX)
			END_SIMULATION = END_SIMULATION || powerRX(i).obj.END_SIMULATION;
		end
		
		if(END_SIMULATION)
			disp('Simulation finished by powerRX');
			break;
		end
		
        %Get some measurements for logging purposes (the measurements are inserted into the log objects inside Manager
		[~,~,~,~,Manager] = getSystemState(Manager,GlobalTime);
        
		if(event.owner==0)%the destinatary is TX
			if(event.isMsg)
				%if the event is a message
                
				%only an alert for realism purposes
				if(powerTX.SEND_OPTIONS.baudRate~=powerRX(event.creator).obj.SEND_OPTIONS.baudRate)
					warningMsg('BaudRate values do not match');
				end
				
				[~,~,~,~,Manager] = getSystemState(Manager,GlobalTime);
				Z = getCompleteLastZMatrix(Manager);
				
				%evaluates via SINR if the message is meant to be sent
				if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,Z))
					%callback the handler function of the message receiver
					[powerTX, network, Manager] = handleMessage(powerTX,event.data,GlobalTime,network,Manager);
				else
					warningMsg('Dropped message: ',['from powerRX id ',num2str(event.creator),' to powerTX']);
				end
			else                
				%if it is a time event
				[powerTX, network, Manager] = handleTimer(powerTX,GlobalTime,network,Manager);
			end
		else
			if(event.owner~=-1)%The destinatary is RX
				if(event.isMsg)
					%if the event is a message
				
					%only an alert for realism purposes
					if(event.creator==0)
						if(powerTX.SEND_OPTIONS.baudRate~=powerRX(event.owner).obj.SEND_OPTIONS.baudRate)
							warningMsg('BaudRate values do not match');
						end
					else
						if(powerRX(event.creator).obj.SEND_OPTIONS.baudRate~=powerRX(event.owner).obj.SEND_OPTIONS.baudRate)
							warningMsg('BaudRate values do not match');
						end
					end
				
					[~,~,~,~,Manager] = getSystemState(Manager,GlobalTime);
					Z = getCompleteLastZMatrix(Manager);
				
					%evaluates via SINR if the message is meant to be sent
					if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,Z))
						[powerRX(event.owner).obj, network, Manager] = handleMessage(powerRX(event.owner).obj,event.data,GlobalTime,network,Manager);
					else
						if event.creator==0
							warningMsg('Dropped message: ',['from powerTX to powerRX id ',num2str(event.owner)]);
						else
							warningMsg('Dropped message: ',['from powerRX id ',num2str(event.creator),' to powerRX id ',num2str(event.owner)]);
						end
					end
				else
					%if it is a time event
					[powerRX(event.owner).obj, network, Manager] = handleTimer(powerRX(event.owner).obj,GlobalTime,network,Manager);
				end
			else %broadcast (always a message)
				[~,~,~,~,Manager] = getSystemState(Manager,GlobalTime);
				Z = getCompleteLastZMatrix(Manager);
				
				if(event.creator==0)%created by powerTX
					%only an alert for realism purposes
					for i=1:length(powerRX)
						if(powerTX.SEND_OPTIONS.baudRate~=powerRX(i).obj.SEND_OPTIONS.baudRate)
							warningMsg('BaudRate values do not match');
						end
					end
					
					for i=1:length(powerRX)
						event.owner = i;
						%evaluates via SINR if the message is meant to be sent
						if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,Z))
							[powerRX(event.owner).obj, network, Manager] = handleMessage(powerRX(event.owner).obj,event.data,GlobalTime,network,Manager);
						else
							warningMsg('Dropped broadcast message: ',['from powerTX to powerRX id ',num2str(event.owner)]);
						end
					end
				else%created by powerRX
					%only an alert for realism purposes
					if(powerRX(event.creator).obj.SEND_OPTIONS.baudRate~=powerTX.SEND_OPTIONS.baudRate)
						warningMsg('BaudRate values do not match');
					end
					for i=1:length(powerRX)
						if(powerRX(event.creator).obj.SEND_OPTIONS.baudRate~=powerRX(i).obj.SEND_OPTIONS.baudRate)
							warningMsg('BaudRate values do not match');
						end
					end
					event.owner = 0;
					%evaluates via SINR if the message is meant to be sent
					if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,Z))
						[powerTX, network, Manager] = handleMessage(powerTX,event.data,GlobalTime,network,Manager);
					else
						warningMsg('Dropped broadcast message: ',['from powerRX id ',num2str(event.creator),' to powerTX']);
					end
					for i=1:length(powerRX)
						if(event.creator~=i)%do not send the message to itself
							event.owner = i;
							%evaluates via SINR if the message is meant to be sent
							if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,Z))
								[powerRX(event.owner).obj, network, Manager] = handleMessage(powerRX(event.owner).obj,event.data,GlobalTime,network,Manager);
							else
								warningMsg('Dropped broadcast message: ',['from powerRX id ',num2str(event.creator),' to powerRX id ',num2str(event.owner)]);
							end
						end
					end
				end
			end
		end
		
		cleanWarningMsg();%avoids a warning message flooding
	end
	
	%harvesting logs
	
	LOG_TX = Manager.TRANSMITTER_DATA;
	
	LOG_dev_list = [];
	for i=1:length(Manager.DEVICE_DATA)
		LOG_dev_list = [LOG_dev_list endDataAquisition(Manager.DEVICE_DATA(i))];
	end
	
	LOG_app_list = powerTX.APPLICATION_LOG;
	for i=1:length(powerRX)
		LOG_app_list = [LOG_app_list powerRX(i).obj.APPLICATION_LOG];
	end
	
	disp(['Simulation ended at time ', num2str(GlobalTime)]);
end
