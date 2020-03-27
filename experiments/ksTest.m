%Requires data to be sorted, (a,b) valid for gamma distribution. cutOffD is a value of D
%for which the test does not matter anymore (because it wont be good enough). Use inf if
%you dont want to use this optimization
function D = ksTest(data,a,b,cutOffD)
    n = length(data);
    D = 0;%maximal distance between the cumulative distributions so far
    for i=1:n
        F = i/n;%proportion of samples less or equal than data(i)
        Fb = gammainc(a,b*data(i))/gamma(a);%reference value of gamma
        if abs(F-Fb)>cutOffD
            D = inf;
            break;
        else
            if abs(F-Fb)>D
                D = abs(F-Fb);
            end
        end
    end
end
