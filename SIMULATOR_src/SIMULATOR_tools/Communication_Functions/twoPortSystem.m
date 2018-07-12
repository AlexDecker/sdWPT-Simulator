%generates the ODE system that represents the interaction between a passive
%and an active circuit. M = mutual coupling, L = self-impedance of both
%coils (must be the same scalar value), C = capacitance of both circuits
%(single scalar), R0 = resistance of the active circuit, Rt = list of
%values of thefunction that describes the resistance of the passive circuit
%on time domain, Vt = list of values of the function that describes the
%source voltage of the active circuit on time domain
function dydt = twoPortSystem(t,y,M,L,C,R0,Rt,R,Vt,V)
    disp('Start interpolation');
    V=interp1(Vt,V,t);
    R=interp1(Rt,R,t);
    disp('Start system generation');
    dydt = zeros(4,1);
    dydt(1) = y(3);%Q1' = I1
    dydt(2) = y(4);%Q2' = I2
    dydt(3) = R.*M/(L^2-M^2)*y(4)...
                + M/(C*(L^2-M^2))*y(2)...
                - L*R0/(L^2-M^2)*y(3)...
                - L/(C*(L^2-M^2))*y(1)...
                + L/(L^2-M^2).*V;
    dydt(4) = R0*M/(L^2-M^2)*y(3)...
                + M/(C*(L^2-M^2))*y(1)...
                - R.*L/(L^2-M^2)*y(4)...
                - L/(C*(L^2-M^2))*y(2)...
                - M/(L^2-M^2).*V;
    disp('Start ODE resolution itself');
end

