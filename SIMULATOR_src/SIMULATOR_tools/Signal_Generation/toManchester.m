%translate to manchester encoding. Uses a clock signal started with 1.
function m = toManchester(msg)
    l = 2*length(msg);
    clk = zeros(1,l);m2 = clk;
    for i=1:l
        if(rem(i,2)==1)
            clk(i)=1;
        end
        m2(i) = msg(ceil(i/2))-48;
    end
    m = xor(clk,m2)+48;
end
