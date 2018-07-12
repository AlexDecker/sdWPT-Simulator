%Objeto retornado pela função Simulate e que recolhe informações de cada
%dispositivo

classdef simulationResults
    
   properties
       running
       device_index %índice do dispositivo ao qual pertencem os dados
       CC %corrente de recarga (dc)
       IE %corrente esperada pelo carregador (para uma recarga ideal)
       DC %corrente de descarga consumida pelo dispositivo
       VB %tensão da bateria
       SOC %state of charge da bateria
       RL %resistência equivalente do dispositivo
   end
   
   methods
      function obj = simulationResults(device_index)
          if (length(device_index)~=1) || (device_index<=0)
              error('simulationResults: parameter error');
          end
          obj.running = true;
          obj.device_index = device_index;
          obj.CC = zeros(2,0);
          obj.IE = zeros(2,0);
          obj.DC = zeros(2,0);
          obj.VB = zeros(2,0);
          obj.SOC = zeros(2,0);
      end
      
      function obj = logCCData(obj,CC,time)
          if obj.running
              aux = [CC;time];
              obj.CC = [obj.CC aux];
          end
      end
      
      function obj = logIEData(obj,IE,time)
          if obj.running
              aux = [IE;time];
              obj.IE = [obj.IE aux];
          end
      end
      
      function obj = logDCData(obj,DC,time)
          if obj.running
              aux = [DC;time];
              obj.DC = [obj.DC aux];
          end
      end
      
      function obj = logVBData(obj,VB,time)
          if obj.running
              aux = [VB;time];
              obj.VB = [obj.VB aux];
          end
      end
      
      function obj = logSOCData(obj,SOC,time)
          if obj.running
              aux = [SOC;time];
              obj.SOC = [obj.SOC aux];
          end
      end
      
      function obj = logRLData(obj,RL,time)
          if obj.running
              aux = [RL;time];
              obj.RL = [obj.RL aux];
          end
      end
      
      function obj = endDataAquisition(obj)
		  if length(obj)~=1
			error('endDataAquisition works with objects, not lists');
		  end
          obj.running = false;
      end
      
      function plotBatteryChart(obj)
          if ~obj.running
              figure;
              hold on;
              yyaxis left
              plot(obj.CC(2,:)/3600,obj.CC(1,:));
              plot(obj.IE(2,:)/3600,obj.IE(1,:));
              plot(obj.DC(2,:)/3600,obj.DC(1,:));
              plot(obj.VB(2,:)/3600,obj.VB(1,:));
              ylabel('(A) / (V)')
              yyaxis right
              plot(obj.SOC(2,:)/3600,obj.SOC(1,:)*100);
              legend('Charge Current','Expected Current',...
                  'Discharge Current','Battery Voltage','SOC');
              xlabel('Time (h)')
              ylabel('(%)')
              title(['Battery Chart for device ', num2str(obj.device_index)]);
          end
      end
      
      function plotBatteryChart2010(obj)
          if ~obj.running
              figure;
              hold on;
              plot(obj.CC(2,:)/3600,obj.CC(1,:),'r');
              plot(obj.IE(2,:)/3600,obj.IE(1,:),'b');
              plot(obj.DC(2,:)/3600,obj.DC(1,:),'g');
              plot(obj.VB(2,:)/3600,obj.VB(1,:),'m');
              xlabel('Time (h)')
              ylabel('(A) / (V)')
              legend('Charge Current','Expected Current',...
                  'Discharge Current','Battery Voltage');
              title(['Battery Chart for device ', num2str(obj.device_index)]);
              
              figure;
              plot(obj.SOC(2,:)/3600,obj.SOC(1,:)*100);
              xlabel('Time (h)')
              ylabel('(%)')
              title(['SOC Chart for device ', num2str(obj.device_index)]);
          end
      end
   end
end
