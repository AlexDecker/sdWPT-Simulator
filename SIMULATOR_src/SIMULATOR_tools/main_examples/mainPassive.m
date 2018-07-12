close all; clear;

f = 1e+5;
d = 0;

v0= 15;
v1= 10;
R0 = 100;
R1 = 10000;
M = 1e-4;
L = 3e-4;
C = 1/(L*(2*pi*f))^2;
I = [R0 -(1i)*2*pi*f*M;-(1i)*2*pi*f*M R1]\[v0;0];
t0 = 1e-4*[2.4 2.4];
baudRate = f/10;
dsec = 4/baudRate;

T = [2e-4 8e-4];
n = 1500;
msg  = ['00000';'10101'];

iZ=calculateInverseZMatrix(R0*[1 1],C*[1 1],L*[1 0;0 1]+M*[0 1;1 0]);
disp('Start evaluating current');
%[I1,t1] = evaluateCurrent(iZ,2,v0*[1 0],v1*[1 0],f*[1 1],d*[1 1],T,n,t0,msg,baudRate,dsec,4);
[I1,t1] = evaluateCurrent(iZ,1,v0*[1 0],[v1 -(R1-R0)*abs(I(2))],f*[1 1],d*[1 1],T,n,t0,msg,baudRate,dsec,4);
disp('Start two port simulation');

Vt = linspace(T(1),T(2),n);
Rt = linspace(T(1),T(2),n);
V = v0*sin(2*pi*f*Vt);
R = heaviside(Rt-(t0(2)))-heaviside(Rt-(t0(2)+1/baudRate))...
    +heaviside(Rt-(t0(2)+2/baudRate))-heaviside(Rt-(t0(2)+3/baudRate))...
    +heaviside(Rt-(t0(2)+4/baudRate))-heaviside(Rt-(t0(2)+5/baudRate));

[I2,t2] = completeTwoPortSimulator(M,L,C,R0,Rt,R0+(R1-R0)*R,Vt,V,T);
%hold on; plot(t1,1000*I1);plot(t2,1000*I2(:,4));
hold on; plot(t1,1000*I1);plot(t2,1000*I2(:,3));figure;plot(t2,1000*I2(:,4));
[a1,~,~] = getSignalAmplitude(I1,R0);
[a2,~,~] = getSignalAmplitude(I2(:,3),R0);