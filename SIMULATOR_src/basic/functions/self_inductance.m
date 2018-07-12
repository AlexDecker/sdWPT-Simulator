function L=self_inductance(x,y,r)

hsf=0.01; % high scale factor, dge*hsf is step in rough integration and in current discretization

ff=0.3; % fine tune factor, ff*r ~ step in finetune (along contour and into deep)
df=5*2; % fintune depth factor to deep, df*r=maximal step in finetune to deep (to inside direction)


sif=ff*r; % ~ step in finetune

ned=length(x); % number of edges

% limits:
x1=min(x);
x2=max(x);
x12=x2-x1;
y1=min(y);
y2=max(y);
y12=y2-y1;

dge=max([x12 y12]); % size estimation, biggest size of box-container


xe=[x x(1)];
ye=[y y(1)];


dx=diff(xe);
dy=diff(ye);
dL=sqrt(dx.^2+dy.^2);
dxn=dx./dL;
dyn=dy./dL;
cL=cumsum(dL);
cLend=cL(end); % total length
cLee=[0 cL];



% find vectors bisctis:

dxn0=[dxn(end) dxn(1:end-1)];
dyn0=[dyn(end) dyn(1:end-1)];

% mean vectors:
xm=dxn+dxn0;
ym=dyn+dyn0;
Lm=sqrt(xm.^2+ym.^2);
xmn=xm./Lm;
ymn=ym./Lm;

% bissectris vectors is perpendicular to mean vectors:
xbn0=-ymn;
ybn0=xmn;

% orient bistectiss vectors to inised:
si=dge*1e-3; % step to inside
xt=x+si*xbn0;
yt=y+si*ybn0; % test points
in = inpolygon(xt,yt,x,y);
sg=2*in-1; % bool to sign
xbn=sg.*xbn0;
ybn=sg.*ybn0;

% means of edges:
xme=(xe(1:end-1)+xe(2:end))/2;
yme=(ye(1:end-1)+ye(2:end))/2;


% vectors perpendicular to edges:
xpn0=-dyn;
ypn0=dxn;
xt=xme+si*xpn0;
yt=yme+si*ypn0; % test points
in = inpolygon(xt,yt,x,y);
sg=2*in-1; % bool to sign
xpn=sg.*xpn0;
ypn=sg.*ypn0;


% si=dge*0.1; 
% plot(xe,ye,'r-');
% hold on;
% quiver(xme,yme,si*xpn,si*ypn);
% axis equal;

% dcf distance conversion coefficients
ca2=xbn.*xpn+ybn.*ypn; % cos(alpha/2), where apha angle between to edges
ica2=1./ca2; % 1/cos(alpha/2);

%si=dge*0.02; 
%plot(xe,ye,'r.-');
%hold on;
%xi=x+si*ica2.*xbn;
%yi=y+si*ica2.*ybn;
%plot(xi,yi,'b.-');
%quiver(xme,yme,si*xpn,si*ypn);
%axis equal;



