clear all;
rng('shuffle');
number = rand;%used to differenciate the experiments
disp(['Starting experiment number ',num2str(number)]);

n = 1;
smooth_radius = 100;
m = 50;
d_min = 5;
d_max = 30;
tTime = 1000;

params.improved_circ = false;
params.improved_rx = 0;%1: Qi+, 2: Qi++, other: regular Qi 1.0
params.improved_tx = false;

params.R = [3;3.59];
params.miEnv = 1.256627e-06;
params.maxCurrent = 1000;
params.env = 'STEIN_ENV.mat';
params.endProb = 0;%0.00175;
params.beta = 0;%0.5;

params.greedy = 0;

%reference values in V(from STEIN paper, 10g/L salty water experiment)
ref_volt = [4.9250,4.7438,4.1629,3.8650,3.0750,2.3200,1.3567,0.1500];
%confidence interval size, considering t-student distribution and 5 degrees of freedom
ref_err = [0.0022,0.0796,0.2187,0.2006,0.4414,0.5421,0.4528,0];
ref_dist = [5, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];


%figure;
hold on;
errorbar(ref_dist,ref_volt,ref_err,'r');

voltage = zeros(n,m);

for i=1:n
    [~, ~, ~, t_RX, CC_RX, ~, ~,~] = simulate_STEIN(params);
    %converting time to distance
	d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
	%adjusting the length of the vectors 
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	%calculating the efficiency
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

disp(['Finishing experiment number ',num2str(number)]);
