function newPstate(oldPstate)

%Variables that no longer exist will be ignored and new variables will be
%set to default in configurePstate

global BpodSystem

mod = getmoduleID;  %return 2 element string
configurePstate(mod) %resets global to default, but we have oldPstate as the input

for j = 1:length(oldPstate.param) %Loop each variable of the loaded Pstate

    for i = 1:length(BpodSystem.StimulusDisplay.Parameters.param) %Loop each variable of the default Pstate to find it and replace it
        if strcmp(oldPstate.param{j}{1},BpodSystem.StimulusDisplay.Parameters.param{i}{1})  
            
            pval = oldPstate.param{j}{3}; %grab the loaded value
            BpodSystem.StimulusDisplay.Parameters.param{i}{3} = pval;  %replace the default with loaded value
            break;
            
        end
    end

end

