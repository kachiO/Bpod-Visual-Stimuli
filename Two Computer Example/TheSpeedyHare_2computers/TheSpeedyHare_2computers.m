
% Bpod with PsychtoolToolbox Display- two computer solution
% Based on TheSlipperyFish
% Written by Kachi Odoemene Dec 2015

% Speed discrimination task 
            
function TheSpeedyHare_2computers
addpath(genpath(fullfile('~','Bpod-ZadorLab','Protocols','TheSpeedyHare_2computers')));

global BpodSystem

%initialize 
PsychToolboxDisplayServer('init') % Initialize communication with display server
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_StimulusDisplay'; % Set soft code handler to trigger stimuli
StimulusParamPreviewer; %launch stimulus preview panel

%% Define settings for protocol

%Initialize default session settings.
%Append new settings to the end
DefaultSettings.SubjectName = 'Hare';
DefaultSettings.leftRewardVolume = 4; % ul
DefaultSettings.rightRewardVolume = 4;% ul
DefaultSettings.centerRewardVolume = 0;% ul
DefaultSettings.preStimDelayMin = 0.01; % secs
DefaultSettings.preStimDelayMax = 0.1; % secs
DefaultSettings.lambdaDelay = 15;
DefaultSettings.StimulusDuration = 1;
DefaultSettings.minWaitTime = 0.5; % secs
DefaultSettings.minWaitTimeStep = 0.0003;% secs
DefaultSettings.timeToChoose = 3; % secs
DefaultSettings.timeOut = 2; % secs

DefaultSettings.SpeedList = [1 2 4 6 8 10 12 14 16]; %deg/s
DefaultSettings.CategoryBoundary = 8; %deg/s
DefaultSettings.SpatialFreqList = [0.05 0.1]; %cycles/deg
DefaultSettings.Azimuth = 40; % degrees, list of possible azimuths
DefaultSettings.Elevation = 0; %degrees, list of possible elevations
DefaultSettings.Orientation = 45; %degrees , or list of possible orientations
DefaultSettings.StimSize = 40; %in degrees, need to be converted into pixels
DefaultSettings.StimContrast = 1; %0-1

DefaultSettings.PropLeft = 0.5;
DefaultSettings.WaitStartCue = 0;
DefaultSettings.WaitEndGoCue = 1;
DefaultSettings.PlayStimulus = 1;

DefaultSettings.Direct = 0; %this will reflect the probability/fraction of trials that are direct reward
DefaultSettings.UseAntiBias = 0;
DefaultSettings.AntiBiasTau = 4;

DefaultSettings.ExtraStimDuration = 0; %sec
DefaultSettings.ExtraStimDurationStep = 0; %sec
DefaultSettings.PlotPMFnTrials = 100;
DefaultSettings.UpdatePMfnTrials = 5;

defaultFieldParamVals = struct2cell(DefaultSettings);
defaultFieldNames = fieldnames(DefaultSettings);

S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct S
currentFieldNames = fieldnames(S);

if isempty(fieldnames(S)) % If settings file was an empty struct, populate struct with default settings
    S = DefaultSettings;
elseif numel(defaultFieldNames) > numel(currentFieldNames)  %an addition to default settings, update
    differentI = find(~ismember(defaultFieldNames,currentFieldNames)); %find the index
    for ii = 1:numel(differentI)
        thisnewfield = defaultFieldNames{differentI(ii)};
        S.(thisnewfield)=defaultFieldParamVals{differentI(ii)};
    end
end

% Launch parameter GUI
BpodParameterGUI_Visual('init', S);

%%
% ports are numbered 0-7. Need to convert to 8bit values for bpod
LeftPort = 2^0;
CenterPort = 2^1;
RightPort = 2^2;

% Create trial types (left vs right)
maxTrials = 5000;
coin = rand(1,maxTrials);
TrialSidesList = coin > (1-S.PropLeft);
TrialSidesList = TrialSidesList(randperm(maxTrials));
PrevPropLeft = S.PropLeft;

