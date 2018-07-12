function L=inductance_neuman(x1,y1,z1,x2,y2,z2)
% mutual inductance of two contours
% conturs are polygones in 3d
% contour 1 vertecies: x1 y1 z1
% contour 2 vertecies: x1 y1 z1
% Neuman formaula was used:
% http://en.wikipedia.org/wiki/Inductance#Mutual_inductance_of_two_wire_loops




hsf=0.002; % high scale factor, dge*hsf is step in current discretization



% limits:
x11=min(x1);
x12=max(x1);
ddx1=x12-x11;

y11=min(y1);
y12=max(y1);
ddy1=y12-y11;

z11=min(z1);
z12=max(z1);
ddz1=z12-z11;



x21=min(x2);
x22=max(x2);
ddx2=x22-x21;

y21=min(y2);
y22=max(y2);
ddy2=y22-y21;

z21=min(z2);
z22=max(z2);
ddz2=z22-z21;




dge1=max([ddx1  ddy1  ddz1]); % maximal size of first contour

dge2=max([ddx2  ddy2  ddz2]); % maximal size of second contour




% discretization of first contour:

xe=[x1 x1(1)];
ye=[y1 y1(1)];
ze=[z1 z1(1)];


dx=diff(xe);
dy=diff(ye);
dz=diff(ze);
dL=sqrt(dx.^2+dy.^2+dz.^2);
dxn=dx./dL;
dyn=dy./dL;
dzn=dz./dL;
cL=cumsum(dL);
cLend=cL(end); % total length
cLee=[0 cL];

dt=hsf*dge1;
nt=round(cLend/dt);
%t=0:dt:cLend;
t=linspace(0,cLend,nt); % closed
xi=interp1(cLee,xe,t);
yi=interp1(cLee,ye,t); % current discretization points
zi=interp1(cLee,ze,t); % current discretization points




dxi=diff(xi);
dyi=diff(yi);
dzi=diff(zi);
dLi=sqrt(dxi.^2+dyi.^2+dzi.^2);
dxin=dxi./dLi;
dyin=dyi./dLi;
dzin=dzi./dLi;
% mean points:
xim=(xi(1:end-1)+xi(2:end))/2;
yim=(yi(1:end-1)+yi(2:end))/2;
zim=(zi(1:end-1)+zi(2:end))/2;



% discretization of second contour:

xe2=[x2 x2(1)];
ye2=[y2 y2(1)];
ze2=[z2 z2(1)];


dx2=diff(xe2);
dy2=diff(ye2);
dz2=diff(ze2);
dL2=sqrt(dx2.^2+dy2.^2+dz2.^2);
dxn2=dx2./dL2;
dyn2=dy2./dL2;
dzn2=dz2./dL2;
cL2=cumsum(dL2);
cLend2=cL2(end); % total length
cLee2=[0 cL2];

dt2=hsf*dge2;
nt2=round(cLend2/dt2);
%t=0:dt:cLend;
t2=linspace(0,cLend2,nt2); % closed
xi2=interp1(cLee2,xe2,t2);
yi2=interp1(cLee2,ye2,t2); % current discretization points
zi2=interp1(cLee2,ze2,t2); % current discretization points




dxi2=diff(xi2);
dyi2=diff(yi2);
dzi2=diff(zi2);
dLi2=sqrt(dxi2.^2+dyi2.^2+dzi2.^2);
dxin2=dxi2./dLi2;
dyin2=dyi2./dLi2;
dzin2=dzi2./dLi2;
% mean points:
xim2=(xi2(1:end-1)+xi2(2:end))/2;
yim2=(yi2(1:end-1)+yi2(2:end))/2;
zim2=(zi2(1:end-1)+zi2(2:end))/2;


I2=zeros(1,length(xim2)); % sumation for integral from curent first's contour piece to all pieces of second contour
for cc=1:length(xim) % current pieces counting in first contour
    
    % curent element of current
    ximt=xim(cc);
    yimt=yim(cc);
    zimt=zim(cc);
    
    dxit=dxi(cc);
    dyit=dyi(cc);
    dzit=dzi(cc);
    
    
    dximt=ximt-xim2;
    dyimt=yimt-yim2;
    dzimt=zimt-zim2;
    
    D=sqrt(dximt.^2+dyimt.^2+dzimt.^2);
    
    
    dp=dxit*dxi2+dyit*dyi2+dzit*dzi2; % dot product
    I2=I2+dp./D;
end

mu0=4*pi*1e-7;
L=(mu0/(4*pi))*abs(sum(I2));