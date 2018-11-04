%Simulando a recarga da bateria LIR18650 2600mAh (vide datasheet em ../docs/)
%version: 2010a ou 2017a
function simulate_battery(version)
	
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');
	
	NTX = 1;
	W = 3769.911; %600Hz
	R = [0.7 0.7]'; %resistência fixa dos RLCs (default)
	C = [-1 -1]';%capacitância dos RLCs (usar a do arquivo .mat)
	MAX_ACT_POWER = inf; %W
	MAX_APP_POWER = inf; %W
	TOTAL_TIME = 12600; %simulation time in seconds (virtual time)
	
	%battery
	fase1Limit = 0.85;          % (85%)
	limitToBegin = 0.9;       % (90%, dummie for this use case)
	constantCurrent_min = 0.01; % (A, dummie for this use case)
	constantCurrent_max = 1.3;   % (A, from datasheet)
	constantVoltage = 4.2;     % (V)

	Rc = -1;      % (ohm, -1=automatic calculation)
	Rd = -1;       % (ohm. -1=automatic calculation)
	R_MAX = 1e7;   % (ohm)
	Q0 = 0;       % (As, starting as dead battery)
	Qmax = 2600/1000*3600;  % (As, equivalent to 2600mAh)

	bat = linearBattery('Li_Ion_Battery_LIR18650.txt',Rc,Rd,Q0,Qmax,R_MAX,fase1Limit,...
		          constantCurrent_min,constantCurrent_max,constantVoltage,...
		          limitToBegin,false);
	
	%disable additional energy consumption
	power_m = 0; % (W)
	power_sd = 0;
	minV = 2.3;     % (V)
	minVTO = 3.3;   % (V)
	err = 0.01;     % (1%)
	
	%conversion efficiency
	efficiency = 0.95; % (95% de eficiência de conversão AC/DC)

	dev = genericDeviceWithBattery(bat,power_m,power_sd,minV,minVTO,err,efficiency);
	DEVICE_LIST = struct('obj',dev);

	%APPLICATIONS
	VOLTAGE = 20;
    powerTX = powerTXApplication_dummie(VOLTAGE);
    powerRX = [];

    for i=1:length(R)-NTX
        powerRX = [powerRX struct('obj',powerRXApplication(i))];
    end

    %SIMULATOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 0.005;
    STEP = 0.2;

    SHOW_PROGRESS = true;

    B_SWIPT = 0.7;%minimum SINR for the message to be undertood
    B_RF = 0.7;%minimum SINR for the message to be undertood
    A_RF = 2;%expoent for free-space path loss (RF only)
    N_SWIPT = 0.1;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)
	
    [~,LOG_dev_list,LOG_app_list] = Simulate('BAT_ENV.mat',NTX,R,C,W,TOTAL_TIME,MAX_ERR,R_MAX,...
        IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,MAX_APP_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,...
		powerTX,powerRX,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF);

    %VISUALISATION
        
    for i=1:length(LOG_dev_list)
        LOG = endDataAquisition(LOG_dev_list(i));
        if(strcmp(version, 'R2010a'))
            plotBatteryChart2010(LOG);
        else
            plotBatteryChart(LOG);
        end
    end
end
