M = [];

w = 1e+5;%frequência angular padrão (dummie)
mi = pi*4e-7;

%Dimensões das bobinas transmissoras
R2_tx = 0.1262;%raio externo, de forma a gerar uma area de 0.05m2
N_tx = 17;%número de espiras
wire_radius_tx = 0.0015875;%espessura do fio (m) diam = 1/8''
R1_tx = R2_tx-4*N_tx*wire_radius_tx;%raio interno

%Dimensões das bobinas receptoras
R2_rx = 0.04;%raio externo, de forma a gerar uma area de 0.005m2
wire_radius_rx = 0.00079375;%espessura do fio (m) diam = 1/16''

pts = 750;%resolução de cada bobina

stx = 0.04;%espaçamento entre os transmissores (aproximadamente, de acordo com
%a ilustração do artigo. Para gerar uma área de 0.3822m2 deve ser 0.0

coilPrototypeTX = SpiralPlanarCoil(R2_tx,R1_tx,N_tx,wire_radius_tx,pts);

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

groupListTX = [group1;group2;group3;group4;group5;group6];

env = Environment(groupListTX,w,mi);

%calcule a submatriz dos transmissores
env = evalM(env,eye(6)-ones(6,6));

%base de cálculo para a matriz M
M0 = [env.M,-ones(6,1);
	 -ones(1,6), 0];
	 
%distâncias
D = [0.1,0.2,0.3,0.4];

data = [];

disp('Calculando o resto');

for R1_rx = linspace(wire_radius_rx,R2_rx-2*wire_radius_rx,5)
	R1_rx%DISP
	for N_rx = linspace(1,(R2_rx-R1_rx)/(2*wire_radius_rx),5)
		N_rx%DISP
		M = [];
		%cria o novo protótipo de bobina receptora
		coilPrototypeRX = SpiralPlanarCoil(R2_rx,R1_rx,N_rx,wire_radius_rx,pts);
		%cria as bobinas receptoras a partir do protótipo
		Group7 = [];
		for d=1:4
			group7.coils.obj = translateCoil(coilPrototypeRX,0,0,D(d));
			group7.R = -1;group7.C = -1;
			
			Group7 = [Group7,group7];
		end
		parfor d=1:4

			groupList = [groupListTX;Group7(d)];
			env = Environment(groupList,w,mi);
			
			%obtendo a matriz de indutâncias
			env = evalM(env,M0);
			
			%armazenando os novos resultados para essa distância
			M = [M,struct('obj',env.M)];
		end
		newData.M = M;
		newData.R1_rx = R1_rx;
		newData.N_rx = N_rx;
		data = [data,newData];
	end
end

save('tunningMagMIMOTrackingData.mat','data');
