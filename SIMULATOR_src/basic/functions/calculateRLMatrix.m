%Calcula a resistência equivalente de um conjunto carregador/bateria

%saídas
%RL_group: resistência equivalente (por grupo)
%It: Vetor coluna com as correntes nos transmissores (por anel RLC)
%Ir: Vetor coluna com as correntes nos receptores (por anel RLC)

%entradas
%Vt_group: Vetor coluna com as tensões das fontes dos transmissores (considerando grupos)
%Z: Matriz de impedância do sistema (considerando os aneis RLC)
%Ie_group: Corrente esperada dada a operação padrão de recarga de uma bateria
%(vetor coluna com o valor para cada grupo receptor)
%RL0_group: RL inicial (um valor para cada grupo receptor). 
%err: erro percentual admissível entre Ir e Ie
%maxRL: valor máximo para RL (escalar)
%ifactor: fator de incremento para a busca de RL. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RL
%iVel: velocidade inicial para a busca de RL no espaço se soluções
%groupMarking: groupMarking(i,j) = {1 caso i pertença ao grupo j e 0 caso contrário}.
%staticRL_group: the already known values. -1 for unknown values

function [RL_group,It,Ir]=calculateRLMatrix(Vt_group,Z,Ie_group,RL0_group,err,maxRL,...
	ifactor,dfactor,iVel,groupMarking,staticRL_group)
	
    %verificações dos parâmetros
    s = size(Z);
    s2 = size(groupMarking);
    
    n = s(1);%número de anéis RLC
    n_groups = s2(2); %número de grupos
    nt_groups = length(Vt_group); %número de grupos transmissores
    nr_groups = n_groups-nt_groups; %número de grupos receptores
    
    nt = sum(sum(groupMarking(:,1:nt_groups)));%número de anéis RLC transmissores
    
    if (s(1)~=s(2))||(nt>=n)||(nt_groups>=n_groups)||...
            (length(Ie_group)~=length(RL0_group))||(err<0)||(err>1)||...
            (ifactor>dfactor)||(dfactor<=1)||(iVel<=0)||...
            (length(RL0_group)~=nr_groups)||(sum(RL0_group<0)>0)||...
			(maxRL<=0)||(~checkGroupMarking(groupMarking))||...
			(length(staticRL_group)~=length(RL0_group))
        error('calculateRLMatrix: parameter error');
    end
    
    %limitando os elementos de impedância (para não prejudicar a inversão)
    for i=1:n %para evitar problemas com singularidade matricial
    	for j=1:n
		    if abs(Z(i,j))>maxRL %testa para impedância máxima
		        Z(i,j)=maxRL/abs(Z(i,j))*Z(i,j);
		    end
        end
    end
    
    %passando de espaço de grupo para espaço de anel RLC
    V = groupMarking*[Vt_group;zeros(nr_groups,1)];
    
    %using the already calculated values and the previously calculated (if static==-1)
    RL_group = RL0_group+(staticRL_group~=-1).*(staticRL_group-RL0_group);
    
    %variation vector (starts with 0's)
    deltaRL = 0*RL0_group;
	
	%time to leave
	ttl = 10000;
    
    while true
		ttl = ttl-1;
        
        I = composeZMatrix(Z,[zeros(nt_groups,1);RL_group],groupMarking)\V;
        It = I(1:nt);
        Ir = I(nt+1:end);
        
        I_groups = groupMarking'*I;%corrente principal de cada grupo de anéis
        
        %error calculation
        absIerr = abs(I_groups(nt+1:end))-abs(Ie_group);%if negative, increase the current
        %(decrease the resistance). If positive, decrease the current
        %(increase the resistance)
        
        %if all values are inside the tolerable margin of error
        %(the already calculated values are disconsidered)
        cond1 = (staticRL_group~=-1)|(abs(absIerr)<err*abs(Ie_group)); 
        
        cond2 = (absIerr<0); %os que devem diminuir a resistência
        cond3 = (RL_group==0); %os que já abaixaram a resistência ao mínimo
        
        cond4 = (absIerr>0); %os que devem aumentar a resistência
        cond5 = (RL_group==maxRL); %os que já aumentaram a resistência ao máximo
        
        %estado de parada individual: caso esteja dentro da margem de erro
        %tolerável ou precise aumentar ou diminuir a corrente apesar de não
        %ser capaz
        cond = cond1 | (cond2 & cond3) | (cond4 & cond5);
        
        %se todos estão em estado de parada individual
        if sum(cond)==length(cond)
            break;
        end
		
		if ttl<=0
			warningMsg('(calculating RL): I give up'); 
			break;
		end
        
        for i=1:length(RL_group)
        	if(staticRL_group(i)==-1)
        		%if applicable
        		
		        %defining the new variation of RL
		        if(absIerr(i)<0)%deltaRL must be negative
		            if(deltaRL(i)<0)%increase the absolute value of the variation
		                deltaRL(i) = deltaRL(i)*ifactor;
		            else
		            	%decrease the absolute value of the variation and switch the signal 
		                if(deltaRL(i)>0)
		                    deltaRL(i) = -deltaRL(i)/dfactor;
		                else%restart (or start) from the minimal velocity
		                    deltaRL(i) = -iVel;
		                end
		            end
		        else
		            if(absIerr(i)>0)%deltaRL must be positive
		            	%decrease the absolute value of the variation and switch the signal 
		            	if(deltaRL(i)<0)
		                   deltaRL(i) = -deltaRL(i)/dfactor;
		                else
		                    if(deltaRL(i)>0)%increase the absolute value of the variation
		                        deltaRL(i) = deltaRL(i)*ifactor;
		                    else%restart (or start) from the minimal velocity
		                        deltaRL(i) = iVel;
		                    end
		                end 
		            else%deltaRL deve ser nulo
		                deltaRL(i)=0;
		            end
		        end
		        
		        RL_group(i) = RL_group(i)+deltaRL(i);
			
		        if RL_group(i)<0 %positive resistance restriction
		            RL_group(i)=0;
		        end
		        if RL_group(i)>maxRL %maximum resistance restriction
		            RL_group(i)=maxRL;
		        end
            end
        end
    end
end
