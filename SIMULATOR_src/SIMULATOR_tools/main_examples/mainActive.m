close all; clear;

f = [1e+5 1e+5];
d = [0 0];

v0= [15 0];
v1= [10 0];
R = [50 50];
M = [1e-4 1e-5;
     1e-5 1e-4];
C = [1/(M(1,1)*(2*pi*f(1,1))^2) 1/(M(2,2)*(2*pi*f(1,1))^2)];

t0 = 1e-4*[0.4 0.4];
baudRate = f(1,1)/20;
%baudRate = f(1,1)/5;
dsec = 4/baudRate;

T = [0 5e-3];
n = 15000;

msg  = [toManchester('0000100101101001');'00000000000000000000000000000000'];

iZ=calculateInverseZMatrix(R,C,M);
[I,t] = evaluateCurrent(iZ,2,v0,v1,f,d,T,n,t0,msg,baudRate,dsec,4);
[a,~,~] = getSignalAmplitude(I,R(2));
[msg,lvl,bri] = decodeSignal(a, 1000, 3);

plot(t,1000*I)%plot in mA
figure;
plot(t,1000*a)%plot in mA
figure;
plot(t,1./((T(2)-T(1))/n*bri))
figure;
plot(t,lvl)
axis([t(1) t(end) -0.5 1.5])