%Aplicação de acordo com o protocolo Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
    properties
        
        dt%variação de tempo do timer
        V%tensão de transmissão
        imax%corrente maxima aceitavel pelo receptor
        pmax%potencia ativa maxima da fonte
        dw%variacao de frequencia operacional angular para o ajuste
        w%frequancia operacional angular atual
        
        %state:
        %0 - busca desligado (ao entrar nesse estado, desliga o transmissor e liga o timer. No final do timer, vai
        %para 1)
        %1 - busca ligado (ao entrar nesse estado, liga o transmissor e envia um ping via SWIPT broadcast)
        %e liga o timer. se não receber uma resposta até o timer terminar, vai para 0. Se receber, vai para 2)
        %2 - Transmitindo (liga o timer a cada dt, incrementa okUntil em dt a cada mensagem recebida e se globalTime
        %ultrapassar okUntil, vai para o estado 0).
        state
        
        %marca o momento em que o sistema irá para o estado 0 caso não receba outra mensagem pedindo a continuidade
        %da transmissão
        okUntil
        
        %imax-i da última rodada
        lastVar
        
        %indica o sentido da variação da frequência operacional na ultima rodada (-1,1)
        ddw
    end
    methods
        function obj = powerTXApplication_Qi(dt,V,pmax,dw)
            obj@powerTXApplication();%construindo a estrutura referente à superclasse
            
            obj.okUntil = 0;%dummie
            obj.state = -1;%dummie
            obj.dt = dt;
            obj.V = V;
            
            obj.imax = 1.2;%default (A)
            obj.pmax = pmax;
            obj.dw = dw;
            obj.w = 2*pi*4000;%4kHz
            
            obj.lastVar = 0;
            obj.ddw = 1;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	%SWIPT, 2048bps (segundo o datasheet do CI), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
            
            %se inicia no estado zero
            [obj,WPTManager] = goToStateZero(obj,WPTManager,0);
            
            %log will receive w data
            obj.APPLICATION_LOG.DATA = zeros(2,0);
            
        	netManager = setTimer(obj,netManager,0,obj.dt);%dispara o timer
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        	switch(obj.state)
        		case 1
        			if length(data)==2
		    			%alguém respondeu o ping. Inicie a transmissão propriamente dita
		    			obj.imax = data(2);
		    			[obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime);
		    			disp('Connection established');
		    		end
        		case 2
        			obj.okUntil = GlobalTime+obj.dt; %renova o atestado por mais um ciclo
        			
        			[It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);
        			pot = real([sum(It);data(1)]'*[obj.V;0]);%calcula a potencia ativa
        			
        			%ajusta a frequência operacional
                    %(como a frequencia ressonante eh proxima de 100 KHz, quanto maior a frequencia, menor
                    %a potencia recebida)
					
					ddw = 0;
					variation = obj.imax-abs(data(1));
					
    				if (variation<0)||(pot>=obj.pmax) %reduza a potência transferida
    					if obj.lastVar>0 %se passou pelo ótimo
    						ddw = -obj.ddw;%volte
    					else
    						if obj.lastVar<0
    							if abs(obj.lastVar)>abs(variation) %se a aproximacao melhorou
    								ddw = obj.ddw;%prossiga
    							else
    								ddw = obj.ddw;%va pelo outro lado
    							end
    						else %se nao ha informacao
    							ddw = 1;%comece de alguma direcao
    						end
    					end
    				else
    					if (variation>0) %aumente a potência transferida
							if obj.lastVar<0 %se passou pelo ótimo
								ddw = -obj.ddw;%volte
							else
								if obj.lastVar>0
									if abs(obj.lastVar)>abs(variation) %se a aproximacao melhorou
										ddw = obj.ddw;%prossiga
									else
										ddw = obj.ddw;%va pelo outro lado
									end
								else %se nao ha informacao
									ddw = 1;%comece de alguma direcao
								end
							end
    					end
    				end
    				
    				if (obj.w+ddw*obj.dw>=2*pi*110000) && (obj.w+ddw*obj.dw<=2*pi*205000)
		    			WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,obj.w+ddw*obj.dw);
		            	obj.w = obj.w+ddw*obj.dw;
                	end
                	
                	obj.lastVar = variation;
                	obj.ddw = ddw;
                	
                    logW = [obj.w/(2*pi);GlobalTime];
                    obj.APPLICATION_LOG.DATA = [obj.APPLICATION_LOG.DATA,logW];
        	end
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
        	switch(obj.state)
        		case 0
        			%alternando entre estados 0 e 1
        			[obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime);
        			%chamada para o próximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        		case 1
	        		%alternando entre estados 0 e 1
        			[obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime);
        			%chamada para o próximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        		case 2
        			%está transmitindo, mas a mensagem de continuidade de transmissãqo não chegou a tempo
        			if(obj.okUntil<=GlobalTime)
        				%desligue a transmissão e volte a buscar
        				disp('Connection lost');
        				[obj,WPTManager] = goToStateZero(obj,WPTManager);
        			end
        			%chamada para o próximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        	end
        end
        
        %tratamento individual de cada estado (ao entrar)
        
        function [obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime)
        	obj.state = 0;
        	WPTManager = turnOff(obj,WPTManager,GlobalTime);%desliga o transmissor de potência
        	%o timer já é disparado automaticamente
        end
        
        function [obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime)
        	obj.state = 1;
        	WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,2*pi*4000);%4kHz
            obj.w = 2*pi*4000;
        	WPTManager = turnOn(obj,WPTManager,GlobalTime);%liga o transmissor de potência (ping analogico)
        end
        
        function [obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime)
        	obj.state = 2;
        	WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,2*pi*110000);%110kHz
            obj.w = 2*pi*110000;
        	WPTManager = turnOn(obj,WPTManager,GlobalTime);%liga o transmissor de potência
        	obj.okUntil = GlobalTime + obj.dt;
        	obj.lastVar = 0;
            obj.ddw = 1;
        end
        
        
        %encapsulamento das funções básicas do sistema
        
        function WPTManager = turnOn(obj,WPTManager,GlobalTime)
        	WPTManager = setSourceVoltages(obj,WPTManager,obj.V,GlobalTime);
        end
        
        function WPTManager = turnOff(obj,WPTManager,GlobalTime)
        	WPTManager = setSourceVoltages(obj,WPTManager,0,GlobalTime);
        end
    end
end
