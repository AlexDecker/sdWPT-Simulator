%abstrai o ambiente em determinado momento.
classdef Environment
    properties
        Coils
        groupMarking
        M
        R_group
        C_group
        w
        miEnv %constante de permeabilidade magn�tica do meio
    end
    methods
	    %Argumentos:
	    %w - frequ�ncia angular do sinal da fonte de tens�o
	    %miEnv - constante de permeabilidade magn�tica do meio (H/m)
	    %groups - cada elemento desse vetor corresponde a um dos circuitos do sistema, que � um
	    %anel RLC atrelado com um n�mero arbitr�rio de bobinas em paralelo
        %Estrutura esperada para groups:
        %groups(i) - Lista de estruras
        %	.coils(j) - Lista de estruturas
        %		.obj  - Objeto coil (esse n�vel a mais permite coils de diferentes classes)
        %	.R - Valor da resist�ncia (real positiva ou -1)
        %	.C - Valor da capacit�ncia (real positiva)
        function obj = Environment(groups,w,miEnv)
        	obj.w = w;
            obj.miEnv = miEnv;
            obj.Coils = [];
            obj.R_group = [];
            obj.C_group = [];
            obj.groupMarking = zeros(0,length(groups));
            
            for i=1:length(groups)
            	obj.Coils = [obj.Coils;groups(i).coils];
		        obj.R_group = [obj.R_group;groups(i).R];
		        obj.C_group = [obj.C_group;groups(i).C];
		        gm = [zeros(length(groups(i).coils),i-1),...
		        		ones(length(groups(i).coils),1),...
		        		zeros(length(groups(i).coils),length(groups)-i)];
		        obj.groupMarking = [obj.groupMarking;gm];
            end
            
            if(~check(obj))
            	error('Environment: parameter error');
            end
        end

        function r = check(obj)
        	s = size(obj.groupMarking);
        	r = checkGroupMarking(obj.groupMarking);
        	r = r && (length(obj.C_group)==length(obj.R_group))&&(obj.w>0)&&(obj.miEnv>0);
        	r =	r && (s(1)==length(obj.Coils)) && (s(2)==length(obj.R_group));
            for i = 1:length(obj.Coils)
                r = r && check(obj.Coils(i).obj);
            end
        end
		
		%encontra os �ndices da primeira e da �ltima bobina de determinado grupo. A numera��o
		%dos grupos se inicia em 1.
		function [c0,c1] = getGroupLimits(obj,g)
			if(g==1)
				c0=1;
			else
				c0=sum(sum(obj.groupMarking(:,1:(g-1))))+1;
			end
			c1=sum(sum(obj.groupMarking(:,1:g)));
		end
		
        %Os valores desconhecidos de M devem vir com valor -1.
        function obj = evalM(obj,M)
            for i = 1:length(M)
                for j = 1:length(M)
                    if (M(i,j)==-1)
                        if(M(j,i)~=-1)
                            M(i,j)=M(j,i);
                        else
                            disp('Iniciando calculo de acoplamento');
                            M(i,j)=evalMutualInductance(obj.Coils(i).obj, obj.Coils(j).obj);
                        end
                    end
                end
            end
            obj.M=M;
        end

        function Z = generateZENV(obj)
            if isempty(obj.Coils)
            	miVector = obj.miEnv*ones(length(obj.M),1);
           	else
		        miVector = zeros(length(obj.M),1);
		        for i=1:length(miVector)
		        	miVector(i) = obj.Coils(i).obj.mi;
		        end
		    end
            L = (obj.groupMarking*obj.C_group ~= -1).*diag(obj.M); %if C=-1, resonance
            
            Z = - (1i)*obj.w*obj.miEnv*(obj.M-diag(diag(obj.M)));...%indut�ncias m�tua
                + (1i)*obj.w*diag(miVector.*L);%auto-indut�ncia
            
            %compose the final matrix (if C=-1, resonance)
            Z = composeZMatrix(Z,...
            	obj.R_group-(obj.C_group ~= -1).*(1i)./(obj.w*obj.C_group),...
            	obj.groupMarking);
        end
    end
end
