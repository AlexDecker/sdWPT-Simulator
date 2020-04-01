%Qi: optimal
%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%optimizing the resistance and the capacitance of the recever's setup. This application
%does not care about how to obtain the coupling between TX and RX. Thus, it is useful
%just for obtaining an upper bound for RX-Qi applications.

classdef powerRXApplication_QiOptimal < powerRXApplication
	properties(Constant)
		tolerance = 1e-3;
	end
    properties
		%Application parameters
    	dt
    	imax %maximum acceptable current
        ttl_TX %time for TX optimization
        ttl_RX %time for RX optimization
		%pre-parametrized parameters
        Rmin %minimum allowed resistance
        P %maximum allowed active power
		Mr %RX inductance sub-matrix
        Mt %TX inductance sub-matrix
		Rt %transmitter's internal resistance
		Ct %transmitter's internal capacitance
		V %peak voltage
		%inferred parameters
		Mtr %channel coupling
        %operational parameters
        state %0=TX has autonomy. 1=RX has autonomy
        ttl %when 0, toggle state
    end
    methods
        function obj = powerRXApplication_QiOptimal(id,dt,imax,ttl_TX,ttl_RX)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
            obj.ttl_TX = ttl_TX;
            obj.ttl_RX = ttl_RX;
			
			obj.APPLICATION_LOG.DATA = [];
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        
			%SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
           	
		   	%gets the inductance of the coil
			obj = getPreParameters(obj,WPTManager);
			
            %let TX optimize first
            obj.state = 0;
            obj.ttl = obj.ttl_TX;

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
                
				%get the variable parammeters from constants, I and w
				obj = estimateParameters(obj,I,w,WPTManager);

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
                    end
                else
                    %use the feedback in order to freeze TX action
                    netManager = send(obj,netManager,0,[obj.imax,obj.imax],128,GlobalTime);
                    %change its own capacitancy in order to optimize the received current
			        [obj, WPTManager] = updateImpedance(obj,WPTManager,GlobalTime,w);
                    if obj.ttl>0
                        obj.ttl=obj.ttl-1;
                    else
                        obj.ttl=obj.ttl_TX;
                        obj.state=0;
                    end
                end

			end
			
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

		%Some useful functions

		function obj = getPreParameters(obj,WPTManager)
			
            Z = getCompleteLastZMatrix(WPTManager);%getting the impedance matrix
			R = diag(real(Z));%getting the resistance vector
			obj.Rt = R(1);%getting the constant TX resistance
			obj.Rmin = R(end);%the initial resistance is used as minimum allowed
            %TX constant capacitance
			obj.Ct = WPTManager.ENV.envList(1).C_group(1);
			
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
		
		function obj = estimateParameters(obj,I,w,WPTManager)
            %get the rest of M matrix using some method which is currently being 
            %abstracted in this function
            Z = getCompleteLastZMatrix(WPTManager);
            M = -imag(Z)/w;
            obj.Mtr = M(1:2,3:4);
		end

		function [obj, WPTManager] = updateImpedance(obj,WPTManager,GlobalTime,w)
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
            for Rr = linspace(obj.Rmin,2*obj.Rmin,10)
                for Cr = linspace(1e-8,1e-6,500)
                    zr = Rr - (1i)/(w*Cr);
                    I  = j - (zr/(1+zr*a))*k;
                    P  = real(obj.V*I'*[1;1;0;0]);
                    if(P < obj.P - powerRXApplication_QiOptimal.tolerance)%if the spent power is feasible
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
            WPTManager = setResistance(obj,WPTManager,GlobalTime,Rr_best);
            WPTManager = setCapacitance(obj,WPTManager,GlobalTime,Cr_best);
			
			%%For debugging purposes%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			obj.APPLICATION_LOG.DATA(end+1) = Rr_best;
		end
    end
end