% Antibias parameters
AntiBiasPrevLR =  NaN;
AntiBiasPrevSuccess = NaN;
SuccessArray = 0.5 * ones(2, 2, 2);    % successArray will be: prevTrialLR x prevTrialSuccessful x thisTrialLR
ModalityRightArray = 0.5 * ones(1, 3);

%% Initialize plots
BpodSystem.ProtocolFigures.AllFigures = figure('Position', [500 1000 600 700], 'name', 'All Plots', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Units', 'pixels', 'Position', [70 580 500 100],'tickdir','out');
BpodSystem.GUIHandles.PerformancePlot = axes('Units', 'pixels', 'Position', [70 440 500 100],'tickdir','out');
BpodSystem.GUIHandles.PMFPlot = axes('Units', 'pixels', 'Position', [70 30 240 280],'tickdir','out','ytick',(0:0.25:1),'XGrid','on','YGrid','on','YLim',[0 1.05]);
BpodSystem.GUIHandles.PMFPlotData = line([0 0],[0 0],'LineStyle','-','Marker','.','MarkerSize',6');

SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', TrialSidesList,'ntrials', 60);
PerformancePlot(BpodSystem.GUIHandles.PerformancePlot,'init');

%% Initialize arrays for storing values later
OutcomeRecord = nan(1,maxTrials);
Rewarded = nan(1,maxTrials);
EarlyWithdrawal = nan(1,maxTrials);
DidNotChoose = nan(1,maxTrials);
ResponseSideRecord = nan(1,maxTrials);
modalityRecord = nan(1,maxTrials);
correctSideRecord = nan(1,maxTrials);

TrialsDone =  0;
%%
HandlePauseCondition; 

%% Main loop
for currentTrial = 1:maxTrials
    
    S = BpodParameterGUI_Visual('update', S); drawnow; % Sync parameters with BpodParameterGUI plugin
    
    LeftValveTime = GetValveTimes(S.leftRewardVolume, 1);
    RightValveTime = GetValveTimes(S.rightRewardVolume, 3);
    CenterValveTime = 0;
    
    if S.centerRewardVolume > 0
        CenterValveTime = GetValveTimes(S.centerRewardVolume, 2);
    end
    
    directTrial = rand < S.Direct; %probability of direct reward
    
    if TrialsDone > 1
        outcome  = OutcomeRecord(TrialsDone);
        if outcome > -1
            
            % Update arrays
            [newModalityRightArray, newSuccessArray] = updateAntiBiasArrays(ModalityRightArray, SuccessArray, ...
                modalityRecord(TrialsDone - 1), outcome, ...
                correctSideRecord(TrialsDone -1), ...
                AntiBiasPrevLR, AntiBiasPrevSuccess, ...
                S.AntiBiasTau, ResponseSideRecord(TrialsDone - 1) - 1);
            
            % Update history
            AntiBiasPrevLR = correctSideRecord(TrialsDone -1);
            AntiBiasPrevSuccess = (OutcomeRecord(TrialsDone -1) == 1);
            
            % Update matrices
            SuccessArray= newSuccessArray;
            ModalityRightArray= newModalityRightArray;
            
        end
        
    end %end TrialsDone%
    
    preStimDelay = generate_random_delay(S.lambdaDelay, S.preStimDelayMin, S.preStimDelayMax);
    
    Modality = 'Visual';
    disp('Visual trial');
    modalityNum = 2;
    
    % Anti-bias for coming trial
    % If we've previously done a trial, are using anti-bias, and the
    % previous trial wasn't an early withdrawal or failure to choose,
    % update the next trial.
    % Note: at this point in the trial, 'outcome' is still from the
    % previous trial
    
    % First ensure that anti-bias strength is a sane value, between 0 and 1
    if S.UseAntiBias < 0
        S.UseAntiBias = 0;
    elseif S.UseAntiBias > 1
        S.UseAntiBias = 1;
    end
    
    if TrialsDone > 1 && S.UseAntiBias > 0 && outcome > -1
        
        pLeft = getAntiBiasPLeft(SuccessArray, ModalityRightArray, modalityNum, ...
            S.UseAntiBias, AntiBiasPrevLR, AntiBiasPrevSuccess);
        
        coin = rand(1);
        sidesList = TrialSidesList;
        
        sidesList(currentTrial) = coin > (1 - pLeft); %the sign is important, it must match the way left and right trials are assigned based on prop left/right
        TrialSidesList = sidesList;
        
    elseif TrialsDone > 1 && (S.PropLeft ~= PrevPropLeft) && (S.UseAntiBias == 0)
        % If experimenter changed PropLeft, then we need to recompute the
        % side of the future trials
        ntrialsRemaining = numel(TrialSidesList(currentTrial:end));
        coin = rand(1,ntrialsRemaining);
        FutureTrials = coin > (1-S.PropLeft);
        FutureTrials  = FutureTrials(randperm(ntrialsRemaining));
        TrialSidesList(currentTrial:end) = FutureTrials;
        PrevPropLeft = S.PropLeft;
        
    end %end S.UseAntiBias, S.PropLeft
    
    if TrialsDone > 0
        UpdateOutcomePlot(TrialSidesList, BpodSystem.Data);
    end
    
    % Pick this trial type
    thisTrialSide = TrialSidesList(currentTrial);
    
    if thisTrialSide == 1 % Leftward trial
        %present fastest of gratings on the left
        LeftPortAction = 'Reward';
        RightPortAction = 'SoftPunish';
        RewardValve = LeftPort; %left-hand port represents port#0, therefore valve value is 2^0
        rewardValveTime = LeftValveTime;
        correctSide = 1;
        
        speedList = S.SpeedList(S.SpeedList >= S.CategoryBoundary);

    else % Rightward trial (thisTrialSide == 0)
        %present fastest of gratings on the right
        LeftPortAction = 'SoftPunish';
        RightPortAction = 'Reward';
        RewardValve = RightPort; %right-hand port represents port#2, therefore valve value is 2^2
        rewardValveTime = RightValveTime;
        correctSide = 2;
        speedList = S.SpeedList(S.SpeedList >= S.CategoryBoundary);%select speed above or equal to category boundary
    end
    thisTrialSpeed = shuffleAndPickOne(speedList);  % randomly shuffle eligible speeds and pick one

    disp(['Grating Speed: ' num2str(thisTrialSpeed) 'degrees/s'])
    
    %assign stimulus parameters
    parameters.StimSize = S.StimSize; %in degrees, need to be converted into pixels
    parameters.Speed = thisTrialSpeed; %degrees/s
    parameters.SFreq = shuffleAndPickOne(S.SpatialFreqList);%cycles/degree
    parameters.Orientation = shuffleAndPickOne(S.Orientation); %degrees
    parameters.Elevation = shuffleAndPickOne(S.Elevation);%degrees
    parameters.Azimuth = shuffleAndPickOne(S.Azimuth);%degrees
    parameters.StimDuration = S.StimulusDuration;
    
    if ~S.PlayStimulus
        parameters.PlayStimulus = 0;
        Modality = '-';
    end
    
    PsychToolBoxDisplayServer('update','SG',parameters); %update stimulus parameter
    PsychToolboxDisplayServer('build','SG'); %build stimulus
    
    % Determine whether to play start cue or cue
    if ~S.WaitStartCue
        StartCueOutputAction  = {};
    else
        StartCueOutputAction = {'PWM1', 255,'PWM3', 255};
    end
    
    if ~S.WaitEndGoCue
        GoCueOutputAction  = {};
    else
        GoCueOutputAction = {'PWM1', 255,'PWM3', 255};
    end
    
    % Build state matrix  
    sma = NewStateMatrix();
    
    sma = AddState(sma, 'Name', 'GoToCenter', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'PlayWaitStartCue'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'PlayWaitStartCue', ...
        'Timer', preStimDelay, ...
        'StateChangeConditions', {'Tup','PlayStimulus', 'Port2Out', 'EarlyWithdrawal'},...
        'OutputActions', StartCueOutputAction);
    
    sma = AddState(sma, 'Name', 'PlayStimulus', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup','WaitCenter'},...
        'OutputActions', {'SoftCode', 1});
    
    sma = AddState(sma, 'Name', 'WaitCenter', ...
        'Timer', S.minWaitTime, ...
        'StateChangeConditions', {'Port2Out', 'EarlyWithdrawal', 'Tup', 'PlayGoTone'}, ...
        'OutputActions',{});
    
    sma = AddState(sma, 'Name', 'PlayGoTone', ...
        'Timer', CenterValveTime, ...
        'StateChangeConditions', {'Tup', 'WaitForWithdrawalFromCenter'},...
        'OutputActions', [GoCueOutputAction,'ValveState', CenterPort]);
    
    if directTrial == 1
        sma = AddState(sma, 'Name', 'WaitForWithdrawalFromCenter', ...
            'Timer', S.timeToChoose,...
            'StateChangeConditions', {'Port2Out', 'DirectReward', 'Tup', 'DidNotChoose'},...
            'OutputActions', {});
    
        sma = AddState(sma, 'Name', 'DirectReward', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'Reward'},...
            'OutputActions', {'SoftCode', 255});
        
    else
        sma = AddState(sma, 'Name', 'WaitForWithdrawalFromCenter', ...
            'Timer', S.timeToChoose,...
            'StateChangeConditions', {'Port2Out', 'WaitForResponse', 'Tup', 'DidNotChoose'},...
            'OutputActions', {});
    end
    
    sma = AddState(sma, 'Name', 'WaitForResponse', ...
        'Timer', S.timeToChoose,...
        'StateChangeConditions', {'Port1In', LeftPortAction, 'Port3In', RightPortAction, 'Tup', 'DidNotChoose'},...
        'OutputActions', {}); %stop stimulus when subjects responds, to accomodate extra stimulus...added 14-Jan-2015
    
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', rewardValveTime,...
        'StateChangeConditions', {'Tup','PrepareNextTrial'},...
        'OutputActions', {'ValveState', RewardValve,'SoftCode', 255});
    
    % For soft punishment just give time out
    sma = AddState(sma, 'Name', 'SoftPunish', ...
        'Timer', S.timeOut,...
        'StateChangeConditions', {'Tup','PrepareNextTrial'},...
        'OutputActions', {'SoftCode', 255});
    
    sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'HardPunish'},...
        'OutputActions', {'SoftCode', 255});
    
    % For hard punishment play noise and give time out
    sma = AddState(sma, 'Name', 'HardPunish', ...
        'Timer', S.timeOut, ...
        'StateChangeConditions', {'Tup', 'PrepareNextTrial'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'DidNotChoose', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'SoftPunish'}, ...
        'OutputActions', {'SoftCode', 255});
    
    sma = AddState(sma, 'Name', 'PrepareNextTrial', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {'SoftCode', 255} );
    
    % Send and run state matrix
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    % Save events and data
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        
        TrialsDone = TrialsDone + 1; %increment number of trials done
        
        % need to save these next five variables as they are no longer
        % included in the settings file.
        BpodSystem.Data.Modality{TrialsDone} = Modality;
        BpodSystem.Data.CategoryBoundary(TrialsDone) = S.CategoryBoundary;
        BpodSystem.Data.DesiredStimDuration(TrialsDone) = S.StimulusDuration;
        
        Rewarded(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Reward(1));
        EarlyWithdrawal(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.EarlyWithdrawal(1));
        DidNotChoose(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.DidNotChoose(1));
        
        BpodSystem.Data.Rewarded(TrialsDone) = Rewarded(TrialsDone);
        BpodSystem.Data.EarlyWithdrawal(TrialsDone) = EarlyWithdrawal(TrialsDone);
        BpodSystem.Data.DidNotChoose(TrialsDone) = DidNotChoose(TrialsDone);
        BpodSystem.Data.LeftSpeed(TrialsDone) = thisTrialSpeed;
        BpodSystem.Data.RightSpeeed(TrialsDone) = thisTrialSpeedR;
        BpodSystem.Data.PreStimDelay(TrialsDone) = preStimDelay;
        BpodSystem.Data.SetWaitTime(TrialsDone) = S.minWaitTime;
        BpodSystem.Data.DirectReward(TrialsDone) = directTrial;
        
        %compute time spent in center for all each trial with one nose poke in
        %and out of the center port. better to compute this now
        BpodSystem.Data.ActualWaitTime(TrialsDone) = nan;
        if isfield(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events,'Port2Out') && isfield(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events,'Port2In')
            if (numel(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2Out)== 1) && (numel(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2In) == 1)
                BpodSystem.Data.ActualWaitTime(TrialsDone) = BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2Out - BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2In;
            end
        end
        
        modalityRecord(TrialsDone) = modalityNum;
        correctSideRecord(TrialsDone) = correctSide;
        BpodSystem.Data.CorrectSide(TrialsDone) = correctSideRecord(TrialsDone);
        
        if BpodSystem.Data.Rewarded(TrialsDone) == 1
            %correct!
            OutcomeRecord(TrialsDone) = 1;
        elseif BpodSystem.Data.EarlyWithdrawal(TrialsDone) == 1
            %early withdrawal
            OutcomeRecord(TrialsDone) = -1;
        elseif BpodSystem.Data.DidNotChoose(TrialsDone) == 1
            %did not choose
            OutcomeRecord(TrialsDone) = -2;
        else
            %incorrect
            OutcomeRecord(TrialsDone) = 0;
        end
        
        if OutcomeRecord(TrialsDone) >= 0 %if the subject responded
            
            if ((correctSideRecord(TrialsDone)==1) && Rewarded(TrialsDone)) || ((correctSideRecord(TrialsDone)==2) && ~Rewarded(TrialsDone))
                ResponseSideRecord(TrialsDone) = 1;
            elseif ((correctSideRecord(TrialsDone)==1) && ~Rewarded(TrialsDone)) || ((correctSideRecord(TrialsDone)==2) && Rewarded(TrialsDone))
                ResponseSideRecord(TrialsDone) = 2;
            end
            
        end
        
        BpodSystem.Data.ResponseSide(TrialsDone) = ResponseSideRecord(TrialsDone);
        
        % If previous trial was not an early withdrawal, increase wait duration
        if ~BpodSystem.Data.EarlyWithdrawal(TrialsDone)
            S.minWaitTime = S.minWaitTime + S.minWaitTimeStep;
            
        end
        
        %print things to screen
        fprintf('Nr. of trials initiated: %d\n', TrialsDone)
        fprintf('Nr. of completed trials: %d\n', TrialsDone - nansum(EarlyWithdrawal)-nansum(DidNotChoose))
        fprintf('Nr. of rewards: %d\n', nansum(Rewarded))
        fprintf('Amount of water (est.): %d\n', nansum(Rewarded) * (mean([S.leftRewardVolume S.rightRewardVolume])))
        
        PerformancePlot(BpodSystem.GUIHandles.PerformancePlot, 'update', currentTrial, TrialSidesList, OutcomeRecord);
        
        if TrialsDone > S.PlotPMFnTrials && (directTrial==0)
            if mod(TrialsDone,S.UpdatePMfnTrials) == 1
                %every n-th trial after TrialsDone, update the PMF plot
                pmfPlot;
            end
        end
        
    end
    
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    
    % Save protocol settings file to directory
    BpodSystem.ProtocolSettings = S; %new bpod format
    save(BpodSystem.SettingsPath, 'S');
    
    HandlePauseCondition;
    
    if BpodSystem.BeingUsed == 0
        return;
    end
    
