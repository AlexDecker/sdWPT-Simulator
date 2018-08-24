%version: 2010a ou 2017a
function simulate_script_exemplo(version)
    %SCRIPT PARA TESTAR E EXEMPLIFICAR O SIMULADOR COMO UM TODO
    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    %ASPECTOS GERAIS
    NTX = 6; %número de dispositivos transmissores
    W = 1e6;
    R = 0.5*ones(9,1);%resistência dos RLCs
    MAX_POWER = 200;%W;
    TOTAL_TIME = 6000;%segundos de simulação (em tempo virtual)

    %BATERIA
    fase1Limit = 0.7;          % (70%)
    limitToBegin = 0.93;       % (93%)
    constantCurrent_min = 0.5; % (A)
    constantCurrent_max = 3.4;   % (A)
    constantVoltage = 4.2;     % (V)
    Rc = -1;      % (ohm. -1=calcular automaticamente)
    Rd = -1;       % (ohm. -1=calcular automaticamente)
    R_MAX = 1e7;   % (ohm)
    Q0 = 0;       % (As)
    Qmax = 4320;  % (As), que equivale a 1200 mAh

    bat = linearBattery('test_data.txt',Rc,Rd,Q0,Qmax,R_MAX,fase1Limit,...
                  constantCurrent_min,constantCurrent_max,constantVoltage,...
                  limitToBegin,false);

    %DISPOSITIVO
    power_m = 0.5; % (W)
    power_sd = 0.001;
    minV = 2.3;     % (V)
    minVTO = 3.3;   % (V)
    err = 0.05;     % (5%)
    efficiency = 0.95; % (95% de eficiência de conversão AC/DC)

    STEP=0.2;     % (s)

    dev = genericDeviceWithBattery(bat,power_m,power_sd,minV,minVTO,err,efficiency);
    DEVICE_LIST = [struct('obj',dev), struct('obj',dev), struct('obj',dev)];

    %APLICAÇÕES
    TIME_SKIP = 10;% (s)
    IFACTOR = 1.1;
    IVEL = 1;
    %duas opções de vetor base pra aplicação
    VT_BASE_VECTOR_1 = ones(NTX,1);
    VT_BASE_VECTOR_2 = [1;zeros(NTX-2,1);1];

    powerTX = powerTXApplication_exemplo(TIME_SKIP,IFACTOR,IVEL,VT_BASE_VECTOR_2);
    powerRX = [];

    for i=1:length(R)-NTX
        powerRX = [powerRX struct('obj',powerRXApplication_exemplo(i))];
    end

    %SIMULADOR

    IFACTOR=1.5;
    DFACTOR=2;
    INIT_VEL=0.01;
    MAX_ERR = 0.005;

    SHOW_PROGRESS = true;

    B_SWIPT = 0.5;%minimum SINR for the message to be undertood
    B_RF = 0.5;%minimum SINR for the message to be undertood
    A_RF = 2;%expoent for free-space path loss (RF only)
    N_SWIPT = 0.1;%Noise for SWIPT (W)
    N_RF = 0.1;%Noise for RF (W)

    [~,LOG_dev_list,LOG_app_list] = Simulate('testENV.mat',NTX,R,W,TOTAL_TIME,MAX_ERR,R_MAX,...
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
