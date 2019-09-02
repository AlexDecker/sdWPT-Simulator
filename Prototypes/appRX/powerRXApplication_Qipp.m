%Qi++
%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%optimizing the resistance and the capacitance of the recever's setup

classdef powerRXApplication_Qipp < powerRXApplication
    properties
		%Application parameters
    	dt
    	imax %maximum acceptable current
        Cmax %maximum allowed capacitance
        Rmin %minimum allowed resistance
		%pre-parametrized parameters
		Mr %RX inductance sub-matrix
        Mt %TX inductance sub-matrix
		Rt %transmitter's internal resistance
		Ct %transmitter's internal capacitance
		V %peak voltage
		%inferred parameters
		Mtr %channel coupling
    end
    methods
        function obj = powerRXApplication_Qipp(id,dt,imax)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
			obj.Cmax = 0.1;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
	        
			%SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
            obj = setSendOptions(obj,0,2048,5);
           	
		   	%gets the inductance of the coil
			obj = getPreParameters(obj,WPTManager);

			%change its own capacitancy in order to ressonate at the operatonal frequency
			WPTManager = getResCapacitance(obj,WPTManager,0);
			
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
                %sends its own current (continuing message)
                netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
				
				%get the variable parammeters from constants, I and w
				obj = estimateParameters(obj,I,w,WPTManager);

				%the following command is used for checking the peak voltage
				if obj.V~=WPTManager.ENV.Vt_group(1)
					error('Please use a Qi v1 transmitter');
				end

                %change its own capacitancy in order to optimize the received current
			    WPTManager = updateImpedance(obj,WPTManager,GlobalTime,w);
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
			M = WPTManager.ENV.envList(1).M*WPTManager.ENV.envList(1).miEnv;
            %the signal of the self-inductance is the oposite of the others
            M = M - 2*diag(diag(M));
            %The relative position between TX coils and between RX coils never changes
            %So, one can pre-parametrize the coupling sub-matrices of TX and RX sets.
            obj.Mt = M(1:2,1:2);
            obj.Mr = M(3:4,3:4);
			obj.V = 5;%Qi v1

		end

		function WPTManager = getResCapacitance(obj,WPTManager,GlobalTime)
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);
            %get the equivalent RX self inductance
            Lr = 1/(1/abs(obj.Mr(1,1))+1/abs(obj.Mr(2,2)));
			C = 1/(w^2*Lr);%calculates the value for the resonance capacitor
			%applies the calculated value to the varcap
			WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C);
		end
		
		%core functions
		
		function obj = estimateParameters(obj,I,w,WPTManager)
            %get the rest of M matrix using some method which is currently being 
            %abstracted in this function
            Z = getCompleteLastZMatrix(WPTManager);
            M = -imag(Z)/w;
            obj.Mtr = M(1:2,3:4);
		end

		function WPTManager = updateImpedance(obj,WPTManager,GlobalTime,w)
            zt = obj.Rt - (1i)/(w*obj.Ct);

            M = [obj.Mt, obj.Mtr;
                obj.Mtr.', obj.Mr];

            iZ = eye(4)/([zt*ones(2),zeros(2);zeros(2),obj.Rmin*ones(2)]-(1i)*w*M);

            a = [0,0,1,1]*iZ*[0;0;1;1];
            j = obj.V*iZ*[1;1;0;0];                                                                                 
            k = obj.V*iZ*[0;0;1;1]*[0,0,1,1]*iZ*[1;1;0;0];
            c = j(3)+j(4);
            b = -(k(3)+k(4));
            
            alpha = abs(b/a)^2+2*real(c'*b/a);
            beta = 2*real(c'*b/a);                                                                              
            gamma = -2*imag(c'*b/a); 

            %crictical points over the frontier of the domain
            [dx_r,dy_r,z_r] = criticalOnLine(alpha,beta,gamma,a,-real(a)/imag(a),1e-7);
            [dx_i,dy_i,z_i] = criticalOnLine(alpha,beta,gamma,a,imag(a)/real(a),1e-7);

            %getting which crictical points are inside the domain

            %the point in which the lines cross each other
            dx0 = 1;
            dy0 = 0;
            DX = dx0;
            DY = dy0;
            Z  = ((beta-2*alpha)*dx0+gamma*dy0+alpha-beta)/(dx0^2+dy0^2);
            %real(zr)=0
            if(imag(a)>=0)
                for i=1:length(dx_r)
                    if(dx_r(i)>=dx0)
                        DX = [DX, dx_r(i)];
                        DY = [DY, dy_r(i)];
                        Z  = [Z, z_r(i)];
                    end
                end
            else
                for i=1:length(dx_r)
                    if(dx_r(i)<=dx0)
                        DX = [DX, dx_r(i)];
                        DY = [DY, dy_r(i)];
                        Z  = [Z, z_r(i)];
                    end
                end   
            end 
            %imag(zr)=0
            if(real(a)>=0)
                for i=1:length(dx_i)
                    if(dx_i(i)>=dx0)
                        DX = [DX, dx_i(i)];
                        DY = [DY, dy_i(i)];
                        Z  = [Z, z_i(i)];
                    end
                end
            else
                for i=1:length(dx_i)
                    if(dx_i(i)<=dx0)
                        DX = [DX, dx_i(i)];
                        DY = [DY, dy_i(i)];
                        Z  = [Z, z_i(i)];
                    end
                end   
            end
            
            [MAX, ind] = max(Z);

            %the optimal zr
            Rr = ((DX(ind)-1)*real(a)-DY(ind)*imag(a))/abs(a)^2;
            Reac = DY(ind)/real(a)-imag(a)/real(a)*Rr;
            Cr = abs(w/Reac);

            %inserting the new parameters
            %WPTManager = setResistance(obj,WPTManager,GlobalTime,max(Rr,0)+obj.Rmin);
            %WPTManager = setCapacitance(obj,WPTManager,GlobalTime,min(Cr,obj.Cmax));
		end
    end
end
