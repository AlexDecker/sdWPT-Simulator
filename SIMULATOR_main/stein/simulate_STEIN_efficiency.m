clear all;
rng('shuffle');
number = rand; %used to differenciate the experiments
disp(['Starting experiment number ',num2str(number)]);

smooth_radius = 100;
m = 140; %resample size

params.improved_tx = false;
params.R = [0.015;3.97];
params.miEnv = 1.256627e-06;
params.maxCurrent = 1.2594;
params.env = 'STEIN_ENV_large.mat';
params.beta = 0.225;

%params for TX/RX joint optimization
params.ttl_TX = 25;
params.ttl_RX = inf;

%involved distances
d_min = 5;
d_max = 74.5;
tTime = 1000;
params.stepByStep = true;

%NO LINK INTERRUPTION

%experiments: regular Qi 1.0, resonant Qi 1.0, Qi+, Qi optimal
improved_rx = [2];%[0, 0, 1, 2];
improved_circ = [false];%[false, true, false, false];
version = [2];%[2, 2, 2, 2];
line_style = {'.g'};%{'-b','--r','*k','.g'};

figure;
hold on;
for exp = 1:length(improved_rx)

	params.improved_rx = improved_rx(exp);%1: Qi+, 2: Qi optimal, other: regular Qi 1.0
	params.improved_circ = improved_circ(exp);
	params.version = version(exp);%Qi+ version

	params.endProb = 0;%no random link interruption
	[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX, t_W, W, ~, t_BC_RX, BC_RX1, BC_RX2, Rr] = simulate_STEIN(params);

	%adjusting the length of the vectors 
	sCC_RX = reduceSeries(CC_RX, smooth_radius, m); %DC current from RX device
	sBC_TX1 = reduceSeries(BC_TX1, smooth_radius, m); %AC current from one TX coil
	sBC_TX2 = reduceSeries(BC_TX2, smooth_radius, m); %AC current from the other TX coil
	
	sBC_RX1 = reduceSeries(BC_RX1, smooth_radius, m); %AC current from one RX coil
	sBC_RX2 = reduceSeries(BC_RX2, smooth_radius, m); %AC current from the other RX coil
	
	sRr = interp1(linspace(d_min, d_max, length(Rr)), Rr, linspace(d_min, d_max, m));

	%adjusting the curves to a single vector of distances
	d = linspace(d_min,d_max, m);
	%power calculation
	Prx = params.R(2)*sCC_RX.^2; %dissipated power on the load resistor
	P = params.R(1)*abs(sBC_TX1+sBC_TX2).^2 + sRr.*abs(sBC_RX1+sBC_RX2).^2; %power dissipated by the entire system (TX and RX)
	eff = Prx./P;
	%calculating the output voltage
	plot(d, eff, line_style{exp});
	%plot(d, params.R(2)*sCC_RX, '-r');
end
xlim([0,80])
ylim([0,1]);
xlabel('Distance (mm)');
ylabel('Efficiency 0-1');
legend('Regular Qi', 'Resonant Ping', 'RX-Optimized', 'Optimal (estimation)');