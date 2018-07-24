classdef eventList
    properties(SetAccess = private, GetAccess = public)
        evList %lista de eventos propriamente dita
        pointer %aponta para o próximo evento
    end
    methods(Access=public)
        function obj = eventList()
            obj.evList = [];
            obj.pointer = 0;
        end
        function r = noNextEvent(obj)
            r = (obj.pointer==0);
        end
        %retorna o próximo evento sem extrai-lo
        function e = nextEvent(obj)
            if(obj.pointer==0)
                e = [];
            else
                e = obj.evList(obj.pointer);
            end
        end
        %retorna o próximo evento extraindo o mesmo
        function [e,obj] = extractNextEvent(obj)
            if(obj.pointer==0)
                e = [];
            else
                e = obj.evList(obj.pointer);
                if(obj.pointer==length(obj.evList))
                    obj.pointer = 0;
                else
                    obj.pointer = obj.pointer + 1;
                end
            end
        end
        %retorna o momento mais tardio contemplado por algum evento
        function r = mostLateTime(obj)
            if(isempty(obj.evList))
                r = 0;
            else
                r = obj.evList(end).time1;
            end
        end
        function obj = addEvent(obj,event)
            if(event.time0<mostLateTime(obj))
                error('(eventList) Error trying to insert new event');
            end
            obj.evList = [obj.evList,event];
            if(obj.pointer==0)
                obj.pointer = length(obj.evList);
            end
        end
        %remove todos os eventos antigos o bastante para não terem contato
        %com o momento t
        function obj = cleanUntilT(obj,t)%TODO: busca binária aqui
            if(obj.pointer>1)
                i = floor(find(obj,1,obj.pointer-1,t));
                if(i==0)
                    if(obj.evList(obj.pointer-1).time1<t)
                        obj.evList = obj.evList(obj.pointer:end);
                        obj.pointer = 1;
                    end
                else
                    obj.evList = obj.evList(i:end);
                    obj.pointer = obj.pointer - i + 1;
                end
            end
        end
        function c = conflictingEvents(obj,event)
            if(~isempty(obj.evList))
                i0 = ceil(find(obj,1,length(obj.evList),event.time0));
                if(i0==0)
                    i1 = floor(find(obj,1,length(obj.evList),event.time1));
                    if(i1==0)
                        if((event.time0<=obj.evList(1).time0)&&...
                        (event.time1>=obj.evList(end).time1))
                            c = obj.evList;
                        else
                            c = [];
                        end
                    else
                        c = obj.evList(1:i1);
                    end
                else
                    i1 = floor(find(obj,i0,length(obj.evList),event.time1));
                    if(i1==0)
                        c = obj.evList(i0:end);
                    else
                        c = obj.evList(i0:i1);
                    end
                end
            else
                c = [];
            end
        end
    end
    methods(Access=private)
        %verifica se o momento t está dentro da linha do tempo entre
        %os eventos de index i0 e i1
        function r = isInside(obj,i0,i1,t)
            r = (obj.evList(i0).time0<t)&&(obj.evList(i1).time1>t);
        end
        %verifica no intervalo de qual evento está o momento t. Se 
        %estiver entre intervalos, retorna um valor fracionado. Se não 
        %estiver em intervalo algum, retorna 0.
        function i = find(obj,i0,i1,t)
            if(isempty(obj.evList))
                i = 0;
            else
                if(~isInside(obj,1,length(obj.evList),t))
                    %se não estiver entre os extremos
                    i = 0;
                else
                    while(true)
                        if(i0==i1)
                            %caso trivial
                            i = i0;
                            break;
                        end
                        if(isInside(obj,i0,floor((i0+i1)/2),t))
                            %ou está na primeira metade
                            i1 = floor((i0+i1)/2);
                        else
                            if(isInside(obj,ceil((i0+i1)/2),i1,t))
                                %ou na segunda
                                i0 = ceil((i0+i1)/2);
                            else
                                %ou entre as duas
                                i = (i0+i1)/2;
                                break;
                            end
                        end
                    end
                end
            end
        end
    end
end