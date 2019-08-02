%Qi++
%RX Application inspired on Qi v1.0 specification (compatible with the TX part)
%but optimized in order to avoid permanent link interruptions and improve efficiency
%optimizing the resistance and the capacitance of the recever's setup

classdef powerRXApplication_Qipp < powerRXApplication
    properties
		%Application parameters
    	dt
    	imax %maximum acceptable current
		greedy %if 1, always ask for the maximum current. If -1, ask for minimum. Otherwise,
            %run normally according to Qi 1.0
        Cmax %maximum allowed capacitance
        Rmin %minimum allowed resistance
		%pre-parametrized parameters
		Lr %self inductance
		Rt %transmitter's internal resistance
		Ct %transmitter's internal capacitance
		Lt %transmitter's self inductance
		V %peak voltage
		%operational parameters
		Rr %last used resistance
		Cr %last used capacitance
		%inferred parameters
		M %channel coupling
    end
    methods
        function obj = powerRXApplication_Qipp(id,dt,imax,greedy,Rmin,Cmax)
            obj@powerRXApplication(id);%building superclass structure
            obj.dt = dt;
            obj.imax = imax;
			obj.greedy = greedy;
            obj.Rmin = Rmin;
            obj.Cmax = Cmax;
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
				%greedy approach: always asks for more power
				if obj.greedy==1
					netManager = send(obj,netManager,0,[0,obj.imax],128,GlobalTime);
				else
                    if obj.greedy==-1
                        %humble: ask for less power, get high frequency
                        netManager = send(obj,netManager,0,obj.imax*[1,1],128,GlobalTime);
                    else
        			    %sends its own current (continuing message)
		    		    netManager = send(obj,netManager,0,[I,obj.imax],128,GlobalTime);
                    end
				end
				
				%get the variable parammeters from constants, I and w
				obj = estimateParameters(obj,I,w);

				%the following command is used for checking the peak voltage
				if obj.V~=WPTManager.ENV.Vt_group(1)
					error('Please use a Qi v1 transmitter');
				end

                %change its own capacitancy in order to optimize the received current
			    [WPTManager,expectedI] = updateImpedance(obj,WPTManager,GlobalTime,w);
                abs(I)
                expectedI
			end
			
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        end

		%Some useful functions

		function obj = getPreParameters(obj,WPTManager)
			%get any environment (we assume the self inductances being constant
			env = WPTManager.ENV.envList(1);
			%For Qi, there are only 2 groups (the first for TX and the second for RX)
			[obj.Rt,Lt,obj.Ct] = getParameters(env,1);
			[obj.Rr,Lr,obj.Cr] = getParameters(env,2);
			%the equivalent inductance of the paralell coils
			obj.Lr = 1/sum(1./Lr);
			obj.Lt = 1/sum(1./Lt);
			obj.V = 5;%Qi v1
		end

		function WPTManager = getResCapacitance(obj,WPTManager,GlobalTime)
			%gets the angular operational frequency of the transmitted signal
			w = getOperationalFrequency(obj,WPTManager);
			C = 1/(w^2*obj.Lr);%calculates the value for the resonance capacitor
			%applies the calculated value to the varcap
			WPTManager = setCapacitance(obj,WPTManager,GlobalTime,C);
		end
		
		%core functions
		
		function obj = estimateParameters(obj,I,w)
		    zt = obj.Rt - (1i)/(w*obj.Ct) + (1i)*w*obj.Lt;
            zr = obj.Rr - (1i)/(w*obj.Cr) + (1i)*w*obj.Lr;
            
            a = (1i)*I;
            b = obj.V;
            c = (1i)*zt*zr*I;

            wM1=(-b+sqrt(b^2-4*a*c))/(2*a);
            wM2=(-b-sqrt(b^2-4*a*c))/(2*a);
            
            if(abs(imag(wM1))<abs(imag(wM2)))
                obj.M = wM1/w;
            else
                obj.M = wM2/w;
            end
		end

		function [WPTManager,expectedI] = updateImpedance(obj,WPTManager,GlobalTime,w)
            zt = obj.Rt - (1i)/(w*obj.Ct) + (1i)*w*obj.Lt;
            
            %the corner of the domain
            ao = -w*obj.Lr*imag(zt) + obj.Rmin*real(zt);
            bo = w*obj.Lr*real(zt) + obj.Rmin*imag(zt);
            
            %the point in real(zt)=0 closest to the global maximum
            m1 = real(zt)/imag(zt);
            m2 = 1;
            m3 = -obj.Rmin*abs(zt)^2/imag(zt);
            x0 = -w^2*obj.M^2;
            y0 = 0;
            ap = (m2*(m2*x0-m1*y0)-m1*m3)/(m1^2+m2^2);
            bp = (m1*(-m2*x0+m1*y0)-m2*m3)/(m1^2+m2^2);

            %optimal solution (for a,b variables)
            if imag(zt)<=0
                a = ap;
                b = bp;
            else
                if ap < ao
                    a = ao;
                    b = b0;
                else
                    a = ap;
                    b = bp;
                end
            end
            
            expectedI = sqrt(obj.V^2/((a^2+b^2)/(w^2*obj.M^2)+2*a+w^2*obj.M^2));

            %the optimal zr
            zr = (a + (1i)*b)*(zt')/abs(zt)^2;

            %inserting the new parameters
            obj.Rr = max(real(zr),obj.Rmin);
            obj.Cr = min(1/(w*(w*obj.Lr)-imag(zr)),obj.Cmax);
            WPTManager = setResistance(obj,WPTManager,GlobalTime,obj.Rr);
            WPTManager = setCapacitance(obj,WPTManager,GlobalTime,obj.Cr);
		end
    end
end
