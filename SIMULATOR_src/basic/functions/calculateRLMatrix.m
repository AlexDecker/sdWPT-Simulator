%Calcula a resistência equivalente de um conjunto carregador/bateria

%saídas
%RL: resistência equivalente
%It: Vetor coluna com as correntes nos transmissores
%Ir: Vetor coluna com as correntes nos receptores

%entradas
%Vt: Vetor coluna com as tensões das fontes dos transmissores
%Z: Matriz de impedância do sistema, com as resistências ohimicas na
%diagonal principal e -jwM nas demais posições, sendo j a unidade
%imaginária, w a frequência angular e M a indutância
%Ie: Corrente esperada dada a operação padrão de recarga de uma bateria
%(vetor coluna com o valor para cada receptor)
%RL0: RL inicial. 
%err: erro percentual admissível entre Ir e Ie
%maxRL: valor máximo para RL (escalar)
%ifactor: fator de incremento para a busca de RL. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RL
%iVel: velocidade inicial para a busca de RL no espaço se soluções

function [RL,It,Ir]=calculateRLMatrix(Vt,Z,Ie,RL0,err,maxRL,ifactor,dfactor,iVel)
    %verificações dos parâmetros
    s = size(Z);
    if (s(1)~=s(2))||(length(Vt)>=s(1))||...
            (length(Ie)~=length(RL0))||(err<0)||(err>1)||...
            (ifactor>dfactor)||(dfactor<=1)||(iVel<=0)||...
            (length(RL0)~=length(Z)-length(Vt))||(sum(RL0<0)>0)||...
			(maxRL<=0)
        error('calculateRLMatrix: parameter error');
    end
    
    n = s(1);
    nt = length(Vt);
    nr = n-nt;
    
    RL = RL0;
    deltaRL = 0*RL0;%matriz de 0 com o tamanho de RL0
	
	ttl = 10000;
    
    while true
		ttl = ttl-1;
        R = diag([zeros(nt,1);RL]);
        V = [Vt;zeros(nr,1)];
        I = (Z+R)\V;
        It = I(1:nt);
        Ir = I(nt+1:end);
        %cálculo dos erros
        absIerr = abs(Ir)-abs(Ie);%se negativo, aumente a corrente
        %(diminua a resistência). Se positivo, diminua a corrente
        %(aumente a resistência)
        
        cond1 = (abs(absIerr)<err*abs(Ie)); %se todos estão dentro da margem de erro tolerável
        
        cond2 = (absIerr<0); %os que devem diminuir a resistência
        cond3 = (RL==0); %os que já abaixaram a resistência ao mínimo
        
        cond4 = (absIerr>0); %os que devem aumentar a resistência
        cond5 = (RL==maxRL); %os que já aumentaram a resistência ao máximo
        
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
        
        for i=1:length(RL)
            %definindo a nova variação de RL
            if(absIerr(i)<0)%deltaRL deve ser negativo
                if(deltaRL(i)<0)%aumente o módulo da variação
                    deltaRL(i) = deltaRL(i)*ifactor;
                else
                    if(deltaRL(i)>0)%passou da solução, diminua o módulo da variação e troque o sinal
                        deltaRL(i) = -deltaRL(i)/dfactor;
                    else%recomece (ou comece) da velocidade mínima
                        deltaRL(i) = -iVel;
                    end
                end
            else
                if(absIerr(i)>0)%deltaRL deve ser positivo
                   if(deltaRL(i)<0)%passou da solução, diminua o módulo da variação e troque o sinal
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
            
            RL(i) = RL(i)+deltaRL(i);
			
            if RL(i)<0 %resistência apenas positiva
                RL(i)=0;
            end
            if RL(i)>maxRL %resistência limitada superiormente
                RL(i)=maxRL;
            end
        end
    end
end