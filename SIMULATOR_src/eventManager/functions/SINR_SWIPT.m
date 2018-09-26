%Calcula o SINR para determinado momento t. Admite que mensagens oriundas
%de um mesmo transmissor não se sobrepoem. A lista conflictList traz os
%eventos que eventualmente se sobrepoem à message e N_RF é a potência do
%ruído.
function SINR = SINR_SWIPT(WPTManager,message,conflictList,N_SWIPT,t)
    %calcule apenas se de fato for SWIPT
    if(message.options.type==0)
        %obtendo a matriz de impedância e o vetor de corrente no momento t
        [curr,Z] = getEstimates(WPTManager,t);
        
        %obtendo o marcador de grupos
        groupMarking = getGroupMarking(WPTManager.ENV);
        
        %obtendo quantos grupos formam o transmissor
        nt_groups = WPTManager.nt_groups;
        
        %construindo o vetor que marca os anéis RLC correspondentes ao receptor
        %da mensagem
        if(message.owner==0)
        	%é o transmissor de energia; some os nt_groups primeiros vetores 
        	gR = sum(groupMarking(:,1:nt_groups)')';
        else
        	%é um receptor de energia; apenas pegue o vetor do grupo
        	gR = groupMarking(:,nt_groups+message.owner);
        end
        
        %construindo o vetor que marca os anéis RLC correspondentes ao transmissor
        %da mensagem
        if(message.creator==0)
        	%é o transmissor de energia; some os nt_groups primeiros vetores 
        	gT = sum(groupMarking(:,1:nt_groups)')';
        else
        	%é um receptor de energia; apenas pegue o vetor do grupo
        	gT = groupMarking(:,nt_groups+message.creator);
        end
        
        %construindo o vetor que marca os anéis RLC correspondentes aos elementos
        %criadores de interferência
        gI = 0*gT;
        
        for i=1:length(conflictList)
            if((conflictList(i).options.type==message.options.type)...
            && (conflictList(i).time0<t)&&(t<conflictList(i).time1))
                if(conflictList(i).creator==0)
                    if(message.owner==0)
                        %se o destinatário estiver enviando uma mensagem,
                        %colisão.
                        SINR = 0;
                        return;
                    else
                        gI = gI | sum(groupMarking(:,1:nt_groups)')';
                    end
                else
                    gI = gI | groupMarking(:,nt_groups+conflictList(i).creator);
                end
            end
        end
        
        %potência do sinal de interesse
        P = real(curr'*diag(gT)*diag(gR)*Z*diag(gT)*curr);
        
        %potência do sinal de interferência
        I = real(curr'*diag(gI)*diag(gR)*Z*diag(gI)*curr);
        
        SINR = P/(I+N_SWIPT);
    else
        SINR = 0;
    end
end
