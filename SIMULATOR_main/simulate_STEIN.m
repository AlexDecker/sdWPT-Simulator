%W = 2*pi*200000;%200kHz
%R = [0.025;30];%resistência dos grupos RLC
%C = [400e-9;200e-9];%capacitância dos grupos RLC
%zone1Limit = 0.013;%(m)
%zone2Limit = 0.015;%(m)
%miEnv1 = pi*4e-7;%permissividade magnética do meio (zona 1)
%miEnv2 = pi*4e-7;%permissividade magnética do meio (zona 2)

function [t_TX, BC_TX1,BC_TX2, t_RX, CC_RX] = simulate_STEIN(params)
	if exist('params','var')
		R = params.R;
		C = params.C;
		W = params.W;
		zone1Limit = params.zone1Limit;
		zone2Limit = params.zone2Limit;
		miEnv1 = params.miEnv1;
		miEnv2 = params.miEnv2;
	else
		R = [0.0250;50];
		C = [1.0000e-07;1.8300e-07];
		W = 6.9115e+05;
		zone1Limit = 0.013;
		zone2Limit = 0.015;
		miEnv1 = 2.7646e-06;
		miEnv2 = 1.2566e-06;
	end
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %ASPECTOS GERAIS
    NTX = 1; %número de grupos transmissores
    
    MAX_POWER = 7.5;%W;
    R_MAX = 1e7;   % (ohm)
    TOTAL_TIME = 1000;%segundos de simulação (em tempo virtual)
	STEP=10; % (s) Aqui basta que esse valor seja inferior ao timeSkip da aplicação,
	%visto que não há recarga de bateria

    %DISPOSITIVO
    maxCurrent = 1.5; % (A)
    efficiency = 0.93; % (eficiência de conversão AC/DC)
	
	currentConverter = CurrentConverter('conversionEff_Qi.txt',false);
    dev = GenericDeviceWithRealisticACDC(true,maxCurrent,currentConverter);
    DEVICE_LIST = struct('obj',dev);

    %APLICAÇÕES
    d0 = 0.005;
    vel = (0.03-0.005)/TOTAL_TIME;
    powerTX = powerTXApplication_Qi(d0,vel,zone1Limit,zone2Limit,miEnv1,miEnv2);
	powerRX = struct('obj',powerRXApplication_Qi(1));

    %SIMULADOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 0.005;

    SHOW_PROGRESS = false;

    B_SWIPT = 0.7;%minimum SINR for the message to be undertood
    B_RF = 0.7;%minimum SINR for the message to be undertood
    A_RF = 2;%expoent for free-space path loss (RF only)
    N_SWIPT = 0.1;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)

    [LOG_TX,LOG_dev_list,~] = Simulate('STEIN_ENV.mat',NTX,R,C,W,TOTAL_TIME,MAX_ERR,R_MAX,...
        IFACTOR,DFACTOR,INIT_VEL,MAX_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,powerTX,powerRX,...
        B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,miEnv1);

    
    LOG_RX = endDataAquisition(LOG_dev_list(1));
    t_RX = LOG_RX.CC(2,:);
    CC_RX = LOG_RX.CC(1,:);
    
    LOG_TX = endDataAquisition(LOG_TX);
    t_TX = LOG_TX.BC(3,:);
    BC_TX1 = LOG_TX.BC(1,:);
    BC_TX2 = LOG_TX.BC(2,:);
end
