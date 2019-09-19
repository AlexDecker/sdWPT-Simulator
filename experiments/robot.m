clear all;
load('robot.mat');

threshold1 = 1.5;
threshold2 = 10000;

stats1 = robot_analyzer(Exp1,threshold1,threshold2);
stats2 = robot_analyzer(Exp2,threshold1,threshold2);
stats3 = robot_analyzer(Exp3,threshold1,threshold2);

onlineTime = [[stats1.onlineTime],[stats2.onlineTime],[stats3.onlineTime]]

offlineTime = [[stats1.offlineTime],[stats2.offlineTime],[stats3.offlineTime]]

timeRatio = onlineTime./(onlineTime+offlineTime)

voltage = 5*double([Exp1(:,2).',Exp2(:,2).',Exp3(:,2).'])/1024

highVoltage = voltage(voltage>=threshold1)

linkInterruptionRatio = 1000*...
    [[stats1.interruptions],[stats2.interruptions],[stats3.interruptions]]./...
    double(onlineTime+offlineTime)

