%Creates a pair of bifilar coils from the Qi specification. The adopted mobility
%model corresponds to the one adopted in STEIN paper (see the reference in our paper)

%savefile (bool) save the data?
%plotAnimation (bool) show the 3D animation?
%evalMutualCoupling (bool) calculate the coupling values (costly operation)?
%file (str) output filename
%maxV (m) amplitude for the translation variations
%maxR (rad) amplitude for the rotation variations

function STEINTracking(savefile,plotAnimation,evalMutualCoupling,file,nFrames,maxV,maxR)

    disp('Reminding: Please be sure that the workspace is clean (use clear all)');

    fixedSeed = -1;%-1 = disable
    nthreads = 4;%parallel processing

    dV = 0.00278;%distancing (meters per frame)

    w = 1e+5;%dummie
    mi = pi*4e-7;

    ntx = 2;%number of transmitters (the transmitter coil is bifilar, so here we
    %consider it as two overlapped coils)

    %Dimensions (transmitting coil)
    R2_tx1 = 0.021;%external radius
    R1_tx2 = 0.01;%internal radius
    N_tx = 5;%number of turns
    ang_tx = pi/6;%angular range of the last turn used for the transition between the
    %two layers
    wire_radius_tx = 0.0005;%wire thickness (radius)
    pts_tx = 1000;%number of points
    R2_tx2 = R2_tx1-2*wire_radius_tx;%external radius
    R1_tx1 = R1_tx2+2*wire_radius_tx;%internal radius

    %Dimensions (receiving coil)
    R2_rx1 = 0.0095;%external radius
    R1_rx2 = 0.0015;%internal radius
    N_rx = 15;%number of turns
    a_rx2 = 0.015;%biggest dimension of the most internal turn
    b_rx2 = 0.0075;%smallest dimension of the most internal turn
    wire_radius_rx = 0.00016;%wire thickness (radius)
    pts_rx = 1000;%number of points
    R2_rx2 = R2_rx1-(R2_rx1-R1_rx2)/(pi*N_rx);%internal radius
    R1_rx1 = R1_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%internal radius
    a_rx1 = a_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%dimension of the most internal turn
    b_rx1 = b_rx2+(R2_rx1-R1_rx2)/(pi*N_rx);%dimension of the most internal turn

    L_TX = 6.3e-6;%self-inductance (H, from coil datasheet)
    L_RX = 9.7e-6;%self-inductance (H, from coil datasheet)

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
        dtx = 2*rand*maxV-maxV;
        dty = 2*rand*maxV-maxV;
        dtz = 2*rand*maxV-maxV+dV;
        
        drx = 2*rand*maxR-maxR;
        dry = 2*rand*maxR-maxR;
        
        c1 = translateCoil(envList(i-1).Coils(ntx+1).obj,dtx,dty,dtz);
        c2 = translateCoil(envList(i-1).Coils(ntx+2).obj,dtx,dty,dtz);
        group.coils = [struct('obj',rotateCoilX(rotateCoilY(c1,dry),drx));... 
            struct('obj',rotateCoilX(rotateCoilY(c2,dry),drx))];
        group.R = -1;group.C = -1;
        
        envList = [envList Environment([groupList(1);group],w,mi)];
    end

    ok = true;
    for i=1:length(envList)
        ok = ok && check(envList(i));
    end

    if(ok)
        if evalMutualCoupling
            %the first frame is the only one that must be calculated
            disp('Starting the first frame');
            envList(1) = evalM(envList(1),-ones(length(envList(1).Coils)));
            
            %it is not necessary to recalculate the mutual induction between the
            %transmitting coils. Neither the self-inductances
            M0 = -ones(length(envList(1).Coils));
            M0(1:ntx,1:ntx) = envList(1).M(1:ntx,1:ntx);
            M0 = M0-diag(diag(M0))+diag(diag(envList(1).M));
            
            disp('Starting the other frames');
            parfor(i=2:length(envList),nthreads)
                envList(i) = evalM(envList(i),M0);
                disp(['Frame ',num2str(i),' concluded'])
            end
            
            %calculating the magnetic permeability values used to match with the
            %self-inductance values from the datasheet
            mi_tx = L_TX*(envList(1).M(1,1)+envList(1).M(2,2))...
                /(envList(1).M(1,1)*envList(1).M(2,2));
        
            mi_rx = L_RX*(envList(1).M(3,3)+envList(1).M(4,4))...
                /(envList(1).M(3,3)*envList(1).M(4,4));
        else
            mi_tx = mi;
            mi_rx = mi;
        end
    
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
            figure;
            hold on;
            plotCoil(coilPrototype_tx1);
            plotCoil(coilPrototype_tx2);
            figure;
            hold on;
            plotCoil(coilPrototype_rx1);
            plotCoil(coilPrototype_rx2);
            figure;
            animation(envList,0.1,0.2);
        end
    else
        error('Something is wrong with the environments.')
    end
end
