dist_water = [0.50; 0.75; 1.00; 1.25; 1.50; 1.75; 2.00; 2.25; 2.50; 2.75];
%reference values in V (from STEIN paper, 35g/L salty water experiment)
ref_volt35 = [4.93, 4.63, 3.88, 3.27, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.93, 4.42, 4.34, 3.59, 3.26, 3.17, 0.80, 0.00, 0.00, 0.00;
              4.93, 4.93, 4.47, 3.50, 3.52, 2.99, 0.12, 0.00, 0.00, 0.00;
              4.77, 4.30, 3.95, 3.17, 1.77, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.91, 3.98, 3.90, 3.64, 1.68, 1.16, 0.00, 0.00, 0.00, 0.00;
              4.92, 4.60, 4.12, 3.37, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00];
mean35 = mean(ref_volt35);
sd35 = std(ref_volt35);
%reference values in V (from STEIN paper, sweet water experiment)
ref_volt00 = [4.99, 4.93, 4.82, 4.62, 3.65, 3.00, 0.00, 0.00, 0.00, 0.00;
              4.93, 4.93, 4.47, 3.15, 1.61, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.93, 4.93, 4.93, 4.75, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.93, 4.80, 4.67, 4.05, 3.43, 2.57, 1.71, 0.00, 0.00, 0.00];
mean00 = mean(ref_volt00);
sd00 = std(ref_volt00);
%reference values in V (from STEIN paper, 10g/L salty water experiment)
ref_volt10 = [4.92, 4.52, 3.51, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.92, 4.92, 4.93, 4.68, 4.28, 2.68, 1.72, 0.00, 0.00, 0.00;
              4.93, 4.89, 3.89, 3.49, 2.32, 0.08, 0.00, 0.00, 0.00, 0.00;
              4.93, 4.60, 4.40, 4.02, 3.72, 3.35, 0.12, 0.00, 0.00, 0.00;
              4.93, 4.49, 3.80, 3.27, 1.38, 0.00, 0.00, 0.00, 0.00, 0.00;
              4.92, 4.93, 4.74, 3.92, 3.74, 3.18, 2.23, 0.15, 0.00, 0.00;
              4.93, 4.93, 4.92, 4.67, 3.87, 3.81, 3.01, 2.31, 0.00, 0.00];
mean10 = mean(ref_volt10);
sd10 = std(ref_volt10);

%reference values in W (from STEIN paper, land experiment)
dist_land = [0.50; 1.00; 1.20; 1.50; 2.00; 2.30; 2.50];
mean_land = [6.99; 6.63; 6.24; 5.12; 2.88; 1.76; 0.00];
sd_land   = [0.29; 0.06; 0.38; 0.26; 0.73; 0.00; 0.00];
%the equivalent resistance of the RX for this experiment:
R = 3.46;%ohms
%the voltage measurements
meanLand = [];
%the standard deviation
sdLand = [];
%a standard normal large sample
stdNormal = sqrt(-2*log(rand(10000000,1))).*cos(2*pi*rand(10000000,1));
%link interruption simulation
p = 0.025;%link interruption probability for each step
noReturnDistance = 0.125;%from this point, no re-establishment for the link
links = ones(sampleSize,1);%1=connected, 0=disconnected
for i=1:length(mean_land)
    %getting the sample of power (considering the normal distribution)
    sample = sd_land(i)*stdNormal+mean_land(i);
    %getting the correspondent sample of voltages
    volt = sqrt(R*sample);
    meanLand = [meanLand,mean(volt)];
    sdLand = [sdLand,std(volt)];
end

hold on;
errorbar(dist_water,mean35,2.02*sd35/sqrt(6));
errorbar(dist_water,mean10,1.94*sd10/sqrt(7));
errorbar(dist_water,mean00,2.35*sd00/sqrt(4));
errorbar(dist_water,meanLand,2.02*sd35/sqrt(6));

%TODO: INTERPOLAÇÃO E SIMULAÇÃO DE INTERRUPÇÃO DE LINK
