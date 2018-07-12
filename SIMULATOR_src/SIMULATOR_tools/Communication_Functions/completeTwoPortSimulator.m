function [y,t] = completeTwoPortSimulator(M,L,C,R0,Rt,R,Vt,V,ID)
    tic;
    [t,y] = ode45(@(t,y) twoPortSystem(t,y,M,L,C,R0,Rt,R,Vt,V),ID,[0 0 0 0]);
    toc;
end

