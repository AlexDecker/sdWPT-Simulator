clear all;

W = 2*pi*linspace(110000,205000,3);%110-205kHz
R1 = 0.025*[1,2,3,4,5];
R2 = [30,35,40];
C1 = linspace(100e-9,500e-9,6);
C2 = 183e-9*[0.5,1,1.5,2,2.5];%a capacitância paralela é desconsiderada por ser muito baixa e, portanto, gerar uma ponte de alta impedância
ZONE1 = 0.014;
ZONE2 = 0.016;
MIENV1 = linspace(pi*4e-7,pi*24e-7,5);%permissividade magnética do meio nas proximidades do atrator
MIENV2 = pi*4e-7;

%valor de referência
ref_eff = [0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0];
ref_dist = [7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

data = [];

%hold on
%plot(ref_dist,ref_eff,'r');
num=0;
for r2 = R2
	for r1 = R1
		for c1 = C1
			for c2 = C2
				for w = W
					for miEnv1 = MIENV1
						for miEnv2 = MIENV2
							for z1 = ZONE1
								for z2 = ZONE2
									params.R = [r1;r2];
									params.C = [c1;c2];
									params.W = w;
									params.zone1Limit = z1;
									params.zone2Limit = z2;
									params.miEnv1 = miEnv1;
									params.miEnv2 = miEnv2;
									[t_TX, BC_TX1, BC_TX2, t_RX, CC_RX] = simulate_STEIN(params);
									%convertendo tempo em distância
									d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
									d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;
									
									eff_list = [];
									
									for i=1:length(ref_eff)
										i_tx1 = interp1(d_TX,BC_TX1,ref_dist(i));
										i_tx2 = interp1(d_TX,BC_TX2,ref_dist(i));
										i_rx = interp1(d_RX,CC_RX,ref_dist(i));
							
										eff = abs(r2*i_rx^2)/(abs(r1*i_tx1^2)+abs(r1*i_tx2^2)+abs(r2*i_rx^2));
										
										eff_list = [eff_list,eff];
									end
									%calculando os erros considerando diferentes taxas de perda
									best = sum((eff_list-ref_eff).^2);
									bestA = 0;
									bestB = 1;
									for a = -1:0.01:0
										for b = (-a):0.01:1
											ef = eff_list.*(a*eff_list+b);
											if(sum(ef>1)+sum(ef<0)>0)
												error('reavalie essa formula');
											end
											er = sum((ef-ref_eff).^2);
											if er<best
												best = er;
												bestA = a;
												bestB = b;
											end
										end
									end
									%registrando melhores resultados
									d.eff = eff_list.*(bestA*eff_list+bestB);
									d.err = best;
									d.c1 = c1;
									d.c2 = c2;
									d.r1 = r1;
									d.r2 = r2;
									d.w = w;
									d.z1 = z1;
									d.z2 = z2;
									d.miEnv1 = miEnv1;
									d.miEnv2 = miEnv2;
									d.a = bestA;
									d.b = bestB;
									
									disp(['C=[',num2str(c1),',',num2str(c2),'];R=[',num2str(r1),',',num2str(r2),'];W=',num2str(w),';mi1=',num2str(miEnv1),';mi2=',num2str(miEnv2),';a = ',num2str(bestA),';b = ',num2str(bestB),';err=',num2str(d.err)]);
									disp(d.eff);
									num=num+1;
									disp(['progresso: ',num2str(100*num/(length(C1)*length(C2)*length(R1)*length(R2)*length(W)*length(MIENV1)*length(MIENV2)*length(ZONE1)*length(ZONE2))),'%']);
									data=[data,d];
									%plot(ref_dist,eff_list,'b');
								end
							end
						end
					end
				end
			end
		end
	end
	save(['save_data_new_Qi_',num2str(r2),'.mat'],'data');
end
