clear all;
rng('shuffle');
err = 1e-6;


verificacao = 100;
maxCoupling = 0.1;

while verificacao>0
    lambda = rand;
    w = 2*pi*(lambda*110000 + (1-lambda)*220000);

    Lr = 3.15e-6;
    Lt = 4.85e-6;
    zt = 0.025 - 1i/(w*4.02e-07);
    
    R0 = 10+rand*10;%resistencia minima do receptor

    v = 1+10*rand;

    maxM = maxCoupling*sqrt(Lr*Lt);
    M = rand(4);
    M = maxM/0.5*(M+M');
    M = M-diag(diag(M))-diag([Lt,Lt,Lr,Lr]);

    Z = [zt*ones(2),zeros(2);zeros(2),R0*ones(2)]-(1i)*w*M;
    zr = 10+30*rand - 1i/(w*(1e-09+1e-05*rand));
    iZc = eye(4)/(Z + [zeros(2),zeros(2);zeros(2),zr*ones(2)]);
    I = iZc*(v*[1;1;0;0]);
    Ir = I(3)+I(4);

    if(sum(abs(v*[1;1;0;0] - (Z+zr*[0;0;1;1]*[0,0,1,1])*I)>err)>0)
        error('eq 1');
    end

    iZ = eye(4)/Z;

    a = [0,0,1,1]*iZ*[0;0;1;1];
    j = v*iZ*[1;1;0;0];
    k = v*iZ*[0;0;1;1]*[0,0,1,1]*iZ*[1;1;0;0];
    c = j(3)+j(4);
    b = -(k(3)+k(4));

    if sum(sum(abs(iZc-(iZ-zr*iZ*[0;0;1;1]*[0,0,1,1]*iZ/(1+zr*a)))))>err
        error('eq 2');
    end

    if sum(abs(I - (j-zr*k/(1+a*zr))))>err
        error('eq 3');
    end

    if abs(Ir-(b*zr/(1+a*zr)+c))>err
        error('eq 4');
    end

    alpha = abs(b/a)^2+2*real(c'*b/a);
    beta = 2*real(c'*b/a);
    gamma = -2*imag(c'*b/a);

    zeta = a*zr;

    x = real(zeta);
    y = imag(zeta);

    if abs(abs(Ir)^2-((alpha*(x^2+y^2)+beta*x+gamma*y)/(x^2+y^2+2*x+1)+abs(c)^2))>err
        error('eq principal');
    end
    
    dx = x+1;
    dy = y;

    if abs(abs(Ir)^2-(alpha+abs(c)^2+((beta-2*alpha)*dx+gamma*dy+alpha-beta)...
        /(dx^2+dy^2)))>err
        error('eq principal 2');
    end

    k = ((beta-2*alpha)*dx+gamma*dy+alpha-beta)/(dx^2+dy^2);

    if abs((dx-(beta-2*alpha)/(2*k))^2+(dy-gamma/(2*k))^2-...
    (((beta-2*alpha)/(2*k))^2+(gamma/(2*k))^2+(alpha-beta)/k))>err
        error('curva de nivel');
    end

    verificacao = verificacao-1;
end

%ultimos parametros
r = 10+10*rand;
d = 3;

%transformacao de coordenadas
dx0 = 1;
dy0 = 0;

%gerando a malha da funcao objetivo
[dx,dy] = meshgrid(dx0-d:0.05:dx0+d,dy0-d:0.05:dy0+d);
z = ((beta-2*alpha)*dx+gamma*dy+alpha-beta)./(dx.^2+dy.^2);

%restricoes
res1 = real(a)*(dx-1)+imag(a)*dy>=0;
res2 = real(a)*dy-imag(a)*(dx-1)<=0;
z = z./(res1.*res2);

%plotando
figure;
set(gcf, 'Position',  [100, 100, 1000, 1000]);
hold on;
surf(dx,dy,z);
xlim([dx0-d,dx0+d]);
ylim([dy0-d,dy0+d]);
view(0,90);
shading interp
title(num2str(a));

%otimizacao


%visualizacao da solucao otimizada
figure;
set(gcf, 'Position',  [100, 100, 1000, 1000]);
hold on;
%semi retas do dominio
if(imag(a)>=0)
    line([dx0,dx0+d],[dy0,imag(a)/real(a)*(dx0+d)]);
else
end
xlim([dx0-d,dx0+d]);
ylim([dy0-d,dy0+d]);
view(0,90);

