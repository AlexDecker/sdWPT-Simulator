clear all;

figure;
hold on;
[~, ~, SOC, TSOC] = simulate_MagMIMO('envMIMODist10.mat');
plot(TSOC/3600,100*SOC);
[~, ~, SOC, TSOC] = simulate_MagMIMO('envMIMODist20.mat');
plot(TSOC/3600,100*SOC);
[~, ~, SOC, TSOC] = simulate_MagMIMO('envMIMODist30.mat');
plot(TSOC/3600,100*SOC);
[~, ~, SOC, TSOC] = simulate_MagMIMO('envMIMODist40.mat');
plot(TSOC/3600,100*SOC);
xlabel('Time (h)')
ylabel('(%)')
legend('10 cm','20 cm','30 cm','40 cm');
title('SOC Progression');

figure;
hold on;
[P_RX, T_RX, ~, ~] = simulate_MagMIMO('envMIMOOrient02.mat');
Orientation = (90/max(T_RX))*T_RX;
plot(Orientation,P_RX);
[P_RX, T_RX, ~, ~] = simulate_MagMIMO('envMIMOOrient10.mat');
Orientation = (90/max(T_RX))*T_RX;
plot(Orientation,P_RX);
[P_RX, T_RX, ~, ~] = simulate_MagMIMO('envMIMOOrient20.mat');
Orientation = (90/max(T_RX))*T_RX;
plot(Orientation,P_RX);
[P_RX, T_RX, ~, ~] = simulate_MagMIMO('envMIMOOrient40.mat');
Orientation = (90/max(T_RX))*T_RX;
plot(Orientation,P_RX);
xlabel('Orientation (deg)')
ylabel('(W)')
legend('2 cm','10 cm','20 cm','40 cm');
title('Power Received vs Orientation of RX');
