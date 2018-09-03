clear;

savefile = true;%salvar depois da execução?
plotAnimation = true;%mostrar a animação?
evalMutualCoupling = true;%calcular as interações das bobinas? (operação custosa)

file = 'BAT_ENV.mat';%arquivo para onde irão os ambientes

ntx = 1;%número de transmissores
w = 1e+5;%frequência angular padrão
mi = pi*4e-7;

%Criação de bobinas dummie

%Dimensões da bobina transmissora
R_tx = 0.01;%raio
N_tx = 200;%número de espiras
pitch_tx = 0.001;%espaçamento entre as espiras
wire_radius_tx = 0.0004;%espessura do fio (raio)
pts_tx = 2; %resolução do caminho

%Dimensões da bobina receptora
R_rx = 0.01;%raio
N_rx = 100;%número de espiras
pitch_rx = 0.002;%espaçamento entre as espiras
wire_radius_rx = 0.0004;%espessura do fio (raio)
pts_rx = 2; %resolução do caminho

groupTX.coils.obj = SolenoidCoil(R_tx,N_tx,pitch_tx,wire_radius_tx,pts_tx,mi);
groupTX.R = -1;groupTX.C = -1;

groupRX.coils.obj = translateCoil(SolenoidCoil(R_rx,N_rx,pitch_rx,...
    wire_radius_rx,pts_rx,mi),0,0.025,0);
groupRX.R = -1;groupRX.C = -1;

L_tx = N_tx^2*pi*R_tx^2/(pitch_tx*N_tx);%indutância própria sem a constante de permissividade magnética
L_rx = N_rx^2*pi*R_rx^2/(pitch_rx*N_rx);%indutância própria sem a constante de permissividade magnética

%w = 1e+5 é apenas um valor default. A frequência é de fato definida a posteriori   
envPrototype = Environment([groupTX;groupRX],w,mi);

envList = [envPrototype,envPrototype];

ok = check(envPrototype);

if(ok)
    if evalMutualCoupling
        %é considerado acoplamento máximo
        disp('Iniciando o calculo dos acoplamentos');
        envList(1) = evalM(envList(1),[L_tx,sqrt(L_tx*L_rx);sqrt(L_tx*L_rx),L_rx]);
        
        %não é necessário calcular para o segundo quadro (pois é igual ao primeiro)
        envList(2) = evalM(envList(2),envList(1).M);
        disp('Concluido');  
    end

    if savefile
        save(file,'envList');
    end

    if plotAnimation
        animation(envList,0.05,0.2);
    end
else
    error('Something is wrong with the environments.')
end
