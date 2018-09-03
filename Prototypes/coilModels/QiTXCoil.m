classdef QiTXCoil < coil
    methods
        %creates a spiral planar coil centered at the origin
        %R1: inner radius, R2: outter radius, N: number of turns,
        %ang: angle (rad) through which the wire moves from first
        %to second layers, pts: desired number of points of the path
        function obj = QiTXCoil(R2,R1,N,ang,wire_radius,pts,mi)
            
            delta = (R2-R1)/(2*pi*N);
            
            teta1 = linspace(0,2*pi*N,pts/2);
            teta2 = linspace(2*pi*N-ang,ang,pts/2);
            
            x1 = (R2-teta1*delta).*cos(teta1);
            y1 = (R2-teta1*delta).*sin(teta1);
            z1 = zeros(1,pts/2);
            
            x2 = (R2-teta2*delta).*cos(-teta2);
            y2 = (R2-teta2*delta).*sin(-teta2);
            z2 = 2*wire_radius*ones(1,pts/2);
            
            if exist('mi','var')
                MI=mi;
            else
                MI=pi*4e-7;
            end
            
            obj@coil([x1,x2],[y1,y2],[z1,z2],wire_radius,MI);
        end
    end
end
