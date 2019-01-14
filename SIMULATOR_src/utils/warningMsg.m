function warningMsg(Msg,Complement)
    global LAST_MSG;
    global NO_WARNINGS;
	if(NO_WARNINGS)
	else
		if(strcmp(LAST_MSG,Msg)==0)
			if exist('Complement','var')
				disp(['!!! Warning: ',Msg,Complement]);
			else
				disp(['!!! Warning: ',Msg]);
			end
			LAST_MSG = Msg;
		end
	end
end
