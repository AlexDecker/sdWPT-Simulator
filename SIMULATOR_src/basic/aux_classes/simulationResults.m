%Objeto retornado pela função Simulate e que recolhe informações de cada
%dispositivo

classdef simulationResults
    
    properties(SetAccess = private, GetAccess = public)
        running
        device_index %índice do dispositivo ao qual pertencem os dados
        BC %corrente bruta (que passa pela bobina)
        CC %corrente de recarga (dc, apenas RX)
        IE %corrente esperada pelo carregador (para uma recarga ideal, apenas RX)
        DC %corrente de descarga consumida pelo dispositivo (apenas RX)
        %(Corrente de transmissão no caso do TX)
        VB %tensão da bateria (apenas RX)
        SOC %state of charge da bateria (apenas RX)
        RL %resistência equivalente do dispositivo (RS no caso do TX)
    end

    methods(Access=public)
        function obj = simulationResults(device_index)
            if (length(device_index)~=1) || (device_index<0)
                error('simulationResults: parameter error');
            end
            obj.running = true;
            obj.device_index = device_index;

            obj.BC = [];
            obj.CC = zeros(2,0);
            obj.IE = zeros(2,0);
            obj.DC = zeros(2,0);
            obj.VB = zeros(2,0);
            obj.SOC = zeros(2,0);
        end

        function obj = logBCData(obj,BC,time)
            if obj.running
                aux = [BC;time];
                if(isempty(obj.BC))
                    obj.BC = aux;
                else
                    if(time>obj.BC(end,end))
                        %caso esperado
                        obj.BC = [obj.BC,aux];
                    else
                    	if(time<obj.BC(end,end))
		                    %tratamento de excessão
		                    i = find(obj, obj.BC, time);
		                    %os casos em que l log está vazio e em que
		                    %a inserção é no final já são tratados
		                    %individualmente. No caso em que a inserção
		                    %é no início o tratamento ocorre naturalmente
		                    obj.BC = [obj.BC(:,1:i),aux,obj.BC(:,i+1:end)];
		                else
		                	%se time for repetido, apenas substitua
		                	s = size(obj.BC);
		                	if(s(2)==1)
		                		obj.BC = aux;
		                	else
		                		obj.BC = [obj.BC(:,1:s(2)-1),aux];
		                	end
		                end
                    end
                end
            end
        end

        function obj = logCCData(obj,CC,time)
            if obj.running
                aux = [CC;time];
                obj.CC = [obj.CC aux];
            end
        end

        function obj = logIEData(obj,IE,time)
            if obj.running
                aux = [IE;time];
                obj.IE = [obj.IE aux];
            end
        end

        function obj = logDCData(obj,DC,time)
            if obj.running
                aux = [DC;time];
                obj.DC = [obj.DC aux];
            end
        end

        function obj = logVBData(obj,VB,time)
            if obj.running
                aux = [VB;time];
                obj.VB = [obj.VB aux];
            end
        end

        function obj = logSOCData(obj,SOC,time)
            if obj.running
                aux = [SOC;time];
                obj.SOC = [obj.SOC aux];
            end
        end

        function obj = logRLData(obj,RL,time)
            if obj.running
                aux = [RL;time];
                if(isempty(obj.RL))
                    obj.RL = aux;
                else
                    if(time>=obj.RL(end,end))
                        %caso esperado
                        obj.RL = [obj.RL,aux];
                    else
                        %tratamento de excessão
                        i = find(obj, obj.RL, time);
                        %os casos em que o log está vazio e em que a inserção é
                        %no final já são tratados individualmente. No caso em que
                        %a inserção é no início o tratamento ocorre naturalmente
                        obj.RL = [obj.RL(:,1:i),aux,obj.RL(:,i+1:end)];
                    end
                end
            end
        end

        function obj = endDataAquisition(obj)
            if length(obj)~=1
                error('endDataAquisition works with objects, not lists');
            end
            obj.running = false;
        end

        function plotBatteryChart(obj)
            if ~obj.running
                figure;
                hold on;
                yyaxis left
                plot(obj.CC(2,:)/3600,obj.CC(1,:));
                plot(obj.IE(2,:)/3600,obj.IE(1,:));
                plot(obj.DC(2,:)/3600,obj.DC(1,:));
                plot(obj.VB(2,:)/3600,obj.VB(1,:));
                ylabel('(A) / (V)')
                yyaxis right
                plot(obj.SOC(2,:)/3600,obj.SOC(1,:)*100);
                legend('Charge Current','Expected Current',...
                'Discharge Current','Battery Voltage','SOC');
                xlabel('Time (h)')
                ylabel('(%)')
                title(['Battery Chart for device ', num2str(obj.device_index)]);
            end
        end

        function plotBatteryChart2010(obj)
            if ~obj.running
                figure;
                hold on;
                plot(obj.CC(2,:)/3600,obj.CC(1,:),'r');
                plot(obj.IE(2,:)/3600,obj.IE(1,:),'b');
                plot(obj.DC(2,:)/3600,obj.DC(1,:),'g');
                plot(obj.VB(2,:)/3600,obj.VB(1,:),'m');
                xlabel('Time (h)')
                ylabel('(A) / (V)')
                legend('Charge Current','Expected Current',...
                'Discharge Current','Battery Voltage');
                title(['Battery Chart for device ', num2str(obj.device_index)]);

                figure;
                plot(obj.SOC(2,:)/3600,obj.SOC(1,:)*100);
                xlabel('Time (h)')
                ylabel('(%)')
                title(['SOC Chart for device ', num2str(obj.device_index)]);
            end
        end
        
        function I = getCurrentEstimate(obj,time)
            I = estimate(obj, obj.BC, time);
        end
        
        function r = getRLEstimate(obj,time)
            r = estimate(obj, obj.RL, time);
        end
    end
    
    methods(Access=private)
        %retorna o maior índice i de um elemento de um momento menor ou igual a time
        %se não existir, o valor 0 é retornado
        function i = find(obj, log, time)
            if(isempty(log))
                %valor default
                i = 0;
            else
                if(time<log(end,1))
                    %o momento foi anterior ao primeiro que se tem registro
                    i = 0;
                else
                    if(time>=log(end,end))
                        %o momento é posterior ao último que se tem registro
                        s = size(log);
                        i = s(2);
                    else
                        %i0 e i1 delimitam o espaço de busca (e fazem parte dele inclusive)
                        i0 = 1;
                        s = size(log);
                        i1 = s(2)-1;%i=end já foi tratado
                        while(true)
                            i = floor((i1+i0)/2);
                            if(time>=log(end,i))
                                if(time<log(end,i+1))
                                    %encontrado o registro mais tardio que precede time
                                    break;
                                else
                                    %o sucessor ainda não supera o time. o espaço de busca agora começa nele
                                    i0 = i+1;
                                end
                            else
                                %esse registro não pode ser um antecessor de time.
                                %o espaço de busca deve terminar em seu antecessor.
                                i1 = i-1;
                            end
                        end
                    end
                end
            end
        end
        
        %interpola linearmente o valor do momento time com base nos dados de log
        function v = estimate(obj, log, time)
            s = size(log);
            nLines = s(1);
            nCols = s(2);
            if(nCols==0)
                warningMsg('(SimulationResults) estimation may be inaccurate (not enough data)');
                v = 0;
            else
                i = find(obj, log, time);
                if(i==0)
                    %se o momento for anterior ao mais antigo já registrado
                    if(time<log(end,1))
                        warningMsg('(SimulationResults) estimation may be inaccurate (past)');
                    end
                    v = log(1:nLines-1,1);
                else
                    if(i==nCols)
                        if(time>log(end,end))
                            warningMsg('(SimulationResults) estimation may be inaccurate (future)');
                        end
                        v = log(1:nLines-1,i);
                    else
                        v0 = log(1:nLines-1,i);
                        t0 = log(end,i);
                        
                        v1 = log(1:nLines-1,i+1);
                        t1 = log(end,i+1);
                        
                        if(t1==t0)
                            warningMsg('(SimulationResults) race condition');
                            v = (v0+v1)/2;
                        else
                            lambda = (time-t0)/(t1-t0);
                            v = lambda*v1 + (1-lambda)*v0;
                        end
                    end 
                end
            end
        end
    end
end
