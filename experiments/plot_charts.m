%RegularQi.svg
load('experiment_784349.mat');
voltage_regularQi = voltage;
current_regularQi = voltage./params.R(2);

%RX-optimal.svg
load('experiment_984658.mat');
voltage_optimal = voltage;
current_optimal = voltage./params.R(2);

%ResonantPing.svg
load('experiment_946664.mat');
voltage_ResonantPing = voltage;
current_ResonantPing = voltage./params.R(2);

%RX-Optimized.svg
load('experiment_652768.mat');
voltage_Optimized = voltage;
current_Optimized = voltage./params.R(2);

%RX_Optimized2.svg (Rmin+1e-7F)
load('experiment_849236.mat');
voltage_Optimized2 = voltage;
current_Optimized2 = voltage./params.R(2);
