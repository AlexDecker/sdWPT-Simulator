%abstracts the environment at a given time moment
classdef Environment
    properties
        Coils
        groupMarking
        M
        R_group
        C_group
        w
        miEnv %magnetic permeability of the medium
    end
    methods
	    %Parameters:
	    %w - Operational angular frequency of the source's signal
	    %miEnv - magnetic permeability of the medium (H/m)
	    %groups - each element of this vector corresponds to one of the system's circuit, which 		%is composed by a RLC ring attached to an arbitrary number of parallel coils
        %Expected structure for the groups:
        %groups(i) - List of structs
        %	.coils(j) - List of structs
        %		.obj  - coil object
        %	.R - Resistance value (real positive or -1)
        %	.C - Capacitance value (real positive)
        function obj = Environment(groups,w,miEnv)
        	obj.w = w;
            obj.miEnv = miEnv;
            obj.Coils = [];
            obj.R_group = [];
            obj.C_group = [];
            obj.groupMarking = zeros(0,length(groups));
            
            for i=1:length(groups)
            	obj.Coils = [obj.Coils;groups(i).coils];
		        obj.R_group = [obj.R_group;groups(i).R];
		        obj.C_group = [obj.C_group;groups(i).C];
		        gm = [zeros(length(groups(i).coils),i-1),...
		        		ones(length(groups(i).coils),1),...
		        		zeros(length(groups(i).coils),length(groups)-i)];
		        obj.groupMarking = [obj.groupMarking;gm];
            end
            
            if(~check(obj))
            	error('Environment: parameter error');
            end
        end

        function r = check(obj)
        	s = size(obj.groupMarking);
        	r = checkGroupMarking(obj.groupMarking);
        	r = r && (length(obj.C_group)==length(obj.R_group))&&(obj.w>0)&&(obj.miEnv>0);
        	r =	r && (s(1)==length(obj.Coils)) && (s(2)==length(obj.R_group));
            for i = 1:length(obj.Coils)
                r = r && check(obj.Coils(i).obj);
            end
        end
		
		%find the indices for the beggining and the end of a given group. The numeration of
		%the groups starts at 1
		function [c0,c1] = getGroupLimits(obj,g)
			if(g==1)
				c0=1;
			else
				c0=sum(sum(obj.groupMarking(:,1:(g-1))))+1;
			end
			c1=sum(sum(obj.groupMarking(:,1:g)));
		end
		
        %Unknown values of M must be specified as -1.
        function obj = evalM(obj,M)
            for i = 1:length(M)
                for j = 1:length(M)
                    if (M(i,j)==-1)
                        if(M(j,i)~=-1)
                            M(i,j)=M(j,i);
                        else
                            M(i,j)=evalMutualInductance(obj.Coils(i).obj, obj.Coils(j).obj);
                        end
                    end
                end
            end
            obj.M=M;
        end

        function Z = generateZENV(obj)
            if isempty(obj.Coils)
            	miVector = obj.miEnv*ones(length(obj.M),1);
           	else
		        miVector = zeros(length(obj.M),1);
		        for i=1:length(miVector)
		        	miVector(i) = obj.Coils(i).obj.mi;
		        end
		    end
            L = (obj.groupMarking*obj.C_group ~= -1).*diag(obj.M); %if C=-1, resonance
            
            Z = - (1i)*obj.w*obj.miEnv*(obj.M-diag(diag(obj.M)));...%mutual inductance
                + (1i)*obj.w*diag(miVector.*L);%self-inductance
            
            %compose the final matrix (if C=-1, resonance)
            Z = composeZMatrix(Z,...
            	obj.R_group-(obj.C_group ~= -1).*(1i)./(obj.w*obj.C_group),...
            	obj.groupMarking);
        end
    end
end
