classdef SolenoidCoil < coil
    methods
        %creates a spiral planar coil centered at the origin
        %R: radius, N: number of turns, pitch: gap between the turns
        %pts: desired number of points of the path
        function obj = SolenoidCoil(R,N,pitch,wire_radius,pts)
            tetaMin = 0;
            tetaMax = 2*pi*N;
            teta = linspace(tetaMin,tetaMax,pts);
            x = R*cos(teta);
            y = R*sin(teta);
            z = teta*pitch;
            obj@coil(x,y,z,wire_radius);
        end
    end
end