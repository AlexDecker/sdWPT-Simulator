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

params.R = [0.015;3.97];%[0.005;3.97];
params.miEnv = 1.256627e-06;
params.maxCurrent = 1.2594;
params.env = 'STEIN_ENV.mat';
params.endProb = 0;%0.00175;
params.beta = 0;%0.5;

params.greedy = 0;

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


%figure;
hold on;
errorbar(ref_dist,ref_mean,ref_err,'r');

voltage = zeros(n,m);

for i=1:n
    [~, ~, ~, t_RX, CC_RX, t_W, W,~] = simulate_STEIN(params);
    %converting time to distance
	d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
	%adjusting the length of the vectors 
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	%calculating the efficiency
	voltage(i,:) = params.R(2)*sCC_RX;
end


if n==1
	plot(linspace(d_min,d_max,m),voltage,'k');
else
    %admit n=100. if you have Statistics Toolbox, use tinv instead of the constant
	errorbar(linspace(d_min,d_max,m),mean(voltage),1.66039*std(voltage)/(2*sqrt(100)),'b');
end
ylim([0 inf]);
title(['Exp number ',num2str(number)]);
xlabel('Distance (mm)','FontSize',14,'FontWeight','bold')
ylabel('Voltage(V)','FontSize',14,'FontWeight','bold')

figure;
plot(t_W,W);
ylim([105000,210000]);
disp(['Finishing experiment number ',num2str(number)]);
