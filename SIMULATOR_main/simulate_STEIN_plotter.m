clear all;

n = 100;
smooth_radius = 20;
m = 11;
d_min = 5;
d_max = 30;
tTime = 1000;

params.improved_circ = false;
params.improved_rx = true;
params.improved_tx = false;

params.R = [0.025;30];
params.miEnv = 1.256627e-06;
params.maxCurrent = 0.06;
params.env = 'STEIN_ENV.mat';
params.endProb = 0.00175;
params.beta = 0.5;

params.greedy = false;

%reference values
ref_eff = [0.74, 0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_err = [0.0078, 0.0104, 0.0547, 0.2396, 0.1849, 0.2760, 0.0938, 0.0052];
ref_dist = [5, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

figure;
hold on;
errorbar(ref_dist,ref_eff,ref_err,'r');

eff = zeros(n,m);

for i=1:n
	[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX, t_W, W,Ir] = simulate_STEIN(params);
	%converting time to distance
	d_TX = ((tTime-t_TX)*d_min + d_max*t_TX)/tTime;
	d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
	%adjusting the length of the vectors 
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	sBC_TX1 = reduceSeries(BC_TX1, smooth_radius, m);
	sBC_TX2 = reduceSeries(BC_TX2, smooth_radius, m);
	%calculating the efficiency
	eff(i,:) = (abs(params.R(2).*sCC_RX.^2)./(abs(params.R(1).*sBC_TX1.^2)...
		+abs(params.R(1).*sBC_TX2.^2)+abs(params.R(2).*sCC_RX.^2)))';
end

number = rand;%used to differenciate the experiments

if n==1
	plot(linspace(d_min,d_max,m),eff,'b');
else
	errorbar(linspace(d_min,d_max,m),mean(eff),std(eff),'b');
end
ylim([0 inf]);
title(['Exp number ',num2str(number)]);
xlabel('Distance (mm)','FontSize',14,'FontWeight','bold')
ylabel('Efficiency','FontSize',14,'FontWeight','bold')

%calculating the normalized mean square error
mse = sqrt(sum((mean(eff)-[ref_eff,zeros(1,length(mean(eff))-length(ref_eff))]).^2))/(length(mean(eff))*mean(ref_eff));

disp(['normalized mean square error: ',num2str(mse*100),'%']);
