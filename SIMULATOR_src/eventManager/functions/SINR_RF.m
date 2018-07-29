%Calcula o SINR em determinado momento t. Admite que mensagens oriundas
%de um mesmo transmissor (de um mesmo tipo) não se sobrepoem. A lista
%conflictList traz os eventos que eventualmente se sobrepoem a message,
%A_RF é o coeficiente de decaimento do sinal e N_RF é a potência do
%ruído.
function SINR = SINR_RF(WPTManager,message,conflictList,A_RF,N_RF,t)
    pos = getCenterPositions(WPTManager.ENV,t);
    d = abs(pos(message.creator+1,:)-pos(message.owner+1,:));
    P = message.options.power/(d^A_RF);
    %calculando a interferência
    I = 0;
    for i=1:length(conflictList)
        %type pode ser usado para diferenciação de canais. O +1 ocorre porque
        %os identificadores se iniciam em 0 e a indexação no matlab se inicia
        %em 1
        if((conflictList(i).options.type==message.options.type)...
        && (conflictList(i).time0<t)&&(conflictList(i).time1>t))
            d = abs(pos(conflictList(i).creator+1,:)...
                -pos(message.owner+1,:));
            I = I + conflictList(i).options.power/(d^A_RF);
        end
    end
    %calculando o SINR
    SINR = P/(I+N_RF);
end