clear all;

disp('Starting 10cm...');
[~, ~, SOC, TSOC, RL, TRL] = simulate_MagMIMO('envMIMODist10.mat');
disp('Finished...');
figure;
plot(TRL.vals/3600,RL.vals);
xlabel('Time (h)')
ylabel('RL (ohms)')
title('Load Resistance Progression');

figure;
plot(SOC.vals(1:min(length(SOC.vals),length(RL.vals)))*100,...
	RL.vals(1:min(length(SOC.vals),length(RL.vals))));
xlabel('SOC (%)')
ylabel('RL (ohms)')
title('Load Resistance vs SOC');

figure;
hold on;
plot([0,2.5],[0,100]);
plot([0,3.5],[0,100]);
plot([0,4.7],[0,100]);
plot([0,8.8],[0,100]);
plot(TSOC.vals/3600,100*SOC.vals);

disp('Starting 20cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist20.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);
disp('Starting 30cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist30.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);
disp('Starting 40cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist40.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);


xlabel('Time (h)')
ylabel('(%)')
legend('10 cm','20 cm','30 cm','40 cm');
title('SOC Progression');

%{
figure;
hold on;
[P_RX, T_RX, ~, ~, ~, ~] = simulate_MagMIMO('envMIMOOrient02.mat');
Orientation = (90/max(T_RX.vals))*T_RX.vals;
plot(Orientation,P_RX.vals);
[P_RX, T_RX, ~, ~, ~, ~] = simulate_MagMIMO('envMIMOOrient10.mat');
Orientation = (90/max(T_RX.vals))*T_RX.vals;
plot(Orientation,P_RX.vals);
[P_RX, T_RX, ~, ~, ~, ~] = simulate_MagMIMO('envMIMOOrient20.mat');
Orientation = (90/max(T_RX.vals))*T_RX.vals;
plot(Orientation,P_RX.vals);
[P_RX, T_RX, ~, ~, ~, ~] = simulate_MagMIMO('envMIMOOrient40.mat');
Orientation = (90/max(T_RX.vals))*T_RX.vals;
plot(Orientation,P_RX.vals);
xlabel('Orientation (deg)')
ylabel('(W)')
legend('2 cm','10 cm','20 cm','40 cm');
title('Power Received vs Orientation of RX');
%}
