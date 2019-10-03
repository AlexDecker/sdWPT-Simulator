clear all;
rng('shuffle');
number = rand;%used to differenciate the experiments
disp(['Starting experiment number ',num2str(number)]);

n = 0;%100;
smooth_radius = 100;
m = 140;

params.improved_circ = false;
params.improved_rx = 1;%1: Qi+, 2: Qi++, other: regular Qi 1.0
params.improved_tx = false;

params.R = [0.015;3.97];
params.miEnv = 1.256627e-06;
params.maxCurrent = 1.2594;
params.env = 'STEIN_ENV_large.mat';
params.beta = 0.225;

%params for TX/RX joint optimization
params.ttl_TX = 25;
params.ttl_RX = inf;

%involved distances
if strcmp('STEIN_ENV.mat',params.env)
    d_min = 5;
    d_max = 30;
	tTime = 1000;
	params.stepByStep = false;
else
    if strcmp('STEIN_ENV_large.mat',params.env)
        d_min = 5;
        d_max = 74.5;
        tTime = 1000;
		params.stepByStep = true;
    end
end

%reference values in V(from STEIN paper, 35g/L salty water experiment)
ref_volt = [4.93, 4.63, 3.88, 3.27, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
            4.93, 4.42, 4.34, 3.59, 3.26, 3.17, 0.80, 0.00, 0.00, 0.00, 0.00;
            4.93, 4.93, 4.47, 3.50, 3.52, 2.99, 0.12, 0.00, 0.00, 0.00, 0.00;
            4.77, 4.30, 3.95, 3.17, 1.77, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
            4.91, 3.98, 3.90, 3.64, 1.68, 1.16, 0.00, 0.00, 0.00, 0.00, 0.00;
            4.92, 4.60, 4.12, 3.37, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
ref_mean = mean(ref_volt);
%confidence interval size, considering t-student distribution
ref_err = (2.015*std(ref_volt)/sqrt(6))/2;
%distance of the samples (mm)
ref_dist = [5, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5, 25, 27.5, 30];

%cubic interpolation of the reference data in order to better compare it to
%the simulated data
ref_mean1 = interp1(ref_dist,ref_mean,linspace(d_min,d_max,m),'pchip');
ref_std = interp1(ref_dist,std(ref_volt),linspace(d_min,d_max,m),'pchip');

figure;
hold on;
errorbar(ref_dist,ref_mean,ref_err,'.r');
plot(linspace(d_min,d_max,m),ref_mean1,'--r');

%NO LINK INTERRUPTION
params.endProb = 0;%no random link interruption
[~, ~, ~, t_RX, CC_RX, t_W, W,~] = simulate_STEIN(params);
%converting time to distance
d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
%adjusting the length of the vectors 
sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
%calculating the output voltage
voltage0 = params.R(2)*sCC_RX;
plot(linspace(d_min,d_max,m),voltage0,'.g');

%CONSIDERING LINK INTERRUPTION
voltage = zeros(n,m);
for i=1:n
    params.endProb = 0.0027;
    [~, ~, ~, t_RX, CC_RX, t_W, W,~] = simulate_STEIN(params);
    %converting time to distance
	d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
	%adjusting the length of the vectors 
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	%calculating the output voltage
	voltage(i,:) = params.R(2)*sCC_RX;
end


if n==1
	plot(linspace(d_min,d_max,m),voltage,'b');
else
    %admit n=100. if you have Statistics Toolbox, use tinv instead of the constant
	errorbar(linspace(d_min,d_max,m),mean(voltage),1.66039*std(voltage)/(2*sqrt(100)),'b');
end
ylim([0 inf]);
title(['Exp number ',num2str(number)]);
xlabel('Distance (mm)','FontSize',14,'FontWeight','bold')
ylabel('Voltage(V)','FontSize',14,'FontWeight','bold')
legend('Real','Real (interpolation)','Simulated (no perturbations)',...
    'Simulated (with perturbations)');
set(gcf,'Position',[10,10,550,390]);

figure;
plot(t_W,W);
ylim([105000,210000]);

disp(['Finishing experiment number ',num2str(round(1000000*number))]);

%comparing the simulated data with the real (interpolated) data
%TODO

save(['experiment_',num2str(round(1000000*number)),'.mat']);

