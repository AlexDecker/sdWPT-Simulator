clear all;

params.R = [0.0250;35];
params.C = [1.0000e-07;1.8300e-07];
params.W = 9.8960e+05;
params.zone1Limit = 0.014;
params.zone2Limit = 0.016;
params.miEnv1 = 7.5398e-06;
params.miEnv2 = 1.2566e-06;

%valor de referência
ref_eff = [0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_dist = [7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

hold on;
plot(ref_dist,ref_eff,'r');

[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX] = simulate_STEIN();
%convertendo tempo em distância
d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;

eff_list = [];

raio = 50;

sBC_TX1 = zeros(length(BC_TX1),1);
sBC_TX2 = zeros(length(BC_TX2),1);
sCC_RX = zeros(length(CC_RX),1);

for i=1:length(BC_TX1)
	i0 = max(1,i-raio);
	i1 = min(length(BC_TX1),i+raio);
	sBC_TX1(i) = mean(BC_TX1(i0:i1));
	sBC_TX2(i) = mean(BC_TX2(i0:i1));
end

for i=1:length(CC_RX)
	i0 = max(1,i-raio);
	i1 = min(length(CC_RX),i+raio);
	sCC_RX(i) = mean(CC_RX(i0:i1));
end

m = min(length(t_TX),length(t_RX));
sCC_RX = sCC_RX(ceil(linspace(1,length(sCC_RX), m)));
sBC_TX1 = sBC_TX1(ceil(linspace(1,length(sBC_TX1), m)));
sBC_TX2 = sBC_TX2(ceil(linspace(1,length(sBC_TX2), m)));

eff = abs(params.R(2).*sCC_RX.^2)./(abs(params.R(1).*sBC_TX1.^2)+abs(params.R(1).*sBC_TX2.^2)+abs(params.R(2).*sCC_RX.^2));


plot(linspace(7.5,22.5,length(eff)),eff,'b');

