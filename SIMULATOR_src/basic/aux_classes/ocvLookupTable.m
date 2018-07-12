%Dicionário que associa open-circuit voltage (OCV) a um dado valor de
%state-of-charge (SOC). Essa função define grande parte do comportamento de
%uma bateria. Para construir o objeto, crie um arquivo txt em que cada
%linha aparece na forma "%f %f\n", que correspondem respectivamente a
%um valor de SOC (entre 0 e 1) e um valor de OCV (em volts). O primeiro
%valor de SOC deve ser 0 e o último 1 necessariamente. Os valores de SOC
%devem ser crescentes. Insira o arquivo com os dados na pasta
%"battery_data" e apenas informe o nome do arquivo ao construtor do objeto,
%sem informar o caminho.

classdef ocvLookupTable
    
   properties
       table %tabela nx2 que associa valores de SOC a valores de OCV
   end
   
   methods
      function obj = ocvLookupTable(file,plotOCV)
          fileID = fopen(['battery_data/',file],'r');
          formatSpec = '%f %f';
          A = fscanf(fileID,formatSpec);
          fclose(fileID);
          
          if isempty(A)
              error('ocvLookupTable: error while loading data');
          end
          
          for x=1:length(A)/2
              obj.table(x,1) = A(2*(x-1)+1);
              obj.table(x,2) = A(2*(x-1)+2);
          end
          
          if isIrregular(obj)
              error('ocvLookupTable: error: battery data is incompatible with the model');
          end
          
          if plotOCV
              ocvPlot(obj);
          end
      end
      
      %a função abaixo utiliza interpolação linear entre dois pontos
      %conhecidos para descobrir o desconhecido.
      function OCV = getOCVFromSOC(obj,SOC)
          if((SOC>1)||(SOC<0))
              error('ocvLookupTable: error: informed SOC is out of bounds');
          end
          if SOC==1
              OCV = obj.table(end,2);
          else
              %busca os indices da tabela que são maiores que o valor de
              %referência
              i = find(obj.table(:,1)>SOC);
              %menor indice com SOC maior que a referência
              Iceil = i(1);
              %maior índice com SOC menor ou igual à referência
              Ifloor = i(1)-1;
              
              %interpolação linear
              SOCceil = obj.table(Iceil,1);
              SOCfloor = obj.table(Ifloor,1);
              OCVceil = obj.table(Iceil,2);
              OCVfloor = obj.table(Ifloor,2);
              factor = (SOC-SOCfloor)/(SOCceil-SOCfloor);
              OCV = factor*OCVceil + (1-factor)*OCVfloor;
          end
      end
      
      function flag = isIrregular(obj)
          flag = false;
          if length(obj.table)<2
              flag = true;
          end
          if obj.table(1,1)~=0
              flag=true;
          end
          if obj.table(end,1)~=1
              flag=true;
          end
          if ~flag%só é necessário verificar se já não tiver concluído que
              %está errado
              for i=2:length(obj.table)
                if(obj.table(i-1,1)>=obj.table(i,1))
                    flag=true;
                    break;
                end
                if(obj.table(i-1,2)>obj.table(i,2))
                    warningMsg('OCV is usually a monotonically increasing function');
                end
              end
          end
      end
      
      function ocvPlot(obj)
          figure;
          plot(obj.table(:,1)*100,obj.table(:,2));
          xlabel('SOC (%)');
          ylabel('OCV (V)');
      end
   end
end
