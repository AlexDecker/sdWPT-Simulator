%cria um conjunto de bobinas sobre um sistema magmimo e varia a dist�ncia
%em rela��o aos transmissores. Cria pertuba��es de rota��o e transla��o
%nestas enquanto se movem
clear;

savefile = true;%salvar depois da execu��o?
plotAnimation = true;%mostrar a anima��o?
evalMutualCoupling = true;%calcular as intera��es das bobinas (opera��o custosa)?

file = 'STEIN_ENV.mat';%arquivo para onde ir�o os ambientes
fixedSeed = 0;%-1 para desativar
nthreads = 4;%para o processamento paralelo

maxV = 0;%amplitude das varia��es de transla��o
maxR = 0;%amplitude das varia��es de rota��o
dV = 0.00278;%velocidade de distanciamento

nFrames = 10;
ntx = 2;%n�mero de transmissores (a bobina do transmissor Qi � bifilar,
%ent�o aqui s�o consideradas duas boinas independentes sobrepostas)

%Dimens�es da bobina transmissora
R2_tx1 = 0.021;%raio externo
R1_tx2 = 0.01;%raio interno
N_tx = 5;%n�mero de espiras
ang_tx = pi/6;%trecho angular de descida da primeira para a segunda camada
wire_radius_tx = 0.0005;%espessura do fio (raio)
pts_tx = 1000;%resolu��o da bobina
R2_tx2 = R2_tx1-2*wire_radius_tx;%raio externo
R1_tx1 = R1_tx2+2*wire_radius_tx;%raio interno

%Dimens�es da bobina receptora
R2_rx = 0.0095;%raio externo
R1_rx = 0.0015;%raio interno
N_rx = 30;%n�mero de espiras
a_rx = 0.015;%dimens�o da volta mais interna da bobina
b_rx = 0.0075;%dimens�o da volta mais interna da bobina
wire_radius_rx = 0.00016;%espessura do fio (raio)
pts_rx = 1000;%resolu��o da bobina

%L_tx = %self-inductance (H)
%L_rx = %self-inductance (H)

coilPrototype_tx1 = QiTXCoil(R2_tx1,R1_tx1,N_tx,ang_tx,wire_radius_tx,pts_tx);
coilPrototype_tx2 = QiTXCoil(R2_tx2,R1_tx2,N_tx,ang_tx,wire_radius_tx,pts_tx);
coilPrototype_rx = QiRXCoil(R1_rx,R2_rx,N_rx,a_rx,b_rx,wire_radius_rx,pts_rx);

coilListPrototype = [struct('obj',coilPrototype_tx1),struct('obj',coilPrototype_tx2),...
	struct('obj',translateCoil(coilPrototype_rx,0,0,0.005))];

%w = 1e+5 � apenas um valor default. A frequ�ncia � de fato definida a posteriori   
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
    envList = [envList Environment([coilListPrototype(1:ntx), aux],1e+5,-ones(length(coilListPrototype),1),true)];
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
    	hold on;
        plotCoil(coilPrototype_tx1);
        plotCoil(coilPrototype_tx2);
        figure;
        plotCoil(coilPrototype_rx);
        figure;
        animation(envList,0.05,0.2);
    end
else
    error('Something is wrong with the environments.')
end