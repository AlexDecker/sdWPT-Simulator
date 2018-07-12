classdef coil
   properties
       x
       y
       z
       r %raio da área do fio em metros
       X %coordenadas X,Y,Z do centro da bobina
       Y
       Z
   end
   methods
      %descreve geometricamente a bobina e inicializa os atributos
      function obj = coil(R2,R1,N,wire_radius,pts)
         delta = (R2-R1)/N;
         tetaMin = R1*N*2*pi/(R2-R1);
         tetaMax = R2*N*2*pi/(R2-R1);
         teta = linspace(tetaMin,tetaMax,pts);
         obj.x = delta*teta.*cos(teta)/(2*pi);
         obj.y = delta*teta.*sin(teta)/(2*pi);
         obj.z = zeros(1,pts);
         obj.r = wire_radius;
         obj.X = 0;obj.Y = 0;obj.Z = 0;
      end
      function plotCoil(obj)
           plot3(obj.x, obj.y, obj.z);
      end
      
      function obj = rotateCoilX(obj,ang)
          tX = obj.X;tY = obj.Y;tZ = obj.Z;
          obj = translateCoil(obj,-tX,-tY,-tZ);
          rotMat = [1 0        0;
                    0 cos(ang) -sin(ang);
                    0 sin(ang) cos(ang)];
          object = [obj.x;obj.y;obj.z];
          object = rotMat*object;
          obj.x = object(1,:);
          obj.y = object(2,:);
          obj.z = object(3,:);
          obj = translateCoil(obj,tX,tY,tZ);
      end
      function obj = rotateCoilY(obj,ang)
          tX = obj.X;tY = obj.Y;tZ = obj.Z;
          obj = translateCoil(obj,-tX,-tY,-tZ);
          rotMat = [cos(ang)  0 sin(ang);
                    0         1 0;
                    -sin(ang) 0 cos(ang)];
          object = [obj.x;obj.y;obj.z];
          object = rotMat*object;
          obj.x = object(1,:);
          obj.y = object(2,:);
          obj.z = object(3,:);
          obj = translateCoil(obj,tX,tY,tZ);
      end
      function obj = rotateCoilZ(obj,ang)
          tX = obj.X;tY = obj.Y;tZ = obj.Z;
          obj = translateCoil(obj,-tX,-tY,-tZ);
          rotMat = [cos(ang) -sin(ang) 0;
                    sin(ang) cos(ang)  0;
                    0        0         1];
          object = [obj.x;obj.y;obj.z];
          object = rotMat*object;
          obj.x = object(1,:);
          obj.y = object(2,:);
          obj.z = object(3,:);
          obj = translateCoil(obj,tX,tY,tZ);
      end
      function obj = translateCoil(obj,tx,ty,tz)
          obj.x = obj.x+tx;
          obj.y = obj.y+ty;
          obj.z = obj.z+tz;
          obj.X = obj.X + tx;
          obj.Y = obj.Y + ty;
          obj.Z = obj.Z + tz;
      end
      
      function L = evalMutualInductance(obj1, obj2)
        L=inductance_neuman(obj1.x,obj1.y,obj1.z,obj2.x,obj2.y,obj2.z);
      end
   end
end