rng('shuffle');
err = 1e-6;


verificacao = 10000;
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
    
    zr1 = 10+30*rand - 1i/(w*(1e-09+1e-05*rand));
    I1 = (Z + [zeros(2),zeros(2);zeros(2),zr1*ones(2)])\[1;1;0;0]*v;

    zr2 = 10+30*rand - 1i/(w*(1e-09+1e-05*rand));
    I2 = (Z + [zeros(2),zeros(2);zeros(2),zr2*ones(2)])\[1;1;0;0]*v;

    %aquisicao de M
    Mt = M(1:2,1:2);
    Mtr = M(1:2,3:4);
    Mr = M(3:4,3:4);
    if sum(abs((R0+zr1)*ones(2)*I1(3:4)-(1i)*w*Mr*I1(3:4)-(1i)*w*Mtr.'*I1(1:2)))>err
        error('aq 1');
    end
    if sum(abs(v*[1;1] - (zt*ones(2)*I1(1:2)-(1i)*w*Mt*I1(1:2)-(1i)*w*Mtr*I1(3:4))))>err
        error('aq 2');
    end
    if sum(abs(v*[1;1] - (-(1i)/w*(zt*ones(2)-(1i)*w*Mt)*(eye(2)/Mtr).'*(R0+zr1-(1i)*w*Mr)*I1(3:4)-...
        (1i)*w*Mtr*I1(3:4))))>err
        error('aq 3');
    end

    Lamb = -(1i)/w*(zt*ones(2)-(1i)*w*Mt);

    lamb1 = ((R0+zr1)*ones(2)-(1i)*w*Mr)*I1(3:4);
    lamb2 = ((R0+zr2)*ones(2)-(1i)*w*Mr)*I2(3:4);

    eps1 = -(1i)*w*I1(3:4);
    eps2 = -(1i)*w*I2(3:4);
    
    if sum(abs(v*[1;1] - (Lamb*(eye(2)/Mtr).'*lamb1+Mtr*eps1)))>err
        error('aq 4');
    end

    if sum(abs(v*[1;1] - (Lamb*(eye(2)/Mtr).'*lamb2+Mtr*eps2)))>err
        error('aq 5');
    end

    a = Mtr(1,1);
    b = Mtr(1,2);
    c = Mtr(2,1);
    d = Mtr(2,2);

    if sum(abs(v*[1;1]-(1/(a*d-b*c)*...
        [Lamb(1,1)*(d*lamb1(1)-c*lamb1(2))+Lamb(1,2)*(-b*lamb1(1)+a*lamb1(2));...
        Lamb(2,1)*(d*lamb1(1)-c*lamb1(2))+Lamb(2,2)*(-b*lamb1(1)+a*lamb1(2))] + ...
        [a*eps1(1)+b*eps1(2);c*eps1(1)+d*eps1(2)])))>err
        error('aq 6');
    end

    if sum(abs(v*[1;1]-(1/(a*d-b*c)*...
        [Lamb(1,1)*(d*lamb2(1)-c*lamb2(2))+Lamb(1,2)*(-b*lamb2(1)+a*lamb2(2));...
        Lamb(2,1)*(d*lamb2(1)-c*lamb2(2))+Lamb(2,2)*(-b*lamb2(1)+a*lamb2(2))] + ...
        [a*eps2(1)+b*eps2(2);c*eps2(1)+d*eps2(2)])))>err
        error('aq 7');
    end

    verificacao = verificacao-1;
end 