% finetune region points and areas:
%xt=interp1(cLee,xe,t);
%yt=interp1(cLee,ye,t);
%zt=interp1(cLee,ze,t);
dca=r:sif:r+df*r;
ddca=dca(2)-dca(1); % height of trapecia is constant
dca1=dca(1:end-1);
dca2=dca(2:end);
dcam=(dca1+dca2)/2;
Ldca=length(dca);
tnpe=(cLend/sif)*Ldca; % total number of finetune points estimation
tnpe=round(tnpe*2); % with margin
xf=zeros(1,tnpe);
yf=zeros(1,tnpe);
Af=zeros(1,tnpe);
fcc=0; % points count
% points
disp('Parte 1');
for fc=1:ned % for each edge
    fprintf('%d de %d\n',fc,ned);
    % bisctise vectors on end points:
    xbn1=xbn(fc);
    ybn1=ybn(fc);
    ica21=ica2(fc);
    xx1=x(fc);
    yy1=y(fc);
    if fc==ned
        xbn2=xbn(1);
        ybn2=ybn(1);
        ica22=ica2(1);
        xx2=x(1);
        yy2=y(1);
    else
        xbn2=xbn(fc+1);
        ybn2=ybn(fc+1);
        ica22=ica2(fc+1);
        xx2=x(fc+1);
        yy2=y(fc+1);
    end
    
    
    dLt=dL(fc); % edge length
    np=round(dLt/sif); % number of points, np+1 in total, np-1 without limits points
    if np==0
        np=1;
    end
    np1=np+1; % total number of points
    dvf=linspace(0,1,np1);% dividing factors
    dvfc=(dvf(1:end-1)+dvf(2:end))/2; % deviding factors, centers
    for dcc=1:Ldca-1
        dcamt=dcam(dcc); % distance of paralle shift of edge
        
        xt1=xx1+ica21*dcamt*xbn1;
        yt1=yy1+ica21*dcamt*ybn1;
        
        xt2=xx2+ica22*dcamt*xbn2;
        yt2=yy2+ica22*dcamt*ybn2;
        
        dxt=xt2-xt1;
        dyt=yt2-yt1;
        
        xtt=xt1+dvfc*dxt;
        ytt=yt1+dvfc*dyt; % points -centers of areas
        
        xf(fcc+1:fcc+np)=xtt;
        yf(fcc+1:fcc+np)=ytt;
        
        
        
        dca1t=dca1(dcc); % distance of paralle shift of edge
        dca2t=dca2(dcc); % distance of paralle shift of edge
        %xtt=xt1+dvf*dxt;
        %ytt=yt1+dvf*dyt; % edges of areas
        
        
        % from first edge:
        xt1=xx1+ica21*dca1t*xbn1;
        yt1=yy1+ica21*dca1t*ybn1;
        
        xt2=xx2+ica22*dca1t*xbn2;
        yt2=yy2+ica22*dca1t*ybn2;
        
        dxt=xt2-xt1;
        dyt=yt2-yt1;
        e1L=sqrt(dxt^2+dyt^2);
        
        
        % from second edge:
        xt1=xx1+ica21*dca2t*xbn1;
        yt1=yy1+ica21*dca2t*ybn1;
        
        xt2=xx2+ica22*dca2t*xbn2;
        yt2=yy2+ica22*dca2t*ybn2;
        
        dxt=xt2-xt1;
        dyt=yt2-yt1;
        e2L=sqrt(dxt^2+dyt^2);
        
        At=((e1L/np+e2L/np)/2)*ddca;
        Af(fcc+1:fcc+np)=At;
 
        fcc=fcc+np;
        
        
    end
    
end

xf=xf(1:fcc);
yf=yf(1:fcc);
Af=Af(1:fcc);

% plot(xe,ye,'r-');
% hold on;
% plot(xf,yf,'k.');


% rough points:
dcae=dca(end); % need final poligon
fpx=x+dcae*ica2.*xbn;
fpy=y+dcae*ica2.*ybn;
% plot(fpx,fpy,'b-');

rss=hsf*dge; % rough square size
[xr yr]=squares_in_polygon(fpx,fpy,rss);
% plot(xr,yr,'g.');


% integration:
% new parametrization:
%dt=hsf*cLend;
dt=hsf*dge;
nt=round(cLend/dt);
%t=0:dt:cLend;
t=linspace(0,cLend,nt); % closed
xi=interp1(cLee,xe,t);
yi=interp1(cLee,ye,t); % current discretization points




dxi=diff(xi);
dyi=diff(yi);
dLi=sqrt(dxi.^2+dyi.^2);
dxin=dxi./dLi;
%dyin=dyi./dLi;
% mean points:
xim=(xi(1:end-1)+xi(2:end))/2;
yim=(yi(1:end-1)+yi(2:end))/2;


ni=length(dxin);
Hf=zeros(size(xf)); %field from finetune
Hr=zeros(size(xr)); %field from rough
disp('Parte 2');
for cc=1:ni % current pieces counting
    fprintf('%d de %d\n',cc,ni);
    ximt=xim(cc);
    yimt=yim(cc);
    
    dxit=dxi(cc);
    dyit=dyi(cc);
    
    
    %finetune:
    
    % r0-r:
    drx=xf-ximt;
    dry=yf-yimt;
    drL=sqrt(drx.^2+dry.^2);
    
    % cross product:
    cp=dxit*dry-dyit*drx;
    
    % Biot?avart law
    Hf=Hf+cp./(drL.^3); % without 1/(4*pi), without I
    
    
    
    %rough:
    
    % r0-r:
    drx2=xr-ximt;
    dry2=yr-yimt;
    drL2=sqrt(drx2.^2+dry2.^2);
    
    % cross product:
    cp2=dxit*dry2-dyit*drx2;
    
    % Biot?avart law
    Hr=Hr+cp2./(drL2.^3); % without 1/(4*pi), without I
end

% flux is sum with areas
Ff=sum(Hf.*Af); % without 1/(4*pi), without I, without mu

mu0=4*pi*1e-7;

Lf=mu0*Ff/(4*pi);


rss2=rss^2; % area of rough square
Fr=sum(Hr*rss2); % without 1/(4*pi), without I, without mu

Lr=mu0*Fr/(4*pi);


L=Lf+Lr;

%N=length(xf)+length(xr)  % number of points