end
end


%% Auxillary functions

%% update outcome plot
function UpdateOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if Data.Rewarded(x)
        Outcomes(x) = 1;
    elseif Data.EarlyWithdrawal(x)
        Outcomes(x) = -1;
    elseif Data.DidNotChoose(x)
        Outcomes(x) = -2;
    else
        Outcomes(x) = 0;
    end
end
SideOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update', Data.nTrials+1, TrialTypes, Outcomes);drawnow
end

%% plot pmf
function pmfPlot

% global BpodSystem
% eventRates = BpodSystem.Data.EventRate;
% responseSides =   BpodSystem.Data.ResponseSide;
% respondedTrials = (responseSides == 1 | responseSides == 2); %trials in which the subject made a decision
% 
% uniquerates = unique(eventRates);
% propRight = nan(1,numel(uniquerates));
% 
% for rr = 1:numel(uniquerates)
%     this_rate = uniquerates(rr);
%     this_rate_trials = (eventRates == this_rate);
%     nRights = sum(responseSides(respondedTrials & this_rate_trials) == 2);
%     nTotal = sum(responseSides(respondedTrials & this_rate_trials) > 0); %using responseside takes care of incompleted/did not choose trials
%     propRight(rr) = nRights./nTotal;
% end
% 
% hpmfdata = BpodSystem.GUIHandles.PMFPlotData;
% 
% set(hpmfdata,'xdata',[],'ydata',[]) %clear figure
% set(hpmfdata,'xdata',uniquerates,'ydata',propRight);drawnow %plot data

