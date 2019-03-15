%(THIS IS AN EXAMPLE FOR THE ONES WHO WANT TO USE THIS SIMULATOR AS A SIMPLE NETWORK SIMULATOR.)
clear all;

savefile = true;%save after executing?
plotAnimation = true;%show the animation of the coils?

file = 'DUMMIE_COIL_ENV.mat';%output file

%DUMMIE-------------------------------------------------------------------------------------------------------------
w = 1e+5;
mi = pi*4e-7;
R = 0.01;
N = 4;
pitch= 0.001;
wire_radius = 0.0004;
pts = 1000; 
%-------------------------------------------------------------------------------------------------------------------

group_list = [];

%defining a network node using the POWER TRANSMITTER (transmitter because it is the first one. This node is defined
%only by using POWERTXAPPICATION)
x = 0;
y = 0;
z = 0;
group.coils.obj = translateCoil(SolenoidCoil(R,N,pitch,...
    wire_radius,pts,mi),x,y,z);
group.R = -1;group.C = -1;
group_list = [group_list;group];

%nodes that can support a POWERRXAPPLICATION:
%defining a node using a POWER RECEIVER
x = 0;
y = 0.25;%positioning in 3D space (meters)
z = 0;
group.coils.obj = translateCoil(SolenoidCoil(R,N,pitch,...
    wire_radius,pts,mi),x,y,z);
group.R = -1;group.C = -1;
group_list = [group_list;group];

%defining other node using a POWER RECEIVER
x = 0.15;
y = 0.25;
z = 1;
group.coils.obj = translateCoil(SolenoidCoil(R,N,pitch,...
    wire_radius,pts,mi),x,y,z);
group.R = -1;group.C = -1;
group_list = [group_list;group];

%defining one more node using a POWER RECEIVER
x = -0.15;
y = 0.5;
z = 1;
group.coils.obj = translateCoil(SolenoidCoil(R,N,pitch,...
    wire_radius,pts,mi),x,y,z);
group.R = -1;group.C = -1;
group_list = [group_list;group];

%------------------------------------------------------------------------------------------------------------------
envPrototype = Environment(group_list,w,mi);

envList = [envPrototype,envPrototype];

ok = check(envPrototype);

if(ok)
    
    envList(1) = evalM(envList(1), zeros(length(group_list)));
    envList(2) = evalM(envList(2), zeros(length(group_list)));

    if savefile
        save(file,'envList');
    end

    if plotAnimation
        animation(envList,0.05,0.2);
    end
else
    error('Something is wrong with the environments.')
end
