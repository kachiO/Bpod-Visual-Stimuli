function modID = getmoduleID

global BpodSystem

modID = get(BpodSystem.GUIhandles.param.module,'value');
switch modID
    case 1
        modID = 'SG';

end