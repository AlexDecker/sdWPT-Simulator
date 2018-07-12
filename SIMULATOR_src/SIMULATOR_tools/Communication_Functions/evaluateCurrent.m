%evaluate the current in a single receiver

%constants:
%T0: start time, T1: end time, n: time resolution (size of the time vector)
%br: baud rate in bps, dsec: period in which the estimation of the inverse
%laplacian is secure
%M: euler_inversion M param

%vectors (line vectors, one value for each transmitter)
%t0: start transmission time, msg:binary string
%v0: min voltage amplitude, v1: max voltage amplitude, d = offset of the
%wave, f=frequency

%iZ: inverse Z matrix
%id: index of this receiver in all parameter lists
function [I,t] = evaluateCurrent(iZ,id,v0,v1,f,d,T,n,t0,msg,br,dsec,M)
    iz = iZ(id,:);
    I = zeros(1,n);
    t = linspace(T(1),T(2),n);
    for i=1:length(iz)
        I = I + evaluateIAddend(iz(i),v0(i),v1(i),f(i),d(i),T(1),T(2),n,t0(i),...
            msg(i,:),br,dsec,M);
    end
end