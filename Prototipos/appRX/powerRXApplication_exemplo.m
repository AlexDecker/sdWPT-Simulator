%Aplicação exemplo do RX
classdef powerRXApplication_exemplo < powerRXApplication
   properties
   end
   methods
       function obj = powerRXApplication_exemplo(id)
           obj@powerRXApplication(id);%construindo a estrutura referente à superclasse
           obj.APPLICATION_LOG.DATA = 'Exemplo de log';
       end
       
       function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
       end
       
       function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
		   dst = data(1);
		   payload = obj.id;
		   netManager = send(obj,netManager,dst,payload,GlobalTime);%responde ao remetente seu id
       end
       
       function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
       end
       
   end
end