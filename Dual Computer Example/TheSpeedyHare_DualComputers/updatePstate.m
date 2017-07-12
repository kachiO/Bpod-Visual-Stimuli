function updatePstate(psymbol,pval)

global BpodSystem

BpodSystem.StimulusDisplay.Parameters = BpodSystem.StimulusDisplay.Parameters;


for i = 1:length(BpodSystem.StimulusDisplay.Parameters .param)
    if strcmp(psymbol,BpodSystem.StimulusDisplay.Parameters .param{i}{1})
    	idx = i;
        break;
    end
end

switch BpodSystem.StimulusDisplay.Parameters.param{idx}{2}
    
   case 'float'
      BpodSystem.StimulusDisplay.Parameters.param{idx}{3} = str2num(pval);
   case 'int'
      BpodSystem.StimulusDisplay.Parameters.param{idx}{3} = str2num(pval);
   case 'string'
      BpodSystem.StimulusDisplay.Parameters.param{idx}{3} = pval;
end
   


