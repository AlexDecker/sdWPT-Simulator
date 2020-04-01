function [t_TX, BC_TX1,BC_TX2, t_RX, CC_RX, t_W, W, Ir, t_BC_RX, BC_RX1, BC_RX2, Rr] = simulate_STEIN(params)
    if exist('params','var')
        R = params.R;
        MI_ENV = params.miEnv;
		STEP_BY_STEP = params.stepByStep;
        maxCurrent = params.maxCurrent;
        ENVIRONMENT = params.env;
        ENDPROB = params.endProb;
		BETA = params.beta;

		%true for resonant ping
		IMPROVED_circ = params.improved_circ;

		%0 for regular Qi, 1 for Qi+ and 2 for Qi++
		IMPROVED_rx = params.improved_rx;
		
		%not used
		IMPROVED_tx = params.improved_tx;

        %for TX/RX joint optimization
        TTL_TX = params.ttl_TX;
        TTL_RX = params.ttl_RX;
		
		VERSION = params.version; %Qi+ version
    else
        R = [0.015;3.97];
        MI_ENV = 1.256627e-06;
		STEP_BY_STEP = false;
        maxCurrent = 1.2594; % (A)
        ENVIRONMENT = 'STEIN_ENV.mat';
        ENDPROB = 0;
		BETA = 0.225; 
		IMPROVED_circ = false;
		IMPROVED_rx = 0;%regular RX
		IMPROVED_tx = false;
        TTL_TX = 50;
        TTL_RX = 800;
		VERSION = 2;
    end
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %GENERAL ASPECTS
    NTX = 1; %number of transmitters
	if IMPROVED_circ
		C = [4e-07;1.6321e-04];%rx resonace for quickly restablishing connection when lost
		%(rx resonates with the 4Hz ping frequency
	else
        C = [4e-07;1e-07];%got from datasheets
	end
    W = 2*pi*4000;%dummie
    
    MAX_ACT_POWER = 7.5;%W
    MAX_APP_POWER = inf;%W
    R_MAX = 1e7;   % (ohm)
    TOTAL_TIME = 1000;%seconds of simulation (virtual time)
    STEP = 0.1; % (s) There is no battery to charge, so this value is only limited
    %by application timeskip

    %DEVICE
    
    currentConverter = CurrentConverter('conversionEff_Qi.txt',false);
    dev = GenericDeviceWithRealisticACDC(true,maxCurrent,currentConverter);
    DEVICE_LIST = struct('obj',dev);

    %APPLICATIONS
    dt = 0.4;%according to IC datasheet
    V = 5;%according to evkit datasheet
    dw = 2*pi*1000;
    wSize = 6;
	
	if IMPROVED_tx
		%TODO
	else
    	powerTX = powerTXApplication_Qi(dt,V,MAX_ACT_POWER,dw,ENDPROB);
	end

	if IMPROVED_rx==2
		powerRX = struct('obj',powerRXApplication_QiOptimal(1,dt,maxCurrent,TTL_TX,TTL_RX));
	else
		if IMPROVED_rx==1
			powerRX = struct('obj',powerRXApplication_Qiplus(1,dt,maxCurrent,TTL_TX,TTL_RX,wSize,VERSION));
		else
    		powerRX = struct('obj',powerRXApplication_Qi(1,dt,maxCurrent));
		end
	end

    %SIMULATOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 1e-06;

    SHOW_PROGRESS = true;

    B_SWIPT = BETA;%minimum SINR for the message to be undertood
    B_RF = 0.7;%minimum SINR for the message to be undertood (dummie no caso)
    A_RF = 2;%expoent for free-space path loss (RF only)(dummie no caso)
    N_SWIPT = 3e-08;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)(dummie no caso)

    [LOG_TX,LOG_dev_list,LOG_app_list] = Simulate(ENVIRONMENT,NTX,R,C,W,...
        TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_ACT_POWER,...
        MAX_APP_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,powerTX,powerRX,...
        B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,MI_ENV,STEP_BY_STEP);

    
    LOG_RX = endDataAquisition(LOG_dev_list(1));
    t_RX = LOG_RX.CC(2,:);
    CC_RX = LOG_RX.CC(1,:);%DC current for RX
	t_BC_RX = LOG_TX.BC(3,:);
    BC_RX1 = LOG_RX.BC(1,:);%AC current for each RX coil
    BC_RX2 = LOG_RX.BC(2,:);
    
    LOG_TX = endDataAquisition(LOG_TX);
    t_TX = LOG_TX.BC(3,:);
    BC_TX1 = LOG_TX.BC(1,:);
    BC_TX2 = LOG_TX.BC(2,:);
    
    W = LOG_app_list(1).DATA(1,:);
    Ir = LOG_app_list(1).DATA(2,:);
    t_W = LOG_app_list(1).DATA(3,:);
	
	Rr = LOG_app_list(2).DATA; %resistance values
end
