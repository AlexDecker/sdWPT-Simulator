%Calcula o SINR para determinado momento t. Admite que mensagens oriundas
%de um mesmo transmissor não se sobrepoem. A lista conflictList traz os
%eventos que eventualmente se sobrepoem a message e N_RF é a potência do
%ruído.
function SINR = SINR_SWIPT(WPTManager,message,conflictList,N_SWIPT,t)
    %calcule apenas se de fato for SWIPT
    if(message.options.type==0)
        %obtendo a matriz de impedância e o vetor de corrente no momento t
        [curr,Z] = getEstimates(WPTManager,t);
        
        %potência do sinal de interesse
        if(message.creator==0)
            %transmissor da mensagem é o próprio dispositivo transmissor de 
            %energia. Considerar a potência das primeiras nt bobinas
            P = 0;
            for i=1:WPTManager.nt
                P = P+abs(Z(message.owner+WPTManager.nt,i)*curr(i)^2);
            end
        else
            if(message.owner==0)
                %receptor da mensagem é o dispositivo transmissor de 
                %energia. Considerar a potência das primeiras nt bobinas
                P = 0;
                for i=1:WPTManager.nt
                    P = P+abs(Z(i,message.creator+WPTManager.nt)...
                        *curr(message.creator+WPTManager.nt)^2);
                end
            else
                P = abs(Z(message.owner+WPTManager.nt,message.creator...
                    +WPTManager.nt)*curr(message.creator+WPTManager.nt)^2);
            end
        end
        
        %calculando a potência de interferência
        I = 0;
        for i=1:length(conflictList)
            if((conflictList(i).options.type==message.options.type)...
            && (conflictList(i).time0<t)&&(conflictList(i).time1>t))
                if(conflictList(i).creator==0)
                    if(message.owner==0)
                        %se o destinatário estiver enviando uma mensagem,
                        %colisão.
                        SINR = 0;
                        return;
                    else
                        for i=1:WPTManager.nt
                            I = I+abs(Z(message.owner+WPTManager.nt,i)...
                                *curr(i)^2);
                        end
                    end
                else
                    if(conflictList(i).creator==0)
                        for i=1:WPTManager.nt
                            I = I+abs(Z(i,conflictList(i).creator+WPTManager.nt)...
                                *curr(conflictList(i).creator+WPTManager.nt)^2);
                        end
                    else
                        I = I + abs(Z(message.owner+WPTManager.nt,...
                            conflictList(i).creator+WPTManager.nt)...
                            *(curr(conflictList(i).creator+WPTManager.nt)^2));
                    end
                end
            end
        end
        
        SINR = P/(I+N_SWIPT);
    else
        SINR = 0;
    end
end