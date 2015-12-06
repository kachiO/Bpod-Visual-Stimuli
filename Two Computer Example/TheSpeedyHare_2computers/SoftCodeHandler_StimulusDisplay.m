function SoftCodeHandler_StimulusDisplay(StimID)
if StimID ~= 255
    PsychToolboxDisplayServer('Play', StimID); 
else
    PsychToolboxDisplayServer('StopAll');
end