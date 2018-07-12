function warningMsg(Msg,Complement)
    global lastMsg;
    if(strcmp(lastMsg,Msg)==0)
		if exist('Complement','var')
			disp(['!!! Warning: ',Msg,Complement]);
		else
			disp(['!!! Warning: ',Msg]);
		end
        lastMsg = Msg;
    end
end