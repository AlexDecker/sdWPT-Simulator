clear all;

W = 2*pi*linspace(100000,400000,4);%100-400kHz
R1 = linspace(0.025,0.5,5);
R2 = linspace(0.198675497,0.75,5);%(o primeiro valor considera a resistência da
% bobina em paralelo com os 30 ohms
C = linspace(50e-9,1000e-9,5);
MIENV = linspace(pi*4e-7,50e-7,5);%permissividade magnética do meio

%valor de referência
ref_eff = [0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_dist = [7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

data = [];

for c1 = C
	for c2 = C
		for r1 = R1
			for r2 = R2
				for w = W
					for miEnv = MIENV
						[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX] = simulate_STEIN([r1;r2],[c1;c2],w,miEnv);
						%convertendo tempo em distância
						d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
						d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;
						
						err = 0;
						eff_list = [];
						for i=1:length(ref_eff)
							i_tx1 = interp1(d_TX,BC_TX1,ref_dist(i));
							i_tx2 = interp1(d_TX,BC_TX2,ref_dist(i));
							i_rx = interp1(d_RX,CC_RX,ref_dist(i));
							
							eff = abs(r2*i_rx^2)/(abs(r1*i_tx1^2)+abs(r1*i_tx2^2)+abs(r2*i_rx^2));
							
							eff_list = [eff_list,eff];
							err = err + (eff-ref_eff(i))^2;
						end
						d.eff = eff_list;
						d.err = err;
						d.c1 = c1;
						d.c2 = c2;
						d.r1 = r1;
						d.r2 = r2;
						d.w = w;
						d.miEnv = miEnv;
						
						disp(['C=[',num2str(c1),',',num2str(c2),'];R=[',num2str(r1),',',num2str(r2),'];W=',num2str(w),';mi=',num2str(miEnv),';err=',num2str(err)]);
						disp(eff_list);
						
						data=[data,d];
					end
				end
			end
		end
	end
end
