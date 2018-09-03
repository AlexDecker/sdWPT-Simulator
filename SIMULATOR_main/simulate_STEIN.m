%version: 2010a ou 2017a
function simulate_STEIN(version)
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %ASPECTOS GERAIS
    NTX = 2; %número de dispositivos transmissores
    W = 2*pi*200000;%200kHz
    R = [0.025;0.2];%resistência dos grupos RLC
    C = [400e-9;200e-9];%capacitância dos grupos RLC
    MAX_POWER = 7.5;%W;
    TOTAL_TIME = 6000;%segundos de simulação (em tempo virtual)
	

    %DISPOSITIVO
    maxCurrent = 1.5; % (A)
    efficiency = 0.93; % (eficiência de conversão AC/DC)

    STEP=0.2;     % (s)

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

    %VISUALIZAÇÃO DOS RESULTADOS
        
    for i=1:length(LOG_dev_list)
        LOG = endDataAquisition(LOG_dev_list(i));
        if(strcmp(version, '2010a'))
            plotBatteryChart2010(LOG);%use isso se estiver no R2010
        else
            plotBatteryChart(LOG); %use isso se estiver no R2017
        end
    end

    figure;
    plot(LOG_app_list(1).DATA(2,:)/3600,LOG_app_list(1).DATA(1,:));
    xlabel('Time (h)')
    ylabel('(V)')
    title('Voltage across each TX coil');

    for i=2:length(LOG_app_list)
        disp(' ');
        disp(['For RX ',num2str(i-1),':']);
        disp('--------------------------------------');
        disp(LOG_app_list(i).DATA);
    end
end
