%fontes: Richard Dengler (http://arxiv.org/abs/1204.1486) e Wyatt Felt
%(adaptado do código NeumannSelfInductance, de 2015)
function I = neumannIntegral2010(obj1, obj2, m0,Y)
    %tratamento de alguns parâmetros
    if m0==-1%valor default para a constante de permeabilidade magnética do meio
        m0 = 4*pi*1e-7;
    end
    if obj1.r~=obj2.r
        a  = min(obj1.r,obj2.r);%default, o problema da divisão por zero da self inductance não é aplicável
    else
        a  = obj1.r;
    end
    
    [ds1,centers1] = generateSegments(obj1);
    [ds2,centers2] = generateSegments(obj2);
    
        function [ds,centers] = generateSegments(obj)
            ds = zeros((length(obj.z)-1),3);
            centers = zeros((length(obj.z)-1),3);

            for j = 1:(length(obj.z)-1)
                ds(j,:) = [obj.x(j+1)-obj.x(j), obj.y(j+1)-obj.y(j), obj.z(j+1)-obj.z(j)];
                xmean = mean(obj.x(j:j+1));
                ymean = mean(obj.y(j:j+1));
                zmean = mean(obj.z(j:j+1));
                centers(j,:) = [xmean, ymean, zmean];
            end
        end
    
    L_local = zeros(length(ds1),1);
    
    for i = 1:length(ds1)
        for j = i:length(ds2) 
            R = norm(centers1(i,:)-centers2(j,:));
            if R > a/2 %if the distance between the segments is greater than half a wire radius
                dotproduct = ds1(i,:)*ds2(j,:)';
                L_i_with_j = dotproduct/R; %calculate the local mutual inductance term
                L_local(i) = L_local(i) + 2*L_i_with_j; 
            end
        end
    end
    
    Lsum = abs(sum(L_local));
    I = m0/pi*((1/4*Lsum) + 1/2*obj1.comprimento*Y);
end