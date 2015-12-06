function SamplingTimePlot(AxesHandle, Action, varargin)
% Plugin for plotting time subject spent in center
% Only plots the time the subject spent waiting in the center port

% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot
% Example usage:

%     SamplingTimePlot(AxesHandle,'init')  %set up axes nicely

%     SamplingTimePlot(AxesHandle,'update',CurrentTrial,SampleTimeRecord)
%     SamplingTimePlot(AxesHandle,'update',CurrentTrial,SampleTimeRecord,'colors',colors)

% varargins:
%
% SampleTimeRecord:  Vector of center times
% 'color': color flag
% colors: nx3 matrix, each row represents a color. eg. red = [1 0 0]
%         make sure there are enough rows for the items you plan to plot

% Current trial: the current trial number

% Adapted from BControl (PerformancePlotSection.m)
% Kachi O. 2014.Mar.17

global nTrialsToShow centerTimeVals %this is for convenience

nTrialsToShow = 90; %default number of trials to display

switch Action
    
    case 'init'
        cla(AxesHandle)
        set(AxesHandle,'TickDir', 'out','XLim',[1 nTrialsToShow],'YLim', [-0.1, 2], 'YTick', [0:0.25:1.5]);
        ylabel(AxesHandle,'Time(s)');
        hold (AxesHandle,'on');
        
        centerTimeVals = nan(nTrialsToShow,1);
    case 'update'
        lastTrial = varargin{1};
        SampleTimeRecord = varargin{2};
        
        if numel(varargin) > 3
            colors = varargin{4};
        else
            colors = [0.5 0.5 0.5];
        end
        
        cla(AxesHandle)
        set(AxesHandle,'TickDir', 'out','YLim', [-0.1, 3], 'YTick', [0:0.5:3.5]);
        [mn,mx] = rescaleX(AxesHandle,lastTrial,nTrialsToShow);
        indxToPlot = mn:mx;
        
        if lastTrial > 0
            %compute fraction of valid trials, i.e. complete trials (no early withdrawals)
            trialsToInclude = max(1,lastTrial - nTrialsToShow ): lastTrial; %in average
            %             centerTimeVals(lastTrial) = SampleTimeRecord(trialsToInclude);
            scatter(AxesHandle,indxToPlot,SampleTimeRecord(indxToPlot),'bo')
            
            
        end
        
        
end

end


function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .99; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end