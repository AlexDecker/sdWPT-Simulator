%cria um conjunto de bobinas sobre um sistema magmimo e mantem a distância
%constante

%savefile = salvar depois da execução?
%plotAnimation = mostrar a animação?
%evalMutualCoupling = calcular as interações das bobinas? (operação custosa)
%file = arquivo .mat para onde irão os ambientes
%d = distância
%M0 = matriz de indutância pré-processada

function M = MagMIMODistanceTracking(savefile, plotAnimation, evalMutualCoupling,...
	file,d,M0)
	
	M = [];

	w = 1e+5;%frequência angular padrão (dummie)
	mi = pi*4e-7;

	%Dimensões das bobinas transmissoras
	R2_tx = 0.1262;%raio externo, de forma a gerar uma area de 0.05m2
	N_tx = 17;%número de espiras
	wire_radius_tx = 0.0015875;%espessura do fio (m) diam = 1/8''
	R1_tx = R2_tx-4*N_tx*wire_radius_tx;%raio interno
	
	%Dimensões das bobinas receptoras
	R1_rx = 0.001368;%inner radius, tunned
	N_rx = 21.9649;%number of turns, tunned
	wire_radius_rx = 0.00079375;%wire radius (m) diam = 1/16''
	R2_rx = R1_rx+2*N_rx*wire_radius_rx;%external radius
	A_rx=0.011272;B_rx=0.00068937;%inner rectangle dimensions, tunned

	pts_tx = 750;%resolução de cada bobina
	pts_rx = 750;%resolução de cada bobina

	stx = 0.04;%espaçamento entre os transmissores (aproximadamente, de acordo com
	%a ilustração do artigo. Para gerar uma área de 0.3822m2 deve ser 0.0
	
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
	
	%{
	if(d==0.2)
		rx_X = -R2_tx-stx/2-(R2_tx+R1_rx)*(0.4-d)/0.3-3.25*A_rx;
	elseif(d==0.1)
		rx_X = -R2_tx-stx/2-(R2_tx+R1_rx)*(0.4-d)/0.3-0.3*A_rx;
	else
		rx_X = -R2_tx-stx/2-(R2_tx+R1_rx)*(0.4-d)/0.3;
	end
	%}
	
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
