function BpodMasterCallback(obj,event)
%originally Mastercb.m, written by Ian Nauhaus, Callaway Lab
%Modified Kachi O. Dec 2015

global comState

try
    n = get(comState.serialPortHandle,'BytesAvailable');
     
    if n > 0
        inString = fread(comState.serialPortHandle,n);
        inString = char(inString');
    else
        return
    end
    
    inString = inString(1:end-1);  %Get rid of the terminator
    
    delims = find(inString == ';');
    msgID = inString(1:delims(1)-1);  %Tells what button was pressed at master
    
    if strcmp(msgID,'M') || strcmp(msgID,'C') || strcmp(msgID,'S')
        paramstring = inString(delims(1):end); %list of parameters and their values
    elseif strcmp(msgID,'B')        
        modID = inString(delims(1)+1:delims(2)-1); %The stimulus module (e.g. 'grater')
        paramstring = inString(delims(2):end); %list of parameters and their values
    else
        modID = inString(delims(1)+1:delims(2)-1); %The stimulus module (e.g. 'grater')
        paramstring = inString(delims(2):end); %list of parameters and their values
    end
%     delims = find(paramstring == ';');
    
    switch msgID
        
        case 'M'  %Update monitor info
            
            for i = 1:length(delims)-1
                
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updateMstate(psymbol,pval)
            end
            
        case 'P'  %Update parameter info.
            
            configurePstate(modID)
            for i = 1:length(delims)-1
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updatePstate(psymbol,pval)
            end
            
        case 'B'  %Build stimulus; update looper info and buffer to video card.
            
            for i = 1:length(delims)-1
                dumstr = paramstring(delims(i)+1:delims(i+1)-1);
                id = find(dumstr == '=');
                psymbol = dumstr(1:id-1);
                pval = dumstr(id+1:end);
                updatePstate(psymbol,pval)
            end
            
            makeTexture(modID)
            makeSyncTexture
          
        case 'G'  %Go Stimulus
            
            playstimulus(modID)
            
        case 'MON'  %Monitor info
            
            global Mstate
            
            Mstate.monitor = modID;
            updateMonitor
            
        case 'C'  %Close Display
            Screen('Close')
            Screen('CloseAll');
            %clear all
            %close all
            Priority(0);         
    end
    
    
    fwrite(comState.serialPortHandle,'a')  %dummy so that Master knows it finished
    
catch
    
    Screen('CloseAll');
    ShowCursor;
    
    msg = lasterror;
    msg.message
    msg.stack.file
    msg.stack.line
    
    fwrite(comState.serialPortHandle,'a')  %dummy so that Master knows it finished
    
end
