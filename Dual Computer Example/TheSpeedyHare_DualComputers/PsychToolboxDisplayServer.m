%% PsychToolboxDisplayServer.m
% Written by Kachi Odoemene, Dec 2015
function PsychToolboxDisplayServer(command, varargin)
global BpodSystem

switch lower(command)
    
    case 'init' %initialize UDP communication with stimulus computer
        disp('PsychToolboxDisplayServer: Establishing UDP communication with stimulus computer...')
        remoteIPaddress = '192.168.0.2';
        
        port = instrfindall('RemoteHost',remoteIPaddress);
        if length(port) > 0;
            fclose(port);
            delete(port);
            clear port;
        end
        
        %declare udp handle and set properties
        udpHandle = udp(remoteIPaddress,'RemotePort',15724,'LocalPort',8844);
        set(udpHandle, 'OutputBufferSize', 1024)
        set(udpHandle, 'InputBufferSize', 1024)
        set(udpHandle, 'Datagramterminatemode', 'off')
        set(udpHandle, 'Timeout',20)
        
        %Establish serial port event callback criterion
        udpHandle.BytesAvailableFcnMode = 'Terminator';
        udpHandle.Terminator = '~'; %Magic number to identify request from Stimulus ('c' as a string)
        udpHandle.bytesavailablefcn = @StimulusDisplayCallback;
        
        % open and check status
        fopen(udpHandle);
        stat=get(udpHandle, 'Status');
        if ~strcmp(stat, 'open')
            disp(' PsychToolboxDisplayServer: trouble opening port; cannot proceed');
            udpHandle= [];
            return;
        else
            disp(['PsychToolboxDisplayServer: Connection with Stimulus computer on ' remoteIPaddress ' established';])
        end
        
        BpodSystem.PluginObjects.StimulusDisplay.StimIPAddress = remoteIPaddress;
        BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle = udpHandle;
        
        %send monitor parameters
        monitorParameters; %loads monitor parameters
        
        msg = 'M';
        msg = sprintf('%s;%s=%.4f',msg,'screenDist',BpodSystem.PluginObjects.StimulusDisplay.ScreenDistance);
        msg = [msg ';~'];  %add the "Terminator"
        
        fwrite(DcomState.serialPortHandle,msg);


    case 'update' %update stimulus parameters. Based on updatePstate.m
        disp('PsychToolboxDisplayServer: Updating parameters...');
        parameterStruct = varargin{2};
        
        Pstate = BpodSystem.PluginObjects.StimulusDisplay.Parameters; %get the current stimulus parameters
        parameterNames = fieldnames(parameterStruct);
        parameterVals = struct2cell(parameterStruct);
        
        for p = 1:numel(parameterNames)
            thisParamName = parameterNames(p);
            thisParamVal = parameterVals(p);
            if strcmpi(thisParamName,Pstate.param{p}{1})
                idx = p;
                switch Pstate.param{idx}{2}
                    case 'float'
                        Pstate.param{idx}{3} = str2num(thisParamVal);
                    case 'int'
                        Pstate.param{idx}{3} = str2num(thisParamVal);
                    case 'string'
                        Pstate.param{idx}{3} = thisParamVal;
                end
            end
        end
        
        BpodSystem.PluginObjects.StimulusDisplay.Parameters = Pstate; %update stimulus parameters
        disp('PsychToolboxDisplayServer: Stimulus parameters updated.')
        
    case 'build' %send Stimulus parameters for building the visual stimulus. Based on buildStimulus.m
        stimID = varargin{1};
        udpHandle = BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle;
        Pstate = BpodSystem.PluginObjects.StimulusDisplay.Parameters; %get current parameters
        
        disp(['PsychToolboxDisplayServer: Sending command to build ' stimID ' stimulus...']);
        
        msg = ['B;' stimID ';']; %start message
        
        %format parameters to be sent        
        for i=1:length(Pstate.param)
            params = Pstate.param{i};
            switch params{2}
                case 'float'
                    msg = sprintf('%s;%s=%.4f',msg,params{1},params{3});
                case 'int'
                    msg = sprintf('%s;%s=%d',msg,params{1},round(double(params{3})));
                case 'string'
                    msg = sprintf('%s;%s=%s',msg,params{1},params{3});
            end
        end
        
        msg = [msg ';~'];  %add the message "Terminator"
        
        fwrite(udpHandle,msg); %write message containing parameters to stimulus display computer
        disp('PsychToolboxDisplayServer: Stimulus instructions sent to stimulus display computer.')
        waitForDisplayResponse;%await response from display computer
        disp('PsychToolboxDisplayServer: Stimulus display computer acknowledges receipt of instructions. Stimulus ready to go.')

    case 'send' %send parameters to stimulus computer. Used by StimulusPreviewer. Based on "sendPinfo.m". THis might be redundant
        disp('PsychToolboxDisplayServer: Sending stimulus parameters to display computer...')

        udpHandle = BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle;
        stimID = BpodSystem.PluginObjects.StimulusDisplay.StimulusID;
        Pstate = BpodSystem.PluginObjects.StimulusDisplay.Parameters;
        
        msg = ['P;' stimID]; %start message
        
        %format parameters to be sent
        for i=1:length(Pstate.param)
            params = Pstate.param{i};
            switch params{2}
                case 'float'
                    msg = sprintf('%s;%s=%.4f',msg,params{1},params{3});
                case 'int'
                    msg = sprintf('%s;%s=%d',msg,params{1},round(double(params{3})));
                case 'string'
                    msg = sprintf('%s;%s=%s',msg,params{1},params{3});
            end
        end
        
        msg = [msg ';~'];  %add the message "Terminator"
        fwrite(udpHandle,msg); %write message
        disp('PsychToolboxDisplayServer: Parameters sent to stimulus computer');
        waitForDisplayResponse; %wait for response from display computer
        disp('PsychToolboxDisplayServer: Stimulus display computer acknowledged message');
        
    case 'play' %play visual stimulus
        stimID = varargin{1};
        playStimulus(stimID);
        
    case 'stop'
        %send blank screen
        
    case 'stopall'
        %send blank screen
        
end
end
%% axuilary functions:
%% function StimulusDisplayCallback
function StimulusDisplayCallback(obj,evt)
%Callback function from Stimulus PC

global BpodSystem

n=get(BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle,'BytesAvailable');
if n > 0
    inString = fread(BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle,n);
    inString = char(inString');
else
    return
end

inString = inString(1:end-1);
disp(['Message received from stimulus computer: ' inString]);
end
%% function waitForDisplayResponse

function waitForDisplayResponse
%wait for the stimulus computer to respond

global BpodSystem

udpHandle = BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle;

%Clear the buffer
n = get(udpHandle,'BytesAvailable');
if n > 0
    fread(udpHandle,n); %clear the buffer
end

%Wait...
n = 0;  %Need this, or it won't enter next loop (if there were leftover bits)!!!!
while n == 0
    n = get(udpHandle,'BytesAvailable'); %Wait for response
end
pause(.5) %Hack to finish the read

n = get(udpHandle,'BytesAvailable');
if n > 0
    fread(udpHandle,n); %clear the buffer
end
end


%% function playStimulus
function playStimulus(stimID)
% send byte to stimulus computer to play stimulus
global BpodSystem

switch stimID
    case 1
        %speed grating stimulus
        moduleID = 'SG';
        
    case 2
        %fullscreen checkboard stimulus- incorrect trials
        moduleID = 'CB';
end

msg = ['G;' moduleID ';~'];

fwrite(BpodSystem.PluginObjects.StimulusDisplay.UDPPortHandle,msg);
end

%%



