clear all;

n = 1;
smooth_radius = 100;
m = 11;

params.R = [0.025;30];
params.miEnv = 1.256627e-06;
params.maxCurrent = 0.06;
params.env = 'STEIN_ENV.mat';
params.endProb = 0;%0.0005;

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
	d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
	d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;
	%ajustando o comprimento 
	%m = min(length(t_TX),length(t_RX));
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
	sBC_TX1 = reduceSeries(BC_TX1, smooth_radius, m);
	sBC_TX2 = reduceSeries(BC_TX2, smooth_radius, m);
	%calculando a eficiência
	eff(i,:) = (abs(params.R(2).*sCC_RX.^2)./(abs(params.R(1).*sBC_TX1.^2)+abs(params.R(1).*sBC_TX2.^2)+abs(params.R(2).*sCC_RX.^2)))';
end

m_eff = 0*ref_eff;
sd_eff = 0*ref_eff;

for i=1:length(m_eff)
	m_eff(i) = mean(eff(:,i));
	sd_eff(i) = std(eff(:,i));
end

errorbar(ref_dist,m_eff,sd_eff,'b');
ylim([0 inf]);