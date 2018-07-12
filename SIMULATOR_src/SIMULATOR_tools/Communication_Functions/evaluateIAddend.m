%evaluate the current produced in a single receiver by a single transmitter
%with a single message.

%T0: start time, T1: end time, n: time resolution (size of the time vector)
%t0: start transmission time, msg:binary string, br: baud rate in bps
%Z: value from the inverse Z Matrix that corresponds to these receiver and
%transmitter.
%v0: min voltage amplitude, v1: max voltage amplitude, d = offset of the
%wave, f=frequency
%dsec: period in which the estimation of the pulse is secure
function Ia = evaluateIAddend(Z,v0,v1,f,d,T0,T1,n,t0,msg,br,dsec,M)
    period = (T1-T0)/n;
    T = linspace(T0,T1,n);
    Ia = generateAndSolveBaseSignal(v0, f, d, Z, T);
    Id = zeros(length(msg),n);
    if(ceil(dsec/period)<=n)
        tic;
        t = T(1:ceil(dsec/period));
        parfor (i=1:length(msg),M)
            disp(['Starting bit|' num2str(i) '| of |' num2str(length(msg)) '|']);
            if(msg(i)~=48)
                center = t0+(i-1)/br+1/(2*br);%central point of this bit
                begin = center-dsec/2;
                Ip = generateAndSolvePulseSignal(v0,v1,f,d,br,center,Z,t+begin);
                index = ceil((begin - T0)/period);
                val = zeros(1,n);
                for j = 1:length(Ip)
                    if (index>=1)&&(index<=length(Ia))
                        val(index) = Ip(j);
                    end
                    index=index+1;
                end
                Id(i,:)=val;
            end
        end
        toc;
            ID = zeros(1,n);
        for i=1:length(ID)
            ID(i) = ID(i)+sum(Id(:,i));
        end
    %     hold on;
    %     plot(T,Ia);
    %     plot(T,ID);
    %     plot(T,Ia+ID);
    %     axis([.004112959413417478 .004335181635639699 -0.15 0.15])

        Ia = Ia+ID;
    else
        disp('No data will be transmitted.');
    end
end