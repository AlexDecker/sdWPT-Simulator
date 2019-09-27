rng('shuffle');
err = 1e-7;


verificacao = 50;

while verificacao>0
	if(rand>0.5)
		lambda = rand;
		w = 2*pi*(lambda*110000 + (1-lambda)*220000);
	else
		w = 2*pi*4000;
	end

    Mt = [-1.3235,   0.3539;
          0.3539,   -1.2023]*1.0e-05;
    Mr = [-1.9735,   0.6892;
           0.6892,  -1.9076]*1.0e-05;
    zt = 0.015 - 1i/(w*4e-07);
    
    R0 = 3.97;%resistencia minima do receptor

    v = 5;

    Mtr = rand(2);
    maxM = sqrt(mean(mean(Mt))*mean(mean(Mr)));
    Mtr = (0.33-0.1)*maxM*Mtr+0.1*maxM;
    M = [Mt, Mtr;
        Mtr', Mr];

    Z = [zt*ones(2),zeros(2);zeros(2),R0*ones(2)]-(1i)*w*M;
    zr = R0+30*rand - 1i/(w*(1e-09+1e-05*rand));
    iZc = eye(4)/(Z + [zeros(2),zeros(2);zeros(2),zr*ones(2)]);
    I = iZc*(v*[1;1;0;0]);
    Ir = I(3)+I(4);

    if(sum(abs(v*[1;1;0;0] - (Z+zr*[0;0;1;1]*[0,0,1,1])*I)>err)>0)
        error('eq 1');
    end

    %landscape

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
    

    %ultimos parametros
    d = 3;

    %encontro das retas da fronteira
    dx0 = 1;
    dy0 = 0;

    %gerando a malha da funcao objetivo
    [dx,dy] = meshgrid(dx0-d:0.05:dx0+d,dy0-d:0.05:dy0+d);
    z = ((beta-2*alpha)*dx+gamma*dy+alpha-beta)./(dx.^2+dy.^2);
	for i = 1:length(dx.')
		for j = 1:length(dy)
			x = dx(i,j);
			y = dy(i,j);
			x1 = (beta-2*alpha)/(2*z(i,j));
			y1 = gamma/(2*z(i,j));
			d2 = ((beta-2*alpha)^2+gamma^2)/(4*z(i,j)^2)+abs(b/a)^2/z(i,j);
			if d2<-err*abs(d2)
				error('Distancia invalida');
			end
			if abs((x-x1)^2+(y-y1)^2-d2)>err*abs(d2)
                error('Distancia invalida 2');
            end
		end
	end

    %restricoes
    res1 = real(a)*(dx-1)+imag(a)*dy>=0;
    res2 = real(a)*dy-imag(a)*(dx-1)<=0;
    z = z./(res1.*res2);

    %verificando as restricoes
    res_test = ((dx-1)*real(a)+dy*imag(a))/abs(a)^2;
    reac_test = (-(dx-1)*imag(a)+dy*real(a))/abs(a)^2;
    if (res_test>=0)~=res1
        error('restricao de resistencia');
    end
    if (reac_test<=0)~=res2
        error('restricao de reatancia');
    end

    %otimizacao

    %otimo aproximado
    [m,I] = max(z.*res1.*res2);
    [m,j] = max(m);
    
    %pontos criticos sobre as retas do dominio
    [dx_r,dy_r,z_r] = criticalOnLine(alpha,beta,gamma,a,-real(a)/imag(a),err);
    [dx_i,dy_i,z_i] = criticalOnLine(alpha,beta,gamma,a,imag(a)/real(a),err);
    
    %pontos criticos que de fato estao no dominio
    %cruzamento das retas
    DX = dx0;
    DY = dy0;
    Z  = ((beta-2*alpha)*dx0+gamma*dy0+alpha-beta)/(dx0^2+dy0^2);
    %reta real=0
    if(imag(a)>=0)
        for i=1:length(dx_r)
            if(dx_r(i)>=dx0)
                DX = [DX, dx_r(i)];
                DY = [DY, dy_r(i)];
                Z  = [Z, z_r(i)];
            end
        end
    else
        for i=1:length(dx_r)
            if(dx_r(i)<=dx0)
                DX = [DX, dx_r(i)];
                DY = [DY, dy_r(i)];
                Z  = [Z, z_r(i)];
            end
        end   
    end
    %reta imag=0
    if(real(a)>=0)
        for i=1:length(dx_i)
            if(dx_i(i)>=dx0)
                DX = [DX, dx_i(i)];
                DY = [DY, dy_i(i)];
                Z  = [Z, z_i(i)];
            end
        end
    else
        for i=1:length(dx_i)
            if(dx_i(i)<=dx0)
                DX = [DX, dx_i(i)];
                DY = [DY, dy_i(i)];
                Z  = [Z, z_i(i)];
            end
        end   
    end

    %verificando se o maximo analitico eh melhor que o amostrado
    [M,ind] = max(Z);
    if M<m
        disp('O maximo nao foi obtido');
        break;
    else
        disp('Maximo obtido com sucesso');
    end

    verificacao = verificacao-1;
end

%plotando a landscape
figure;
set(gcf, 'Position',  [100, 100, 500, 500]);
hold on;
surf(dx,dy,z);
xlim([dx0-d,dx0+d]);
ylim([dy0-d,dy0+d]);
view(0,90);
shading interp
title(num2str(a));

%visualizacao da solucao otimizada
figure;
set(gcf, 'Position',  [100, 100, 500, 500]);
hold on;
%semi retas do dominio
if(imag(a)>=0)
    plot([dx0,dx0+d],[dy0,-real(a)/imag(a)*(dx0+d-1)]);
else
    plot([dx0-d,dx0],[-real(a)/imag(a)*(dx0-d-1),dy0]);
end
if(real(a)>=0)
    plot([dx0,dx0+d],[dy0,imag(a)/real(a)*(dx0+d-1)],'b-');
else
    plot([dx0-d,dx0],[imag(a)/real(a)*(dx0-d-1),dy0],'b-');
end
plot([dx0-d,dx0+d],gamma/(beta-2*alpha)*[dx0-d,dx0+d],'r-');

xlim([dx0-d,dx0+d]);
ylim([dy0-d,dy0+d]);
view(0,90);

plot(DX,DY,'bo');
plot(DX(ind),DY(ind),'r*','markersize',18);
plot(dx(I(j),j),dy(I(j),j),'b*','markersize',18);
