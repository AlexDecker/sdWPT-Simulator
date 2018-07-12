%Evento genérico para o network manager
classdef genericEvent
   properties
       isMsg%true para mensagem
       time%tempo em que o evento é disparado
       owner%para quem será este evento
       data%eventuais dados (para quando for uma mensagem)
   end
   methods
       function obj = genericEvent(isMsg,time,owner,data)
           obj.isMsg=isMsg;
           obj.time=time;
           obj.owner=owner;
           obj.data=data;
       end
   end
end