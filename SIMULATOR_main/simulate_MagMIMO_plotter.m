clear all;

%reference values

MIMO10X = [0;0.240356083;0.486053412;0.753115727;0.998813056;1.255192878;1.500890208;
1.746587537;2.002967359;2.248664688;2.50504451];
MIMO10Y = [0;14.34927697;30.14460512;43.27030033;53.2814238;63.07007786;73.30367075;
82.20244716;90.21134594;94.21579533;100];

MIMO20X = [0;0.283086053;0.592878338;0.870623145;1.169732938;1.458160237;1.746587537;
2.035014837;2.323442136;2.622551929;2.900296736;3.210089021;3.49851632];
MIMO20Y = [0;12.12458287;21.91323693;33.25917686;43.04783092;51.94660734;61.06785317;
71.07897664;79.31034483;86.20689655;91.32369299;94.21579533;100];

MIMO30X = [0;0.261721068;0.528783383;0.795845697;1.062908012;1.329970326;1.597032641;
1.874777448;2.13115727;2.398219585;2.665281899;2.932344214;3.210089021;3.466468843;
3.733531157;4.000593472;4.267655786;4.524035608;4.812462908];
MIMO30Y = [0;8.120133482;15.23915462;21.02335929;27.91991101;35.26140156;40.378198;
46.38487208;51.27919911;57.28587319;62.40266963;67.07452725;73.30367075;78.19799778;
84.20467186;89.3214683;92.43604004;95.55061179;100];

MIMO40X = [0;0.43264095;0.881305638;1.319287834;1.75727003;2.205934718;2.633234421;
3.08189911;3.519881306;3.957863501;4.395845697;4.833827893;5.282492582;5.720474777;
6.158456973;6.585756677;7.023738872;7.483086053;7.921068249;8.359050445;8.797032641];

MIMO40Y = [0;7.007786429;15.01668521;21.02335929;27.03003337;33.25917686;39.04338154;
44.16017798;49.27697442;53.05895439;58.39822024;62.40266963;67.07452725;73.08120133;
77.08565072;81.53503893;86.20689655;90.21134594;92.43604004;95.10567297;100];

%executing the simulations

disp('Starting 10cm...');
[~, ~, SOC, TSOC, RL, TRL] = simulate_MagMIMO('envMIMODist10.mat');
disp('Finished...');

figure;
plot(TRL.vals/3600,RL.vals);
xlabel('Time (h)')
ylabel('RL (ohms)')
title('Load Resistance Progression');

%load resistance vs SOC chart
figure;
plot(SOC.vals(1:min(length(SOC.vals),length(RL.vals)))*100,...
	RL.vals(1:min(length(SOC.vals),length(RL.vals))));
xlabel('SOC (%)')
ylabel('RL (ohms)')
title('Load Resistance vs SOC');

figure;
hold on;

%Starting main chart
plot(TSOC.vals/3600,100*SOC.vals);

%error estimation
lim_min = max(min(TSOC.vals/3600),min(MIMO10X));
lim_max = min(max(TSOC.vals/3600),max(MIMO10X));
[X,index] = unique(TSOC.vals/3600);%removing repeated values
eMIMO10 = interp1(MIMO10X,MIMO10Y,...
	linspace(lim_min,lim_max,100))...
	- interp1(X,100*SOC.vals(index),...
	linspace(lim_min,lim_max,100));

disp('Starting 20cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist20.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);

%error estimation
lim_min = max(min(TSOC.vals/3600),min(MIMO20X));
lim_max = min(max(TSOC.vals/3600),max(MIMO20X));
[X,index] = unique(TSOC.vals/3600);%removing repeated values
eMIMO20 = interp1(MIMO20X,MIMO20Y,...
	linspace(lim_min,lim_max,100))...
	- interp1(X,100*SOC.vals(index),...
	linspace(lim_min,lim_max,100));

disp('Starting 30cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist30.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);

%error estimation
lim_min = max(min(TSOC.vals/3600),min(MIMO30X));
lim_max = min(max(TSOC.vals/3600),max(MIMO30X));
[X,index] = unique(TSOC.vals/3600);%removing repeated values
eMIMO30 = interp1(MIMO30X,MIMO30Y,...
	linspace(lim_min,lim_max,100))...
	- interp1(X,100*SOC.vals(index),...
	linspace(lim_min,lim_max,100));

disp('Starting 40cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist40.mat');
disp('Finished...');
plot(TSOC.vals/3600,100*SOC.vals);

%error estimation
lim_min = max(min(TSOC.vals/3600),min(MIMO40X));
lim_max = min(max(TSOC.vals/3600),max(MIMO40X));
[X,index] = unique(TSOC.vals/3600);%removing repeated values
eMIMO40 = interp1(MIMO40X,MIMO40Y,...
	linspace(lim_min,lim_max,100))...
	- interp1(X,100*SOC.vals(index),...
	linspace(lim_min,lim_max,100));

%reference curves
plot(MIMO10X,MIMO10Y,'--');
plot(MIMO20X,MIMO20Y,'--');
plot(MIMO30X,MIMO30Y,'--');
plot(MIMO40X,MIMO40Y,'--');

xlabel('Time (h)')
ylabel('(%)')
legend('10 cm','20 cm','30 cm','40 cm');
title('SOC Progression');

%error estimation
e10 = sqrt(sum(eMIMO10.^2))/(length(eMIMO10)*mean(MIMO10Y));
e20 = sqrt(sum(eMIMO20.^2))/(length(eMIMO20)*mean(MIMO20Y));
e30 = sqrt(sum(eMIMO30.^2))/(length(eMIMO30)*mean(MIMO30Y));
e40 = sqrt(sum(eMIMO40.^2))/(length(eMIMO40)*mean(MIMO40Y));
disp(['normalized mean square error: (10 cm)',num2str(e10*100),'%']);
disp(['normalized mean square error: (20 cm)',num2str(e20*100),'%']);
disp(['normalized mean square error: (30 cm)',num2str(e30*100),'%']);
disp(['normalized mean square error: (40 cm)',num2str(e40*100),'%']);
