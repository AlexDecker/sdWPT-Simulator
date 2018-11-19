w = 2*pi*1000000;
u = pi*4e-7;
P = 20;
Qmax = 1.43;
step = 0.001;
eff = 0.95;

coef_ref = [1/2.5;1/3.5;1/4.8;1/8.8];

load('tunningMagMIMOTrackingData.mat');

rlLookupTable = LookupTable('magMIMOLinearBattery_data.txt',false);

%hold on;
E = [];
minErr = inf;
for d=5%1:length(data)
	for Rr = [2,5,10,20,25,30]
		for Rt = [0.01,0.025,0.05,0.075,0.1,0.25,0.5]
			err = [0,0,0,0];
			for i=1:4
				Z = -(1i)*w*u*data(d).M(i).obj + diag([Rt*ones(6,1);Rr]);
				m_Rl = (1i)*w*u*data(d).M(i).obj(1:6,7);
				Q = [];
				RL = [];
				IL = [];
				q=0;
				ttl=20;
				while true
					Rl = getYFromX(rlLookupTable,q/Qmax);
					RL = [RL;Rl];
					m  = m_Rl/(Rl+Rr);
					bl = m.'*m;
					It = m*(sqrt(P/real([m;bl]'*Z*[m;bl])));
					Il = m.'/(Rl+Rr)*It;
					IL = [IL;Il];
					q = q+eff*abs(Il)*step;
					if q>=Qmax
						Q = [Q;Qmax];
						break;
					else
						Q = [Q;q];
					end
					ttl = ttl-step;
					if ttl<0
						break;
					end
				end
				if ttl<0
					err(i) = inf;
				else
					err_parc = (Q.')/Qmax-(coef_ref(i)*linspace(0,step*(length(Q)-1),length(Q)));
					err(i) = mean(err_parc.^2);
				end
				%plot(linspace(0,step*(length(Q)-1),length(Q)),100*Q/Qmax);
				%plot(linspace(0,1/coef_ref(i),2),100*coef_ref(i)*linspace(0,1/coef_ref(i),2),'r');
			end
			e.Rt = Rt;
			e.Rr = Rr;
			e.err = sum(err);
			e.d = d;
			E = [E,e];
			if e.err<minErr
				minErr = e.err;
			end
			minErr %DISPLAY
		end
	end
end

