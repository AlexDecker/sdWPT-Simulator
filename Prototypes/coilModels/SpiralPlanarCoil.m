classdef SpiralPlanarCoil < coil
    methods
        %creates a spiral planar coil centered at the origin
        %R1: inner radius, R2: outter radius, N: number of turns,
        %pts: desired number of points of the path
        function obj = SpiralPlanarCoil(R2,R1,N,wire_radius,pts)
            delta = (R2-R1)/N;
            tetaMin = R1*N*2*pi/(R2-R1);
            tetaMax = R2*N*2*pi/(R2-R1);
            teta = linspace(tetaMin,tetaMax,pts);
            x = delta*teta.*cos(teta)/(2*pi);
            y = delta*teta.*sin(teta)/(2*pi);
            z = zeros(1,pts);
            obj@coil(x,y,z,wire_radius);
        end
    end
end