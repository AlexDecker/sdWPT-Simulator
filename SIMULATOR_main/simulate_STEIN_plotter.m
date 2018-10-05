clear all;

params.R = [0.025;30];
params.miEnv = 1.256627e-06;
params.maxCurrent = 0.0376;

%valor de referência
ref_eff = [0.74, 0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_dist = [5, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

hold on;
plot(ref_dist,ref_eff,'r');

[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX, t_W, W] = simulate_STEIN(params);
%convertendo tempo em distância
d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;

eff_list = [];

smooth_radius = 50;

m = min(length(t_TX),length(t_RX));
sCC_RX = reduceSeries(CC_RX, smooth_radius, m);
sBC_TX1 = reduceSeries(BC_TX1, smooth_radius, m);
sBC_TX2 = reduceSeries(BC_TX2, smooth_radius, m);

eff = abs(params.R(2).*sCC_RX.^2)./(abs(params.R(1).*sBC_TX1.^2)+abs(params.R(1).*sBC_TX2.^2)+abs(params.R(2).*sCC_RX.^2));


plot(linspace(5,30,length(eff)),eff,'b');
figure;
plot(t_W,W);
