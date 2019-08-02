clear all;
rng('shuffle');
err = 1e-6;

global quit;
quit=false;

figure;
set(gcf, 'Position',  [100, 100, 100, 50]);
H = uicontrol('Style', 'PushButton', ...
                'String', 'Break', ...
                'Callback', 'global quit; quit=true');
while ~quit
    pause(0.01);
    wM = rand;
    zt = rand + (1i)*(rand-0.5);
    zr = rand + (1i)*(rand-0.5);
    Z = [zt, -(1i)*wM; -(1i)*wM, zr];
    V = [5*rand;0];
    I = Z\V;

	disp('AQUISICAO DE M');

	disp('eq 2 reformulada');
	if abs(wM*I(1)+(1i)*zr*I(2))>err
		error('eq2');
	end

	disp('eq 1');
	if abs(V(1)-zt*I(1)+(1i)*I(2)*wM)>err
		error('eq1');
	end

    disp('eq 1 reformulada');
    if(abs(V(1)/zt-I(1)+(1i)*I(2)/zt*wM)>err || ...
        abs(V(1)*wM/zt -I(1)*wM + (1i)*I(2)/zt*wM^2)>err ||...
        abs(wM*I(1) -wM*V(1)/zt - (1i)*I(2)*wM^2/zt)>err)
        error('eq1 reformulada');
    end

	disp('eq 2 igualada a 1');
	V(1)*wM+(1i)*I(2)*wM^2+(1i)*zt*zr*I(2)
	a = (1i)*I(2);
	b = V(1);
	c = (1i)*zt*zr*I(2);
	if abs(a*wM^2+b*wM+c)>err
		error('eq 2 igualada a 1');
	end

	disp('formula');
	wM1=(-b+sqrt(b^2-4*a*c))/(2*a);
	wM2=(-b-sqrt(b^2-4*a*c))/(2*a);
	if(abs(imag(wM1))<abs(imag(wM2)))
		if abs(wM1-wM)>err
			error('formula');
		end
	else
		if abs(wM2-wM)>err
			error('formula');
		end
	end

	disp('OTIMIZACAO');

	disp('ir a partir de V');
	if abs(I(2)-((1i)*V(1))/(zt*zr/wM+wM))>err
		error('otimizacao 1');
	end

	disp('ir conjugado a partir de V');
	if abs(I(2)'-(-(1i)*V(1))/((zt*zr)'/wM+wM))>err
		error('otimizacao 2');
	end

	disp('|ir|2 a partir de V');
	if abs(abs(I(2))^2-((1i)*V(1))/(zt*zr/wM+wM)*(-(1i)*V(1))/((zt*zr)'/wM+wM))>err
		error('otimizacao 3');
	end

	disp('forma retracta de |Ir|2');
	if abs(abs(I(2))^2-V(1)^2/((zt*zr/wM+wM)*((zt*zr)'/wM+wM)))>err
		error('otimizacao 4');
	end

	disp('forma retracta de |Ir|2: parte 2');
	if abs(abs(I(2))^2-V(1)^2/((zt*zr*(zt*zr)'/wM^2+zt*zr+(zt*zr)'+wM^2)))>err
		error('otimizacao 5');
	end

	disp('forma retracta de |Ir|2: parte 3');
	if abs(abs(I(2))^2-V(1)^2/(abs(zt*zr)^2/wM^2+2*real(zt*zr)+wM^2))>err
		error('otimizacao 6');
	end

	a = real(zt*zr);
	b = imag(zt*zr);

	disp('forma retracta de |Ir|2: parte 4');
	if abs(abs(I(2))^2-V(1)^2/((a^2+b^2)/wM^2+2*a+wM^2))>err
		error('otimizacao 7');
	end

	disp('testando a minimalidade da funcao objetivo');
	n = 1000000;
	A = 5*(-wM^2)*[(2*(rand(1,n)<0.5)-1).*rand(1,n),0.2];
	B = 5*(-wM^2)*[(2*(rand(1,n)<0.5)-1).*rand(1,n),0];
	if abs(min((A.^2+B.^2)/wM^2+2*A+wM^2))>err
		error('otimizacao 8');
	end

	disp('testando a conexao entre a,b,zt e zr');
	if abs(real(zr)-(a*real(zt)+b*imag(zt))/abs(zt)^2)>err
		error('otimizacao 9');
	end
	if abs(imag(zr)-(-a*imag(zt)+b*real(zt))/abs(zt)^2)>err
		error('otimizacao 10');
	end

	wL = rand;
    r = rand;

	ind = ((real(zt)*A+imag(zt)*B)>=r*abs(zt)^2)&((real(zt)*B-imag(zt)*A)<=wL*abs(zt)^2);
	dA = A(ind);
	dB = B(ind);

	%encontro das linhas
	ao = -wL*imag(zt) + r*real(zt);
	bo = wL*real(zt) + r*imag(zt);

	%pontos da linha real(zr)=0 mais proximo do minimo global
    m1 = real(zt)/imag(zt);
    m2 = 1;
    m3 = -r*abs(zt)^2/imag(zt);
    x0 = -wM^2;
    y0 = 0;

	ap = (m2*(m2*x0-m1*y0)-m1*m3)/(m1^2+m2^2);
	bp = (m1*(-m2*x0+m1*y0)-m2*m3)/(m1^2+m2^2);

	%solucao otima
	if imag(zt)<=0
        disp('Case1');
        sol_a = ap;
        sol_b = bp;
	else
		if ap < ao
            disp('Case2');
			sol_a = ao;
			sol_b = bo;
		else
            disp('Case3');
			sol_a = ap;
			sol_b = bp;
		end
	end

	%garantindo o ponto otimo na nuvem de pontos
	dA = [dA, sol_a];
	dB = [dB, sol_b];

	[m,ind] = max(V(1)^2./((dA.^2+dB.^2)/wM^2+2*dA+wM^2));

	dist = (dA+wM^2).^2+dB.^2; %distancia euclidiana entre cada ponto no dominio e o maximo global
	[m1,ind1] = min(dist); %distancia minima

	disp('max (global is inf)');
	m
	ind-ind1 %o minimo eh o mais perto do minimo global?
	if(ind~=ind1)
		error('ind');
	end

	if(ind~=length(dA))
       error('formula de otimizacao errada.');
	end

    %testando se a solucao eh realmente viavel
    if (sol_a*real(zt)+sol_b*imag(zt)<r*abs(zt)^2-err) ||...
        (sol_b*real(zt)-sol_a*imag(zt)>wL*abs(zt)^2+err)
        disp('non feasible a,b');
        quit = true;
    end
    zr = (sol_a + (1i)*sol_b)*(zt')/abs(zt)^2;
    if(real(zr)<r-err || imag(zr)>wL+err)
        zr
        disp('non feasible solution');
        quit=true;
    end
end

figure;
hold on;

plot(dA,dB,'ro');
plot(-wM^2,0,'mo');
plot(dA(ind),dB(ind),'g*','MarkerSize',8);%aproximacao da solucao

mx = max(max(abs(dA),abs(dB)));

%linhas que marcam o dominio
plot([-mx,+mx],imag(zt)/real(zt)*[-mx,mx]+wL*abs(zt)^2/real(zt),'k-','linewidth',2);
plot([-mx,+mx],-real(zt)/imag(zt)*[-mx,mx]+r*abs(zt)^2/imag(zt),'c-','linewidth',2);

plot(ao,bo,'bo');

plot(sol_a,sol_b,'go','MarkerSize',10);

ylim(1.5*[-mx,mx]);
xlim(1.5*[-mx,mx]);
line([0,0],1.5*[-mx,mx]);
line(1.5*[-mx,mx],[0,0]);
title(['real(zt): ',num2str(real(zt)),'; imag(zt): ', num2str(imag(zt))]);
