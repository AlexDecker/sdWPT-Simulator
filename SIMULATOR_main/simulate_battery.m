%Simulating the charging process for LIR18650 2600mAh battery(see datasheet in ../docs/)
%version: 2010 ou 2017
clear all;
version = 2018;

%reference values
VOLTAGEX = [2.21987315;2.66384778;4.88372093;10.21141649;18.64693446;32.85412262;
48.8372093;62.1564482;72.81183932;83.91120507;91.01479915;103.0021142;120.3171247;
136.744186;150.5073996;164.2706131;176.7019027];
VOLTAGEY = [3.473333333;3.613333333;3.726666667;3.793333333;3.833333333;3.9;3.94;
3.973333333;4;4.093333333;4.113333333;4.2;4.2;4.2;4.2;4.2;4.2];

CAPACITYX = [0;12.87526427;29.30232558;44.84143763;60.38054968;75.91966173;90.12684989;
101.6701903;114.5454545;126.0887949;141.1839323;160.2748414;175.8139535];
CAPACITYY = [0;0.106707317;0.243902439;0.368902439;0.506097561;0.634146341;
0.743902439;0.844512195;0.917682927;0.951219512;0.969512195;0.987804878;0.984756098];

CURRENTX = [0;5.32769556;30.19027484;45.72938689;60.38054968;75.91966173;95.89852008;
103.8900634;108.3298097;113.6575053;122.9809725;132.7484144;142.9598309;155.3911205;
165.1585624;176.7019027];
CURRENTY =[0.493902439;0.506097561;0.506097561;0.506097561;0.506097561;0.506097561;
0.506097561; 0.43902439;0.323170732;0.231707317;0.146341463;0.094512195;0.057926829;
0.042682927;0.027439024;0.021341463]*1.3/0.5;

%parameter definition
NTX = 1;
W = 3769.911; %600Hz
R = [0.7 0.7]'; %fixed resistance (default)
C = [-1 -1]';%capacitance (use .mat file)
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
efficiency = 0.95;

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
    if(version<=2010)
        plotBatteryChart2010(LOG);
    else
        plotBatteryChart(LOG);
        %the original data
        figure;
        hold on;
        yyaxis left
        plot(VOLTAGEX,VOLTAGEY);
        ylabel('(V)');
        yyaxis right
        plot(CURRENTX,CURRENTY);
        plot(CAPACITYX,CAPACITYY);
        legend('Battery Voltage','Charge Current','SOC');
        xlabel('Time (min)')
        ylabel('(A)/(0-1)')
        title('Battery Chart for device 1');
        ax = gca;
		ax.YAxis(1).Limits = [0,5];
    end
    %ERROR ESTIMATION
    volt_lim_min = max(min(LOG.VB(2,:)/60),min(VOLTAGEX));
    volt_lim_max = min(max(LOG.VB(2,:)/60),max(VOLTAGEX));
	eVOLTAGE = interp1(VOLTAGEX,VOLTAGEY,...
		linspace(volt_lim_min,volt_lim_max,100))...
		- interp1(LOG.VB(2,:)/60,LOG.VB(1,:),...
		linspace(volt_lim_min,volt_lim_max,100));
	
	cap_lim_min = max(min(LOG.SOC(2,:)/60),min(CAPACITYX));
    cap_lim_max = min(max(LOG.SOC(2,:)/60),max(CAPACITYX));
	eCAPACITY = interp1(CAPACITYX,CAPACITYY,...
		linspace(cap_lim_min,cap_lim_max,100))...
		-interp1(LOG.SOC(2,:)/60,LOG.SOC(1,:),...
		linspace(cap_lim_min,cap_lim_max,100));
	
	cur_lim_min = max(min(LOG.CC(2,:)/60),min(CURRENTX));
    cur_lim_max = min(max(LOG.CC(2,:)/60),max(CURRENTX));
	eCURRENT = interp1(CURRENTX,CURRENTY,...
		linspace(cur_lim_min,cur_lim_max,100))...
		-interp1(LOG.CC(2,:)/60,LOG.CC(1,:),...
		linspace(cur_lim_min,cur_lim_max,100));

	eVOLT = sqrt(sum(eVOLTAGE.^2))/(length(eVOLTAGE)*mean(VOLTAGEY));
	eCAP = sqrt(sum(eCAPACITY.^2))/(length(eCAPACITY)*mean(CAPACITYY));
	eCURR = sqrt(sum(eCURRENT.^2))/(length(eCURRENT)*mean(CURRENTY));
	
	disp(['normalized mean square error: (voltage)',num2str(eVOLT*100),'%']);
	disp(['normalized mean square error: (SOC)',num2str(eCAP*100),'%']);
	disp(['normalized mean square error: (current)',num2str(eCURR*100),'%']);
end
