function [t_TX, BC_TX1,BC_TX2, t_RX, CC_RX, t_W, W, Ir] = simulate_STEIN(params)
	if exist('params','var')
		R = params.R;
		miEnv = params.miEnv;
		maxCurrent = params.maxCurrent;
		ENVIRONMENT = params.env;
		ENDPROB = params.endProb;
	else
		R = [0.0250;35];
		miEnv = 1.256627e-06;
		maxCurrent = 1.5; % (A)
		ENVIRONMENT = 'STEIN_ENV.mat';
		ENDPROB = 0;
	end
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %ASPECTOS GERAIS
    NTX = 1; %número de grupos transmissores
    C = [4.02e-07;2.7237e-07];%for 2*pi*100kHz angular ressonanting frequency
    W = 2*pi*4000;%dummie
    
    MAX_ACT_POWER = 5;%W
	MAX_APP_POWER = inf;%W
    R_MAX = 1e7;   % (ohm)
    TOTAL_TIME = 1000;%segundos de simulação (em tempo virtual)
	STEP = 0.1; % (s) Aqui basta que esse valor seja inferior ao timeSkip da aplicação,
	%visto que não há recarga de bateria

    %DISPOSITIVO
	
	currentConverter = CurrentConverter('conversionEff_Qi.txt',false);
    dev = GenericDeviceWithRealisticACDC(true,maxCurrent,currentConverter);
    DEVICE_LIST = struct('obj',dev);

    %APLICAÇÕES
    dt = 0.4;%segundo o datasheet do CI
    V = 5;%segundo o datasheet do evkit
    dw = 2*pi*1000;%1000
    powerTX = powerTXApplication_Qi(dt,V,MAX_POWER,dw,ENDPROB);
	powerRX = struct('obj',powerRXApplication_Qi(1,dt,maxCurrent));

    %SIMULADOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 0.005;

    SHOW_PROGRESS = true;

    B_SWIPT = 0.7;%minimum SINR for the message to be undertood
    B_RF = 0.7;%minimum SINR for the message to be undertood (dummie no caso)
    A_RF = 2;%expoent for free-space path loss (RF only)(dummie no caso)
    N_SWIPT = 3e-08;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)(dummie no caso)

    [LOG_TX,LOG_dev_list,LOG_app_list] = Simulate(ENVIRONMENT,NTX,R,C,W,...
    	TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,...
		MAX_APP_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,powerTX,powerRX,...
		B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,miEnv);

    
    LOG_RX = endDataAquisition(LOG_dev_list(1));
    t_RX = LOG_RX.CC(2,:);
    CC_RX = LOG_RX.CC(1,:);
    
    LOG_TX = endDataAquisition(LOG_TX);
    t_TX = LOG_TX.BC(3,:);
    BC_TX1 = LOG_TX.BC(1,:);
    BC_TX2 = LOG_TX.BC(2,:);
    
    W = LOG_app_list(1).DATA(1,:);
	Ir = LOG_app_list(1).DATA(2,:);
	t_W = LOG_app_list(1).DATA(3,:);
end
