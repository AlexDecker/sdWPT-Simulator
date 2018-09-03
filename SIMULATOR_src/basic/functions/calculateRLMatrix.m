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

function [RL_group,It,Ir]=calculateRLMatrix(Vt_group,Z,Ie_group,RL0_group,err,maxRL,...
	ifactor,dfactor,iVel,groupMarking)
	
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
			(maxRL<=0)||(~checkGroupMarking(groupMarking))
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
    
    RL_group = RL0_group;
    deltaRL = 0*RL0_group;%matriz de 0 com o tamanho de RL0_group
	
	ttl = 10000;
    
    while true
		ttl = ttl-1;
        
        I = composeZMatrix(Z,[zeros(nt_groups,1);RL_group],groupMarking)\V;
        It = I(1:nt);
        Ir = I(nt+1:end);
        
        I_groups = groupMarking'*I;%corrente principal de cada grupo de anéis
        
        %cálculo dos erros
        absIerr = abs(I_groups(nt+1:end))-abs(Ie_group);%se negativo, aumente a corrente
        %(diminua a resistência). Se positivo, diminua a corrente
        %(aumente a resistência)
        
        %se todos estão dentro da margem de erro tolerável
        cond1 = (abs(absIerr)<err*abs(Ie_group)); 
        
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
            %definindo a nova variação de RL
            if(absIerr(i)<0)%deltaRL deve ser negativo
                if(deltaRL(i)<0)%aumente o módulo da variação
                    deltaRL(i) = deltaRL(i)*ifactor;
                else
                	%passou da solução, diminua o módulo da variação e troque o sinal
                    if(deltaRL(i)>0)
                        deltaRL(i) = -deltaRL(i)/dfactor;
                    else%recomece (ou comece) da velocidade mínima
                        deltaRL(i) = -iVel;
                    end
                end
            else
                if(absIerr(i)>0)%deltaRL deve ser positivo
                	%passou da solução, diminua o módulo da variação e troque o sinal
                	if(deltaRL(i)<0)
                       deltaRL(i) = -deltaRL(i)/dfactor;
                    else
                        if(deltaRL(i)>0)%aumente o módulo da variação
                            deltaRL(i) = deltaRL(i)*ifactor;
                        else%recomece (ou comece) da velocidade mínima
                            deltaRL(i) = iVel;
                        end
                    end 
                else%deltaRL deve ser nulo
                    deltaRL(i)=0;
                end
            end
            
            RL_group(i) = RL_group(i)+deltaRL(i);
			
            if RL_group(i)<0 %resistência apenas positiva
                RL_group(i)=0;
            end
            if RL_group(i)>maxRL %resistência limitada superiormente
                RL_group(i)=maxRL;
            end
        end
    end
end
