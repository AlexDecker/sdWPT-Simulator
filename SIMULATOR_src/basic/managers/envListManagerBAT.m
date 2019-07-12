%Based on envListManager, but with support to energy consumers (devices)

classdef envListManagerBAT
    
    properties
        ENV %envListManager
        deviceList %list of structs where the field 'obj' contains 'Device'-friendly objects

		%TODO: save a list of voltages and times is now useless. Calculate and integrate the current
		%every time the voltage changes
        Vlist %list of voltage vectors updated but still not processed
        Tlist %times where the voltages were updated

        CurrTime %Last moment that we have knowledge about (reading or writing parameters)
        previousRL %RL of the last iteration (for performance reasons)
        step %integration step
        first %boolean. Is it the first time that the batteries are being updated?

        showProgress %if true, prints from time to time the progress regarding the total time
        lastPrint %used for reducing the number of progress prints
        
        TRANSMITTER_DATA %simulationResults (TX)
        DEVICE_DATA %list of simulationResults (RX)
        nt %number of transmitting RLC rings
        nt_groups %number of transmitting devices (groups of RLC rings)

        latestCI %the last calculated values of current (phasors)
    end

    methods
        function obj = envListManagerBAT(elManager,deviceList,step,showProgress)
            obj.ENV = elManager;
            obj.deviceList = deviceList;

            obj.nt_groups = length(obj.ENV.Vt_group);
            
            gm = getGroupMarking(obj.ENV);
            obj.nt = sum(sum(gm(:,1:obj.nt_groups)));
            
            obj.Vlist = zeros(length(obj.ENV.Vt_group),0);
            obj.Tlist = [];
            obj.CurrTime = 0;

            obj.previousRL = zeros(length(deviceList),1);
            obj.step = step;
            obj.first = true;

            obj.showProgress=showProgress;
            obj.lastPrint=0;

            obj.latestCI = zeros(length(obj.ENV.envList(1).Coils),1);
            
            obj.TRANSMITTER_DATA = simulationResults(0);
            
            obj.DEVICE_DATA=[];
            for i=1:length(deviceList)
                obj.DEVICE_DATA = [obj.DEVICE_DATA simulationResults(i)];
            end

            if ~check(obj)
                error('envListManagerBAT: parameter error');
            end
        end

        %verifies if the attibutes are valid
        function r=check(obj)
            r=(obj.step>0)&&check(obj.ENV);
            r=r&&(length(obj.ENV.R_group)==obj.nt_groups + length(obj.deviceList));
            for i=1:length(obj.deviceList)
                r = r && check(obj.deviceList(i).obj);
            end
        end

        %updates the transmitters' voltage vector
        function obj = setVt(obj, Vt, CurrTime)
            if(length(Vt)~=obj.nt_groups)
                error('envListManagerBAT: Inconsistent value of Vt');
            end
            if(CurrTime<obj.CurrTime)
                error('envListManagerBAT (setVt): Inconsistent time value');
            end

            obj.CurrTime = CurrTime;
            obj.Vlist = [obj.Vlist Vt];
            obj.Tlist = [obj.Tlist CurrTime];
        end   
		
		%for evaluation and measurements
        function Z = getCompleteLastZMatrix(obj)
        	Z = composeZMatrix(getZ(obj.ENV,obj.CurrTime),...
        		[obj.ENV.RS*ones(obj.nt_groups,1);obj.previousRL],getGroupMarking(obj.ENV));
        end

        %Calculates the load resistance vector which abstracts the devices within the system
        function [obj,RL] = calculateAllRL(obj,time,Vt)
        	
        	%expected current
            Ie = zeros(length(obj.deviceList),1);
            
            %if the battery already has a RL definition, it informs the correct value here.
            %if not, -1
            staticRL = zeros(length(obj.deviceList),1);
            for i=1:length(obj.deviceList)
            	
            	staticRL(i) = getRL(obj.deviceList(i).obj);
            	
                [obj.deviceList(i).obj,Ie(i)] = expectedCurrent(obj.deviceList(i).obj); 
                %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
                obj.DEVICE_DATA(i) = logIEData(obj.DEVICE_DATA(i),Ie(i),time);
                %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            Z = getZ(obj.ENV,time);%actual impedance matrix
            
            %calculate adaptatively the unknown values
            [RL,~,~]=calculateRLMatrix(Vt,Z,Ie,obj.previousRL,...
            obj.ENV.err,obj.ENV.maxResistance,obj.ENV.ifactor,...
            obj.ENV.dfactor,obj.ENV.iVel,getGroupMarking(obj.ENV),...
            staticRL);

            %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%
            for i=1:length(obj.deviceList)
                obj.DEVICE_DATA(i) = logRLData(obj.DEVICE_DATA(i),RL(i),time);
            end
            %LOG%%%%%%%%%%%%%%%%%%%%%%%%%%

            obj.previousRL = RL;%para recalcular futuramente com mais efici�ncia
        end

        function [obj,I1] = integrateCurrent(obj,t0,t1,Vt)        
            obj.ENV.Vt_group = Vt;
            t = t0;
            [obj,RL] = calculateAllRL(obj,t,Vt);
            [obj.ENV,I0,obj.TRANSMITTER_DATA] = getCurrent(obj.ENV,RL,...
                obj.TRANSMITTER_DATA,t);
            %log-------------------
            obj.TRANSMITTER_DATA = logBCData(obj.TRANSMITTER_DATA,...
                I0(1:obj.nt),t);
            for i=1:length(obj.DEVICE_DATA)
            	[c0,c1] = getGroupLimits(obj.ENV,obj.nt_groups+i);
                obj.DEVICE_DATA(i) = logBCData(obj.DEVICE_DATA(i),...
                    I0(c0:c1),t);
            end
            %log-------------------
            I1=I0;%default value
            step = min(obj.step,t1-t0);%avoiding too big steps...
            
            while(true)
                if(t==t1)
                    break;
                else
                    if(t+step>t1)
                        t = t1;
                        step = t1-t;
                    else
                        t = t+step;
                    end 
                end
				%calculating the equivalent resistance of the energy consumers
                [obj,RL] = calculateAllRL(obj,t,Vt);
                
				%calculating the current for each RLC ring
                [obj.ENV,I1,obj.TRANSMITTER_DATA] = getCurrent(obj.ENV,RL,...
                    obj.TRANSMITTER_DATA,t);
                    
				%finding the average point with the last sample
                meanI = (I1+I0)/2;
                meanI_group = getGroupMarking(obj.ENV)'*meanI;
                
                %log-------------------
                obj.TRANSMITTER_DATA = logBCData(obj.TRANSMITTER_DATA,...
                    meanI(1:obj.nt),t);
                for i=1:length(obj.DEVICE_DATA)
                	[c0,c1] = getGroupLimits(obj.ENV,obj.nt_groups+i);
                    obj.DEVICE_DATA(i) = logBCData(obj.DEVICE_DATA(i),...
                        meanI(c0:c1),t);
                end
                %log-------------------
                
				%updating the stated of the devices (battery, operation or other used-defined feature)
				%according to the actual current and the update time interval t.
                for i=1:length(obj.deviceList)
                    [obj.deviceList(i).obj,obj.DEVICE_DATA(i)] = updateDeviceState(obj.deviceList(i).obj,...
                    meanI_group(length(Vt)+i), step,obj.DEVICE_DATA(i),t);
                end
                
                I0 = I1;
                
				%data visualization
                if obj.showProgress && (obj.lastPrint ~= round(100*t/obj.ENV.tTime))
                    disp(['progress (until totalTime): ',num2str(round(100*t/obj.ENV.tTime)),'%']);
                    obj.lastPrint = round(100*t/obj.ENV.tTime);
                end
            end
        end

		%updates the charge of the batteries, but admitting variable tensions
        function [obj,I] = updateBatteryCharges(obj,time)
            if(time<obj.CurrTime)
                error('envListManagerBAT: Inconsistent time value');
            end
            if(isempty(obj.Tlist))
                warningMsg('(envListManagerBAT) nothing to compute');
                I = zeros(length(obj.deviceList),1);
                return;
            end

            obj.first = false;
            while length(obj.Tlist)>=2
                t0 = obj.Tlist(1);
                Vt = obj.Vlist(:,1);
                t1 = obj.Tlist(2);
                obj.Tlist = obj.Tlist(2:end);
                obj.Vlist = obj.Vlist(:,2:end);
                [obj,I] = integrateCurrent(obj,t0,t1,Vt);
            end
            t0 = obj.Tlist(1);
            Vt = obj.Vlist(:,1);
            t1 = time;
            [obj,I] = integrateCurrent(obj,t0,t1,Vt);
            obj.Tlist(1) = time;
            obj.CurrTime = time;
        end

        %'tolerance' may be used for performance improvement
        function [cI,I,cI_groups,Q,obj] = getSystemState(obj,CurrTime,tolerance)
            s = size(obj.Vlist);
            nCol = s(2);
            if exist('tolerance','var')
                tolerance_val = tolerance;
            else
                tolerance_val = 0;%default value
            end
			%recalculate if the last measurement is too old, if the voltage changed
			%or ir it is the first measurement
            if((abs(CurrTime-obj.CurrTime)>tolerance_val)||(nCol~=1)||(obj.first))
                [obj,cI] = updateBatteryCharges(obj,CurrTime);
                obj.latestCI = cI;
            else
                cI = obj.latestCI;%return the last calculated value
            end
            Q = zeros(length(obj.deviceList),1);
            for i=1:length(obj.deviceList)
                Q(i) = obj.deviceList(i).obj.bat.Q;
            end
            I = abs(cI);
            cI_groups = getGroupMarking(obj.ENV)'*cI;
        end
        
		%calculates the current vector and the impedance matriz based on
		%statistics from simulationResults for a given moment t
        function [curr,Z] = getEstimates(obj,t)
            curr = getCurrentEstimate(obj.TRANSMITTER_DATA,t);
            RS = getRLEstimate(obj.TRANSMITTER_DATA,t);
            RL = [];
            for i=1:length(obj.DEVICE_DATA)
                curr = [curr;getCurrentEstimate(obj.DEVICE_DATA(i),t)];
                RL = [RL;getRLEstimate(obj.DEVICE_DATA(i),t)];
            end
            
            Z = composeZMatrix(getZ(obj.ENV,obj.CurrTime),...
        		[RS*ones(obj.nt_groups,1);RL],getGroupMarking(obj.ENV));
        end
    end
end
