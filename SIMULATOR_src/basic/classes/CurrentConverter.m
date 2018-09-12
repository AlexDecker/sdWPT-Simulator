%Para construir o objeto, crie um arquivo txt em que cada
%linha aparece na forma "%f %f\n", que correspondem respectivamente a
%um valor de corrente (A) e um valor de eficiência de conversão (entre 0 e 1).
%Os valores de corrente devem ser crescentes. Insira o arquivo com os dados na pasta
%"conversor_data" e apenas informe o nome do arquivo ao construtor do objeto,
%sem informar o caminho.

classdef CurrentConverter < LookupTable
    
   properties
   end
   
   methods
      function obj = CurrentConverter(file,plotData)
          obj@LookupTable(['converter_data/',file],false);
          
          if ~check(obj)
              error('CurrentConverter: error: informed data is incompatible with the model');
          end
          
          if plotData
              ccPlot(obj);
          end
      end
      
      %a função abaixo utiliza interpolação linear entre dois pontos
      %conhecidos para descobrir o desconhecido.
      function DC = getDCFromAC(obj,AC)
          DC = getYFromX(obj,abs(AC))*abs(AC);
      end
      
      function flag = check(obj)
          flag = true;
          if length(obj.table)<2
              flag = false;
          end
          if ~flag%só é necessário verificar se já não tiver concluído que
              %está errado
              
              for i=1:length(obj.table)
                if((obj.table(i,2)<0) && (obj.table(i,2)>1))
                    flag=false;
                    break;
                end
              end
          end
      end
      
      function ccPlot(obj)
          figure;
          plot(obj.table(:,1),obj.table(:,2)*100);
          xlabel('(A)');
          ylabel('eff (%)');
      end
   end
end
