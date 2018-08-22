clear all;

disp('This script works fine using MATLAB R2016a or further');

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
              limitToBegin,true);
figure;

power_m = 0.5; % (W)
power_sd = 0.001;
minV = 2.3;     % (V)
minVTO = 3.3;   % (V)
err = 0.05;     % (5%)
efficiency = 0.95; % (95% de eficiência de conversão AC/DC)

dev = genericDeviceWithBattery(bat,power_m,power_sd,minV,minVTO,err,efficiency);

ifactor=1.5;
dfactor=2;
iVel=0.01;
err = 0.005;

%2-port network
Vt = 5;             % (V ac)
Z = 0.5*[1 -1j;-1j 1];     % (ohm)
maxPower = 50; %(W)

%variação de tempo entre os samples
timeVariation=0.2;     % (s)
%número de samples
steps = 30000;

%inicializando variáveis
steps2 = steps;
I0 = 0;
RL = 0;
RS = 0;
It = 0;
Ir = 0;
%variáveis de monitoramento
IE = [];
SOC=[];
CC =0;
DC =0;
VB =[];

RLwatcher = 0;
ant = 0;
LOG = simulationResults(1);
while steps>0
    [dev.bat,Ie] = expectedCurrent(dev.bat);
    
    %variáveis de monitoramento
    VB =[VB dev.Vbatt];
    SOC = [SOC getSOC(dev.bat)];
    IE = [IE Ie];
    
    %Vt = maxPowerFromVector(1, Z+diag([zeros(1,1);RL]), err, 1, maxPower);
    
    [RL,It,Ir]=calculateRLMatrix(Vt,Z,Ie,RL,err,dev.bat.Rmax,...
        ifactor,dfactor,iVel);
    
    RLwatcher = [RLwatcher RL];
    
    [~,RS,I]=calculateCurrents(Vt,Z,RL,RS,err,dev.bat.Rmax,ifactor,...
    dfactor,iVel,maxPower);
    
    dev = updateDeviceState(dev, (I(2)+I0)/2, timeVariation,LOG,0);
    CC = [CC dev.chargeCurrent];
    DC = [DC dev.dischargeCurrent];
    I0 = I(2);
    now = round(100-steps/steps2*100);
    if(now~=ant)
        disp([num2str(now), '%']);
        ant=now;
    end
    steps = steps-1;
    cleanWarningMsg();
end

[dev.bat,Ie] = expectedCurrent(dev.bat);
IE = [IE Ie];
VB =[VB dev.Vbatt];
SOC = [SOC getSOC(dev.bat)];


%apenas para facilitar a visualização de RL
n=0;
sum=0;
for i=1:length(RLwatcher)
    if RLwatcher(i)~=dev.bat.Rmax
        sum = sum+RLwatcher(i);
        n=n+1;
    end
end

plot(timeVariation/3600*(0:1:steps2),RLwatcher);
if n~= 0
    ylim([0 5*sum/n]);
end
xlim([0 timeVariation/3600*steps2]);
xlabel('Time (h)')
ylabel('RL (ohms)')
figure;

plot(SOC*100,VB);
title('SOC(%) x Battery Voltage (V)');
figure;

hold on;
plot(timeVariation/3600*(0:1:steps2),CC,'r');
plot(timeVariation/3600*(0:1:steps2),IE,'b');
plot(timeVariation/3600*(0:1:steps2),DC,'g');
plot(timeVariation/3600*(0:1:steps2),VB,'m');
ylabel('(A) / (V)')
legend('Charge Current','Expected Current','Discharge Current','Battery Voltage');
figure;
plot(timeVariation/3600*(0:1:steps2),SOC*100);
title('SOC evolution');
xlabel('Time (h)')
ylabel('(%)')