end

%% generate_random_delay
%from Matt Kaufman
function random_delay = generate_random_delay (lambda, minimum, maximum)
random_delay = 0;
if ~((minimum == 0) && (maximum ==0))
    x = -log(rand)/lambda;
    random_delay = mod(x, maximum - minimum) + minimum;
end
end



%% Anti-bias functions from Matt Kaufman
function [newModeRightArray, newSuccessArray] = ...
    updateAntiBiasArrays(modeRightArray, successArray, visOrAud, outcome, ...
    prevCorrectSide, prevLR, prevSuccess, antiBiasTau, wentRight)
% Based on what happened on the last completed trial, update our beliefs
% about the animal's biases. modeRightArray tracks how likely he is to go
% right for each modality. successArray tracks how likely he is to succeed
% for left or right given what he did on the previous trial.
%
% Note: we'll actually use antiBiasTau * 3 for updating the
% modality-related side bias. If we don't, and there's only one modality,
% the updates will cause oscillation against a perfectly consistent
% strategy.

% For an exponential function, the pdf = (1/tau)*e^(-t/tau)
% The integral from 0 to 1 is [1 - e^(-1/tau)]
% This lets us do exponential decay using only the current
% outcome and previous biases
antiAlternationW = 1 - exp(-1/(3*antiBiasTau));
antiBiasW = 1 - exp(-1/antiBiasTau);

