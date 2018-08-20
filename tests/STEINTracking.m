%cria um conjunto de bobinas sobre um sistema magmimo e varia a distância
%em relação aos transmissores. Cria pertubações de rotação e translação
%nestas enquanto se movem
clear;

savefile = false;%salvar depois da execução?
plotAnimation = false;%mostrar a animação?
evalMutualCoupling = true;%calcular as interações das bobinas (operação custosa)?

file = 'STEIN_ENV.mat';%arquivo para onde irão os ambientes
fixedSeed = 0;%-1 para desativar
nthreads = 4;%para o processamento paralelo

maxV = 0;%amplitude das variações de translação
maxR = 0;%amplitude das variações de rotação
dV = 0.05;%velocidade de distanciamento

nFrames = 5;
ntx = 6;%número de transmissores
stx = 0.01;%espaçamento entre os transmissores

%Dimensões da bobina transmissora
R2_tx = 0.15;%raio externo
R1_tx = 0.05;%raio interno
N_tx = 25;%número de espiras
ang_tx = pi/6;%trecho angular de descida da primeira para a segunda camada
wire_radius_tx = 0.001;%espessura do fio (raio)
pts_tx = 750;%resolução da bobina

%Dimensões da bobina receptora
R2_rx = 0.05;%raio externo
R1_rx = 0.025;%raio interno
N_rx = 25;%número de espiras
a_rx = 0.015;%dimensão da volta mais interna da bobina
b_rx = 0.025;%dimensão da volta mais interna da bobina
wire_radius_rx = 0.0005;%espessura do fio (raio)
pts_rx = 750;%resolução da bobina

coilPrototype_tx = QiTXCoil(R2_tx,R1_tx,N_tx,ang_tx,wire_radius_tx,pts_tx);
coilPrototype_rx = QiRXCoil(R1_rx,R2_rx,N_rx,a_rx,b_rx,wire_radius_rx,pts_rx);

coilListPrototype = [coilPrototype_tx,coilPrototype_rx];
            
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
        disp('Iniciando o primeiro quadro');
        envList(1) = evalM(envList(1),-ones(length(coilListPrototype)));
        
        %não é necessário recalcular a indutância entre as bobinas transmissoras
        %nem nenhuma self-inductance
        M0 = -ones(length(coilListPrototype));
        M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);%%AQUI!!!!!!!!!
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
