clear;
globalTime = 0;
np = 3;
network = networkManager(np);

options.type = 0;
options.baudRate = 1000;

eventList = [];
pastEvents=[];
newEventId = 0;

while true
    for i=0:np
        myId = i;
        owner = rem(myId+1,np+1);
        dataLen = round(rand*900)+100;
        vTime = rand;
        
        if(rand<0.15)
            [time0,time1,network] = send(network,myId,owner,[],dataLen,options,globalTime);
            eventList = [eventList,genericEvent(newEventId,true,time0,...
                time1,owner,myId,[],options)];
            newEventId = newEventId + 1;
        end
        
        if(rand<0.1)
            network = setTimer(network,myId,globalTime,vTime);
            eventList = [eventList,genericEvent(newEventId,false,globalTime,...
                globalTime+vTime,owner,myId,[],[])];
            newEventId = newEventId + 1;
        end
    end
    
    event1 = [];
    for i=1:length(eventList)
        if(eventList(i).time1>=globalTime)
            %se não tiver passado ainda
            past = false;
            for j=1:length(pastEvents)
                if(pastEvents(j).id==eventList(i).id)
                    past = true;
                    break;
                end
            end
            if(~past)
                %se não tiver sido escolhido ainda, escolha o de menor time1
                if(isempty(event1))
                    event1 = eventList(i);
                else
                    if(eventList(i).time1<event1.time1)
                        event1 = eventList(i);
                    end
                end
            end
        end
    end
    
    pastEvents = [pastEvents,event1];
    
    conflictingMsgs1 = [];
    if(length(event1)==1)
        if(event1.isMsg)
            for i=1:length(eventList)
                if((eventList(i).id~=event1.id)&&(eventList(i).isMsg))
                    if(((eventList(i).time0<=event1.time0)...
                    &&(eventList(i).time1>event1.time0))...
                    ||((eventList(i).time0>event1.time0)...
                    &&(eventList(i).time0<event1.time1)))
                        conflictingMsgs1 = [conflictingMsgs1,eventList(i)];
                    end
                end
            end
        end
    end
    
    [globalTime, c, event2, network] = nextEvent(network);
    conflictingMsgs2 = [];
    for i=1:length(c)
        if(~isempty(c(i)))
            conflictingMsgs2 = [conflictingMsgs2,c(i).events];
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
                            error('ConflictingMsgs must have the same elements');
                        end
                    end
                    disp('OK');
                end
            end
        end
    end
    len = length(network.timerEventList);
    for i=1:length(network.msgRFEventLists)
        len = len + length(network.msgRFEventLists(i).evList);
        len = len + length(network.msgSWIPTEventLists(i).evList);
    end
    disp(['GlobalTime: ',num2str(globalTime),' | keptEvents: ',num2str(len),...
        ' | #events: ',num2str(length(eventList))]);
end