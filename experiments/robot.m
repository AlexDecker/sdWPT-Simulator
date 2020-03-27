clear all;
load('robot.mat');

threshold1 = 1.5;
threshold2 = 10000;

stats1 = robot_analyzer(Exp1,threshold1,threshold2);
stats2 = robot_analyzer(Exp2,threshold1,threshold2);
stats3 = robot_analyzer(Exp3,threshold1,threshold2);

onlineTime = [[stats1.onlineTime],[stats2.onlineTime],[stats3.onlineTime]];

offlineTime = [[stats1.offlineTime],[stats2.offlineTime],[stats3.offlineTime]];

timeRatio = onlineTime./(onlineTime+offlineTime);

voltage = 5*double([Exp1(:,2).',Exp2(:,2).',Exp3(:,2).'])/1024;

highVoltage = voltage(voltage>=threshold1);

interruptions = [[stats1.interruptions],[stats2.interruptions],[stats3.interruptions]];

linkInterruptionRatio = 1000*interruptions./double(onlineTime+offlineTime);

%subplot(2,2,1); boxplot(double(onlineTime)/1000,{'online time (s)'});ylim([0,17]);
%subplot(2,2,2); boxplot(double(offlineTime)/1000,{'offline time (s)'});ylim([0,17]);
%subplot(2,2,3); boxplot(highVoltage,{'online voltage (V)'});
%subplot(2,2,4); boxplot(linkInterruptionRatio,{'link interruption ratio (hz)'});

subplot(2,2,1); histogram(double(onlineTime)/1000,...
                    'edgealpha',0,...
                    'normalization','probability',...
                    'numbins',10);
                title('online time (s)');
subplot(2,2,2); histogram(highVoltage,...
                    'edgealpha',0,...
                    'normalization','probability');
                title('online voltage (V)');
subplot(2,2,3); histogram(double(offlineTime)/1000,...
                    'edgealpha',0,...
                    'normalization','probability',...
                    'numbins',10);
                title('interruptions per attempt');
subplot(2,2,4); histogram(linkInterruptionRatio,...
                    'edgealpha',0,...
                    'normalization','probability',...
                    'numbins',10);
                title('interruptions per second');

