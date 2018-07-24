%Mantém um conjunto de listas de eventos que podem ser usadas tanto para mensagens
%entre nós quanto para timers dentro de um mesmo nó
classdef networkManager
    properties(SetAccess = private, GetAccess = public)
        np%número de nós passivos. O número de ativos é sempre 1
        currTime%maior globalTime já visto
        %listas de eventos
        timerEventList%temporizador
        msgRFEventLists%lista de mensagens em RF ordenadas de cada dispositivo
        msgSWIPTEventLists%lista de mensagens em SWIPT ordenadas de cada dispositivo
        newEventId
    end
    methods
        function obj = networkManager(np)
            if(np<=0)
                error('(NetworkManager) np must be greater than 0');
            end
            obj.np = np;
            obj.currTime = 0;
            obj.timerEventList = [];
            obj.msgRFEventLists = [];
            obj.msgSWIPTEventLists = [];
            for(i=0:obj.np)
                obj.msgRFEventLists = [obj.msgRFEventLists,eventList()];
                obj.msgSWIPTEventLists = [obj.msgSWIPTEventLists,eventList()];
            end
            obj.newEventId = 0;
        end

        function obj = setTimer(obj,myId,globalTime,vTime)
            if((myId>obj.np)||(myId<0)||(vTime<=0))
                warningMsg('(NetworkManager) parameter out of bounds');
                return;
            end
            
            %atualização das noções de tempo
            if(globalTime<obj.currTime)
                error('(NetworkManager) invalid globalTime');
            end
            obj.currTime = globalTime;
            
            %criação do novo evento
            event = genericEvent(obj.newEventId,false,globalTime,...
                globalTime+vTime,myId,myId,[],[]);
            obj.newEventId = obj.newEventId + 1;
            
            %encontrando o index que antecederá o novo evento
            if(isempty(obj.timerEventList))
                index = 0;
            else
                if(event.time1<obj.timerEventList(1).time1)
                    index = 0;
                else
                    if(event.time1>=obj.timerEventList(end).time1)
                        index = length(obj.timerEventList);
                    else
                        i0 = 1;
                        i1 = length(obj.timerEventList)-1;
                        while(true)
                            index = floor((i1+i0)/2);
                            if(event.time1>=obj.timerEventList(index).time1)
                                if(event.time1<obj.timerEventList(index+1).time1)
                                    %encontrado o evento mais tardio que precede um evento
                                    %cujo time1 supera o do evento a ser inserido
                                    break;
                                else
                                    %o sucessor ainda não supera o time1 do evento a ser 
                                    %inserido. o espaço de busca agora começa nele
                                    i0 = index+1;
                                end
                            else
                                %esse evento não pode ser um antecessor do novo evento.
                                %o espaço de busca deve terminar em seu antecessor.
                                i1 = index-1;
                            end
                        end
                    end
                end
            end
            
            %inserção do novo evento na lista
            obj.timerEventList = [obj.timerEventList(1:index),event,...
                obj.timerEventList(index+1:end)];
        end

        function resp = emptyEnventList(obj)
            resp = true;
            for(i=0:obj.np)
                %é somado 1 pois os identificadores se iniciam em 0 e a indexação no matlab
                %se inicia em 1
                resp = resp&&noNextEvent(msgRFEventLists(i+1));
                resp = resp&&noNextEvent(msgSWIPTEventLists(i+1));
            end
            resp = (isempty(obj.timerEventList)&&resp);
        end

        function [GlobalTime, conflictingMsgs, event, obj] = nextEvent(obj)
            
            if(isempty(obj.timerEventList))
                event = [];
            else
                event = obj.timerEventList(1);
            end
            
            %oldestTime0 = time 0 mais antigo dentre todos os nextEvents das listas de msg
            oldestTime0 = [];
            
            %busca o próximo exento dentre os de mensagens SWIPT
            for i = 1:length(obj.msgSWIPTEventLists)
                e = nextEvent(obj.msgSWIPTEventLists(i));
                if(~isempty(e))
                    if(isempty(event))
                        event = e;
                        oldestTime0 = e.time0;
                    else
                        if((e.time1<event.time1)||...
                        ((e.time1==event.time1)&&(e.id<event.id)))
                            event = e;
                        end
                        if(oldestTime0 > e.time0)
                            oldestTime0 = e.time0;
                        end
                    end
                end
            end
            
            %busca o próximo exento dentre os de mensagens RF
            for i = 1:length(obj.msgSWIPTEventLists)
                e = nextEvent(obj.msgSWIPTEventLists(i));
                if(~isempty(e))
                    if(isempty(event))
                        event = e;
                        oldestTime0 = e.time0;
                    else
                        if((e.time1<event.time1)||...
                        ((e.time1==event.time1)&&(e.id<event.id)))
                            event = e;
                        end
                        if(oldestTime0 > e.time0)
                            oldestTime0 = e.time0;
                        end
                    end
                end
            end
            
            %garbage collector (eventos anteriores ao nextEvent (msg) de menor time0 não
            %são mais necessários
            if(~isempty(oldestTime0))
                for i=0:obj.np
                    obj.msgSWIPTEventLists(i+1) = cleanUntilT(obj.msgSWIPTEventLists(i+1),...
                        oldestTime0);
                    obj.msgRFEventLists(i+1) = cleanUntilT(obj.msgRFEventLists(i+1),...
                        oldestTime0);
                end
            end
            
            conflictingMsgs = [];
            
            if(~isempty(event))
                if(event.isMsg)
                    %apenas se for uma mensagem é necessário buscar eventos conflitantes
                    switch(event.options.type)
                        case 0
                            %SWIPT
                            %avança o ponteiro na lista de origem (é somado 1 pelo fato do id
                            %se iniciar em 0 e a indexação no matlab se iniciar em 1)
                            [e,obj.msgSWIPTEventLists(event.creator+1)] = extractNextEvent(...
                                obj.msgSWIPTEventLists(event.creator+1));
                            %apenas uma verificação básica
                            if(e.id~=event.id)
                                error('(networkManager) internal error - event id do not match');
                            end
                            %busca os eventos conflitantes
                            for i=1:length(obj.msgSWIPTEventLists)
                                if(i~=event.creator+1)%se não tiver a mesma origem
                                    c = conflictingEvents(obj.msgSWIPTEventLists(i),event);
                                    conflictingMsgs = [conflictingMsgs,c];
                                end
                            end
                        otherwise
                            %RF (sem diferenciação de canais)
                            %avança o ponteiro na lista de origem (é somado 1 pelo fato do id
                            %se iniciar em 0 e a indexação no matlab se iniciar em 1)
                            [e,obj.msgRFEventLists(event.creator+1)] = extractNextEvent(...
                                obj.msgRFEventLists(event.creator+1));
                            %apenas uma verificação básica
                            if(e.id~=event.id)
                                error('(networkManager) internal error - event id do not match');
                            end
                            %busca os eventos conflitantes
                            for i=1:length(obj.msgRFEventLists)
                                if(i~=event.creator+1)%se não tiver a mesma origem
                                    c = conflictingEvents(obj.msgRFEventLists(i),event);
                                    conflictingMsgs = [conflictingMsgs,c];
                                end
                            end
                    end
                else
                    %evento de timer, apenas remova o mesmo da lista
                    obj.timerEventList = obj.timerEventList(2:end);
                end
            end
            
            if(isempty(event))
                GlobalTime = obj.currTime;
            else
                GlobalTime = event.time1;
            end
            
            if(GlobalTime<obj.currTime)
                error('(NetworkManager) Internal error - new GlobalTime value not expected');
            end
        end

        %Network functions

        function [time0,time1,obj] = send(obj,myId,dest,data,dataLen,options,globalTime)
            if((dest>obj.np)||(dest<0)||(myId>obj.np)||(myId<0)||(dataLen<=0)||(myId==dest))
                warningMsg('(NetworkManager) parameter out of bounds');
                return;
            end
            
            %atualização das noções de tempo
            if(globalTime<obj.currTime)
                error('(NetworkManager) invalid globalTime');
            else
                obj.currTime = globalTime;
            end
            
            latency = dataLen/options.baudRate;
            
            switch(options.type)
                case 0
                    %é somado 1 pois os identificadores se iniciam em 0 e no matlab a
                    %indexação se inicia em 1
                    time0 = mostLateTime(obj.msgSWIPTEventLists(myId+1));
                    %não comece uma nova transmissão enquanto o transmissor estiver ocupado
                    if(time0<globalTime)
                        time0 = globalTime;
                    end
                    time1 = time0+latency;
                    %cria o novo evento
                    event = genericEvent(obj.newEventId,true,time0,time1,...
                        dest,myId,data,options);
                    %adiciona o novo evento na fila de saída do transmissor correspondente
                    obj.msgSWIPTEventLists(myId+1) = addEvent(...
                        obj.msgSWIPTEventLists(myId+1),event);
                otherwise
                    %é somado 1 pois os identificadores se iniciam em 0 e no matlab a
                    %indexação se inicia em 1
                    time0 = mostLateTime(obj.msgRFEventLists(myId+1));
                    %não comece uma nova transmissão enquanto o transmissor estiver ocupado
                    if(time0<globalTime)
                        time0 = globalTime;
                    end
                    time1 = time0+latency;
                    %cria o novo evento
                    event = genericEvent(obj.newEventId,true,time0,time1,...
                        dest,myId,data,options);
                    %adiciona o novo evento na fila de saída do transmissor correspondente
                    obj.msgRFEventLists(myId+1) = addEvent(...
                        obj.msgRFEventLists(myId+1),event);
            end
            %atualiza o id do próximo evento a ser criado
            obj.newEventId = obj.newEventId + 1;
        end

        function obj = broadcast(obj,src,data,dataLen,options,globalTime)
            if((src>obj.np)||(src<0)||(dataLen<=0))
                warningMsg('(NetworkManager) parameter out of bounds');
                return;
            end
            
            %atualização das noções de tempo
            if(globalTime<obj.currTime)
                error('(NetworkManager) invalid globalTime');
            else
                obj.currTime = globalTime;
            end
            
            latency = dataLen/options.baudRate;
            
            %envia uma mensagem para cada dispositivo excetuando o transmissor
            for i=0:obj.np
                if(i~=src)
                    switch(options.type)
                        case 0
                            %é somado 1 pois os identificadores se iniciam em 0 e no matlab a
                            %indexação se inicia em 1
                            time0 = mostLateTime(obj.msgSWIPTEventLists(myId+1));
                            %não comece uma nova transmissão enquanto o transmissor estiver
                            %ocupado
                            if(time0<globalTime)
                                time0 = globalTime;
                            end
                            %cria o evento
                            event = genericEvent(obj.newEventId,true,time0,time0+...
                                latency,i,myId,data,options);
                            %adiciona o novo evento na fila de saída do transmissor
                            %correspondente
                            obj.msgSWIPTEventLists(myId+1) = addEvent(...
                                obj.msgSWIPTEventLists(myId+1),event);
                        otherwise
                            %é somado 1 pois os identificadores se iniciam em 0 e no matlab a
                            %indexação se inicia em 1
                            time0 = mostLateTime(obj.msgRFEventLists(myId+1));
                            %não comece uma nova transmissão enquanto o transmissor estiver
                            %ocupado
                            if(time0<globalTime)
                                time0 = globalTime;
                            end
                            %cria o evento
                            event = genericEvent(obj.newEventId,true,time0,time0+...
                                latency,i,myId,data,options);
                            %adiciona o novo evento na fila de saída do transmissor
                            %correspondente
                            obj.msgRFEventLists(myId+1) = addEvent(...
                                obj.msgRFEventLists(myId+1),event);
                    end
                    obj.newEventId = obj.newEventId + 1;
                end
            end
        end
    end
end