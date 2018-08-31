classdef envListManager
    properties
        envList
        Vt_group %vetor coluna com a tens�o ac de cada grupo transmissor (V) 
        R_group %vetor coluna com a resis�ncia de cada grupo Transmissor/Receptor (ohm)
        w %frequ�ncia ressonante angular (rad/s)
        tTime %tempo decorrido do primeiro (time=0) ao �ltimo quadro (s)
        err %erro admiss�vel para a pot�ncia (%)
        maxResistance %teto para qualquer valor de resist�ncia (ohm)
        ifactor %> 1 e < dfactor, usado na busca por RS
        dfactor
        iVel %velocidade inical para a busca de RS
        maxPower %pot�ncia m�xima da fonte dos transmissores
        mostRecentZ %valor mais recente de Z utilizado 
		miEnv %constante de permeabilidade magn�tica do meio
        RS %ponto de partida para a busca do pr�ximo vetor RS
    end
    methods
        function obj = envListManager(envList,Vt_group,w,R_group,tTime,err,...
            maxResistance,ifactor,dfactor,iVel,maxPower,miEnv)
            obj.envList = envList;
            obj.Vt_group = Vt_group;
            obj.w = w;
            obj.R_group = R_group;
            obj.tTime=tTime;

            obj.err=err;
            obj.maxResistance=maxResistance;
            obj.ifactor=ifactor;
            obj.dfactor=dfactor;
            obj.iVel=iVel;
            obj.maxPower=maxPower;
            if exist('miEnv','var')
                obj.miEnv = miEnv;
            else
                obj.miEnv = pi*4e-7;
            end
			
            obj.mostRecentZ = getZ(obj,0);

            obj.RS = 0;

            if ~check(obj)
                error('envListManager: parameter error');
            else
                disp(['Environment Manager created with ',num2str(length(obj.Vt_group)),...
                    ' active groups and ',num2str(length(obj.R_group)-length(obj.Vt_group)),' passives']);
            end
        end

        %verifica se os par�metros est�o em ordem
        function r = check(obj)
            r = true;
            for i = 1:length(obj.envList)
                r = r && check(obj.envList(i));
            end
            r = r && (obj.w>0) && (sum(obj.R_group<=0)==0) && (obj.tTime>0) &&...
                (length(obj.R_group)<=length(obj.mostRecentZ)) &&...
                (length(obj.Vt_group)<length(obj.R_group)) && (obj.err>0) && (obj.err<1) &&...
                (sum(obj.R_group>obj.maxResistance)==0) && (length(obj.maxResistance)==1) &&...
                (obj.ifactor>1) && (length(obj.ifactor)==1) && ...
                (obj.dfactor>obj.ifactor) && (length(obj.dfactor)==1) && ...
                (obj.iVel>0) && (length(obj.iVel)==1) && ...
                (obj.maxPower>0) && (length(obj.maxPower)==1);
        end
        
        function groupMarking = getGroupMarking(obj)
        	groupMarking = obj.envList(1).groupMarking;
        end

        %os dados de que n�o se t�m informa��o s�o aproximados com uma
        %combina��o linear convexa, na forma
        %dado[time] = dado[i0]*lambda+(1-lambda)*dado[1]
        function [i0,i1,lambda] = getIndexFromTime(obj,time)
            n = length(obj.envList);
            i = 1+(n-1)*time/obj.tTime;
            i0 = floor(i);
            i1 = ceil(i);
            lambda = i1-i;
        end

        function Z = getZ(obj,time)%requer onisci�ncia for�ada
            [i0,i1,lambda] = getIndexFromTime(obj,time);
			
			%define com R os valores antes marcados com -1
            obj.envList(i0).R_group = obj.envList(i0).R_group...
            	+ (obj.envList(i0).R_group<0).*(obj.R_group-obj.envList(i0).R_group);
            
            obj.envList(i0).miEnv = obj.miEnv;
            obj.envList(i0).w = obj.w;
            Z0 = generateZENV(obj.envList(i0));
			
			%define com R os valores antes marcados com -1
            obj.envList(i1).R_group = obj.envList(i1).R_group...
            	+ (obj.envList(i1).R_group<0).*(obj.R_group-obj.envList(i1).R_group);
            	
           	obj.envList(i1).miEnv = obj.miEnv;
            obj.envList(i1).w = obj.w;
            Z1 = generateZENV(obj.envList(i1));

            Z = lambda*Z0+(1-lambda)*Z1;%faz a interpola��o linear entre as
            %duas matrizes que se tem informa��o real
        end

        %generates a matrix in which each line is the ordered triple of the center of each coil.
        function P = getCenterPositions(obj,time)
            [i0,i1,lambda] = getIndexFromTime(obj,time);
            P0 = zeros(length(obj.envList(i0).Coils),3);
            P1 = zeros(length(obj.envList(i1).Coils),3);
            for j = 1:length(obj.envList(i0).Coils)
                P0(j,:) = [obj.envList(i0).Coils(j).obj.X,...
                    obj.envList(i0).Coils(j).obj.Y, obj.envList(i0).Coils(j).obj.Z];
                P1(j,:) = [obj.envList(i1).Coils(j).obj.X,...
                    obj.envList(i1).Coils(j).obj.Y, obj.envList(i1).Coils(j).obj.Z];
            end
            P = lambda*P0 + (1-lambda)*P1;
        end

        %RL_group: resist�ncia equivalente do dispositivo atrelado a cada grupo receptor.
        function [obj,I,TRANSMITTER_DATA] = getCurrent(obj,RL_group,...
            TRANSMITTER_DATA,time)
            if ~check(obj)
                error('envListManager: attribute violation');
            end
            Z = getZ(obj,time);
            [obj.mostRecentZ,obj.RS,I]=calculateCurrents(obj.Vt_group,Z,RL_group,...
                obj.RS,obj.err,obj.maxResistance,obj.ifactor,obj.dfactor,...
                obj.iVel,obj.maxPower,getGroupMarking(obj));
            TRANSMITTER_DATA = logRLData(TRANSMITTER_DATA,obj.RS,time);
        end
    end
end
