%RegularQi.svg
load('experiment_784349.mat');
voltage_regularQi = voltage;
voltage0_regularQi = voltage0;
current_regularQi = voltage./params.R(2);
current0_regularQi = voltage0./params.R(2);
d_regularQi = linspace(d_min,d_max,m);

%RX-optimal.svg
load('experiment_984658.mat');
voltage_optimal = voltage;
voltage0_optimal = voltage0;
current_optimal = voltage./params.R(2);
current0_optimal = voltage0./params.R(2);
d_optimal = linspace(d_min,d_max,m);

%ResonantPing.svg
load('experiment_946664.mat');
voltage_ResonantPing = voltage;
voltage0_ResonantPing = voltage0;
current_ResonantPing = voltage./params.R(2);
current0_ResonantPing = voltage0./params.R(2);
d_ResonantPing = linspace(d_min,d_max,m);

%RX-Optimized.svg
%load('experiment_652768.mat');
%voltage_Optimized = voltage;
%current_Optimized = voltage./params.R(2);

%RX_Optimized2.svg (Rmin+1e-7F)
load('experiment_849236.mat');
voltage_Optimized2 = voltage;
voltage0_Optimized2 = voltage0;
current_Optimized2 = voltage./params.R(2);
current0_Optimized2 = voltage0./params.R(2);
d_Optimized2 = linspace(d_min,d_max,m);


%admit n=100. if you have Statistics Toolbox, use tinv instead of the constant

figure;
hold on;

errorbar(d_regularQi, mean(voltage_regularQi), 1.66039*std(voltage_regularQi)/sqrt(100), '-b');
errorbar(d_ResonantPing, mean(voltage_ResonantPing), 1.66039*std(voltage_ResonantPing)/sqrt(100), '--r');
errorbar(d_Optimized2, mean(voltage_Optimized2), 1.66039*std(voltage_Optimized2)/sqrt(100), '*k');
errorbar(d_optimal, mean(voltage_optimal), 1.66039*std(voltage_optimal)/sqrt(100), '.g');

plot(d_regularQi, voltage0_regularQi, '-b');
plot(d_ResonantPing, voltage0_ResonantPing, '--r');
plot(d_Optimized2, voltage0_Optimized2, '*k');
plot(d_optimal, voltage0_optimal, '.g');

legend('Regular Qi', 'Resonant Ping', 'RX-Optimized', 'Optimal (estimation)');

figure;
hold on;

errorbar(d_regularQi, mean(current_regularQi), 1.66039*std(current_regularQi)/sqrt(100), '-b');
errorbar(d_ResonantPing, mean(current_ResonantPing), 1.66039*std(current_ResonantPing)/sqrt(100), '--r');
errorbar(d_Optimized2, mean(current_Optimized2), 1.66039*std(current_Optimized2)/sqrt(100), '*k');
errorbar(d_optimal, mean(current_optimal), 1.66039*std(current_optimal)/sqrt(100), '.g');

plot(d_regularQi, current0_regularQi, '-b');
plot(d_ResonantPing, current0_ResonantPing, '--r');
plot(d_Optimized2, current0_Optimized2, '*k');
plot(d_optimal, current0_optimal, '.g');
legend('Regular Qi', 'Resonant Ping', 'RX-Optimized', 'Optimal (estimation)');