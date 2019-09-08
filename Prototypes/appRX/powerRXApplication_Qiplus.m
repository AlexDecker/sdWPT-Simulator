%Qi: plus
%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%optimizing the resistance and the capacitance of the recever's setup. This application
%gets parameters fairly and than is feasible in the real world

classdef powerRXApplication_Qiplus < powerRXApplication
    properties
		%Application parameters
    	dt
    	imax %maximum acceptable current
        ttl_TX %time for TX optimization
        ttl_RX %time for RX optimization
        wSize %window size
		%pre-parametrized parameters
        Rmin %minimum allowed resistance
        P %maximum allowed active power
		Mr %RX inductance sub-matrix
        Mt %TX inductance sub-matrix
        Mtr
		Rt %transmitter's internal resistance
		Ct %transmitter's internal capacitance
        Rr %receiver's internal resistance
		Cr %receiver's internal capacitance
		V %peak voltage
        %operational parameters
        w %last measured angular frequency 
        state %0=TX has autonomy. 1=RX has autonomy
        ttl %when 0, toggle state
        window %parameters from other executions
    end
    methods
        function obj = powerRXApplication_Qiplus(id,dt,imax,ttl_TX,ttl_RX,wSize)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
            obj.ttl_TX = ttl_TX;
            obj.ttl_RX = ttl_RX;
            obj.wSize = wSize;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        
			%SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
           	
		   	%gets the inductance of the coil
			obj = getPreParameters(obj,WPTManager);
			
            %let TX optimize first
            obj.state = 0;
            obj.ttl = obj.ttl_TX;
            obj.w = 0;

            %starting operational loop
			netManager = setTimer(obj,netManager,0,obj.dt);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	%gets the phasor notation receiving current
			[I,WPTManager] = getI(obj,WPTManager,GlobalTime);
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);

        	if(abs(I)>0)%if it is transmitting power
                
				
				%the following command is used for checking the peak voltage
				if obj.V~=WPTManager.ENV.Vt_group(1)
					error('Please use a Qi v1 transmitter');
				end
                
                if (obj.state==0 && w>=2*pi*110000) %if it's a ping, optimize anyway
                    %sends its own current (continuing message) and let TX optimize
                    netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
                    if obj.ttl>0
                        obj.ttl=obj.ttl-1;
                    else
                        obj.ttl=obj.ttl_RX;
                        obj.state=1;
                        if obj.w~=w
                            obj.window = [];%last parameters are no longer useful (w changed)
                        end
                    end
                else
                    if length(obj.window)>=obj.wSize %now run normally
                        
                        %use the feedback in order to freeze TX action
                        netManager = send(obj,netManager,0,[obj.imax,obj.imax],128,GlobalTime);
                        
                        %update window
                        item.Ir = I;
                        item.Zr = obj.Rr - (1i)/(w*obj.Cr);
						item.Z1 = zeros(4);%RETIRAR
                        obj.window = [obj.window(2:end), item];

                        %get the variable parammeters from constants, I and w
                        obj = estimateParameters(obj,WPTManager);

                        %change its own capacitancy in order to optimize the received current
                        [obj,WPTManager] = updateImpedance(obj,WPTManager,GlobalTime,w);
                        if obj.ttl>0
                            obj.ttl=obj.ttl-1;
                        else
                            obj.ttl=obj.ttl_TX;
                            obj.state=0;
                        end
                    else
                        item.Ir = I;
                        item.Zr = obj.Rr - (1i)/(w*obj.Cr);
						item.Z1 = zeros(4);%RETIRAR
                        obj.window = [obj.window, item];
                    end
                end

			end

			obj.w = w;
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

		%Some useful functions

		function obj = getPreParameters(obj,WPTManager)
			
            Z = getCompleteLastZMatrix(WPTManager);%getting the impedance matrix
			R = diag(real(Z));%getting the resistance vector
			obj.Rt = R(1);%getting the constant TX resistance
            obj.Rr = R(end);%getting the constant RX resistance
			obj.Rmin = R(end);%the initial resistance is used as minimum allowed
            %TX constant capacitance
			obj.Ct = WPTManager.ENV.envList(1).C_group(1);
			%RX constant capacitance
            obj.Cr = WPTManager.ENV.envList(1).C_group(end);

            %getting the coupling matrix
			M = WPTManager.ENV.envList(1).M;
            L = diag(M);%self-inductance
            M = M-diag(L);%coupling matrix without self-inductances

            %introducing magnetic permeability constants
            M = WPTManager.ENV.envList(1).miEnv*M;
            L = genMiVector(WPTManager.ENV.envList(1)).*L;
            
            %the signal of the self-inductance is the oposite of the others
            M = M - diag(L);

            %The relative position between TX coils and between RX coils never changes
            %So, one can pre-parametrize the coupling sub-matrices of TX and RX sets.
            obj.Mt = M(1:2,1:2);
            obj.Mr = M(3:4,3:4);
			obj.V = 5;%Qi v1
            obj.P = 7.5;%transmitter's datasheet (considering the product between typical
            %current and typical voltage
            
		end
		
        %core functions
		
		function obj = estimateParameters(obj,WPTManager)
            Zr = [obj.window.Zr];
            Ir = [obj.window.Ir];

            Zr0 = Zr(1:end-1);
            Zr1 = Zr(2:end);

            Ir0 = Ir(1:end-1);
            Ir1 = Ir(2:end);
            dIr = Ir1-Ir0;
            
            w = getOperationalFrequency(obj,WPTManager);
            Z = getCompleteLastZMatrix(WPTManager);
            Z1 = Z.*(1-[0;0;1;1]*[0,0,1,1])+[zeros(2),zeros(2);zeros(2),-(1i)*w*obj.Mr];
            diff = Z-Z1; actualZr = diff(end,end);
			
			obj.window(end).Z1 = Z1;
			
			%confirming if the context is of saturation or frame changing
			sat = false;
			for i=2:length(obj.window)
				if sum(sum(abs(obj.window(i).Z1-obj.window(i-1).Z1)))~=0
					sat=true;
					break;
				end
			end
            
            if(~sat)
                iZ = eye(4)/Z1;
                actualA = [0,0,1,1]*iZ*[0;0;1;1];
                actualJ = obj.V*iZ*[1;1;0;0];
                actualK = obj.V*iZ*[0;0;1;1]*[0,0,1,1]*iZ*[1;1;0;0];
                actualB = [0,0,1,1]*iZ*[1;1;0;0];
                I = actualJ-(Zr(end)/(1+Zr(end)*actualA))*actualK;

                %errs = [];
				%for i=1:length(Ir)
                %for i=1:length(dIr)
                    %I = actualJ-(Zr(i)/(1+Zr(i)*actualA))*actualK;
					%errs = [errs, (sum(I(3:4))-Ir(i))/Ir(i)];
					
                    %dir0 = (Zr0(i)/(1+Zr0(i)*actualA)-Zr1(i)/(1+Zr1(i)*actualA))*obj.V*actualA*actualB;
					%dir1 = (Zr0(i)-Zr1(i))/(Zr0(i)*Zr1(i)*actualA^2 + (Zr0(i)+Zr1(i))*actualA + 1)*obj.V*actualA*actualB;
					%er = dIr(i)*Zr0(i)*Zr1(i)*actualA^2 + dIr(i)*(Zr0(i)+Zr1(i))*actualA + dIr(i)-(Zr0(i)-Zr1(i))*obj.V*actualA*actualB;
                    %errs=[errs,er];
                %end
                %errs

                Q = [dIr.*Zr0.*Zr1;dIr.*(Zr0+Zr1);-obj.V*(Zr0-Zr1)].';
                Q*[actualA^2;actualA;actualA*actualB]+dIr.';
				x = (eye(3)/(Q'*Q))*Q'*(-dIr.');
				disp('results');
				x(1) %compare esse e o da linha de baixo pra saber se a estimativa de A está correta
				x(2).^2
				x(2)
				actualA
            end

            M = -imag(Z)/w;
            obj.Mtr = M(1:2,3:4);
		end

		function [obj,WPTManager] = updateImpedance(obj,WPTManager,GlobalTime,w)
            Zt = (obj.Rt - (1i)/(w*obj.Ct))*[ones(2),zeros(2);zeros(2),zeros(2)];

            M = [obj.Mt, obj.Mtr;
                obj.Mtr.', obj.Mr];
                       
            Z1 = Zt - (1i)*w*M;%impedance matrix without zr
            iZ = eye(4)/Z1;%inverse of Z1

            %auxiliary variables for calculating I quickly
            j = obj.V*iZ*[1;1;0;0];
            a = [0,0,1,1]*iZ*[0;0;1;1];
            k = obj.V*iZ*[0;0;1;1]*[0,0,1,1]*iZ*[1;1;0;0];

            Rr_best = obj.Rmin;
            Cr_best = 1e-7;
            I_best = 0;
            aux = 0;
            for Rr = linspace(obj.Rmin,2,10)
                for Cr = linspace(1e-8,1e-6,500)
                    zr = Rr - (1i)/(w*Cr);
                    I  = j - (zr/(1+zr*a))*k;
                    P  = real(obj.V*I'*[1;1;0;0]);
                    if(P<obj.P)%if the spent power is feasible
                        Ir = abs(sum(I(3:4)));
                        if(Ir>I_best)
                            I_best = Ir;
                            Rr_best = Rr;
                            Cr_best = Cr;
                            P_best = P;
                            aux = I;
                        end
                    end
                end
            end
            %inserting the new parameters
            obj.Rr = Rr_best+rand;
            obj.Cr = rand*Cr_best;
            WPTManager = setResistance(obj,WPTManager,GlobalTime,obj.Rr);
            WPTManager = setCapacitance(obj,WPTManager,GlobalTime,obj.Cr);
		end
    end
end
