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
[~, ~, SOC, TSOC, ~, ~] = simulate_MagMIMO('envMIMODist10.mat');
disp('Finished...');
X10 = TSOC.vals/3600;
Y10 = 100*SOC.vals;

disp('Starting 20cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist20.mat');
disp('Finished...');
X20 = TSOC.vals/3600;
Y20 = 100*SOC.vals;

disp('Starting 30cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist30.mat');
disp('Finished...');
X30 = TSOC.vals/3600;
Y30 = 100*SOC.vals;

disp('Starting 40cm...');
[~, ~, SOC, TSOC,~,~] = simulate_MagMIMO('envMIMODist40.mat');
disp('Finished...');
X40 = TSOC.vals/3600;
Y40 = 100*SOC.vals;

figure;hold on;
plot(X10,Y10,'-');
plot(X20,Y20,'-');
plot(X30,Y30,'-');
plot(X40,Y40,'-');

%reference curves
plot(MIMO10X,MIMO10Y,'--');
plot(MIMO20X,MIMO20Y,'--');
plot(MIMO30X,MIMO30Y,'--');
plot(MIMO40X,MIMO40Y,'--');

xlabel('Time (h)')
ylabel('(%)')
legend('10 cm','20 cm','30 cm','40 cm');
title('SOC Progression');

%preparing the data to comparision
x10 = linspace(max(min(X10),min(MIMO10X)),min(max(X10),max(MIMO10X)),100);
x20 = linspace(max(min(X20),min(MIMO20X)),min(max(X20),max(MIMO20X)),100);
x30 = linspace(max(min(X30),min(MIMO30X)),min(max(X30),max(MIMO30X)),100);
x40 = linspace(max(min(X40),min(MIMO40X)),min(max(X40),max(MIMO40X)),100);
ref10 = interp1(MIMO10X,MIMO10Y,x10);%the reference data for 10cm
ref20 = interp1(MIMO20X,MIMO20Y,x20);
ref30 = interp1(MIMO30X,MIMO30Y,x30);
ref40 = interp1(MIMO40X,MIMO40Y,x40);
calc10 = interp1(X10(index),Y10(index),x10);%the data to be evaluated for 10cm
calc20 = interp1(X20(index),Y20(index),x20);
calc30 = interp1(X30(index),Y30(index),x30);
calc40 = interp1(X40(index),Y40(index),x40);

%root mean squared error
rmse10 = sqrt(mean((ref10-calc10).^2))
rmse20 = sqrt(mean((ref20-calc20).^2))
rmse30 = sqrt(mean((ref30-calc30).^2))
rmse40 = sqrt(mean((ref40-calc40).^2))

%pearson correlation
V = cov(ref10,calc10);%covariance matrix
corr10 = V(1,2)/sqrt(V(1,1)*V(2,2))
V = cov(ref20,calc20);%covariance matrix
corr20 = V(1,2)/sqrt(V(1,1)*V(2,2))
V = cov(ref30,calc30);%covariance matrix
corr30 = V(1,2)/sqrt(V(1,1)*V(2,2)) 
V = cov(ref40,calc40);%covariance matrix
corr40 = V(1,2)/sqrt(V(1,1)*V(2,2)) 
