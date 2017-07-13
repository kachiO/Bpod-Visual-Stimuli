%% Speed discrimination task
% Example Bpod protocol with PsychtoolToolbox video display

% In the task subjects are presented with two grating stimuli on the left
% and right of the screen. The gratings are drifting at difference speeds
% (in degrees/s): reference and test. The reference speed is the same value on
% every trial (e.g. 25 degrees/s), however the spatial/temporal frequency
% of the reference grating can vary on each trial. 
% Kachi Odoemene Jan 2015

% Modification history
% Aug 2016: pilot task ready
% July 2017: comments

function TheSpeedyHare
%other names: SpeedyGrater

global BpodSystem

PsychToolboxSoundServer('init') % Initialize sound server
PsychToolboxDisplayServer('init') % Initialize display server
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_StimulusDisplay'; % Set soft code handler to trigger sounds

%% Define settings for protocol
%Initialize default settings.
%Append new settings to the end
DefaultSettings.SubjectName = 'Hare';
DefaultSettings.leftRewardVolume = 2;           % ul, left reward port volume
DefaultSettings.rightRewardVolume = 2;          % ul, right reward port volume
DefaultSettings.centerRewardVolume = 0.5;       % ul, center reward port volume
DefaultSettings.centerRewardProp = 1;           % probability of 

DefaultSettings.preStimDelayMin = 0.01;         % secs, 
DefaultSettings.preStimDelayMax = 0.1;          % secs, 
DefaultSettings.lambdaDelay = 15;

DefaultSettings.StimulusDuration = 1;           % desired stimulus duration
DefaultSettings.minWaitTime = 0.025;            % secs, minimum center wait duration
DefaultSettings.minWaitTimeStep = 0.001;        % secs, increment wait step
DefaultSettings.maxWaitTime = 1.25;             % maximum center wait duration

DefaultSettings.timeToChoose = 3;               % secs, maximum allowed time before making choice
DefaultSettings.timeOut = 2;                    % secs, time out period for incorrect trials or early center fixation withdrawals

DefaultSettings.RefSpeed = 25;                  % degrees/s, reference speed. can also set to 37.5 degs/s
DefaultSettings.SpeedList =[3.125 200];         % degrees/s, list of test speeds. Full list: [3.125 6.25 12.5 18.75 37.5 50 100 200]; %deg/s  --> full list [3.125 4.1667 6.25 8.3333 12.5 16.6667 18.75 25 33.3333 37.5 50 75 100 150 200]
DefaultSettings.SFreqList = [0.02 0.16];        % cycles/deg, list of spatial frequencies. Full list: [0.02 0.04 0.08 0.12 0.16]
DefaultSettings.TFreqList = [0.5 4];            % cycles/sec, list of temporal frequencies. Full list: [0.5 1 2 3 4]
DefaultSettings.RefContrast = 1;                % list of reference contrasts [0.1 0.8];
DefaultSettings.TestContrast = 1;               % list of test contrasts [0.1 0.4 0.8];

DefaultSettings.StimSize = 40;                  % degrees, size of grating stimulus
DefaultSettings.Azimuth = 40;                   % degrees, azimuth location to the right or left of center. can enter list of possible azimuths
DefaultSettings.Elevation = 10;                 % degrees, list of possible elevations
DefaultSettings.Orientation = 90;               % degrees , or list of possible orientations

DefaultSettings.PropLeft = 0.5;                 % proportion of left/right side
DefaultSettings.WaitStartCue = 1;               % flag, 0 or 1, play tone at the beginning of center wait period
DefaultSettings.WaitEndGoCue = 1;               % flag, 0 or 1, play tone at the end of center wait period
DefaultSettings.PlayStimulus = 1;               % flag, 0 or 1, play stimulus
DefaultSettings.Direct = 0;                     % probability 0-1. this will reflect the probability/fraction of trials that are direct reward
DefaultSettings.UseAntiBias = 0;                % flag, 0 or 1, use antibias feature
DefaultSettings.AntiBiasTau = 4;                % anti-bias time constant. reflects how far back (in trials) to calculate antibias parameters

DefaultSettings.PlotPMFnTrials = 100;           % number of completed trials before plotting psychometric function (PMF)
DefaultSettings.UpdatePMfnTrials = 5;           % update PMF after n trials

% update settings
defaultFieldNames = fieldnames(DefaultSettings); % get current settings field names
prevSettings = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct S
prevFieldNames = fieldnames(prevSettings);
prevFieldVals = struct2cell(prevSettings);

% go through previous settings and update accordingly
newSettings = DefaultSettings;
for n = 1:numel(defaultFieldNames)
  thisfield = defaultFieldNames{n};
  index = find(strcmpi(thisfield,prevFieldNames));
  if isempty(index)
      continue;
  end
  newSettings.(thisfield) = prevFieldVals{index};
