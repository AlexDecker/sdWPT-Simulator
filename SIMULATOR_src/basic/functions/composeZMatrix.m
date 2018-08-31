%Adiciona mais resistência e capacitância ao sistema considerando um modelo RLC multifilar.
%Z0 - Matriz de impedância inicial
%Z_group - Impedância elétrica (apenas resistência e reatância capacitiva) a ser adicionada em
%cada grupo (cada agrupamento de anéis RLC, que constitui cada circuito em si)
%groupMarking: groupMarking(i,j) = {1 caso i pertença ao grupo j e 0 caso contrário}

function Z = composeZMatrix(Z0,Z_group,groupMarking)

	Z = Z0;
    
    s = size(groupMarking);
    n = s(1);
    n_groups = s(2);
	
	%matriz em que cada linha é o produto do Z no circuito correspondente por [1 1 ... 1]
	Z_aux = ones(n)*diag(groupMarking*Z_group);
	
    for i=1:n_groups
        %cria uma matrix diagonal de bloco em que cada bloco relaciona elementos de
        %um mesmo grupo
        Z = Z + diag(groupMarking(:,i))*Z_aux*diag(groupMarking(:,i));
    end
end
