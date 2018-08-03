clear;
globalTime = 0;

options.type = 0;
options.baudRate = 1000;

eventList1 = [];
eventList2 = [eventList(),eventList()];
pastEvents=[];
newEventId = 0;

while true
    for i=1:2
        if(rand<0.2)
            myId = i;
            owner = i+1;
            dataLen = round(rand*900)+100;
            latency = dataLen/options.baudRate;
            %é somado 1 pois os identificadores se iniciam em 0 e no matlab a
            %indexação se inicia em 1
            time0 = mostLateTime(eventList2(i));
            %não comece uma nova transmissão enquanto o transmissor estiver ocupado
            if(time0<globalTime)
                time0 = globalTime;
            end
            time1 = time0+latency;
            %cria o novo evento
            event = genericEvent(newEventId,true,time0,time1,owner,myId,...
                [],options);
            
            eventList1 = [eventList1,event];
            %adiciona o novo evento na fila de saída do transmissor correspondente
            eventList2(i) = addEvent(eventList2(i), event);
            
            newEventId = newEventId + 1;
        end
    end
    
    event1 = [];
    for i=1:length(eventList1)
        if(eventList1(i).time1>=globalTime)
            %se não tiver passado ainda
            past = false;
            for j=1:length(pastEvents)
                if(pastEvents(j).id==eventList1(i).id)
                    past = true;
                    break;
                end
            end
            if(~past)
                %se não tiver sido escolhido ainda, escolha o de menor time1
                if(isempty(event1))
                    event1 = eventList1(i);
                else
                    if(eventList1(i).time1<event1.time1)
                        event1 = eventList1(i);
                    end
                end
            end
        end
    end
    
    pastEvents = [pastEvents,event1];
    
    conflictingMsgs1 = [];
    if(length(event1)==1)
        if(event1.isMsg)
            for i=1:length(eventList1)
                if((eventList1(i).id~=event1.id)&&(eventList1(i).isMsg))
                    if(((eventList1(i).time0<=event1.time0)...
                    &&(eventList1(i).time1>event1.time0))...
                    ||((eventList1(i).time0>event1.time0)...
                    &&(eventList1(i).time0<event1.time1)))
                        conflictingMsgs1 = [conflictingMsgs1,eventList1(i)];
                    end
                end
            end
        end
    end
    
    %buscando o next event2
    e1 = nextEvent(eventList2(1));
    e2 = nextEvent(eventList2(2));
    if(isempty(e1))
        event2 = e2;
        [e, eventList2(2)] = extractNextEvent(eventList2(2));
    else
        if(isempty(e2))
            event2 = e1;
            [e, eventList2(1)] = extractNextEvent(eventList2(1));
        else
            if((e1.time1<e2.time1)||((e1.time1==e2.time1)&&(e1.id<e2.id)))
                event2 = e1;
                [e, eventList2(1)] = extractNextEvent(eventList2(1));
            else
                event2 = e2;
                [e, eventList2(2)] = extractNextEvent(eventList2(2));
            end
        end
    end
    
    if((~isempty(e))&&(~isempty(event2)))
        if(e.id~=event2.id)
            error('Internal error.');
        end
        if(e.creator==1)
            conflictingMsgs2 = conflictingEvents(eventList2(2),event2);
        else
            conflictingMsgs2 = conflictingEvents(eventList2(1),event2);
        end
    else
        conflictingMsgs2 = [];
        if(length(e)+length(event2)~=0)
            error('Internal error 2.');
        end
    end
    
    if(~isempty(event2))
        if(event2.time1<globalTime)
            error('Wrong globalTime');
        else
            globalTime = event2.time1;
        end
    end
    
    if(length(event1)~=length(event2))
        error('Events have different lenghts');
    else
        if(isempty(event1))
            if((~isempty(conflictingMsgs1))||(~isempty(conflictingMsgs2)))
                error('ConflictingMsgs must be empty');
            else
                disp('OK');
            end
        else
            if(event1.id~=event2.id)
                error('Different next msgs');
            else
                if(length(conflictingMsgs1)~=length(conflictingMsgs2)~=0)
                    disp('conflictingMsgs1:');
                    for i=1:length(conflictingMsgs1)
                        conflictingMsgs1(i)
                    end
                    disp('conflictingMsgs2:');
                    for i=1:length(conflictingMsgs2)
                        conflictingMsgs2(i)
                    end
                    event1
                    event2
                    error('ConflictingMsgs length must be the same');
                else
                    for i=1:length(conflictingMsgs1)
                        found=false;
                        for j=1:length(conflictingMsgs2)
                            if(conflictingMsgs1(i).id==conflictingMsgs2(j).id)
                                found=true;
                                break;
                            end
                        end
                        if(~found)
                            disp('conflictingMsgs1:');
                            for i=1:length(conflictingMsgs1)
                                conflictingMsgs1(i)
                            end
                            disp('conflictingMsgs2:');
                            for i=1:length(conflictingMsgs2)
                                conflictingMsgs2(i)
                            end
                            event1
                            event2
                            error('ConflictingMsgs must have the same elements');
                        end
                    end
                    disp('OK');
                end
            end
        end
    end
    disp(['GlobalTime: ',num2str(globalTime),' | eventList2: ',...
        num2str(length(eventList2(1).evList)+length(eventList2(2).evList))]);
end