classdef QiTXCoil < coil
    methods
        %creates a spiral planar coil centered at the origin
        %R1: inner radius, R2: outter radius, N: number of turns,
        %ang: angle (rad) through which the wire moves from first
        %to second layers, pts: desired number of points of the path
        function obj = QiTXCoil(R2,R1,N,ang,wire_radius,pts)
            delta = (R2-R1)/N;
            
            tetaMin1 = R1*N*2*pi/(R2-R1);
            tetaMax1 = R2*N*2*pi/(R2-R1);
            
            teta1 = linspace(tetaMin1,tetaMax1,pts/2);
            teta2 = linspace(tetaMax1+ang,tetaMin1+ang,pts/2);
            
            x1 = delta*teta1.*cos(teta1)/(2*pi);
            y1 = delta*teta1.*sin(teta1)/(2*pi);
            z1 = zeros(1,pts/2);
            
            x2 = delta*teta2.*cos(-teta2)/(2*pi);
            y2 = delta*teta2.*sin(-teta2)/(2*pi);
            z2 = 2*wire_radius*ones(1,pts/2);
            
            obj@coil([x2,x1],[y2,y1],[z2,z1],wire_radius);
        end
    end
end
