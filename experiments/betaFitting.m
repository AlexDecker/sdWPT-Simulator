%get the best alpha, gamma parammeters for beta distribution in order to fit the data
%Also returns the D statistic of kolmogorov-smirnov test
function [alpha, beta, bestD] = betaFitting(data,num)
    bestD = inf;
    alpha = NaN;
    beta = NaN;
    data = sort(data);
    for a=linspace(0,10,num)
        for b=linspace(0,10,num)
            D = ksTest(data, a, b, bestD);
            if D<bestD
                bestD = D;
                alpha = a;
                beta = b;
            end
        end
    end
end
