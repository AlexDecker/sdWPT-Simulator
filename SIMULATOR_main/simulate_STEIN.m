%W = 2*pi*200000;%200kHz
%R = [0.025;30];%resistência dos grupos RLC
%C = [400e-9;200e-9];%capacitância dos grupos RLC

function [t, CC] = simulate_STEIN(R,C,W)
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %ASPECTOS GERAIS
    NTX = 1; %número de grupos transmissores
    
    MAX_POWER = 7.5;%W;
    R_MAX = 1e7;   % (ohm)
    TOTAL_TIME = 1000;%segundos de simulação (em tempo virtual)
	STEP=5; % (s) Aqui basta que esse valor seja inferior ao timeSkip da aplicação,
	%visto que não há recarga de bateria

    %DISPOSITIVO
    maxCurrent = 1.5; % (A)
    efficiency = 0.93; % (eficiência de conversão AC/DC)

    dev = Device(true,maxCurrent,efficiency);
    DEVICE_LIST = struct('obj',dev);

    %APLICAÇÕES
    powerTX = powerTXApplication_Qi();
    powerRX = [];

    for i=1:length(R)-NTX
        powerRX = [powerRX struct('obj',powerRXApplication_Qi(i))];
    end

    %SIMULADOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 0.005;

    SHOW_PROGRESS = true;

    B_SWIPT = 0.7;%minimum SINR for the message to be undertood
    B_RF = 0.7;%minimum SINR for the message to be undertood
    A_RF = 2;%expoent for free-space path loss (RF only)
    N_SWIPT = 0.1;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)

    [~,LOG_dev_list,LOG_app_list] = Simulate('STEIN_ENV.mat',NTX,R,C,W,TOTAL_TIME,MAX_ERR,R_MAX,...
        IFACTOR,DFACTOR,INIT_VEL,MAX_POWER,DEVICE_LIST,STEP,SHOW_PROGRESS,powerTX,powerRX,...
        B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF);

    
    LOG = endDataAquisition(LOG_dev_list(i));
    t = LOG.CC(2,:);
    CC = LOG.CC(1,:);
end
