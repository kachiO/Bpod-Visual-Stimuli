function SoftCodeHandler_StimulusDisplay(StimID)
%soft code to handle playing stimulus

switch (StimID)
    case 1 %play visual stimulus
        PsychToolboxDisplayServer('play',StimID)
        PsychToolboxSoundServer('StopAll');
    case 254 %clear screen
        PsychToolboxDisplayServer('stop')

    case 255 %stop everything
        PsychToolboxSoundServer('StopAll');
        PsychToolboxDisplayServer('stop')

    otherwise %play auditory stimuli
        PsychToolboxSoundServer('play',StimID);
end

