%cria um conjunto de bobinas sobre um sistema magmimo e varia a dist�ncia
%em rela��o aos transmissores. Cria pertuba��es de rota��o e transla��o
%nestas enquanto se movem
clear;

savefile = true;%salvar depois da execu��o?
plotAnimation = true;%mostrar a anima��o?
evalMutualCoupling = true;%calcular as intera��es das bobinas (opera��o custosa)?
file = 'testENV.mat';%arquivo para onde ir�o os ambientes
fixedSeed = 0;%-1 para desativar
nthreads = 4;%para o processamento paralelo

maxV = 0;%amplitude das varia��es de transla��o
maxR = 0;%amplitude das varia��es de rota��o
dV = 0.05;%velocidade de distanciamento

nFrames = 5;
ntx = 6;%n�mero de transmissores
stx = 0.01;%espa�amento entre os transmissores

%Dimens�es das bobinas transmissoras
R2_tx = 0.15;%raio externo
R1_tx = 0.05;%raio interno
N_tx = 25;%n�mero de espiras

%Dimens�es das bobinas receptoras
R2_rx = 0.05;%raio externo
R1_rx = 0.025;%raio interno
N_rx = 25;%n�mero de espiras

wire_radius = 0.001;%espessura do fio
pts = 750;%resolu��o de cada bobina

shift = 4*R2_tx+4*stx;%dist�ncia entre os conjuntos de 6 bobinas tradicionais

coilPrototypeRX = SpiralPlanarCoil(R2_rx,R1_rx,N_rx,wire_radius,pts);
coilPrototypeTX = SpiralPlanarCoil(R2_tx,R1_tx,N_tx,wire_radius,pts);

coilListPrototype = [struct('obj',translateCoil(coilPrototypeTX,-R2_tx-stx,+2*R2_tx+stx,0))%1
                struct('obj',translateCoil(coilPrototypeTX,-R2_tx-stx,0,0))%2
                struct('obj',translateCoil(coilPrototypeTX,-R2_tx-stx,-2*R2_tx-stx,0))%3
                struct('obj',translateCoil(coilPrototypeTX,+R2_tx+stx,+2*R2_tx+stx,0))%4
                struct('obj',translateCoil(coilPrototypeTX,+R2_tx+stx,0,0))%5
                struct('obj',translateCoil(coilPrototypeTX,+R2_tx+stx,-2*R2_tx-stx,0))%6 - at� aqui s�o os transmissores normais
                struct('obj',translateCoil(coilPrototypeRX,0,2*R2_tx+stx,0.05))
                struct('obj',translateCoil(coilPrototypeRX,0,0,0.15))
                struct('obj',translateCoil(coilPrototypeRX,0,-(2*R2_tx+stx),0.05))];
            
envPrototype = Environment(coilListPrototype,1e+5,-ones(length(coilListPrototype),1),true);

envList = envPrototype;
if fixedSeed ~= -1
    rand('seed',0);
end
for i=2:nFrames
    aux = [];
    for j=ntx+1:length(coilListPrototype)
        c = translateCoil(envList(i-1).Coils(j).obj,unifrnd(-maxV,maxV),...
                                unifrnd(-maxV,maxV),unifrnd(-maxV,maxV)+dV);
        aux = [aux struct('obj',rotateCoilX(rotateCoilY(c,unifrnd(-maxR,maxR)),...
                    unifrnd(-maxR,maxR)))];
    end
    envList = [envList Environment([coilListPrototype(1:ntx).' aux],1e+5,-ones(length(coilListPrototype),1),true)];
end

ok = true;
for i=1:length(envList)
    ok = ok && check(envList(i));
end

if(ok)
    if evalMutualCoupling
        %o primeiro � o �nico que precisa ser completamente calculado
        disp('Iniciando o primeiro quadro');
        envList(1) = evalM(envList(1),-ones(length(coilListPrototype)));
        
        %n�o � necess�rio recalcular a indut�ncia entre as bobinas transmissoras
        %nem nenhuma self-inductance
        M0 = -ones(length(coilListPrototype));
        M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);
        M0 = M0-diag(diag(M0))+diag(diag(envList(1).M));
        
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
