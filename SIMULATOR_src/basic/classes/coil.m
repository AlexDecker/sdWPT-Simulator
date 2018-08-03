classdef coil
    properties(SetAccess = private, GetAccess = public)
        x %list of values for x coordinate
        y %list of values for y coordinate
        z %list of values for z coordinate
        r %ratio of the wire (meters)
        %coordinates of coil's center
        X
        Y
        Z
    end
    methods
        %creates a coil
        function obj = coil(x,y,z,wire_radius)
            obj.x = x;
            obj.y = y;
            obj.z = z;
            obj.r = wire_radius;
            obj.X = 0;obj.Y = 0;obj.Z = 0;
        end
        
        function r = check(obj)
            r = (length(obj.x)>=2) && (length(obj.y)==length(obj.x)) &&...
                (length(obj.z)==length(obj.x)) && (length(obj.r)==1) &&...
                (obj.r>0) && (length(obj.X)==1) && (length(obj.Y)==1) &&...
                (length(obj.Z)==1);
        end
        
        function plotCoil(obj)
            plot3(obj.x, obj.y, obj.z);
        end
        
        function obj = rotateCoilX(obj,ang)
            tX = obj.X;tY = obj.Y;tZ = obj.Z;
            obj = translateCoil(obj,-tX,-tY,-tZ);
            rotMat = [1 0 0;
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
        
        %evaluate the mutual inductance between two coils
        function L = evalMutualInductance(obj1, obj2)
            L=inductance_neuman(obj1.x,obj1.y,obj1.z,obj2.x,obj2.y,obj2.z,...
                max(obj1.r,obj2.r));
        end
        
    end
end