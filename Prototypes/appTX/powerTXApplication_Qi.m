%TX application according to Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
	properties
		dt%time variation step (time events)
		V%transmission voltage
		imax%maximum acceptable receiving current
		pmax%maximum acceptable active power
		dw%operational frequency variation step 
		w%operational frequancy (now)
	
		%state:
		%0 - search turned off (after starting this state, the transmitter turns off and the timer turns on.
		%When the time event is triggered, go to state 1)
		%1 - search turned on (after starting this state, the transmitter turns on and a ping is sent via
		%SWIPT broadcast)
		%and the time event is scheduled. If an answare is not received untill the timer is triggered, the
		%state goed to 0. If it is received, it goes to state 2)
		%2 - Transmitting... (time events at each dt interval, increments okUntil by dt at each received
		%message and if globalTime reaches okUntil, it goes to state 0).
		state
		%the time moment at which the system goes to state 0 (updated if a new message arrives)
		okUntil
        
		%imax-i (previous round)
		lastVar
		%the signal of the variation of the operational frequency at previous round(-1,1)
		ddw
		
		%probability of a message to be lost due pertubations over the coils movement
		endProb
	end
	methods
		function obj = powerTXApplication_Qi(dt,V,pmax,dw,endProb)
			obj@powerTXApplication();%building superclass structure
			
			obj.okUntil = 0;%dummie
			obj.state = -1;%dummie
			obj.dt = dt;
			obj.V = V;
		
			obj.imax = 1.2;%default (A)
			obj.pmax = pmax;
			obj.dw = dw;
			obj.w = 2*pi*4000;%4kHz

			obj.lastVar = 0;
			obj.ddw = 1;
			obj.endProb = endProb;
		end

		function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        		%SWIPT, 2048bps (according to IC datasheet), 5W (dummie)
			obj = setSendOptions(obj,0,2048,5);

			%starts at state 0
			[obj,WPTManager] = goToStateZero(obj,WPTManager,0);

			%log will receive w data
			obj.APPLICATION_LOG.DATA = zeros(3,0);
            
			netManager = setTimer(obj,netManager,0,obj.dt);%schedules the timer
		end

		function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        	switch(obj.state)
			case 1
				if length(data)==2
					%somebody answered the ping. Start the power transmission
		    			obj.imax = data(2);
		    			[obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime);
		    			disp('Connection established');
		    		end
        		case 2
				if rand>=obj.endProb
					obj.okUntil = GlobalTime+obj.dt; %renova o atestado por mais um ciclo
						
					[It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime);
					pot = real([sum(It);data(1)]'*[obj.V;0]);%calculates the active power
						
					%adjusts the operational frequency
					%(as the ressonant frequency is ~100 KHz, when the frequency
					%increases, it gets further from the ressonance and therefore the 
					%received power decreases)

					ddw = 0;
					variation = obj.imax-abs(data(1));
					
					if (variation<0)||(pot>=obj.pmax) %reduces the received power
						if obj.lastVar>0 %if passed by the optimum point
							ddw = -obj.ddw;%come back
						else
							if obj.lastVar<0
								if abs(obj.lastVar)>abs(variation) %if the
								%result got better
									ddw = obj.ddw;%keep going
								else
									ddw = -obj.ddw;%come back
								end
							else %no information
								ddw = 1;%start from somewhere
							end
						end
					else
						if (variation>0) %increase the receiving power
							if obj.lastVar<0 %if passed by the optimim point
								ddw = -obj.ddw;%come back
							else
								if obj.lastVar>0
									if abs(obj.lastVar)>abs(variation)
									%if it got better
										ddw = obj.ddw;%keep going
									else
										ddw = -obj.ddw;%go back
									end
								else %no information
									ddw = 1;%start somehow
								end
							end
						end
					end
					%if the change is acceptable, update the frequency	
					if (obj.w+ddw*obj.dw>=2*pi*110000) && (obj.w+ddw*obj.dw<=2*pi*205000)
						%disp(['TX: ',num2str(obj.w/(2*pi*1000)),' KHz']);
						WPTManager = setOperationalFrequency(...
							obj,WPTManager,GlobalTime,obj.w+ddw*obj.dw);
						obj.w = obj.w+ddw*obj.dw;
					end
					
					obj.lastVar = variation;
					obj.ddw = ddw;
						
					logW = [obj.w/(2*pi);abs(data(1));GlobalTime];
					obj.APPLICATION_LOG.DATA = [obj.APPLICATION_LOG.DATA,logW];
				end
			end
		end

		function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
			switch(obj.state)
				case 0
					%alternating between states 0 and 1
					[obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime);
				case 1
					%alternating between states 0 and 1
					[obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime);
				case 2
					%it is still transmitting, but the continuing message did not arrive at time
					if(obj.okUntil<=GlobalTime)
						%turn off the transmission and restart the search
						disp('Connection lost');
						[obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime);
					end
			end
			%chamada para o próximo ciclo
			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
		end
        
		%finite automata state description (actions just after the transition)

		function [obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime)
			obj.state = 0;
			WPTManager = turnOff(obj,WPTManager,GlobalTime);%turns off the power transmission
			%the timer is already scheduled automatically
		end

		function [obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime)
			obj.state = 1;
			%disp('TX: 4 KHz');
			WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,2*pi*4000);%4kHz
			obj.w = 2*pi*4000;
			WPTManager = turnOn(obj,WPTManager,GlobalTime);%turns on the power transmitter (analog ping)
		end

		function [obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime)
			obj.state = 2;
			%disp('TX: 110 KHz');
			WPTManager = setOperationalFrequency(obj,WPTManager,GlobalTime,2*pi*110000);%110kHz
			obj.w = 2*pi*110000;
			WPTManager = turnOn(obj,WPTManager,GlobalTime);%turns on the power transmitter
			obj.okUntil = GlobalTime + obj.dt;
			obj.lastVar = 0;
			obj.ddw = 1;
		end


		%basic functions of the system
        
		function WPTManager = turnOn(obj,WPTManager,GlobalTime)
			WPTManager = setSourceVoltages(obj,WPTManager,obj.V,GlobalTime);
		end

		function WPTManager = turnOff(obj,WPTManager,GlobalTime)
			WPTManager = setSourceVoltages(obj,WPTManager,0,GlobalTime);
		end
	end
end