% modeRightArray -- how often he's gone right for each modality
% modality = 2 + visOrAud;
modality = visOrAud;
newModeRightArray = modeRightArray;
if ~isnan(wentRight)
    newModeRightArray(modality) = antiAlternationW * wentRight + (1 - antiAlternationW) * modeRightArray(modality);
end

% Can only update arrays if we already had a trial in the history (since we
% have a two-trial dependence)
newSuccessArray = successArray;
if ~isnan(prevLR)
    newSuccessArray(prevLR, prevSuccess + 1, prevCorrectSide) = antiBiasW * (outcome > 0) + ...
        (1-antiBiasW) * successArray(prevLR, prevSuccess + 1, prevCorrectSide);
end

end


function pLeft = getAntiBiasPLeft(successArray, modeRightArray, modality, ...
    antiBiasStrength, prevLR, prevSuccess)

% Find the relevant part of the SuccessArray and ModeRightArray
successPair = squeeze(successArray(prevLR, prevSuccess + 1, :));

modeRight = modeRightArray(modality);


% Based on the previous successes on this type of trial,
% preferentially choose the harder option

succSum = sum(successPair);

pLM = modeRight;  % prob desired for left based on modality-specific bias
pLT = successPair(2) / succSum;  % same based on prev trial
iVar2M = 1 / (pLM - 1/2) ^ 2; % inverse variance for modality
iVar2T = 1 / (pLT - 1/2) ^ 2; % inverse variance for trial history

if succSum == 0 || iVar2T > 10000
    % Handle degenerate cases, trial history uninformative
    pLeft = pLM;
elseif iVar2M > 10000
    % Handle degenerate cases, modality bias uninformative
    pLeft = pLT;
else
    % The interesting case... combine optimally
    pLeft = pLM * (iVar2T / (iVar2M + iVar2T)) + pLT * iVar2M / (iVar2M + iVar2T);
end

% Weight pLeft from anti-bias by antiBiasStrength
pLeft = antiBiasStrength * pLeft + (1 - antiBiasStrength) * 0.5;

end