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
        %P %maximum allowed active power
		Mr %RX inductance sub-matrix
        %Mt %TX inductance sub-matrix
        %Mtr
		%Rt %transmitter's internal resistance
		%Ct %transmitter's internal capacitance
        Rr %receiver's internal resistance
		Cr %receiver's internal capacitance
		V %peak voltage
        %operational parameters
        w %last measured angular frequency 
        state %0=TX has autonomy. 1=RX has autonomy
        ttl %when 0, toggle state
        window %parameters from other executions
        variability %used in order to add entropy to the system parameters
        %parameters adquired from the environment
        A
        B
        %last RX impedance that led to a non-saturated system state
        safeRr
        safeCr
		version %1: use (safeRr, safeCr); 2: use (Rmin, 1e-7 F)
    end
    methods
        function obj = powerRXApplication_Qiplus(id,dt,imax,ttl_TX,ttl_RX,wSize,version)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
            obj.ttl_TX = ttl_TX;
            obj.ttl_RX = ttl_RX;
            obj.wSize = wSize;
			obj.version = version;
			
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
            obj.w = 0;
            
            %initializing operational parameters
            obj.variability = 0.05;
            obj.A = NaN; obj.B = NaN;
            obj.safeRr = obj.Rmin;
            obj.safeCr = 1e-7;

            %starting operational loop
			netManager = setTimer(obj,netManager,0,obj.dt);
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	%gets the phasor notation receiving current
			[Ir,WPTManager] = getI(obj,WPTManager,GlobalTime);
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);

        	if(abs(Ir)>0)%if it is transmitting power
                
				
				%the following command is used for checking the peak voltage
				if obj.V~=WPTManager.ENV.Vt_group(1)
					error('Please use a Qi v1 transmitter');
				end
                
                if (obj.state==0 && w>=2*pi*110000) %if it's a ping, optimize anyway
                    %sends its own current (continuing message) and let TX optimize
                    netManager = send(obj,netManager,0,[abs(Ir),obj.imax],128,GlobalTime);
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
                        item.Ir = Ir;
                        item.Rr = obj.Rr;
                        item.w = w;
                        item.Cr = obj.Cr;
                        %Only for debugging purposes-----------------------------------------
						item.Z1 = zeros(4);
                        %--------------------------------------------------------------------
                        obj.window = [obj.window(2:end), item];

                        %get the variable parammeters from the data window
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
                        item.Ir = Ir;
                        item.Rr = obj.Rr;
                        item.w = w;
                        item.Cr = obj.Cr;
                        %Only for debugging purposes-----------------------------------------
						item.Z1 = zeros(4);
                        %--------------------------------------------------------------------
                        obj.window = [obj.window, item];
                    end
                end

			end

			obj.w = w;
            if isnan(obj.A)
			    netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
            else
			    netManager = setTimer(obj,netManager,GlobalTime,obj.dt/1.5);
            end
        end

		%Some useful functions

		function obj = getPreParameters(obj,WPTManager)
			
            Z = getCompleteLastZMatrix(WPTManager);%getting the impedance matrix
			R = diag(real(Z));%getting the resistance vector
			%obj.Rt = R(1);%getting the constant TX resistance
            obj.Rr = R(end);%getting the constant RX resistance
			obj.Rmin = R(end);%the initial resistance is used as minimum allowed
            %TX constant capacitance
			%obj.Ct = WPTManager.ENV.envList(1).C_group(1);
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
            %obj.Mt = M(1:2,1:2);
            obj.Mr = M(3:4,3:4);
			obj.V = 5;%Qi v1
            %obj.P = 7.5;%transmitter's datasheet (considering the product between typical
            %current and typical voltage
            
		end
		
        %core functions
		
		function obj = estimateParameters(obj,WPTManager)
            Ir = [obj.window.Ir];%vector with the total RX currents in the window
            Rr = [obj.window.Rr];%values of receiving resistance in the window
            Cr = [obj.window.Cr];%values of receiving capacitance in the window
            W = [obj.window.w];%values of angular frequency in the window
            Zr = Rr - (1i)./(W.*Cr);%values of receiving impedance in the window

            Zr0 = Zr(1:end-1);
            Zr1 = Zr(2:end);

            Ir0 = Ir(1:end-1);
            Ir1 = Ir(2:end);
            dIr = Ir1-Ir0;

            %EXTRA DATA FOR DIAGNOSTICS------------------------------------------------

            Z = getCompleteLastZMatrix(WPTManager);
            Z1 = Z.*(1-[0;0;1;1]*[0,0,1,1])+...
                [zeros(2),zeros(2);zeros(2),-(1i)*W(end)*obj.Mr+obj.Rmin*ones(2)];
            diff = Z-Z1; actualZr = diff(end,end);
			
			obj.window(end).Z1 = Z1;
			
			%confirming if the context is of saturation or frame changing
			badData = false;
			for i=2:length(obj.window)
				if sum(sum(abs(obj.window(i).Z1-obj.window(i-1).Z1)))~=0
					badData=true;
					break;
				end
			end
            
            global Positives;
            global Negatives;
            global FalsePositives;
            global FalseNegatives;
            global A_error;
            global B_error;

            if isempty(Positives), Positives = 0;, end
            if isempty(Negatives), Negatives = 0;, end
            if isempty(FalsePositives), FalsePositives = 0;, end
            if isempty(FalseNegatives), FalseNegatives = 0;, end

            if badData
                Positives = Positives+1;
            else
                Negatives = Negatives+1;
            end
            
            iZ = eye(4)/Z1;
            actualA = [0,0,1,1]*iZ*[0;0;1;1];
            actualB = obj.V*[0,0,1,1]*iZ*[1;1;0;0];
            
            %--------------------------------------------------------------------------

            Q = [dIr.*Zr0.*Zr1;dIr.*(Zr0+Zr1);(Zr1-Zr0)].';
            %if abs(det(Q'*Q))>1e-5 
            if rcond(Q'*Q)>1e-14
                x = (eye(3)/(Q'*Q))*Q'*(-dIr.');
                %descrease the forced variability of the impedance - 
                obj.variability = obj.variability/1.2;
                %if the error is less than 1%
                if abs(x(1)-x(2).^2)/abs(x(1))<1e-2
                    if badData
                        FalseNegatives = FalseNegatives+1;
                    end
                    %x(1) has two square roots. Evaluate both and use the closest
                    %to x(2) in order to get a better result for A estimation
                    if abs(x(2)-sqrt(x(1)))<abs(x(2)+sqrt(x(1)))
                        obj.A = mean([x(2),sqrt(x(1))]);
                    else
                        obj.A = mean([x(2),-sqrt(x(1))]);
                    end

                    obj.B = x(3)/obj.A;

                    %register these values as safe
                    obj.safeRr = Rr(end);
                    obj.safeCr = Cr(end);
                else
                    if ~badData
                        FalsePositives = FalsePositives+1;
                    end

                    obj.A = NaN;%the estimated value cannot be used
                    obj.B = NaN;
                end
                %comparing the estimated values to the actual values
                A_error = [A_error, abs(obj.A-actualA)/abs(actualA)];
                B_error = [B_error, abs(obj.B-actualB)/abs(actualB)];
            else
                %use the old data and
                %increase entropy at system params in order to get more
                %information
                obj.variability = min(obj.variability*1.05,1.4);
            end
           
		end

		function [obj,WPTManager] = updateImpedance(obj,WPTManager,GlobalTime,w)
            
			if obj.version==1
				Rr_best = obj.safeRr;
				Cr_best = obj.safeCr;
			elseif obj.version==2
				Rr_best = obj.Rmin;
				Cr_best = 1e-7;
			else
				error('powerRXApplication_Qiplus: version must be either 1 or 2');
			end
            
            if ~isnan(obj.A)
                %A lower bound for the best current (debugging purposes)--------
                I_best_0 = 0;
                %Rr_best_0 = inf;
                %Cr_best_0 = inf;
                for Rr = linspace(0,10,70)
                    for Cr = linspace(1e-8,1e-6,500)
                        zr = Rr - (1i)/(w*Cr);
                        ir = abs(obj.B - (zr/(1+zr*obj.A))*obj.B*obj.A);
                        if(ir>I_best_0)
                            I_best_0 = ir;
                            %Rr_best_0 = Rr;
                            %Cr_best_0 = Cr;
                        end
                    end
                end
                %zr = Rr_best_0 - (1i)/(w*Cr_best_0);
                %x = real(obj.A*zr)+1;
                %y = imag(obj.A*zr);
                
                %testing the first formula of the article
                %{
                abs(obj.B - (zr/(1+zr*obj.A))*obj.A*obj.B)
                sqrt((obj.B - (zr/(1+zr*obj.A))*obj.A*obj.B)'*(obj.B - (zr/(1+zr*obj.A))*obj.A*obj.B))
                sqrt((obj.B' - (zr'/(1+zr'*obj.A'))*obj.A'*obj.B')*(obj.B - (zr/(1+zr*obj.A))*obj.A*obj.B))
                sqrt(obj.B'*obj.B + (-obj.A*obj.B*zr)'*(-obj.A*obj.B*zr)/abs(1+obj.A*zr)^2+...
                    obj.B'*(-obj.A*obj.B*zr)/(1+obj.A*zr)+(-obj.A*obj.B*zr)'*obj.B/((1+obj.A*zr)'))
                sqrt(abs(obj.B)^2 + abs(obj.A)^2*abs(obj.B)^2*abs(zr)^2/abs(1+obj.A*zr)^2+...
                    2*real((-obj.A*obj.B*zr)'*obj.B/((1+obj.A*zr)')))
                sqrt(abs(obj.B)^2 + abs(obj.A)^2*abs(obj.B)^2*abs(zr)^2/abs(1+obj.A*zr)^2-...
                    2*real(obj.A*abs(obj.B)^2*zr+abs(obj.A)^2*abs(obj.B)^2*abs(zr)^2)/abs(1+obj.A*zr)^2)
                sqrt(abs(obj.B)^2 - abs(obj.A)^2*abs(obj.B)^2*abs(zr)^2/abs(1+obj.A*zr)^2-...
                    2*abs(obj.B)^2*real(obj.A*zr)/abs(1+obj.A*zr)^2)
                sqrt(abs(obj.B)^2-abs(obj.B)^2*(abs(1+obj.A*zr)^2-1)/abs(1+obj.A*zr)^2)
                sqrt(abs(obj.B)^2/abs(1+obj.A*zr)^2)
                %}
                %testing the last formula (it should be equal to the first)
                %sqrt(abs(obj.B)^2/(x^2+y^2))
                %the found solution is over the frontier? If so, the expression below will return something
                %close to zero
                %(real(obj.A)*x+imag(obj.A)*y-real(obj.A))*(real(obj.A)*y-imag(obj.A)*x+imag(obj.A))
                %---------------------------------------------------------------
                
                %candidates for optimal solution               
                x = [real(obj.A)^2/abs(obj.A)^2,imag(obj.A)^2/abs(obj.A)^2,1];
                y = [real(obj.A)*imag(obj.A)/abs(obj.A)^2,-real(obj.A)*imag(obj.A)/abs(obj.A)^2,0];
                %candidates for optimal resistance
                Rr = ((x-1)*real(obj.A)+y*imag(obj.A))/abs(obj.A)^2;
                %candidates for optimal capacitive reactance
                React = (y*real(obj.A)-imag(obj.A)*(x-1))/abs(obj.A)^2;
                %candidates for optimal impedances
                Zr = Rr + React*(1i);
                %candidates for optimal current
                I = abs(obj.B - Zr*obj.B*obj.A./(1+obj.A*Zr));
                %discarting unfeasible solutions
                I = (((Rr<-1e-9)|(React>1e-9)).*(-I-1e-9))+I;

                %actual solution
                [I0,index] = max(I);

                Rr_best = Rr(index);
                Cr_best = -1/(w*min(React(index),-1e-9));
    
                if I0+1e-6*I_best_0<I_best_0
                    %the value is below the estimated
                    global SubOptimals;
                    if isempty(SubOptimals), SubOptimals=1;, else, SubOptimals=SubOptimals+1;,end
                else
                    %the value is consistent to the estimated value
                    global Optimals;
                    if isempty(Optimals), Optimals=1;, else, Optimals=Optimals+1;,end
                end
            end

            %inserting the new parameters
            obj.Rr = min(Rr_best*(1+rand*obj.variability),10)+obj.Rmin;
            obj.Cr = Cr_best*(1+rand*obj.variability);
            WPTManager = setResistance(obj,WPTManager,GlobalTime,obj.Rr);
            WPTManager = setCapacitance(obj,WPTManager,GlobalTime,obj.Cr);
			
			%%For debugging purposes%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			obj.APPLICATION_LOG.DATA(end+1) = obj.Rr;
		end
    end
end
