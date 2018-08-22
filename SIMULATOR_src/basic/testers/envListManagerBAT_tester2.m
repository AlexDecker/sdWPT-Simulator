%script para testar o envListManagerBAT
clear all;
env = Environment([0 0],0,[-1; -1; -1],false);%criando um objeto vazio
env.M = 5e-7*[0 1 0.5;1 0 1;0.5 1 0]; %indutância mútua de 50uH

envList = [env env];

w = 1e6;
R = [0.5 2 0.5]';%resistência dos RLCs
maxPower = 50;%mude para 20 e veja os efeitos da saturação
tTime = 6000;%segundos de simulação (em tempo virtual)

%bateria
fase1Limit = 0.7;          % (70%)
limitToBegin = 0.93;       % (93%)
constantCurrent_min = 0.5; % (A)
constantCurrent_max = 3.4;   % (A)
constantVoltage = 4.2;     % (V)

Rc = -1;      % (ohm. -1=calcular automaticamente)
Rd = -1;       % (ohm. -1=calcular automaticamente)
Rmax = 1e7;   % (ohm)
Q0 = 0;       % (As)
Qmax = 4320;  % (As), que equivale a 1200 mAh

bat = linearBattery('test_data.txt',Rc,Rd,Q0,Qmax,Rmax,fase1Limit,...
              constantCurrent_min,constantCurrent_max,constantVoltage,...
              limitToBegin,false);

power_m = 0.5; % (W)
power_sd = 0.001;
minV = 2.3;     % (V)
minVTO = 3.3;   % (V)
err = 0.05;     % (5%)
efficiency = 0.95; % (95% de eficiência de conversão AC/DC)

dev = genericDeviceWithBattery(bat,power_m,power_sd,minV,minVTO,err,efficiency);
deviceList = [struct('obj',dev), struct('obj',dev)];

ifactor=1.5;
dfactor=2;
iVel=0.01;
err = 0.005;

step=0.2;     % (s)

%managers
elManager = envListManager(envList,0,w,R,tTime,err,...
              Rmax,ifactor,dfactor,iVel,maxPower);
manager = envListManagerBAT(elManager,deviceList,step,true);


Vt = 5;
manager = setVt(manager, Vt, 0.01);

[cI,I,Q,manager] = getSystemState(manager,tTime);

for i=1:length(manager.DEVICE_DATA)
	LOG = endDataAquisition(manager.DEVICE_DATA(i));
	%plotBatteryChart(LOG);
	plotBatteryChart2010(LOG);
end
