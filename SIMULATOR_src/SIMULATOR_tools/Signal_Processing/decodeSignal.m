function [msg,lvl,bri] = decodeSignal(a, win,sr)
    lvl = a;
    bri = a;
    br = 0;
    msg=[];
    imsg=1;
    lt=0;
    for i = 1:length(a)
        if i-win<=0
            i0 = 1;
        else
            i0 = i-win;
        end
        mi = min(a(i0:i));
        ma = max(a(i0:i));
        threshold = (ma+mi)/2;
        if(a(i)<threshold)
            lvl(i)=0;
        else
            lvl(i)=1;
        end
        if(i>1)
            if(lvl(i)~=lvl(i-1))
                d = i-lt;
                if(br==0)
                    br=i;
                else
                    br = (sr*br+d)/(sr+1);
                end
                for j=1:round(d/br)
                    msg(imsg)=lvl(i-1);
                    imsg=imsg+1;
                end
                lt = i;
            end
        end
        bri(i)=br;
    end
end