end

S = newSettings; %update parameters
BpodParameterGUI_Visual('init', S); % Launch parameter GUI

%%
SamplingFreq = 192000; % This has to match the sampling rate initialized in PsychToolboxSoundServer.m
generateAndUploadSounds(SamplingFreq, 1); % generate audio signals and load to psychtoolbox

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
BpodSystem.GUIHandles.Figures.AllFigures = figure('Position', [500 1000 600 700], 'name', 'All Plots', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Units', 'pixels', 'Position', [70 580 500 100],'tickdir','out');
BpodSystem.GUIHandles.PerformancePlot = axes('Units', 'pixels', 'Position', [70 440 500 100],'tickdir','out');
BpodSystem.GUIHandles.PMFPlot = axes('Units', 'pixels', 'Position', [70 30 240 280],'tickdir','out','ytick',(0:0.25:1),'XGrid','on','YGrid','on','YLim',[0 1.05]);
BpodSystem.GUIHandles.PMFPlotData = line([0 0],[0 0],'LineStyle','-','Marker','.','MarkerSize',6');

OutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', TrialSidesList, 60);
PerformancePlot(BpodSystem.GUIHandles.PerformancePlot,'init');

BpodSystem.GUIHandles.LabelsText.TrialsDone = uicontrol('Style', 'text', 'String', 'Trials Done:', 'Position', [330 290 60 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsText.CompletedTrials = uicontrol('Style', 'text', 'String', 'Valid Trials:', 'Position', [330 260 60 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsText.RewardedTrials = uicontrol('Style', 'text', 'String', 'Rewarded Trials:', 'Position', [330 230 85 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsText.WaterAmount = uicontrol('Style', 'text', 'String', 'Est. Water (mL):', 'Position', [330 200 85 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsVal.TrialsDone = uicontrol('Style', 'text', 'String', '0', 'Position', [400 290 30 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsVal.CompletedTrials = uicontrol('Style', 'text', 'String', '0', 'Position', [400 260 30 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsVal.RewardedTrials = uicontrol('Style', 'text', 'String', '0', 'Position', [420 230 30 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');
BpodSystem.GUIHandles.LabelsVal.WaterAmount = uicontrol('Style', 'text', 'String', '0', 'Position', [420 200 45 18], 'FontWeight', 'normal', 'FontSize', 10, 'FontName', 'Arial');

%% Initialize arrays for storing values later
OutcomeRecord = nan(1,maxTrials);
Rewarded = nan(1,maxTrials);
EarlyWithdrawal = nan(1,maxTrials);
DidNotChoose = nan(1,maxTrials);
ResponseSideRecord = nan(1,maxTrials);
modalityRecord = nan(1,maxTrials);
correctSideRecord = nan(1,maxTrials);

TrialsDone =  0;

%% Main loop
for currentTrial = 1:maxTrials
    
    S = BpodParameterGUI_Visual('update', S); drawnow; % Sync parameters with BpodParameterGUI B
    
    LeftValveTime = GetValveTimes(S.leftRewardVolume, 1);
    RightValveTime = GetValveTimes(S.rightRewardVolume, 3);
    CenterValveTime = GetValveTimes(S.centerRewardVolume,2);
    
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
    
    preStimDelay = generate_random_delay(S.lambdaDelay, S.preStimDelayMin, S.preStimDelayMax); % calculate pre-stimulus delay
    
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
    
    % Pick this trial type and speed
    refSpeed = S.RefSpeed; %deg/s
    refContrast = selectRandomIndex(S.RefContrast);
    speedList = S.SpeedList;
    testSpeed = selectRandomIndex(speedList);
    testContrast = selectRandomIndex(S.TestContrast);
    thisTrialSpeeds = [testSpeed refSpeed];
    thisTrialSide = TrialSidesList(currentTrial);
    Contrasts = nan(1,2);
    
    if thisTrialSide == 1 % Reward on Left-hand port, i.e. present fastest of the two gratings on left side
        LeftPortAction = 'Reward';
        RightPortAction = 'SoftPunish';
        RewardValve = LeftPort; %left-hand port represents port#0, therefore valve value is 2^0
        rewardValveTime = LeftValveTime;
        correctSide = 1;
        LRSpeeds = [max(thisTrialSpeeds) min(thisTrialSpeeds)];
        
    else % Reward on Right-hand port, i.e. present fastest of the two gratings on right side
        LeftPortAction = 'SoftPunish';
        RightPortAction = 'Reward';
        RewardValve = RightPort; %right-hand port represents port#2, therefore valve value is 2^2
        rewardValveTime = RightValveTime;
        correctSide = 2;
        LRSpeeds = [min(thisTrialSpeeds) max(thisTrialSpeeds)];
    end
    
    disp(['Left Speed: ' num2str(LRSpeeds(1)) ' degrees/s'])
    disp(['Right Speed: ' num2str(LRSpeeds(2)) ' degrees/s'])
    
    Contrasts(LRSpeeds == refSpeed) = refContrast;
    Contrasts(LRSpeeds ~= refSpeed) = testContrast;
    
    %create visual speed matrix
    sFreqList = S.SFreqList; %cycles/deg
    tFreqList = S.TFreqList; %cycles/sec
    
    [sf,tf] = meshgrid(sFreqList,tFreqList);
    speedMatrix = tf./sf;
    
    leftSFreq = selectRandomIndex(unique(sf(speedMatrix == LRSpeeds(1))));
    rightSFreq = selectRandomIndex(unique(sf(speedMatrix == LRSpeeds(2))));
    
    leftTFreq = selectRandomIndex(unique(tf(speedMatrix==LRSpeeds(1))));
    rightTFreq = selectRandomIndex(unique(tf(speedMatrix == LRSpeeds(2))));
    
    %store and load parameters to PsychtoolboxDisplayServer
    stimParameters.PlayStimulus = 1;
    stimParameters.StimSize = selectRandomIndex(S.StimSize); %in degrees, need to be converted into pixels
    
    stimParameters.Speeds = LRSpeeds;
    stimParameters.SFreqs = [leftSFreq rightSFreq];
    stimParameters.TFreqs = [leftTFreq rightTFreq];
    stimParameters.StimContrasts = Contrasts;
    
    stimParameters.Orientation = selectRandomIndex(S.Orientation); %degrees
    stimParameters.Elevation = S.Elevation;%degrees
    stimParameters.Azimuth = S.Azimuth;%degrees
    stimParameters.StimDuration = S.minWaitTime;
    
    %add random delay to post stimulus
    postStimWaitTime = (S.minWaitTime - S.StimulusDuration) + generate_random_delay(S.lambdaDelay, S.preStimDelayMin, S.preStimDelayMax);
    
    if postStimWaitTime < 0
        postStimWaitTime = 0;
    else
        stimParameters.StimDuration = S.StimulusDuration;
    end
    
    if ~S.PlayStimulus
        stimParameters.PlayStimulus = 0;
        Modality = '-';
    end
    
    PsychToolboxDisplayServer('Make','DG',stimParameters);
    
    GoCueOutputAction = {};
    WaitStartCueOutputAction = {};
    
    if S.WaitEndGoCue
        GoCueOutputAction  = {'SoftCode', 3};
    end
    
    if S.WaitStartCue
        WaitStartCueOutputAction = {'SoftCode', 2};
    end

    
    %% Build state matrix
    sma = NewStateMatrix();
    
    sma = AddState(sma, 'Name', 'GoToCenter', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'WaitStimStart'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'WaitStimStart', ...
        'Timer', preStimDelay, ...
        'StateChangeConditions', {'Tup','PlayStimulus', 'Port2Out', 'EarlyWithdrawal'},...
        'OutputActions', WaitStartCueOutputAction);
    
    sma = AddState(sma, 'Name', 'PlayStimulus', ...
        'Timer', 0.05, ...
        'StateChangeConditions', {'Tup','WaitCenter','Port2Out', 'EarlyWithdrawal'},...
        'OutputActions', {'SoftCode', 1});
    
    sma = AddState(sma, 'Name', 'WaitCenter', ...
        'Timer',  S.minWaitTime, ...
        'StateChangeConditions', {'Port2Out', 'EarlyWithdrawal', 'Tup', 'PlayGoTone'}, ...
        'OutputActions',{'SoftCode',254});
    
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
        'OutputActions', {'ValveState', RewardValve,'SoftCode', 254});
    
    % For soft punishment just give time out
    sma = AddState(sma, 'Name', 'SoftPunish', ...
        'Timer', (S.timeOut + 0.1),...
        'StateChangeConditions', {'Tup','PrepareNextTrial'},...
        'OutputActions', {'SoftCode', 254});
    
    sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'HardPunish'},...
        'OutputActions', {'SoftCode', 254});
    
    % For hard punishment play noise and give time out
    sma = AddState(sma, 'Name', 'HardPunish', ...
        'Timer', (S.timeOut + 0.1), ...
        'StateChangeConditions', {'Tup', 'PrepareNextTrial'}, ...
        'OutputActions', {'SoftCode',4,'PWM1',128,'PWM2',128,'PWM3',128});
    
    sma = AddState(sma, 'Name', 'DidNotChoose', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'SoftPunish'}, ...
        'OutputActions', {'SoftCode', 254});
    
    sma = AddState(sma, 'Name', 'PrepareNextTrial', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {'SoftCode', 255} );
    
    %% Send and run state matrix
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    %% Save events and data
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        
        TrialsDone = TrialsDone + 1; %increment number of trials done
        Rewarded(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Reward(1));
        EarlyWithdrawal(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.EarlyWithdrawal(1));
        DidNotChoose(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.DidNotChoose(1));
      
        BpodSystem.Data.Modality{TrialsDone} = Modality;
        BpodSystem.Data.ReferenceSpeed(TrialsDone) = refSpeed;
        BpodSystem.Data.TestSpeed(TrialsDone) = testSpeed;
        BpodSystem.Data.RefContrast(TrialsDone) = refContrast;
        BpodSystem.Data.TestContrast(TrialsDone) = testContrast;
        BpodSystem.Data.DesiredStimDuration(TrialsDone) = S.StimulusDuration;
        BpodSystem.Data.Rewarded(TrialsDone) = Rewarded(TrialsDone);
        BpodSystem.Data.EarlyWithdrawal(TrialsDone) = EarlyWithdrawal(TrialsDone);
        BpodSystem.Data.DidNotChoose(TrialsDone) = DidNotChoose(TrialsDone);
        BpodSystem.Data.LeftRightSpeed{TrialsDone} = LRSpeeds;
        BpodSystem.Data.StimParameters(TrialsDone) = stimParameters;
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
        
        if S.minWaitTime > S.maxWaitTime
            S.minWaitTime = S.maxWaitTime;
            S.minWaitTimeStep = 0;
        end
        
        set(BpodSystem.GUIHandles.LabelsVal.TrialsDone,'String',num2str(TrialsDone'));
        set(BpodSystem.GUIHandles.LabelsVal.CompletedTrials,'String',num2str( TrialsDone - nansum(EarlyWithdrawal)-nansum(DidNotChoose)));
        set(BpodSystem.GUIHandles.LabelsVal.RewardedTrials,'String',num2str(nansum(Rewarded)));
        set(BpodSystem.GUIHandles.LabelsVal.WaterAmount,'String',[num2str((nansum(Rewarded) * (mean([S.leftRewardVolume S.rightRewardVolume])))/1000) ' ml']);
        drawnow;
        
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
    
    if BpodSystem.BeingUsed == 0
        PsychToolboxSoundServer('Close');
        Screen('Close')
        return;
    end
    
end
end


%% Auxillary functions

%% selectRandomIndex
function index = selectRandomIndex(vectorList)
indices = randperm(numel(vectorList));
index = vectorList(indices(1));
end


%%
function generateAndUploadSounds (samplingFreq, soundLoudness)
% Star wait cue
waveStartSound = (0.5*soundLoudness) * GenerateSineWave(samplingFreq, 7000, 0.1); % Sampling freq (hz), Sine frequency (hz), duration (s)
WaitStartSound = [zeros(1,size(waveStartSound,2)); waveStartSound];

% Go cue
waveStopSound = (0.5 * soundLoudness) * GenerateSineWave(samplingFreq, 3000, 0.1);
WaitStopSound = [zeros(1,size(waveStopSound,2)); waveStopSound];

% Early withdrawal punishment tone
wavePunishSound = (rand(1,samplingFreq*.5)*2) - 1;
% wavePunishSound = 0.15 * soundLoudness * GenerateSineWave(samplingFreq, 12000, 1);
PunishSound = [zeros(1,size(wavePunishSound,2)); wavePunishSound];

% Upload sounds to sound server. Channel 1 reserved for stimuli
PsychToolboxSoundServer('Load', 2, WaitStartSound);
PsychToolboxSoundServer('Load', 3, WaitStopSound);
PsychToolboxSoundServer('Load', 4, PunishSound);
end
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
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update', Data.nTrials+1, TrialTypes, Outcomes);drawnow
end

%% plot pmf
function pmfPlot

global BpodSystem
testSpeeds = BpodSystem.Data.TestSpeed;
responseSides =   BpodSystem.Data.ResponseSide;
respondedTrials = (responseSides == 1 | responseSides == 2); %trials in which the subject made a decision
%
uniqueSpeeds = unique(testSpeeds);
propRight = nan(1,numel(uniqueSpeeds));
%
for rr = 1:numel(uniqueSpeeds)
    thisSpeed = uniqueSpeeds(rr);
    theseTrials = (testSpeeds == thisSpeed);
    nRights = sum(responseSides(respondedTrials & theseTrials) == 2);
    nTotal = sum(responseSides(respondedTrials & theseTrials) > 0); %using responseside takes care of incompleted/did not choose trials
    propRight(rr) = nRights./nTotal;
end
%
hpmfdata = BpodSystem.GUIHandles.PMFPlotData;

set(hpmfdata,'xdata',[],'ydata',[]) %clear figure
set(hpmfdata,'xdata',uniqueSpeeds,'ydata',propRight);drawnow %plot data

end

%% Matt Kaufman's MOD solution for this is very elegant and works great.
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