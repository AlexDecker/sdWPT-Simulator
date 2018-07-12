%saídas
%eZ: Matriz de impedância efetivamente usada
%RS: resistência da fonte (considerando que todos possuem a mesma fonte, ohms)
%I: Vetor coluna com as correntes nos elementos do sistema (A)

%entradas
%Vt: Vetor coluna com as tensões das fontes dos transmissores (V, phasor)
%Z: Matriz de impedância do sistema, com as resistências ohimicas na
%diagonal principal e -jwM nas demais posições, sendo j a unidade
%imaginária, w a frequência angular e M a indutância
%RL: resistência equivalente do sistema sendo carregado (ohms)
%RS0: RS inicial (escalar, ohms). 0 se não tiver algum valor pronto
%err: erro percentual admissível para o limite de potência
%maxResistance: valor máximo para a RS ou a resistência fixa (escalar, ohms)
%ifactor: fator de incremento para a busca de RS. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RS
%iVel: velocidade inicial para a busca de RS no espaço se soluções
%maxPower: potência máxima da fonte de tensão (W)

function [eZ,RS,I]=calculateCurrents(Vt,Z,RL,RS0,err,maxResistance,ifactor,...
    dfactor,iVel,maxPower)

    s = size(Z);
    n = s(1);
    nt = length(Vt);
    nr = n-nt;
    
    %verificações dos parâmetros
    if (s(1)~=s(2))||(length(Vt)>=n)||(err<0)||(err>1)||(length(err)~=1)...
            ||(ifactor>dfactor)||(dfactor<=1)||(length(ifactor)~=1)||(length(dfactor)~=1)...
            ||(iVel<=0)||(length(iVel)~=1)||(length(RL)~=nr)||(sum(RL<0)>0)...
            ||(length(RS0)~=1)||(length(maxResistance)~=1)||(length(maxPower)~=1)||(maxPower<=0)
        error('calculateCurrents: parameter error');
    end
    
    V = [Vt;zeros(nr,1)];
    Z = Z + diag([zeros(nt,1);RL]);
    for i=1:n %para evitar problemas com singularidade matricial
        if Z(i,i)>maxResistance
            Z(i,i)=maxResistance;
        end
    end
    I = Z\V;
    P = abs(V.'*I);
    
	ttl = 10000;
	
    if P-maxPower<err*maxPower %operação normal
        RS = 0;
        eZ = Z;
    else %condição de saturação         
        RS = RS0;
        deltaRS = 0;
        while true
			ttl = ttl-1;
            R = diag([RS*ones(nt,1);zeros(nr,1)]);
            I = (Z+R)\V;
            %cálculo do erros
            absPerr = abs(V.'*I)-maxPower;%se negativo, diminua a resistência.
            %se positivo, aumente a resistência

            cond1 = (abs(absPerr)<err*maxPower); %se todos estão dentro da margem de erro tolerável

            cond2 = (absPerr<0); %deve diminuir a resistência
            cond3 = (RS==0); %já abaixou a resistência ao mínimo

            cond4 = (absPerr>0); %deve aumentar a resistência
            cond5 = (RS==maxResistance); %já aumentou a resistência ao máximo
            
            %condição de parada: resultado aceitável ou deve variar e não
            %consegue
            if  cond1 || (cond2 && cond3) || (cond4 && cond5)
                eZ = Z+R;
                break;
            end
			
			if ttl<=0
				warningMsg('(calculating RS): I give up'); 
				break;
			end

            %definindo a nova variação de RS
            if(absPerr<0)%deltaRS deve ser negativo
                if(deltaRS<0)%aumente o módulo da variação
                    deltaRS = deltaRS*ifactor;
                else
                    if(deltaRS>0)%passou da solução, diminua o módulo da variação e troque o sinal
                        deltaRS = -deltaRS/dfactor;
                    else%recomece (ou comece) da velocidade mínima
                        deltaRS = -iVel;
                    end
                end
            else
                if(absPerr>0)%deltaRL deve ser positivo
                   if(deltaRS<0)%passou da solução, diminua o módulo da variação e troque o sinal
                       deltaRS = -deltaRS/dfactor;
                    else
                        if(deltaRS>0)%aumente o módulo da variação
                            deltaRS = deltaRS*ifactor;
                        else%recomece (ou comece) da velocidade mínima
                            deltaRS = iVel;
                        end
                    end 
                else%deltaRL deve ser nulo
                    deltaRS=0;
                end
            end

            RS = RS+deltaRS;

            if RS<0 %resistência apenas positiva
                RS=0;
            end
            if RS>maxResistance %resistência limitada superiormente
                RS=maxResistance;
            end
        end
		warningMsg('the source is satured',[': asked for ',num2str(P),' W, but the source provided ',num2str(abs(V.'*I)),' W']);
    end
end