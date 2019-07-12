%This class controls a list of environment objects and use them for estimating
%the entire system (except by energy consumers) at each moment.
classdef envListManager
    properties
        envList
        Vt_group %column vector with the voltage of each transmitting group (V) 
        R_group %column vector with the resistance of each group (ohm)
		C_group %the same as above, but for capacitances
        w %angular operational frequency (rad/s)
        tTime %time between the first (time=0) and the last frame (s)
        err %acceptable error for power calculation (%)
        maxResistance %ceil for the resistance values (ohm)
        ifactor %> 1 and < dfactor, used for searching RS
        dfactor
        iVel %initial velocity for searching RS
        maxActPower %maximum active power for the voltage source
		maxAppPower %maximum apparent power for the voltage source (limits the current)
        mostRecentZ %most recent calculated Z matrix 
		miEnv %magnetic permeability of the medium
        RS %last calculated RS, used for easily finding the next value
    end
    methods
        function obj = envListManager(envList,Vt_group,w,R_group,tTime,err,...
            maxResistance,ifactor,dfactor,iVel,maxActPower,maxAppPower,miEnv)
            obj.envList = envList;
            obj.Vt_group = Vt_group;
            obj.w = w;
            obj.R_group = R_group;
			obj.C_group = -ones(length(R_group),1);
            obj.tTime=tTime;

            obj.err=err;
            obj.maxResistance=maxResistance;
            obj.ifactor=ifactor;
            obj.dfactor=dfactor;
            obj.iVel=iVel;
			obj.maxActPower = maxActPower;
			obj.maxAppPower = maxAppPower;
            if exist('miEnv','var')
                obj.miEnv = miEnv;
            else
                obj.miEnv = pi*4e-7;
            end

            obj.RS = 0;
            if ~check(obj)
                error('envListManager: parameter error');
            else
                disp(['Environment Manager created with ',num2str(length(obj.Vt_group)),...
                    ' active groups and ',num2str(length(obj.R_group)-length(obj.Vt_group)),' passives']);
            end
            
            obj.mostRecentZ = getZ(obj,0);
        end

        %verify if the attributes of this object are valid
        function r = check(obj)
            r = true;
            for i = 1:length(obj.envList)
                r = r && check(obj.envList(i));
            end
            
            if (obj.w<=0) || (obj.tTime<=0)
                warningMsg('The angular frequency and the tTime must both be real positive.');
                r = false;
            end
            
            if (sum(obj.R_group<=0)~=0)||(sum(obj.R_group>obj.maxResistance)~=0)
                warningMsg('The resistance values must be real positive and less then maxResistance.');
                r = false;
            end
            
            if ((length(obj.R_group)>length(obj.mostRecentZ)) &&...
                ~isempty(obj.mostRecentZ)) ||...
				length(obj.C_group)~=length(obj.R_group) ||...
                (length(obj.R_group)~=length(obj.envList(1).R_group)) ||...
                (length(obj.Vt_group)>=length(obj.R_group))
                warningMsg('Please review the lengths of R_group, C_group and Vt_group.');
                disp('R_group:');
                disp(obj.R_group);
				disp('C_group:');
				disp(obj.C_group);
                disp('Vt_group:');
                disp(obj.Vt_group);
                r = false;
            end
                
            if (obj.err<=0) || (obj.err>=1)
                warningMsg('err must be more then 0 and less then 1.');
                r = false;
            end 
                
            if (obj.ifactor<=1)||(obj.dfactor<=obj.ifactor)
                warningMsg('You must respect the relation 1<ifactor<dfactor.');
                r = false;
            end
                
            if (length(obj.ifactor)~=1)||(length(obj.dfactor)~=1)|| ...
                (length(obj.iVel)~=1)||(length(obj.maxActPower)~=1)|| ...
                (length(obj.maxAppPower)~=1)||(obj.iVel<=0)||...
				(obj.maxActPower<=0)||(obj.maxAppPower<=0)||...
				(length(obj.maxResistance)~=1)||(obj.maxResistance<=0)				
                warningMsg('ifactor, dfactor, iVel, maxActPower, maxAppPower and maxResistance must be real positive scalars.');
                r = false;
            end
        end
        
        function groupMarking = getGroupMarking(obj)
        	groupMarking = obj.envList(1).groupMarking;
        end
        
        function [c0,c1] = getGroupLimits(obj,g)
            [c0,c1] = getGroupLimits(obj.envList(1),g);
        end

        %the data is estimated using convex linear combination:
        %data[time] = data[i0]*lambda+(1-lambda)*data[1]
        function [i0,i1,lambda] = getIndexFromTime(obj,time)
            n = length(obj.envList);
            i = 1+(n-1)*time/obj.tTime;
            i0 = floor(i);
            i1 = ceil(i);
            lambda = i1-i;
        end

        function Z = getZ(obj,time)%impedance matrix
            [i0,i1,lambda] = getIndexFromTime(obj,time);
			
			%define as R the values of resistance previously marked with -1
            obj.envList(i0).R_group = obj.envList(i0).R_group...
            	+ (obj.envList(i0).R_group<0).*(obj.R_group-obj.envList(i0).R_group);
			
			%define new values of capacitance if each position of C_group is valid
			obj.envList(i0).C_group = obj.envList(i0).C_group...
            	+ (obj.C_group>=0).*(obj.C_group-obj.envList(i0).C_group);
            
			obj.envList(i0).miEnv = obj.miEnv;
            obj.envList(i0).w = obj.w;
            Z0 = generateZENV(obj.envList(i0));

			%define as R the values of resistance previously marked with -1
            obj.envList(i1).R_group = obj.envList(i1).R_group...
            	+ (obj.envList(i1).R_group<0).*(obj.R_group-obj.envList(i1).R_group);
            
			%define new values of capacitance if each position of C_group is valid
			obj.envList(i1).C_group = obj.envList(i1).C_group...
            	+ (obj.C_group>=0).*(obj.C_group-obj.envList(i1).C_group);

           	obj.envList(i1).miEnv = obj.miEnv;
            obj.envList(i1).w = obj.w;
            Z1 = generateZENV(obj.envList(i1));

            Z = lambda*Z0+(1-lambda)*Z1;%linear interpolation
        end

        %generates a matrix in which each line is the ordered triple of the center of each coil.
        function P = getCenterPositions(obj,time)
            [i0,i1,lambda] = getIndexFromTime(obj,time);
            P0 = zeros(length(obj.envList(i0).Coils),3);
            P1 = zeros(length(obj.envList(i1).Coils),3);
            for j = 1:length(obj.envList(i0).Coils)
                P0(j,:) = [obj.envList(i0).Coils(j).obj.X,...
                    obj.envList(i0).Coils(j).obj.Y, obj.envList(i0).Coils(j).obj.Z];
                P1(j,:) = [obj.envList(i1).Coils(j).obj.X,...
                    obj.envList(i1).Coils(j).obj.Y, obj.envList(i1).Coils(j).obj.Z];
            end
            P = lambda*P0 + (1-lambda)*P1;
        end

        %RL_group: equivalent resistance of each receiving group.
        function [obj,I,TRANSMITTER_DATA] = getCurrent(obj,RL_group,...
            TRANSMITTER_DATA,time)
            if ~check(obj)
                error('envListManager: attribute violation');
            end
            Z = getZ(obj,time);
            [obj.mostRecentZ,obj.RS,I]=calculateCurrents(obj.Vt_group,Z,RL_group,...
                obj.RS,obj.err,obj.maxResistance,obj.ifactor,obj.dfactor,...
                obj.iVel,obj.maxActPower,obj.maxAppPower,getGroupMarking(obj));
            TRANSMITTER_DATA = logRLData(TRANSMITTER_DATA,obj.RS,time);
        end
    end
end
