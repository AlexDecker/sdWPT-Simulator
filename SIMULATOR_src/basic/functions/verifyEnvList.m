function r = verifyEnvList(envList)
	if(length(envList)<2)
		r = false;
		return;
	end
	
	n_groups = length(envList(1).R_group);
	n = length(envList(1).Coils);
	
	r = true;
	for i=1:length(envList)
		r = r && check(envList(i));
		r = r && (length(envList(i).Coils)==n);
		r = r && (length(envList(i).C_group)==n_groups);
		r = r && (length(envList(i).R_group)==n_groups);
	end
end
