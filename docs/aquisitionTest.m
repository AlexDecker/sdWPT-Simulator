rng('shuffle');
err = 1e-6;


verificacao = 1;
nSamples = 5;
maxCoupling = 0.1;

while verificacao>0
    lambda = rand;
    w = 2*pi*(lambda*110000 + (1-lambda)*220000);

    Lr = 3.15e-6;
    Lt = 4.85e-6;
    zt = 0.025 - 1i/(w*4.02e-07);
    
    R0 = 3+rand*3;%resistencia minima do receptor

    v = 1+10*rand;

    maxM = maxCoupling*sqrt(Lr*Lt);
    M = rand(4);
    M = maxM/0.5*(M+M');
    M = M-diag(diag(M))-diag([Lt,Lt,Lr,Lr]);

    Mt = M(1:2,1:2);
    Mr = M(3:4,3:4);
    Mtr = w*M(1:2,3:4);

    m = [1;Mtr(:,1);Mtr(:,2)];
    a = m(2);b = m(3);c = m(4);d = m(5);
    x = [a+b+c+d;
        a^2+b^2+a*c+b*d;
        2*a*b+a*d+b*c;
        c^2+d^2+a*c+b*d;
        2*c*d+a*d+b*c];

    Z = [zt*ones(2),zeros(2);zeros(2),R0*ones(2)]-(1i)*w*M;

    janela = zeros(0,5);
    imagens = [];
    n = 0;
    
    for sample=1:nSamples
        zr = 50*rand - 1i/(w*(1e-09+1e-05*rand));
        I = (Z + [zeros(2),zeros(2);zeros(2),zr*ones(2)])\[1;1;0;0]*v;

        %aquisicao de M
        if sum(abs((R0+zr)*ones(2)*I(3:4)-(1i)*w*Mr*I(3:4)-(1i)*Mtr.'*I(1:2)))>err
            error('aq 1');
        end
        if sum(abs(v*[1;1] - (zt*ones(2)*I(1:2)-(1i)*w*Mt*I(1:2)-(1i)*Mtr*I(3:4))))>err
            error('aq 2');
        end
        if sum(abs(v*[1;1] - (-(1i)*(zt*ones(2)-(1i)*w*Mt)*(eye(2)/Mtr).'*(R0+zr-(1i)*w*Mr)*I(3:4)-...
            (1i)*Mtr*I(3:4))))>err
            error('aq 3');
        end

        Lamb = -(1i)*(zt*ones(2)-(1i)*w*Mt);

        lamb = ((R0+zr)*ones(2)-(1i)*w*Mr)*I(3:4);
        
        disp('new data'); 
        (-(1i)*w*Mr)*I(3:4)
        ((R0+zr)*ones(2))*I(3:4)

        eps = -(1i)*I(3:4);
        
        if sum(abs(v*[1;1] - (Lamb*(eye(2)/Mtr).'*lamb+Mtr*eps)))>err
            error('aq 4');
        end
        
        iLamb = eye(2)/Lamb;

        if sum(abs(Mtr.'*iLamb*Mtr*eps-v*Mtr.'*iLamb*[1;1]+lamb))>err
            error('aq 5');
        end
        
        A = [lamb(1),          -0.5*v*[1,1]*iLamb.',   [0, 0];
             -0.5*v*iLamb*[1;1],eps(1)*iLamb,          0.5*eps(2)*iLamb;
             [0;0],             0.5*eps(2)*iLamb.',    zeros(2)];
        
        B = [lamb(2),           [0,0],               -0.5*v*[1,1]*iLamb.';
             [0;0],              zeros(2),            0.5*eps(1)*iLamb.';
             -0.5*v*iLamb*[1;1], 0.5*eps(1)*iLamb,   eps(2)*iLamb];

        if abs(m.'*A*m)>err
            error('aq 6');
        end

        if abs(m.'*B*m)>err
            error('aq 7');
        end

        Real = real(A);
        Imag = imag(B);

        Real = Real/norm(Real);
        Imag = Imag/norm(Imag);

        alpha = iLamb(1,1);
        beta = iLamb(2,1);
        
        if sum(abs(sum(lamb)-v*iLamb*[1;1]*(a+b+c+d)+...
            eps(1)*alpha*(a^2+b^2)+2*eps(1)*beta*a*b+eps(2)*alpha*(c^2+d^2)+...
            2*eps(2)*beta*c*d+sum(eps)*alpha*(a*c+b*d)+sum(eps)*beta*(a*d+b*c)))>err
            error('aq 8');
        end

        if sum(abs(sum(lamb)-mean(v*iLamb*[1;1])*(a+b+c+d)+...
            eps(1)*alpha*(a^2+b^2+a*c+b*d)+...
            eps(1)*beta*(2*a*b+a*d+b*c)+...
            eps(2)*alpha*(c^2+d^2+a*c+b*d)+...
            eps(2)*beta*(2*c*d+a*d+b*c)))>err
            error('aq 9');
        end

        line = [-mean(v*iLamb*[1;1]),eps(1)*alpha,eps(1)*beta,eps(2)*alpha,eps(2)*beta];

        if abs(real(line)*x+real(sum(lamb)))>err
            error('aq 10');
        end
        
        if abs(imag(line)*x+imag(sum(lamb)))>err
            error('aq 11');
        end

        janela = [janela;real(line)];
        janela = [janela;imag(line)];
        
        imagens = [imagens;-real(sum(lamb))];
        imagens = [imagens;-imag(sum(lamb))];
    end

    verificacao = verificacao-1;
end 
