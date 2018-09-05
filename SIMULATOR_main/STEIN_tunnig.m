clear all;

W = 2*pi*linspace(100000,400000,4);%100-400kHz
R1 = linspace(0.025,0.5,5);
R2 = linspace(0.198675497,0.75,5);%(o primeiro valor considera a resistência da
% bobina em paralelo com os 30 ohms
C = linspace(50e-9,1000e-9,5);
miEnv = pi*4e-7;%permissividade magnética do meio

%valor de referência
ref = [0.735, 0.745, 0.74, 0.715, 0.63, 0.27, 0.14, 0.06, 0;
 5.000, 7.50, 10.00, 12.5, 15.0, 17.5, 20.0, 22.5];

for c1 = C1
	for c2 = C2
		for r1 = R1
			for r2 = R2
				for w = W
					for miEnv = MIENV
						[t_TX, CC_TX, t_RX, CC_RX] = simulate_STEIN(R,C,W,miEnv);
						%convertendo tempo em distância
						d_TX = ((1000-t_TX)*5 + 30*t_TX)/1000;
						d_RX = ((1000-t_RX)*5 + 30*t_RX)/1000;
						
						
					end
				end
			end
		end
	end
end
