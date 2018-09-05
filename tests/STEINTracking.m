%cria um par de bobinas bifilares de um sistema Qi. Modelo de mobilidade
%adotado reflete o esquema de movimentação do artigo do STEIN
clear;

savefile = true;%salvar depois da execução?
plotAnimation = true;%mostrar a animação?
evalMutualCoupling = true;%calcular as interações das bobinas (operação custosa)?

file = 'STEIN_ENV.mat';%arquivo para onde irão os ambientes
fixedSeed = 0;%-1 para desativar
nthreads = 4;%para o processamento paralelo

maxV = 0;%amplitude das variações de translação
maxR = 0;%amplitude das variações de rotação
dV = 0.00278;%velocidade de distanciamento

w = 1e+5;%frequência angular padrão
mi = pi*4e-7;

nFrames = 10;
ntx = 2;%número de transmissores (a bobina do transmissor Qi é bifilar,
%então aqui são consideradas duas boinas independentes sobrepostas)

%Dimensões da bobina transmissora
R2_tx1 = 0.021;%raio externo
R1_tx2 = 0.01;%raio interno
N_tx = 5;%número de espiras
ang_tx = pi/6;%trecho angular de descida da primeira para a segunda camada
wire_radius_tx = 0.0005;%espessura do fio (raio)
pts_tx = 1000;%resolução da bobina
R2_tx2 = R2_tx1-2*wire_radius_tx;%raio externo
R1_tx1 = R1_tx2+2*wire_radius_tx;%raio interno

%Dimensões da bobina receptora
R2_rx1 = 0.0095;%raio externo
R1_rx2 = 0.0015;%raio interno
N_rx = 15;%número de espiras
a_rx2 = 0.015;%dimensão da volta mais interna da bobina
b_rx2 = 0.0075;%dimensão da volta mais interna da bobina
wire_radius_rx = 0.00016;%espessura do fio (raio)
pts_rx = 1000;%resolução da bobina
R2_rx2 = R2_rx1-(R2_rx1-R1_rx2)/(pi*N_rx);%raio externo
R1_rx1 = R1_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%raio interno
a_rx1 = a_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%dimensão da volta mais interna da bobina
b_rx1 = b_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%dimensão da volta mais interna da bobina

L_TX = 6.3e-6;%self-inductance (H)
L_RX = 9.7e-6;%self-inductance (H)

coilPrototype_tx1 = QiTXCoil(R2_tx1,R1_tx1,N_tx,ang_tx,wire_radius_tx,pts_tx);
coilPrototype_tx2 = QiTXCoil(R2_tx2,R1_tx2,N_tx,ang_tx,wire_radius_tx,pts_tx);
coilPrototype_rx1 = QiRXCoil(R1_rx1,R2_rx1,N_rx,a_rx1,b_rx1,...
    wire_radius_rx,pts_rx);
coilPrototype_rx2 = QiRXCoil(R1_rx2,R2_rx2,N_rx,a_rx2,b_rx2,...
    wire_radius_rx,pts_rx);

groupTX.coils = [struct('obj',coilPrototype_tx1);...
    struct('obj',coilPrototype_tx2)];
groupTX.R = -1;groupTX.C = -1;

groupRX.coils = [struct('obj',translateCoil(coilPrototype_rx1,0,0,0.005));...
    struct('obj',translateCoil(coilPrototype_rx2,0,0,0.005))];
groupRX.R = -1;groupRX.C = -1;

groupList = [groupTX;groupRX];
  
envPrototype = Environment(groupList,w,mi);

envList = envPrototype;
if fixedSeed ~= -1
    rand('seed',0);
end
for i=2:nFrames
    c1 = translateCoil(envList(i-1).Coils(ntx+1).obj,unifrnd(-maxV,maxV),...
                            unifrnd(-maxV,maxV),unifrnd(-maxV,maxV)+dV);
    c2 = translateCoil(envList(i-1).Coils(ntx+2).obj,unifrnd(-maxV,maxV),...
                            unifrnd(-maxV,maxV),unifrnd(-maxV,maxV)+dV);
    group.coils = [struct('obj',rotateCoilX(rotateCoilY(...
        c1,unifrnd(-maxR,maxR)),unifrnd(-maxR,maxR)));... 
        struct('obj',rotateCoilX(rotateCoilY(...
        c2,unifrnd(-maxR,maxR)),unifrnd(-maxR,maxR)))];
    group.R = -1;group.C = -1;
    
    envList = [envList Environment([groupList(1);group],w,mi)];
end

ok = true;
for i=1:length(envList)
    ok = ok && check(envList(i));
end

if(ok)
    if evalMutualCoupling
        %o primeiro é o único que precisa ser completamente calculado
        disp('Iniciando o primeiro quadro');
        envList(1) = evalM(envList(1),-ones(length(envList(1).Coils)));
        
        %não é necessário recalcular a indutância entre as bobinas transmissoras
        %nem nenhuma self-inductance
        M0 = -ones(length(envList(1).Coils));
        M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);
        M0 = M0-diag(diag(M0))+diag(diag(envList(1).M));
        
        %calculado o resto
        disp('Iniciando as demais bobinas');
        parfor(i=2:length(envList),nthreads)
            envList(i) = evalM(envList(i),M0);
            disp(['Frame ',num2str(i),' concluido'])
        end
    end
	
	%adequando os valores de auto-indutância aos que já se tem de antemão
	
	mi_tx = L_TX*(envList(1).M(1,1)+envList(1).M(2,2))...
		/(envList(1).M(1,1)*envList(1).M(2,2));
		
	mi_rx = L_RX*(envList(1).M(3,3)+envList(1).M(4,4))...
		/(envList(1).M(3,3)*envList(1).M(4,4));
	
	for i=1:length(envList)
		for j=1:2
			envList(i).Coils(j).obj.mi = mi_tx;
		end
		for j=3:4
			envList(i).Coils(j).obj.mi = mi_rx;
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
        hold on;
        plotCoil(coilPrototype_rx1);
        plotCoil(coilPrototype_rx2);
        figure;
        animation(envList,0.05,0.2);
    end
else
    error('Something is wrong with the environments.')
end
