clear all;clc;
w = 2*pi*1000000;%1MHz
u = pi*4e-7;%permeabilidade magnética
P = 20;%potência ativa em W
Qmax = 1.43;%carga máxima em Ah
step = 0.001;%passo de integração (h)
eff = 0.95;%eficiência de conversão

%referência para a inclinação média das curvas de carregamento em função de tempo
coef_ref = [1/2.5;1/3.5;1/4.8;1/8.8];

%carregando os dados de acoplamento do sistema
%data(instância).M(índice relativo à distância).obj -> matriz de acoplamento
load('tunningMagMIMOTrackingData.mat');

%tensão em função da carga
rlLookupTable = LookupTable('magMIMOLinearBattery_data.txt',false);

%hold on;
E = [];%dados de log
minErr = inf;%erro mínimo conhecido até o momento

for d=1:length(data)%instância (design da bobina receptora)
	if(data(d).N_rx>0)%para o controle das instâncias a serem utilizadas
		disp(['Iniciando nova instância: R1_rx=',num2str(data(d).R1_rx),...
			' N_rx=',num2str(data(d).N_rx),...
			' A_rx=',num2str(data(d).A_rx),...
			' B_rx=',num2str(data(d).B_rx)]);
		for Rr = [2,5,10,20,25,30]%resistência do ressonador no receptor
			for Rt = [0.01,0.025,0.05,0.075,0.1,0.25,0.5]%resistência de cada ressonador transmissor
				err = [0,0,0,0];%erro (para cada distância)
				for i=1:4%para cada distância
					%calculando a matriz de impedância
					Z = -(1i)*w*u*data(d).M(i).obj + diag([Rt*ones(6,1);Rr]);
					%vetor de qualidade de canal*Rl
					m_Rl = (1i)*w*u*data(d).M(i).obj(1:6,7);
					%lista com a progressão da carga
					Q = [];
					%lista com a progressão da resistência equivalente do circuito da bateria
					RL = [];
					%lista com a progressão da corrente no anel receptor
					IL = [];
					%carga atual (inicialmente morta)
					q=0;
					%tempo máximo de simulação em horas
					ttl=20;
					while true
						%obtem a resistência equivalente do circuito da bateria (dado o estado atual)
						Rl = getYFromX(rlLookupTable,q/Qmax);
						RL = [RL;Rl];
						%vetor de qualidade de canal
						m  = m_Rl/(Rl+Rr);
						%calculando a corrente do receptor caso seja aplicada uma corrente igual a m
						bl = m.'/(Rl+Rr)*m;
						%normalizando a corrente de transmissão baseada em m mas de forma a não superar
						%a potência P
						It = m*(sqrt(P/real([m;bl]'*Z*[m;bl])));
						%aplicando a nova corrente transmissora e obtendo a corrente de recebimento
						Il = m.'/(Rl+Rr)*It;
						IL = [IL;Il];
						%incrementando a carga
						q = q+eff*abs(Il)*step;
						%limitando a carga a 100%
						if q>=Qmax
							Q = [Q;Qmax];
							break;
						else
							Q = [Q;q];
						end
						%controle de tempo
						ttl = ttl-step;
						if ttl<0
							break;
						end
					end
					%se o loop foi rompido pelo ttl<0, o teste foi muito desastroso para ser
					%considerado
					if ttl<0
						err(i) = inf;
					else
						%calculando o erro em relação ao referencial adotado
						err_parc = (Q.')/Qmax-(coef_ref(i)*linspace(0,step*(length(Q)-1),length(Q)));
						err(i) = mean(err_parc.^2);
					end
					%plot(linspace(0,step*(length(Q)-1),length(Q)),100*Q/Qmax);
					%plot(linspace(0,1/coef_ref(i),2),100*coef_ref(i)*linspace(0,1/coef_ref(i),2),'r');
				end
				%log
				e.Rt = Rt;
				e.Rr = Rr;
				e.err = sum(err);
				e.d = d;
				E = [E,e];
				%verificando o menor valor de erro
				if e.err<minErr
					minErr = e.err;
				end
				disp(['MIN ERR: ', num2str(minErr)]);
			end
		end
	end
end

