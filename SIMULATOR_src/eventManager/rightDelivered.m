%REFAZER ESSA FUNÇÃO
function r = rightDelivered(message,messageList,WPTManager,...
    B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,curr,Z)
    %TODO: descontar a energia gasta
    
    %utilizado para evitar que a interferência de uma mesma
    %fonte seja contada mais de uma vez
    interfMap = zeros(length(Z),1);
    %para não considerar o próprio sinal como interferência
    interfMap(message.creator) = 1;
    
    switch(message.options.type)
        case 0 %SWIPT
            P = abs(Z(message.owner,message.creator)...
                *curr(message.creator)^2);
            I = 0;
            for i=1:length(messageList)
                if((messageList(i).options.type==message.options.type)...
                && (interfMap(messageList(i).creator)==0))
                    I = I + abs(Z(message.owner,messageList(i).creator)...
                        .*(curr(messageList(i).creator).^2);
                    interfMap(messageList(i).creator)=1;
                end
            end
            SINR = P/(I+N_SWIPT);
            r = (SINR > B_SWIPT);
        otherwise %RF
            pos = getCenterPositions(WPTManager.ENV,message.time1);
            d = abs(pos(message.creator,:)-pos(message.owner,:));
            P = message.options.power/(d^A_RF);
            %calculando a interferência
            I = 0;
            for i=1:length(messageList)
                %type pode ser usado para diferenciação de canais
                if((messageList(i).options.type==message.options.type)
                && (interfMap(messageList(i).creator)==0))
                    d = abs(pos(messageList(i).creator,:)...
                        -pos(message.owner,:));
                    I = I + messageList(i).options.power/(d^A_RF);
                    interfMap(messageList(i).creator)=1;
                end
            end
            %calculando o SINR
            SINR = P/(I+N_RF);
            %verificando se a transmissão obteve sucesso
            r = (SINR > B_RF);
    end
end