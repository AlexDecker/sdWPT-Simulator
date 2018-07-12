%O cálculo da tensão da bateria é feito conforme o modelo linear com
%auxílio de uma tabela look up, de acordo com o artigo "An Overview of
%Generic Battery Models", de Ala Al-Haj Hussein et al. O modelo em que se
%aproxima a bateria a um resistor variável foi retirado de "Analysis and 
%parameters optimization of a contactless IPT system for EV charger" de
%Chen et al.
%O procedimento de carregamento desta bateria foi baseado na tecnologia
%Li-Ion, popular dentre aparelhos móveis modernos.
%O procedimento de recarga em si é dividido em duas fases. A primeira
%perdura até o momento em que o SOC atinge o limite fase1Limit (tipicamente
%70%) e é caracterizado por manter a corrente de recarga constante. A fase
%2,por sua vez, mantém a tensão constante enquanto a corrente decai até seu
%limite mínimo, quando a bateria finalmente atinge seu limite superior.
%Mais informações: 
%http://batteryuniversity.com/learn/article/charging_lithium_ion_batteries
%(acessado em 15/02/18)

classdef linearBattery
    
   properties
       Rc %resistência interna da bateria durante a carga (ohm). -1 para ser calculado automaticamente
       Rd %resistência interna da bateria durante a descarga (ohm). -1 para ser calculado automaticamente
       
       ocvTable %tabela OCVxSOC
       
       Q %carga atual
       Qmax %carga máxima (As)
       
       Rmax %maior resistência equivalente que a bateria pode assumir
       
       fase1Limit %SOC a partir do qual a fase 2 se inicia
       limitToBegin %SOC a partir do qual a bateria é recarregada
       constantCurrent_min %corrente mínima de recarga da fase 1
       constantCurrent_max %corrente máxima de recarga da fase 1
       constantVoltage %tensão de recarga da fase 2
       
       fase %1, 2 ou 3
   end
   
   methods
      function obj = linearBattery(file,Rc,Rd,Q0,Qmax,Rmax,fase1Limit,...
              constantCurrent_min,constantCurrent_max,constantVoltage,...
              limitToBegin, plotOCV)
          obj.ocvTable = ocvLookupTable(file,plotOCV);
          obj.Rd = Rd;
          obj.Q = Q0;
          obj.Qmax = Qmax;
          obj.Rmax = Rmax;
          obj.fase1Limit = fase1Limit;
          obj.constantCurrent_min = constantCurrent_min;
          obj.constantCurrent_max = constantCurrent_max;
          obj.constantVoltage = constantVoltage;
          obj.limitToBegin = limitToBegin;
          if((Q0<0)||(Q0>Qmax)||(Rmax<=0)||...
                  (fase1Limit<=0)||(fase1Limit>=1)||...
                  (constantCurrent_min<=0)||(constantCurrent_max<constantCurrent_min)||...
                  (limitToBegin<fase1Limit)||(limitToBegin>1)||...
                  (constantVoltage<=0))
              error('linearBattery: parameter error');
          end
          if(Rc<=0)
              if(Rc==-1)%calculado de forma a coincidir as curvas das duas fases
                 obj.Rc = (constantVoltage-getOCVFromSOC(obj.ocvTable,fase1Limit))/constantCurrent_max; 
              else
                 error('linearBattery: parameter error'); 
              end
          else
              obj.Rc = Rc;
          end
          
          if(Rd<=0)
              if(Rd==-1)%calculado de forma a coincidir as curvas das duas fases
                 obj.Rd = obj.Rc;
              else
                 error('linearBattery: parameter error'); 
              end
          else
              obj.Rd = Rd;
          end
          
          SOC = getSOC(obj);
          if SOC<limitToBegin
              if SOC<fase1Limit
                obj.fase=1;
              else
                  obj.fase=2;
              end
          else
              obj.fase=3;
          end
      end
      
      %verifica se os parâmetros estão em ordem
      function r=check(obj)
          r = (obj.Q>=0)&&(obj.Q<=obj.Qmax)&&(obj.Rmax>0)&&...
                  (obj.fase1Limit>0)&&(obj.fase1Limit<1)&&...
                  (obj.constantCurrent_min>0)&&...
                  (obj.constantCurrent_max>obj.constantCurrent_min)&&...
                  (obj.limitToBegin>obj.fase1Limit)&&...
                  (obj.limitToBegin<1)&&...
                  (obj.constantVoltage>0)&&...
                  (obj.Rc>0)&&(obj.Rd>0);
      end
      
      function SOC = getSOC(obj)
          SOC = obj.Q/obj.Qmax;
      end
      
      function [obj,fase] = getFase(obj)
          SOC = getSOC(obj);
          if SOC<obj.fase1Limit
              fase=1;
          else
              if SOC<obj.limitToBegin
                fase=2;
              else
                  if SOC==1
                      fase=3;
                  else
                      if obj.fase~=3
                          fase=2;
                      else
                          fase = 3;
                      end
                  end
              end
          end
          obj.fase=fase;
      end
      
      %retorna a corrente esperada de acordo com o procedimento de
      %carregamento de uma li-ion
      function [obj,I] = expectedCurrent(obj)
          [obj,f] = getFase(obj);
          if f==1
              I = obj.constantCurrent_max;%o máximo é o desejado
          else
              if f==2
                  SOC = getSOC(obj);
                  I = (obj.constantVoltage-getOCVFromSOC(obj.ocvTable,SOC))/obj.Rc;
              else% fase 3
                  I=0;
              end
          end
      end
      
      function V = getVBatt(obj,current)
          SOC = getSOC(obj);
          if(current<0)
              R=obj.Rd;
          else
              R=obj.Rc;
          end
          OCV = getOCVFromSOC(obj.ocvTable,SOC);
          V = OCV + R*current;
      end
      
      %obtém a tensão da bateria quando há um dispositivo atrelado a ela.
      %err é o erro percentual máximo admitido para a aproximação.
      %charge_current deve estar em ampères e discharge_power, em Watts.
      function V = getVBattWithDischarge(obj,charge_current,discharge_power,err)
          if((err<=0)||(err>1))
              error('linearBattery: parameter error at getVBattWithDischarge');
          end 
          discharge_current = 0;
          V0 = 0;
          %obtendo a corrente de descarga
          while true
              V = getVBatt(obj,charge_current-discharge_current);
              if abs((V-V0)/V)<err %se o erro for menor que 5%
                  break;
              end
              discharge_current = discharge_power/V;
              V0 = V;
          end
      end
      
      %atualiza carga baseado na corrente (A) fornecida pelo carregador e na
      %corrente (A) consumida pelo dispositivo. A variação de tempo deve
      %ser em segundos.
      function [obj,DEVICE_DATA] = updateCharge(obj,charge_current,discharge_current,timeVariation,DEVICE_DATA,time)
          [obj,Fase] = getFase(obj);
          current = charge_current-discharge_current;
          if((current<obj.constantCurrent_min)&&(Fase==1))
			  %se não tiver definido uma tensão válida no init
              if time>0 
                warningMsg('Current is not enough to charge the battery.');
              end
          else
              obj.Q = obj.Q+current*timeVariation;
              if obj.Q>obj.Qmax%limitando o SOC em 100%
                  obj.Q=obj.Qmax;
              end
			  %log-------------------
			  DEVICE_DATA = logSOCData(DEVICE_DATA,getSOC(obj),time);
			  %log-------------------
          end
      end
   end
end