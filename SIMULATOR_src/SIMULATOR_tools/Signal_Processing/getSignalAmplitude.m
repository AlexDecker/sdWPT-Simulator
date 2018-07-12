%returns the absolute amplitude of a sinusoidal wave current S over time,
%the rms amplitude and the power over time for a resistance R.
function [a,rms,prms,p] = getSignalAmplitude(S,R)
    j=1;
    M=[];
    for i=1:length(S)-1
        if ((S(i)>=0) && (S(i+1)<0))||((S(i)<0) && (S(i+1)>=0))
            M(j) = i;
            j = j+1;
        end
    end
    a = 0*S;rms = 0*S;
    if(length(M)>=1)
        if M(1)~=1
            m = max(abs(S(1:M(1)-1)));
            r = sqrt(sum(S(1:M(1)-1).^2)/length(S(1:M(1)-1)));
            for j=1:M(1)-1
               a(j)=m;
               rms(j)=r;
            end
        end
        for i=1:length(M)-1
            m = max(abs(S(M(i):M(i+1))));
            r = sqrt(sum(S(M(i):M(i+1)).^2)/length(S(M(i):M(i+1))));
            for j=M(i):M(i+1)-1
               a(j)=m;
               rms(j)=r;
            end
        end
        if M(end)<length(S)
            m = max(abs(S(M(end):end)));
            r = sqrt(sum(S(M(end):end).^2)/length(S(M(end):end)));
            for j=M(end):length(S)
               a(j)=m;
               rms(j)=r;
            end
        end
    end
    prms = R.*rms.^2;
    p = R.*a.^2;
end