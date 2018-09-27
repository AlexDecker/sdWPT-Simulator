%Baseado no envListManager, porem com suporte a recarga de baterias.

classdef envListManagerBAT
    
    properties
        ENV %envListManager
        deviceList %lista de dispositivos com interface compativel com Device
        Vlist %lista das tensoes Vt variadas porem ainda nao computadas
        Tlist %tempos em que cada entrada em Vlist foi adicionada
        CurrTime %Ultimo momento que se tem conhecimento (por leitura ou escrita)
        previousRL %RL da ultima iteracao, guardado por razoes de eficiencia
        step %passo de integracao
        first %booleano. indica a primeira vez que as baterias foram atualizadas

        showProgress %se verdadeiro, imprime na tela o progresso da simulacao
        lastPrint %utilizado para reduzir o numero de prints de progresso
        
        TRANSMITTER_DATA %simulationResults (TX)
        DEVICE_DATA %lista de simulationResults (RX)
        nt %numero de aneis transmissores
        nt_groups %numero de grupos transmissores

        latestCI %os ultimos valores calculados da corrente em fasores
    end

    methods
        function obj = envListManagerBAT(elManager,deviceList,step,showProgress)
            obj.ENV = elManager;
            obj.deviceList = deviceList;

            obj.nt_groups = length(obj.ENV.Vt_group);
            
            gm = getGroupMarking(obj.ENV);
            obj.nt = sum(sum(gm(:,1:obj.nt_groups)));
            
            obj.Vlist = zeros(length(obj.ENV.Vt_group),0);
            obj.Tlist = [];
            obj.CurrTime = 0;

            obj.previousRL = zeros(length(deviceList),1);
            obj.step = step;
            obj.first = true;

            obj.showProgress=showProgress;
            obj.lastPrint=0;

            obj.latestCI = zeros(length(obj.ENV.envList(1).Coils),1);
            
            obj.TRANSMITTER_DATA = simulationResults(0);
            
            obj.DEVICE_DATA=[];
            for i=1:length(deviceList)
                obj.DEVICE_DATA = [obj.DEVICE_DATA simulationResults(i)];
            end

            if ~check(obj)
                error('envListManagerBAT: parameter error');
            end
        end

        %verifica se os par�metros est�o em ordem
        function r=check(obj)
            r=(obj.step>0)&&check(obj.ENV);
            for i=1:length(obj.deviceList)
                r = r && check(obj.deviceList(i).obj);
            end
        end

        %altera o vetor de tans�es dos transmissores
        function obj = setVt(obj, Vt, CurrTime)
            if(length(Vt)~=obj.nt_groups)
                error('envListManagerBAT: Inconsistent value of Vt');
            end
            if(CurrTime<obj.CurrTime)
                error('envListManagerBAT (setVt): Inconsistent time value');
            end

            obj.CurrTime = CurrTime;
            obj.Vlist = [obj.Vlist Vt];
            obj.Tlist = [obj.Tlist CurrTime];
        end   
		
		%para fins de medi��es
        function Z = getCompleteLastZMatrix(obj)
        	Z = composeZMatrix(getZ(obj.ENV,obj.CurrTime),...
        		[obj.ENV.RS*ones(obj.nt_groups,1);obj.previousRL],getGroupMarking(obj.ENV));
        end

        %calcula o vetor de resist�ncias que abstrai os dispositivos
        %receptores do sistema
        function [obj,RL] = calculateAllRL(obj,time,Vt)
            Ie = zeros(length(obj.deviceList),1);%corrente esperada
            for i=1:length(obj.deviceList)
                [obj.deviceList(i).obj,Ie(i)] = expectedCurrent(obj.deviceList(i).obj); 
                %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
                obj.DEVICE_DATA(i) = logIEData(obj.DEVICE_DATA(i),Ie(i),time);
                %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            Z = getZ(obj.ENV,time);%matriz de imped�ncia atual
            [RL,~,~]=calculateRLMatrix(Vt,Z,Ie,obj.previousRL,...
            obj.ENV.err,obj.ENV.maxResistance,obj.ENV.ifactor,...
            obj.ENV.dfactor,obj.ENV.iVel,getGroupMarking(obj.ENV));

            %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
            for i=1:length(obj.deviceList)
                obj.DEVICE_DATA(i) = logRLData(obj.DEVICE_DATA(i),RL(i),time);
            end
            %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%

            obj.previousRL = RL;%para recalcular futuramente com mais efici�ncia
        end

        function [obj,I1] = integrateCurrent(obj,t0,t1,Vt)        
            obj.ENV.Vt_group = Vt;
            t = t0;
            [obj,RL] = calculateAllRL(obj,t,Vt);
            [obj.ENV,I0,obj.TRANSMITTER_DATA] = getCurrent(obj.ENV,RL,...
                obj.TRANSMITTER_DATA,t);
            %log-------------------
            obj.TRANSMITTER_DATA = logBCData(obj.TRANSMITTER_DATA,...
                I0(1:obj.nt),t);
            for i=1:length(obj.DEVICE_DATA)
            	[c0,c1] = getGroupLimits(obj.ENV,obj.nt_groups+i);
                obj.DEVICE_DATA(i) = logBCData(obj.DEVICE_DATA(i),...
                    I0(c0:c1),t);
            end
            %log-------------------
            I1=I0;%valor default
            t=t+obj.step;
            while(t<t1)
            	%calcula a resist�ncia equivalente dos consumidores de energia
                [obj,RL] = calculateAllRL(obj,t,Vt);
                
                %obt�m a medida de corrente em cada anel RLC
                [obj.ENV,I1,obj.TRANSMITTER_DATA] = getCurrent(obj.ENV,RL,...
                    obj.TRANSMITTER_DATA,t);
                    
                %encontra o ponto m�dio com a �ltima amostragem
                meanI = (I1+I0)/2;
                meanI_group = getGroupMarking(obj.ENV)'*meanI;
                
                %log-------------------
                obj.TRANSMITTER_DATA = logBCData(obj.TRANSMITTER_DATA,...
                    meanI(1:obj.nt),t);
                for i=1:length(obj.DEVICE_DATA)
                	[c0,c1] = getGroupLimits(obj.ENV,obj.nt_groups+i);
                    obj.DEVICE_DATA(i) = logBCData(obj.DEVICE_DATA(i),...
                        meanI(c0:c1),t);
                end
                %log-------------------
                
                %atualiza a carga das baterias de acordo com a corrente atual e o intervalo de tempo t
                for i=1:length(obj.deviceList)
                    [obj.deviceList(i).obj,obj.DEVICE_DATA(i)] = updateDeviceState(obj.deviceList(i).obj,...
                    meanI_group(length(Vt)+i), obj.step,obj.DEVICE_DATA(i),t);
                end
                
                I0 = I1;
                
                %visualiza��o do progresso
                if obj.showProgress && (obj.lastPrint ~= round(100*t/obj.ENV.tTime))
                    disp(['progress: ',num2str(round(100*t/obj.ENV.tTime)),'%']);
                    obj.lastPrint = round(100*t/obj.ENV.tTime);
                end
                
                t=t+obj.step;
            end
        end

        %atualiza a carga de todas as baterias, por�m admitindo Vt vari�vel
        function [obj,I] = updateBatteryCharges(obj,time)
            if(time<obj.CurrTime)
                error('envListManagerBAT: Inconsistent time value');
            end
            if(isempty(obj.Tlist))
                warningMsg('(envListManagerBAT) nothing to compute');
                I = zeros(length(obj.deviceList),1);
                return;
            end

            obj.first = false;
            while length(obj.Tlist)>=2
                t0 = obj.Tlist(1);
                Vt = obj.Vlist(:,1);
                t1 = obj.Tlist(2);
                obj.Tlist = obj.Tlist(2:end);
                obj.Vlist = obj.Vlist(:,2:end);
                [obj,I] = integrateCurrent(obj,t0,t1,Vt);
            end
            t0 = obj.Tlist(1);
            Vt = obj.Vlist(:,1);
            t1 = time;
            [obj,I] = integrateCurrent(obj,t0,t1,Vt);
            obj.Tlist(1) = time;
            obj.CurrTime = time;
        end

        %'tolerance' pode ser utilizado para melhorar o desempenho
        function [cI,I,cI_groups,Q,obj] = getSystemState(obj,CurrTime,tolerance)
            s = size(obj.Vlist);
            nCol = s(2);
            if exist('tolerance','var')
                tolerance_val = tolerance;
            else
                tolerance_val = 0;%valor default
            end
            %recalcule se j� tiver passado mais do que um per�odo de toler�ncia,
            %se a tens�o tiver mudado ou se for a primeira medi��o
            if((abs(CurrTime-obj.CurrTime)>tolerance_val)||(nCol~=1)||(obj.first))
                [obj,cI] = updateBatteryCharges(obj,CurrTime);
                obj.latestCI = cI;
            else
                cI = obj.latestCI;%envie o �ltimo valor calculado
            end
            Q = zeros(length(obj.deviceList),1);
            for i=1:length(obj.deviceList)
                Q(i) = obj.deviceList(i).obj.bat.Q;
            end
            I = abs(cI);
            cI_groups = getGroupMarking(obj.ENV)'*cI;
        end
        
        %calcula o vetor de corrente e a matriz de imped�ncia completa
        %com base em estimativas de simulationResults para determinado
        %momento t
        function [curr,Z] = getEstimates(obj,t)
            curr = getCurrentEstimate(obj.TRANSMITTER_DATA,t);
            RS = getRLEstimate(obj.TRANSMITTER_DATA,t);
            RL = [];
            for i=1:length(obj.DEVICE_DATA)
                curr = [curr,getCurrentEstimate(obj.DEVICE_DATA(i),t)];
                RL = [RL,getRLEstimate(obj.DEVICE_DATA(i),t)];
            end
            
            Z = composeZMatrix(getZ(obj.ENV,obj.CurrTime),...
        		[RS*ones(obj.nt_groups,1);RL],getGroupMarking(obj.ENV));
        end
    end
end
