function [xr yr]=squares_in_polygon(x,y,ss)
% finds squares that all inside polygon with vertecies in x y (square meshing)
% ss - square size
% xr,yr - squares centers

x1=min(x);
x2=max(x);

y1=min(y);
y2=max(y);


ss2=ss/2;

% try this sqyare centers:
xm=x1+ss2:ss:x2-ss2;
ym=y1+ss2:ss:y2-ss2;

[X Y]=meshgrid(xm,ym);
%IN = inpolygon(X,Y,x,y);

X1=X(:)+ss2;
Y1=Y(:)+ss2;
IN1 = inpolygon(X1,Y1,x,y);

X2=X(:)-ss2;
Y2=Y(:)+ss2;
IN2 = inpolygon(X2,Y2,x,y);

X3=X(:)-ss2;
Y3=Y(:)-ss2;
IN3 = inpolygon(X3,Y3,x,y);

X4=X(:)+ss2;
Y4=Y(:)-ss2;
IN4 = inpolygon(X4,Y4,x,y);

IN=IN1&IN2&IN3&IN4;

xr=X(IN);
yr=Y(IN);

