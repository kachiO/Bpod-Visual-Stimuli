function varargout = BpodParameterGUI_Visual(varargin)
    % BpodParameterGUI('init', ParamStruct) - initializes a GUI with edit boxes for every field in subfield ParamStruct.GUI
    % BpodParameterGUI('update', ParamStruct) - updates the GUI with fields of
    %       ParamStruct.GUI, if they have not been changed by the user. 
    %       Returns a param struct. Fields in the GUI sub-struct are read from the UI.
    global BpodSystem
    Op = varargin{1};
    Params = varargin{2};
    switch Op
        case 'init'        

            ParamNames = fieldnames(Params);
            nValues = length(ParamNames);
            ParamValues = struct2cell(Params);

            Vsize = 25+(23*nValues);
            BpodSystem.GUIHandles.Figures.ParamFig = figure('Position', [10 1000 230 Vsize],'name','Live Params','numbertitle','off', 'MenuBar', 'none', 'Resize', 'on');
            uicontrol('Style', 'text', 'String', 'Parameter', 'Position', [10 Vsize-30 120 20], 'FontWeight', 'bold', 'FontSize', 11, 'FontName', 'Arial');
            uicontrol('Style', 'text', 'String', 'Value', 'Position', [140 Vsize-30 80 20], 'FontWeight', 'bold', 'FontSize', 11, 'FontName', 'Arial');
            BpodSystem.GUIHandles.ParameterGUI = struct;
            BpodSystem.GUIHandles.ParameterGUI.ParamNames = ParamNames;
            BpodSystem.GUIHandles.ParameterGUI.LastParamValues = ParamValues;
            nValues = length(BpodSystem.GUIHandles.ParameterGUI.LastParamValues);
            

            BpodSystem.GUIHandles.ParameterGUI.LabelsHandle = zeros(1,nValues);
            Pos = Vsize-60;

            for x = 1:nValues
                if ~isempty(str2num(num2str(ParamValues{x}))); % if is numeric
                    BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x} = str2num(num2str(ParamValues{x}));
                end
                eval(['BpodSystem.GUIHandles.ParameterGUI.LabelsHandle(x) = uicontrol(''Style'', ''text'', ''String'', ''' ParamNames{x} ''', ''Position'', [10 ' num2str(Pos) ' 120 18], ''FontWeight'', ''normal'', ''FontSize'', 10, ''FontName'', ''Arial'');']);
                eval(['BpodSystem.GUIHandles.ParameterGUI.ParamValHandle(x) = uicontrol(''Style'', ''edit'', ''String'', ''' num2str(ParamValues{x}) ''', ''Position'', [140 ' num2str(Pos) ' 80 20], ''FontWeight'', ''normal'', ''FontSize'', 9, ''FontName'', ''Arial'');']);
                Pos = Pos - 20;
            end
            % uicontrol('Style', 'pushbutton', 'String', 'Save settings', 'Position', [20 20 100 20], 'Callback', {@save_settings_callback});

        case 'update'
            ParamNames = fieldnames(Params);
            nValues = length(BpodSystem.GUIHandles.ParameterGUI.LastParamValues);

            for x = 1:nValues

                thisParamGUIValue = get(BpodSystem.GUIHandles.ParameterGUI.ParamValHandle(x), 'String');
                thisParamLastValue = BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x};
                thisParamInputValue = Params.(ParamNames{x});

                if ~strcmp(thisParamGUIValue, num2str(thisParamLastValue)) % If the user changed the GUI input parameter
                    param_is_numeric = ~isempty(str2num(num2str(thisParamGUIValue)));   
                    if param_is_numeric
                        Params.(ParamNames{x}) = str2num(num2str(thisParamGUIValue));
                        BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x} = str2num(num2str(thisParamGUIValue));
                    else
                        Params.(ParamNames{x}) = thisParamGUIValue;
                        BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x} = thisParamGUIValue;
                    end
                else
                    if ~isempty(str2num(num2str(thisParamInputValue))) % if is numeric
                        BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x} = str2num(num2str(thisParamInputValue));
                    else
                        BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x} = thisParamInputValue;
                    end
                    set(BpodSystem.GUIHandles.ParameterGUI.ParamValHandle(x), 'String', num2str(thisParamInputValue));
                end

            end
            varargout{1} = Params;

        case 'close'
            close(BpodSystem.GUIHandles.ParamFig);


    end

end

% function result = save_settings_callback (h, ev)
%     global BpodSystem
%     nValues = length(BpodSystem.GUIHandles.ParameterGUI.LastParamValues);
%     params = struct;
%     for x = 1:nValues
%         this_paramName = BpodSystem.GUIHandles.ParameterGUI.ParamNames{x};
%         this_paramValue = BpodSystem.GUIHandles.ParameterGUI.LastParamValues{x};
%         params.(this_paramName) = this_paramValue;
%     end
%     BpodParameterGUI_Visual('update', params);
%     SaveProtocolSettings(params);
% end


