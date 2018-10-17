%cria um conjunto de bobinas sobre um sistema magmimo e varia a distância
%em relação aos transmissores. Cria pertubações de rotação e translação
%nestas enquanto se movem
clear;

savefile = true;%salvar depois da execução?
plotAnimation = true;%mostrar a animação?
evalMutualCoupling = true;%calcular as interações das bobinas (operação custosa)?
file = 'testENV.mat';%arquivo para onde irão os ambientes
fixedSeed = 0;%-1 para desativar
nthreads = 4;%para o processamento paralelo

maxV = 0;%amplitude das variações de translação
maxR = 0;%amplitude das variações de rotação
dV = 0.05;%velocidade de distanciamento

w = 1e+5;%frequência angular padrão
mi = pi*4e-7;

nFrames = 5;
ntx = 6;%número de transmissores
stx = 0.01;%espaçamento entre os transmissores

%Dimensões das bobinas transmissoras
R2_tx = 0.15;%raio externo
R1_tx = 0.05;%raio interno
N_tx = 25;%número de espiras

%Dimensões das bobinas receptoras
R2_rx = 0.05;%raio externo
R1_rx = 0.025;%raio interno
N_rx = 25;%número de espiras

wire_radius = 0.001;%espessura do fio
pts = 750;%resolução de cada bobina

coilPrototypeRX = SpiralPlanarCoil(R2_rx,R1_rx,N_rx,wire_radius,pts);
coilPrototypeTX = SpiralPlanarCoil(R2_tx,R1_tx,N_tx,wire_radius,pts);

group1.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx,+2*R2_tx+stx,0);
group1.R = -1;group1.C = -1;

group2.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx,0,0);
group2.R = -1;group2.C = -1;

group3.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx,-2*R2_tx-stx,0);
group3.R = -1;group3.C = -1;

group4.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx,+2*R2_tx+stx,0);
group4.R = -1;group4.C = -1;

group5.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx,0,0);
group5.R = -1;group5.C = -1;

group6.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx,-2*R2_tx-stx,0);
group6.R = -1;group6.C = -1;                

group7.coils.obj = translateCoil(coilPrototypeRX,0,2*R2_tx+stx,0.05);
group7.R = -1;group7.C = -1;

group8.coils.obj = translateCoil(coilPrototypeRX,0,0,0.15);
group8.R = -1;group8.C = -1;

group9.coils.obj = translateCoil(coilPrototypeRX,0,-(2*R2_tx+stx),0.05);
group9.R = -1;group9.C = -1;

groupList = [group1;group2;group3;group4;group5;group6;group7;group8;group9];

envPrototype = Environment(groupList,w,mi);

envList = envPrototype;
if fixedSeed ~= -1
    rand('seed',0);
end
for i=2:nFrames
    aux = [];
    for j=ntx+1:length(groupList)
        c = translateCoil(envList(i-1).Coils(j).obj,unifrnd(-maxV,maxV),...
                                unifrnd(-maxV,maxV),unifrnd(-maxV,maxV)+dV);
        group.coils.obj = rotateCoilX(rotateCoilY(c,unifrnd(-maxR,maxR)),unifrnd(-maxR,maxR));
        group.R = -1;group.C = -1;
        aux = [aux group];
    end
    envList = [envList Environment([groupList(1:ntx).' aux],w,mi)];
end

ok = true;
for i=1:length(envList)
    ok = ok && check(envList(i));
end

if(ok)
    if evalMutualCoupling
        %o primeiro é o único que precisa ser completamente calculado
        disp('Starting the first frame');
        envList(1) = evalM(envList(1),-ones(length(envList(1).Coils)));
        
        %não é necessário recalcular a indutância entre as bobinas transmissoras
        %nem nenhuma self-inductance
        M0 = -ones(length(envList(1).Coils));
        M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);
        M0 = M0-diag(diag(M0))+diag(diag(envList(1).M));
        
        %calculado o resto
        disp('Calculating the rest of the frames');
        parfor(i=2:length(envList),nthreads)
            envList(i) = evalM(envList(i),M0);
            disp(['Frame ',num2str(i),' concluded'])
        end
    end

    if savefile
        save(file,'envList');
    end

    if plotAnimation
        plotCoil(coilPrototypeTX);
        figure;
        plotCoil(coilPrototypeRX);
        figure;
        animation(envList,0.05,0.2);
    end
else
    error('Something is wrong with the environments.')
end
