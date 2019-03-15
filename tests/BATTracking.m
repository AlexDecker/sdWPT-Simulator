clear;

savefile = true;%save the data after the execution?
plotAnimation = true;%show the animation of the coils?
evalMutualCoupling = true;%calculate the interactions between the coils? (costly operation)

file = 'BAT_ENV.mat';%output file

ntx = 1;%number of transmitters
w = 1e+5;%dummie
mi = pi*4e-7;%dummie

%creating dummie coils

R_tx = 0.01;
N_tx = 200;
pitch_tx = 0.001;
wire_radius_tx = 0.0004;
pts_tx = 2;

R_rx = 0.01;
N_rx = 100;
pitch_rx = 0.002;
wire_radius_rx = 0.0004;
pts_rx = 2;

groupTX.coils.obj = SolenoidCoil(R_tx,N_tx,pitch_tx,wire_radius_tx,pts_tx,mi);
groupTX.R = -1;groupTX.C = -1;

groupRX.coils.obj = translateCoil(SolenoidCoil(R_rx,N_rx,pitch_rx,...
    wire_radius_rx,pts_rx,mi),0,0.025,0);
groupRX.R = -1;groupRX.C = -1;

L_tx = N_tx^2*pi*R_tx^2/(pitch_tx*N_tx);%self-inductance without the magnetic permeability
L_rx = N_rx^2*pi*R_rx^2/(pitch_rx*N_rx);
   
envPrototype = Environment([groupTX;groupRX],w,mi);

envList = [envPrototype,envPrototype];

ok = check(envPrototype);

if(ok)
    if evalMutualCoupling
        %maximum coupling
        disp('Iniciando o calculo dos acoplamentos');
        envList(1) = evalM(envList(1),[L_tx,sqrt(L_tx*L_rx);sqrt(L_tx*L_rx),L_rx]);
        
        %second frame is equal to the first
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
