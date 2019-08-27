%Dicionário que associa dois conjuntos de valores numéricos quaisquer.
%Para construir o objeto, crie um arquivo txt em que cada
%linha aparece na forma "%f %f\n", que correspondem respectivamente a
%um valor da abcissa e um valor da ordenada. Os valores da abcissa
%devem ser crescentes.

classdef LookupTable
    
   properties
       table %tabela nx2 que associa valores de SOC a valores de OCV
   end
   
   methods
      function obj = LookupTable(file,plotData)
          fileID = fopen(file,'r');
          formatSpec = '%f %f';
          A = fscanf(fileID,formatSpec);
          fclose(fileID);
          
          if isempty(A)
              error('LookupTable: error while loading data');
          end
          
          for x=1:length(A)/2
              obj.table(x,1) = A(2*(x-1)+1);
              obj.table(x,2) = A(2*(x-1)+2);
          end
          
          if ~check(obj)
              error('LookupTable: error: the data informed is invalid');
          end
          
          if plotData
              plotDataSet(obj);
          end
      end
      
      %a função abaixo utiliza interpolação linear entre dois pontos
      %conhecidos para descobrir o desconhecido.
      function Y = getYFromX(obj,X)
          if X>=obj.table(end,1)
              Y = obj.table(end,2);
          else
              %busca os indices da tabela que são maiores que o valor de
              %referência
              i = find(obj.table(:,1)>X);
              %menor indice com SOC maior que a referência
              Iceil = i(1);
              %maior índice com SOC menor ou igual à referência
              Ifloor = i(1)-1;
              
              %interpolação linear
              Xceil = obj.table(Iceil,1);
              Xfloor = obj.table(Ifloor,1);
              Yceil = obj.table(Iceil,2);
              Yfloor = obj.table(Ifloor,2);
              factor = (X-Xfloor)/(Xceil-Xfloor);
              Y = factor*Yceil + (1-factor)*Yfloor;
          end
          
      end
      
      function flag = check(obj)
          flag = (length(obj.table)>=2);
      end
      
      function plotDataSet(obj)
          figure;
          plot(obj.table(:,1),obj.table(:,2));
          xlabel('X');
          ylabel('Y');
      end
   end
end
