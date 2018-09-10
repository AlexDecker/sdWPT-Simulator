clear all;

W = 2*pi*110000;%2*pi*linspace(110000,205000,4);%110-205kHz
R1 = 0.025;
R2 = 30;
C1 = 400e-9;
C2 = 183e-9;%a capacitância paralela é desconsiderada por ser muito baixa e, portanto, gerar uma ponte de alta impedância
ZONE1 = 0.013;
ZONE2 = 0.015;
MIENV1 = pi*4e-7;%linspace(pi*4e-7,50e-7,5);%permissividade magnética do meio nas proximidades do atrator
MIENV2 = pi*4e-7;

%valor de referência
ref_eff = [0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_dist = [7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

data = [];

hold on
plot(ref_dist,ref_eff,'r');

for c1 = C1
	for c2 = C2
		for r1 = R1
			for r2 = R2
				for w = W
					for miEnv1 = MIENV1
						for miEnv2 = MIENV2
							for z1 = ZONE1
								for z2 = ZONE2
									[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX] = simulate_STEIN([r1;r2],[c1;c2],w,z1,z2,miEnv1,miEnv2);
									%convertendo tempo em distância
									d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
									d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;
						
									err = 0;
									eff_list = [];
									for i=1:length(ref_eff)
										i_tx1 = interp1(d_TX,BC_TX1,ref_dist(i));
										i_tx2 = interp1(d_TX,BC_TX2,ref_dist(i));
										i_rx = interp1(d_RX,CC_RX,ref_dist(i));
							
										%eff = abs(r2*i_rx^2)/(abs(r1*i_tx1^2)+abs(r1*i_tx2^2)+abs(r2*i_rx^2));
										eff = abs(r2*i_rx^2)/(abs(5*(i_tx1+i_tx2)));
							
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
									d.z1 = z1;
									d.z2 = z2;
									d.miEnv1 = miEnv1;
									d.miEnv2 = miEnv2;
						
									disp(['C=[',num2str(c1),',',num2str(c2),'];R=[',num2str(r1),',',num2str(r2),'];W=',num2str(w),';mi1=',num2str(miEnv1),';mi2=',num2str(miEnv2),';err=',num2str(err)]);
									disp(eff_list);
						
									data=[data,d];
									plot(ref_dist,eff_list,'b');
								end
							end
						end
					end
				end
			end
		end
	end
end
