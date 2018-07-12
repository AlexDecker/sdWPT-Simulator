%Mantém uma lista de eventos que pode ser usada tanto para mensagens entre
%nós quanto para timers dentro de um mesmo nó
classdef networkManager
   properties
       eventList
       np%número de nós passivos. O número de ativos é sempre 1
	   latencia
	   sigma %desvio padrão da latência para enviar mensagens
   end
   methods
       function obj = networkManager(np,latencia,sigma)
           obj.eventList=[];
           obj.np = np;
		   obj.latencia = latencia;
		   obj.sigma = sigma;
       end
       
       function obj = addEvent(obj,isMsg,owner,data,T0,vTime,s)
           time = abs(T0 + normrnd(vTime,s));
           ev = genericEvent(isMsg,time,owner,data);
           obj.eventList = [obj.eventList ev];
           [~, ind] = sort([obj.eventList.time]);
           obj.eventList = obj.eventList(ind);
       end
       
       function obj = send(obj,dest,data,globalTime)
           if((dest>obj.np)||(dest<0))
               warningMsg('(NetworkManager) dest out of bounds');
               return;
           end
           obj = addEvent(obj,true,dest,data,globalTime,obj.latencia,obj.sigma);
       end
       
	   function obj = broadcast(obj,src,data,globalTime)
           if((src>obj.np)||(src<0))
               warningMsg('(NetworkManager) src out of bounds');
               return;
           end
		   for i=0:obj.np
			   if i~=src
			       obj = addEvent(obj,true,i,data,globalTime,obj.latencia,obj.sigma);
			   end
		   end
       end
	   
       function obj = setTimer(obj,myId,globalTime,vTime)
           obj = addEvent(obj,false,myId,[],globalTime,vTime,0);
       end
       
       function resp = emptyEnventList(obj)
           resp = (isempty(obj.eventList));
       end
       
       function [GlobalTime, owner, isMsg, data, obj] = nextEvent(obj)
           ev = obj.eventList(1);
           obj.eventList = obj.eventList(2:end);
           GlobalTime = ev.time;
           owner = ev.owner;
           isMsg = ev.isMsg;
           data = ev.data;
       end
   end
end