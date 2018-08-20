classdef QiRXCoil < coil
    methods
        %creates a spiral planar coil centered at the origin
        %R1: inner border-radius, R2: outter border-radius,
        %N: number of turns,
        %pts: desired number of points of the path,
        %a,b:distance between the center of the borders
        
        function obj = QiRXCoil(R1,R2,N,a,b,wire_radius,pts)
            delta = (R2-R1)/N;
            tetaMin = R1*N*2*pi/(R2-R1);
            tetaMax = R2*N*2*pi/(R2-R1);
            teta = linspace(tetaMin,tetaMax,pts);
            x = delta*teta.*cos(teta)/(2*pi);
            y = delta*teta.*sin(teta)/(2*pi);
            z = zeros(1,pts);
            
            i=1;
            for t=teta
                p = t/(2*pi)-floor(t/(2*pi));
                if(p<0.25)
                    dx = a/2;
                    dy = b/2;
                else
                    if(p<0.5)
                        dx = -a/2;
                        dy = b/2;
                    else
                        if(p<0.75)
                            dx = -a/2;
                            dy = -b/2;
                        else
                            dx = a/2;
                            dy = -b/2;
                        end
                    end
                end
                x(i) = x(i)+dx;
                y(i) = y(i)+dy;
                i = i+1;
            end
            obj@coil(x,y,z,wire_radius);
        end
    end
end
