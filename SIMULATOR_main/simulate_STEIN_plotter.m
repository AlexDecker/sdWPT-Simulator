clear all;

n = 10;
smooth_radius = 20;
m = 11;
d_min = 5;
d_max = 30;
tTime = 1000;

params.R = [0.025;30];
params.miEnv = 1.256627e-06;
params.maxCurrent = 0.06;
params.env = 'STEIN_ENV.mat';
params.endProb = 0.002;

%valor de referência
ref_eff = [0.74, 0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_err = [0.0078, 0.0104, 0.0547, 0.2396, 0.1849, 0.2760, 0.0938, 0.0052];
ref_dist = [5, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

hold on;
errorbar(ref_dist,ref_eff,ref_err,'r');

eff = zeros(n,m);

for i=1:n
	[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX, t_W, W,Ir] = simulate_STEIN(params);
	%convertendo tempo em distância
	d_TX = ((tTime-t_TX)*d_min + d_max*t_TX)/tTime;
	d_RX = ((tTime-t_RX)*d_min + d_max*t_RX)/tTime;
	%ajustando o comprimento 
	%m = min(length(t_TX),length(t_RX));
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	sBC_TX1 = reduceSeries(BC_TX1, smooth_radius, m);
	sBC_TX2 = reduceSeries(BC_TX2, smooth_radius, m);
	%calculando a eficiência
	eff(i,:) = (abs(params.R(2).*sCC_RX.^2)./(abs(params.R(1).*sBC_TX1.^2)+abs(params.R(1).*sBC_TX2.^2)+abs(params.R(2).*sCC_RX.^2)))';
end

if n==1
	plot(linspace(d_min,d_max,m),eff,'b');
else
	errorbar(linspace(d_min,d_max,m),mean(eff),std(eff),'b');
end
ylim([0 inf]);