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
dV = 0.1;%velocidade de distanciamento

nFrames = 7;
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

shift = 4*R2_tx+4*stx;%distância entre os conjuntos de 6 bobinas tradicionais

coilPrototypeRX = coil(R2_rx,R1_rx,N_rx,wire_radius,pts);
coilPrototypeTX = coil(R2_tx,R1_tx,N_tx,wire_radius,pts);

coilListPrototype = [translateCoil(coilPrototypeTX,-R2_tx-stx,+2*R2_tx+stx,0)%1
                translateCoil(coilPrototypeTX,-R2_tx-stx,0,0)%2
                translateCoil(coilPrototypeTX,-R2_tx-stx,-2*R2_tx-stx,0)%3
                translateCoil(coilPrototypeTX,+R2_tx+stx,+2*R2_tx+stx,0)%4
                translateCoil(coilPrototypeTX,+R2_tx+stx,0,0)%5
                translateCoil(coilPrototypeTX,+R2_tx+stx,-2*R2_tx-stx,0)%6 - até aqui são os transmissores normais
                translateCoil(coilPrototypeRX,0,2*R2_tx+stx,0.05)
                translateCoil(coilPrototypeRX,0,0,0.15)
                translateCoil(coilPrototypeRX,0,-(2*R2_tx+stx),0.05)];
            
envPrototype = Environment(coilListPrototype,1e+5,zeros(1,length(coilListPrototype)),true);

envList = envPrototype;
if fixedSeed ~= -1
    rand('seed',0);
end
for i=2:nFrames
    aux = [];
    for j=ntx+1:length(coilListPrototype)
        c = translateCoil(envList(i-1).Coils(j),unifrnd(-maxV,maxV),...
                                unifrnd(-maxV,maxV),unifrnd(-maxV,maxV)+dV);
        aux = [aux rotateCoilX(rotateCoilY(c,unifrnd(-maxR,maxR)),...
                    unifrnd(-maxR,maxR))];
    end
    envList = [envList Environment([coilListPrototype(1:ntx).' aux],1e+5,zeros(1,length(coilListPrototype)),true)];
end

ok = true;
for i=1:length(envList)
    ok = ok && check(envList(i));
end

if(ok)
    if evalMutualCoupling
        %o primeiro é o único que precisa ser completamente calculado
        disp('Iniciando primeira bobina');
        envList(1) = evalM(envList(1),-ones(length(coilListPrototype)));
        M0 = -ones(length(coilListPrototype));
        M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);
        %calculado o resto
        disp('Iniciando as demais bobinas');
        parfor(i=2:length(envList),nthreads)
            envList(i) = evalM(envList(i),M0);
            disp(['Frame ',num2str(i),' concluido'])
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