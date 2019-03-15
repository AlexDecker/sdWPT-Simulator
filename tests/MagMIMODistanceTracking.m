%creates a set of coils over a magmimo transmitting setup and keep a constant
%distance

%-savefile = boolean, save after the execution?
%-plotAnimation = boolean, show the animation of the coils in 3D?
%-evalMutualCoupling = boolean, calculate the interactions between the coils?
%-file = output filename
%-d = distance in meters
%-M0 = preprocessed mutual coupling matrix with no magnetic permeability constant.
%use -1 for certain position to be calculated when evalMutualCoupling==true.

function M = MagMIMODistanceTracking(savefile, plotAnimation, evalMutualCoupling,...
    file,d,M0)
    
    M = [];

    w = 1e+5;%(dummie)
    mi = pi*4e-7;%(dummie)

    %Dimensions (transmitting coils)
    R2_tx = 0.1262;%external radius, in order to the total area to be 0.05m2
    N_tx = 17;%number of turns
    wire_radius_tx = 0.0015875;%wire thickness(m) diam = 1/8''
    R1_tx = R2_tx-4*N_tx*wire_radius_tx;%internal radius
    
    %Dimensions (receiving coils)
    R1_rx = 0.001368;%inner radius, tunned
    N_rx = 21.9649;%number of turns, tunned
    wire_radius_rx = 0.00079375;%wire radius (m) diam = 1/16''
    R2_rx = R1_rx+2*N_rx*wire_radius_rx;%external radius
    A_rx=0.011272;B_rx=0.00068937;%inner rectangle dimensions, tunned

    pts_tx = 750;%resolution of each coils (number of points)
    pts_rx = 750;

    stx = 0.04;%espacing between transmitters (acording with the illustration
    %of the paper. For generating an area of 0.3822m2, it must be 0.0
    
    coilPrototypeRX = QiRXCoil(R1_rx,R2_rx,N_rx,A_rx,B_rx,wire_radius_rx,pts_rx);
    coilPrototypeTX = SpiralPlanarCoil(R2_tx,R1_tx,N_tx,wire_radius_tx,pts_tx);

    group1.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx/2,+2*R2_tx+stx,0);
    group1.R = -1;group1.C = -1;

    group2.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx/2,0,0);
    group2.R = -1;group2.C = -1;

    group3.coils.obj = translateCoil(coilPrototypeTX,-R2_tx-stx/2,-2*R2_tx-stx,0);
    group3.R = -1;group3.C = -1;

    group4.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx/2,+2*R2_tx+stx,0);
    group4.R = -1;group4.C = -1;

    group5.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx/2,0,0);
    group5.R = -1;group5.C = -1;

    group6.coils.obj = translateCoil(coilPrototypeTX,+R2_tx+stx/2,-2*R2_tx-stx,0);
    group6.R = -1;group6.C = -1;                
    
    %function used to describe the path of the receiving coil
    rx_X = -17.7833*d^3+14.1700*d^2-2.9142*d-0.1096;
    
    group7.coils.obj = translateCoil(coilPrototypeRX,rx_X,0,d);
    group7.R = -1;group7.C = -1;

    groupList = [group1;group2;group3;group4;group5;group6;group7];

    envPrototype = Environment(groupList,w,mi);

    envList = [envPrototype,envPrototype];

    ok = true;
    for i=1:length(envList)
        ok = ok && check(envList(i));
    end

    if(ok)
        if evalMutualCoupling
            envList(1) = evalM(envList(1),M0);
            M = envList(1).M;
            envList(2) = evalM(envList(1),M);
        end

        if savefile
            save(file,'envList');
        end

        if plotAnimation
            figure;
            plotCoil(coilPrototypeRX);
            figure;
            plotCoil(coilPrototypeTX);
            figure;
            hold on;

            for i=1:7
                plotCoil(groupList(i).coils.obj);
            end
            z = linspace(0.1,0.4,100);
            rx_X = -17.7833*z.^3+14.1700*z.^2-2.9142*z-0.1096;
            plot3(rx_X,0*z,z,'r-');
            plot3([rx_X(1),rx_X(end)],[0,0],[0.1,0.4],'x');
        end
        disp('Calculations finished');
    else
        error('Something is wrong with the environments.')
    end
end
