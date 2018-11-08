w = 2*pi*1000000;
P = 20;
w2MtM = [0.8143;0.6634;0.2083;0.0727];
Qmax = 1.43;
step = 0.001;
eff = 0.95;

coef_ref = [1/2.5;1/3.5;1/4.8;1/8.8];

rlLookupTable = LookupTable('magMIMOLinearBattery_data.txt',false);

hold on;
E = [];
minErr = inf;
%while true
	%w2MtM = [0,0,0,0];
	%w2MtM(1) = unifrnd(0,2);
	%for i=2:length(w2MtM)
	%	w2MtM(i) = unifrnd(0,w2MtM(i-1));
	%end
	%w2MtM %DISPLAY
	for Rr = 25%[2,5,10,20,25,30]
		for Rt = 0.05%[0.01,0.025,0.05,0.075,0.1,0.25,0.5]
			err = 0;
			for i=1:4
				Q = [];
				RL = [];
				IL = [];
				q=0;
				while true
					Rl = getYFromX(rlLookupTable,q/Qmax);
					RL = [RL;Rl];
					Il = -sqrt(w2MtM(i)*P/(Rt*(Rr+Rl)^2));
					IL = [IL;Il];
					q = q+eff*abs(Il)*step;
					if q>=Qmax
						Q = [Q;Qmax];
						break;
					else
						Q = [Q;q];
					end
				end
				err_parc = (Q.')/Qmax-(coef_ref(i)*linspace(0,step*(length(Q)-1),length(Q)));
				err = err+mean(err_parc.^2);
				plot(linspace(0,step*(length(Q)-1),length(Q)),100*Q/Qmax);
				plot(linspace(0,1/coef_ref(i),2),100*coef_ref(i)*linspace(0,1/coef_ref(i),2),'r');
			end
			e.w2MtM = w2MtM;
			e.Rt = Rt;
			e.Rr = Rr;
			e.err = err;
			E = [E,e];
			if err<minErr
				minErr = err;
			end
			minErr %DISPLAY
		end
	end
%end

