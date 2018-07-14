%abstrai o ambiente em determinado momento.
classdef Environment
    properties
        Coils
        M
        R
        w
    end
    methods
        %inicia a lista de coils e a matriz de acoplamento. R é a lista de
        %resistências ohmicas dos RLCs em ordem, V a lista de tensões das
        %fontes (0 para receptores) e w é a frequência ressonante.
        function obj = Environment(Coils,w,R)
            obj.Coils = Coils;
            obj.w = w;
            obj.R = R;
        end

        function r = check(obj)
            r = true;
            for i = 1:length(obj.Coils)
                r = r && check(obj.Coils(i));
            end
        end

        %Os valores desconhecidos de M devem vir com valor -1.
        function obj = evalM(obj,M)
            for i = 1:length(M)
                for j = 1:length(M)
                    if i==j
                        M(i,j)=0;%self-inductance não é calculada aqui.
                    else
                        if (M(i,j)==-1)
                            if(M(j,i)~=-1)
                                M(i,j)=M(j,i);
                            else
                                disp('Iniciando calculo de acoplamento');
                                M(i,j)=evalMutualInductance(obj.Coils(i), obj.Coils(j));
                            end
                        end
                    end
                end
            end
            obj.M=M;
        end

        function Z = generateZENV(obj)
            if(length(obj.R)~=length(obj.M))
                error('R and M sizes dont agree');
            end
            Z = diag(obj.R)-(1i)*obj.w*obj.M;
        end
    end
end