function varargout = SeroProcessData(varargin)
% SEROPROCESSDATA MATLAB code for SeroProcessData.fig
%      SEROPROCESSDATA, by itself, creates a new SEROPROCESSDATA or raises the existing
%      singleton*.
%
%      H = SEROPROCESSDATA returns the handle to a new SEROPROCESSDATA or the handle to
%      the existing singleton*.a
%
%      SEROPROCESSDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SEROPROCESSDATA.M with the given input arguments.
%
%      SEROPROCESSDATA('Property','Value',...) creates a new SEROPROCESSDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SeroProcessData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SeroProcessData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SeroProcessData

% Last Modified by GUIDE v2.5 07-Oct-2022 14:33:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SeroProcessData_OpeningFcn, ...
                   'gui_OutputFcn',  @SeroProcessData_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SeroProcessData is made visible.
function SeroProcessData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args,9 see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SeroProcessData (see VARARGIN)
global C ModifiedData

try
    if isdeployed
        % User is running an executable in standalone mode.
        [status, result] = system('set PATH');
        executableFolder = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
        % 			fprintf(1, '\nIn function GetExecutableFolder(), currentWorkingDirectory = %s\n', executableFolder);
    else
        % User is running an m-file from the MATLAB integrated development environment (regular MATLAB).
        executableFolder = pwd;
    end
catch ME
    errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ME.stack(1).name, ME.stack(1).line, ME.message);
    uiwait(warndlg(errorMessage));
end

cd(executableFolder);
diary('log.txt');
diary on;

if exist('Config.cfg','file')==2
    C=load('Config.cfg','-mat');
else
    PathDataFiles=getenv('USERPROFILE'); 
    PathFigures=getenv('USERPROFILE');
    PathSignals=getenv('USERPROFILE');
    C.PathDataFiles=PathDataFiles;
    C.PathFigures=PathFigures;
    C.PathSignals=PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
end

%set the logo
axes(handles.axesLabLogo)
matlabImage = imread('SDPlogo.jpg');
image(matlabImage)
axis off
axis image

% Set WindowButtonMotionFcn to TimeSinceInjection
set(handles.frmMain, 'WindowButtonMotionFcn', '');
    
%modified data flag
ModifiedData=0;

% Choose default command line output for SeroProcessData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes SeroProcessData wait for user response (see UIRESUME)
% uiwait(handles.frmMain);


% --- Executes on button press in cmdLoadData.
function cmdLoadData_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLoadData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V t t_2 hplt hplt_2 OxPeakV OxPeak OxPeakV_2 OxPeak_2 hzoom hzoom_2 hPointsSP hPointsPP hPointsEP FilterFrec DisplaySignal Hd 
global OxPeakFiltered ModifiedData C FileName hlblTimeSinceInjection PlotMouseMoveMode SelectedRow
global Saved_Data_Array SignalFreq
global SignalPeriod_ms FilterFrecIIR OxPeakFilteredMA FilterFrecMA coeffMA

%check if an analysis is already in progress
if ModifiedData==1
    Answer = questdlg('Do you want to load a new file without saving data?', 'Warning','Yes', 'No','No');
    if strcmp(Answer,'No')==1
        return;
    end
end

%navigate to file location
[NewFileName,PathName]=uigetfile('*.dat','Introduce the name of the measurement data file',C.PathDataFiles);



if NewFileName~=0
    progress_bar = waitbar(0.1, 'Loading data...');
    FileName=NewFileName;
    C.PathDataFiles=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    
    %V is the dat file loaded as a mat file
    V=load(strcat(PathName,FileName),'-mat');
    
    %-----START code for handling data stored in compressed format-----%
    Saved_Data_Array = []; %TODO: unsure if empty assignment is necessary

    if (V.IgnoreSelected == 1)
        
        % query for how many points were ignored in each cycle.
        answer = inputdlg({'Please enter start of ignored data in cycle:'}, 'Prompt:');
        IgnoreStart = str2double(answer{1}); 
        
        answer = inputdlg({'Please enter number of ignored points in cycle:'},'Prompt:');
        NumIgnoredPoints = str2double(answer{1});
        
        waitbar(0.33, progress_bar, 'Uncompressing data...');
        
        data1_width = IgnoreStart - 1;
        data2_start = IgnoreStart + NumIgnoredPoints;
        data2_width = V.PointsPerCycle - (data2_start) + 1;
        save_unit_width = length(V.Saved_Data)/(V.N_Cycles);
        
        Saved_Data_Array = zeros(1, (V.N_Cycles * V.PointsPerCycle));
        
        for i=1:V.N_Cycles
            Saved_Data_Array((((i-1)*V.PointsPerCycle)+1):(((i-1)*V.PointsPerCycle)+data1_width))= V.Saved_Data(1, ((i-1) * save_unit_width+1):((i-1) * save_unit_width + data1_width));
            %Saved_Data_Array((((i-1)*V.PointsPerCycle)+NumIgnoredPoints+data1_width+1):(((i-1)*V.PointsPerCycle)+V.PointsPerCycle)) = V.Saved_Data(2, ((i-1) * save_unit_width+1):((i-1) * save_unit_width + data2_width));
            Saved_Data_Array((((i-1)*V.PointsPerCycle)+data2_start):(((i-1)*V.PointsPerCycle)+V.PointsPerCycle)) = V.Saved_Data(2, ((i-1) * save_unit_width+1):((i-1) * save_unit_width + data2_width));
            %Saved_Data_Array = [Saved_Data_Array ; V.Saved_Data(1, ((i-1) * save_unit_width):((i-1) * save_unit_width + save_unit_width))];
            %Saved_Data_Array = [Saved_Data_Array ; zeros(1, NumIgnoredPoints)];
            %Saved_Data_Array = [Saved_Data_Array ; V.Saved_Data(2, ((i-1) * save_unit_width):((i-1) * save_unit_width + save_unit_width))];  
        end
        
    else
        waitbar(0.33, progress_bar, 'Uncompressing data...');
        Saved_Data_Array = V.Saved_Data;
    end
    
    %debugging code (TODO: comment out after test)
    %disp(['Points per Cycle: ',  num2str(V.PointsPerCycle)]);
    %disp(['Number of Cycles: ',  num2str(V.N_Cycles)]);
    [m,n] = size(Saved_Data_Array);
    %disp(['Saved_Data_Array row size: ',  num2str(m)]); % checked that Saved_Data_Array is single dimension matrix
    %disp(['Saved_Data_Array col size: ' , num2str(n)]); % checked that Saved_Data_Array has correct number of data points
    %disp(Saved_Data_Array);
    
    %end
    %-----END code for handling data stored in compressed format-----%
    
    waitbar(0.66, progress_bar,'Configuring filters and plots...');
    
    
    %look for signal frequency in file; if not, ask user
    try
        SignalPeriod_ms = 1000/(str2double(V.Signal_Frequency));
        SignalFreq = str2double(V.Signal_Frequency);
    catch 
        answer = inputdlg({'Please enter the signal frequency in Hz (example: 10): '}, 'Prompt:');  
        SignalFreq = str2double(answer{1});
        SignalPeriod_ms = 1000/(str2double(answer{1}));
    end 

    
    %show file name and set sliders
    handles.txtFileName.String=FileName(1:length(FileName)-4);
    handles.sldOxPeakV.Max=V.PointsPerCycle;
    handles.sldOxPeakV.Value=V.OxPeakVM; 
    handles.sldOxPeakV_2.Max=V.PointsPerCycle;
    handles.sldOxPeakV_2.Value=V.OxPeakVM; 
    handles.sldOxPeakV.Min=1; %TODO: check...
    handles.sldOxPeakV.SliderStep(1) = 1 / V.PointsPerCycle;
    handles.sldOxPeakV.SliderStep(2) = 2*(1 / V.PointsPerCycle);
    handles.sldOxPeakV_2.Min=1; %TODO: check...
    handles.sldOxPeakV_2.SliderStep(1) = 1 / V.PointsPerCycle;
    handles.sldOxPeakV_2.SliderStep(2) = 2*(1 / V.PointsPerCycle);
    
    %set monitored sample to saved value, configure filtering
    %TODO: finish configuring filtering
    OxPeakV=handles.sldOxPeakV.Value;
    handles.lblOxPeakV.String=OxPeakV;
    handles.optOriginal.Value=1;
    OxPeakV_2=handles.sldOxPeakV_2.Value;
    handles.lblOxPeakV_2.String=OxPeakV_2;
    handles.optOriginal_2.Value=1;
    
    handles.sldFilterFrec.Max=0.795;
    handles.sldFilterFrec.Min=0.005;
    handles.sldFilterFrec.SliderStep(1)=0.005/(handles.sldFilterFrec.Max-handles.sldFilterFrec.Min);
    handles.sldFilterFrec.SliderStep(2)=0.1/(handles.sldFilterFrec.Max-handles.sldFilterFrec.Min);
    
    FilterFrec=0.05;
    handles.sldFilterFrec.Value=FilterFrec;
    DisplaySignal=1; % Orignal signal is displayed
    Fpass = FilterFrec;            % Passband Frequency
    Fstop = FilterFrec+0.05;             % Stopband Frequency
    Dpass = 0.057501127785;  % Passband Ripple
    Dstop = 0.0001;          % Stopband Attenuation
    flag  = 'scale';         % Sampling Flag
    % Calculate the order from the parameters using KAISERORD.
    [N,Wn,BETA,TYPE] = kaiserord([Fpass Fstop], [1 0], [Dstop Dpass]);
    % Calculate the coefficients using the FIR1 function.
    b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
    Hd = dfilt.dffir(b);
    
    
    %CONFIGURE IIR Filter
    %%TODO: check accuracy
    FilterFrecIIR=SignalFreq/2;
    handles.sldFilterFrecIIR.Max=SignalFreq/2;
    handles.sldFilterFrecIIR.Min=0.0001;
    handles.sldFilterFrecIIR.Value=FilterFrecIIR;
    handles.lblFilterFrecIIR.String=str2double(FilterFrecIIR);
    DisplaySignal=5; % TODO:update multiple display
    N=2; %TODO:?
    df1 = designfilt('highpassiir', 'FilterOrder', 2, 'HalfPowerFrequency',FilterFrecIIR, 'SampleRate', SignalFreq,'DesignMethod', 'butter');
    
    %CONFIGURE MA FILTER
    FilterFrecMA = str2double(handles.txtMAinterval.String);
    coeffMA = ones(1,FilterFrecMA)/FilterFrecMA;
    OxPeakFilteredMA = filter(coeffMA,1,OxPeak);
    
    %get the sampled point from each voltammgram 
    OxPeak=0;
    for i=1:V.N_Cycles
        OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV);
    end
    
    OxPeak_2=0;
    for i=1:V.N_Cycles
        OxPeak_2(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV_2);
    end
    
    
    [m,n] = size(OxPeak);
    %disp(['OxPeak matrix dimension (row): ', num2str(m)]);
    %disp(['OxPeak matrix dimension (col): ', num2str(n)]);
    
    %disp(['N: ', num2str(N)]);
    
    if V.N_Cycles>=500 %TODO: this does not cover all cases...need to revise (what happens when V.N_Cycles<500??)
        %disp('entered this segment');
        OxPeakFiltered=filter(Hd,OxPeak);
        OxPeakFiltered=OxPeakFiltered(round(N/2):length(OxPeakFiltered));
        OxPeakFiltered(1:round(N/2))=OxPeakFiltered(round(N/2)+1:2*round(N/2));
    end;
    
    [m,n] = size(OxPeakFiltered);
    %disp(['OxPeakFiltered matrix dimension (row): ', num2str(m)]);
    %disp(['OxPeakFiltered matrix dimension (col): ', num2str(n)]);
    
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,(1:length(OxPeak)),V.Gain*OxPeak,'color',[0.8,0.4,0]);
    %title(handles.pltOxPeak,FileName(1:length(FileName)-4), 'FontSize', 11, 'Color', 'k','Interpreter','none');
    ylabel(handles.pltOxPeak,'Current (nA)','FontSize',10);
    
    cla(handles.pltOxPeak_2);
    plot(handles.pltOxPeak_2,(1:length(OxPeak_2)),V.Gain*OxPeak_2,'color',[0.8,0.4,0]);
    %title(handles.pltOxPeak_2,FileName(1:length(FileName)-4), 'FontSize', 11, 'Color', 'k','Interpreter','none');
    ylabel(handles.pltOxPeak_2,'Current (nA)','FontSize',10);
    

    %set period to determine correct time is plotted
    signal_period_label = strcat('Time (',num2str(SignalPeriod_ms), ' ms)'); 
    xlabel(handles.pltOxPeak,signal_period_label,'FontSize',10); 
    xlabel(handles.pltOxPeak_2,signal_period_label,'FontSize',10); 
    
    waitbar(1, progress_bar,'Finishing...');
    close(progress_bar);
    delete(progress_bar);
    
    %label and mark the injections on the plots
    hzoom=zoom(handles.pltOxPeak); %toggle zoom
    hzoom.ActionPostCallback = '';%function to execute after zooming
    zoom(handles.pltOxPeak,'out');%zoom out
    zoom(handles.pltOxPeak,'reset');%reset zoom
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
  
    hzoom_2=zoom(handles.pltOxPeak_2);
    hzoom_2.ActionPostCallback = '';
    zoom(handles.pltOxPeak_2,'out');
    zoom(handles.pltOxPeak_2,'reset');
    hold on;
    t_2=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak_2.YLim,'Color','r')
        LimitesY_2=handles.pltOxPeak_2.YLim;
        t_2(i)=text(V.Injections(i),LimitesY_2(2),V.InjectionLabel{i});
        t_2(i).Position(2)=LimitesY_2(2)-t_2(i).Extent(4)/2;
    end
   
    
    % Concentration peaks table
    hPointsSP = gobjects;
    hPointsPP = gobjects;
    hPointsEP = gobjects;
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
    
    SelectedRow=0;
    UpdateTable(handles);
    ModifiedData=0;
    
    % Set WindowButtonMotionFcn to PlotMouseMove
    set(handles.frmMain, 'WindowButtonMotionFcn', @PlotMouseMove);
    PlotMouseMoveMode=0; % Only time since injection is display
    hlblTimeSinceInjection=handles.lblTimeSinceInjection;
    
    % Enable zoom and various buttons
    hzoom.ActionPostCallback = @mypostcallback;
    hzoom_2.ActionPostCallback = @mypostcallback_2;
    hplt=handles.pltOxPeak;
    hplt_2=handles.pltOxPeak_2;
    handles.cmdAddPeakValues.Enable='on';
    handles.cmdAddInjStimPeaks.Enable='on';
    handles.cmdSaveData.Enable='on';
    handles.cmdSelectInterval.Enable='on';
    handles.sldOxPeakV.Enable='on';
    handles.sldOxPeakV_2.Enable='on';
    handles.tblPeaks.Enable='on';
    handles.cmdCopypltOxPeak.Enable='on';
    handles.cmdSavepltOxpeak.Enable='on';
    handles.cmdExportExcelpltOxPeak.Enable='on';
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
    handles.cmdSignalAnalyzer.Enable='on';
    handles.btn_extract_segment.Enable='on';
    handles.txt_extract_stimNumber.Enable='on';
    handles.txt_extract_msbefore.Enable='on';
    handles.txt_extract_msafter.Enable='on';
    
    %only allow filter if >=500 cycles
    %TODO: is this needed?
    if V.N_Cycles>=500
        handles.sldFilterFrec.Enable='on';
        handles.sldFilterFrecIIR.Enable='on';
        handles.optOriginal.Enable='on';
        handles.optFiltered.Enable='on';
        handles.optBoth.Enable='on';
        handles.optIIRFilter.Enable='on';
        handles.optMA.Enable='on';
        handles.txtMAinterval.Enable='on';
        handles.optCustomFilter.Enable='on';
    end
    
    %only enable table if peaks exist
    if V.N_Peaks>0
        handles.cmdCopyTable.Enable='on';
        handles.chkCommaDecimalDelimiter.Enable='on';
        handles.chkAverageSignals.Value=0;
        handles.chkAverageSignals.Enable='on';
        handles.txtAverageInterval.Enable='on';
        handles.lblAverageInterval.ForegroundColor=[0 0 0];
    else 
        handles.cmdCopyTable.Enable='off';
        handles.chkCommaDecimalDelimiter.Enable='off';
        handles.chkAverageSignals.Value=0;
        handles.chkAverageSignals.Enable='off';
        handles.txtAverageInterval.Enable='off';
        handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
    end
    

end


function mypostcallback(obj,evd)
global V t
newYLim = evd.Axes.YLim;
newXLim = evd.Axes.XLim;
for i=1:V.N_Injections
    if (V.Injections(i)>newXLim(1)) && (V.Injections(i)<newXLim(2))
        line([V.Injections(i) V.Injections(i)],newYLim,'Color','r')
        t(i).Position=[V.Injections(i) newYLim(2)-t(i).Extent(4)/2];
        t(i).Visible='on';
    else
        t(i).Visible='off';
    end
end

function mypostcallback_2(obj,evd_2)
global V t_2
newYLim_2 = evd_2.Axes.YLim;
newXLim_2 = evd_2.Axes.XLim;
for i=1:V.N_Injections
    if (V.Injections(i)>newXLim_2(1)) && (V.Injections(i)<newXLim_2(2))
        line([V.Injections(i) V.Injections(i)],newYLim_2,'Color','r')
        t_2(i).Position=[V.Injections(i) newYLim_2(2)-t_2(i).Extent(4)/2];
        t_2(i).Visible='on';
    else
        t_2(i).Visible='off';
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = SeroProcessData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cmdSelectInterval.
function cmdSelectInterval_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSelectInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IntervalIni IntervalEnd V l1 l2

%turn buttons off
handles.cmdSelectInterval.Enable='off';
handles.cmdAddPeakValues.Enable='off';
handles.cmdAddInjStimPeaks.Enable='off';
handles.sldOxPeakV.Enable='off';
handles.cmdSignalAnalyzer.Enable='off';
handles.tblPeaks.Enable='off';
handles.optOriginal.Enable='off';
handles.optFiltered.Enable='off';
handles.optBoth.Enable='off';
handles.sldFilterFrec.Enable='off';
handles.cmdSaveData.Enable='off';
handles.cmdLoadData.Enable='off';

%draw lines where user selects
[x,y,button]=ginput(1)
IntervalX1=round(x);
l1=line(handles.pltOxPeak,[IntervalX1 IntervalX1],handles.pltOxPeak.YLim,'Color','g')
[x,y,button]=ginput(1);
IntervalX2=round(x);
l2=line(handles.pltOxPeak,[IntervalX2 IntervalX2],handles.pltOxPeak.YLim,'Color','g')

%swap the intervals if they are out of order
if IntervalX1<IntervalX2
    IntervalIni=IntervalX1;
    IntervalEnd=IntervalX2;
else
    IntervalIni=IntervalX2;
    IntervalEnd=IntervalX1;
end

%ensure interval is within signal limits
if (IntervalIni<=0) || (IntervalEnd>V.N_Cycles)
    msgbox('The selected interval should be within the signal limits','Selection Error');
    delete(l1);
    delete(l2);
    handles.cmdSelectInterval.Enable='on';
    handles.cmdAddPeakValues.Enable='on';
    handles.cmdAddInjStimPeaks.Enable='on';
    handles.sldOxPeakV.Enable='on';
    handles.cmdSignalAnalyzer.Enable='on';
    handles.tblPeaks.Enable='on';
    if V.N_Cycles>=500
        handles.optOriginal.Enable='on';
        handles.optFiltered.Enable='on';
        handles.optBoth.Enable='on';
        handles.sldFilterFrec.Enable='on';
    end
    handles.cmdSaveData.Enable='on';
    handles.cmdLoadData.Enable='on';
else
    handles.cmdCancelEdit.Enable='on';
    handles.cmdDeleteInterval.Enable='on'; 
end


% --- Executes when entered data in editable cell(s) in tblPeaks.
function tblPeaks_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tblPeaks (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
%disp('Hola');
%disp(eventdata.NewData);


% --------------------------------------------------------------------
function tblPeaks_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to tblPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%disp('Hola');


% --- Executes during object creation, after setting all properties.
function pltOxPeak_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate pltOxPeak


% --- Executes during object creation, after setting all properties.
function pltOxPeak_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate pltOxPeak


% --- Executes on button press in cmdDeleteInterval.
function cmdDeleteInterval_Callback(hObject, eventdata, handles)
% hObject    handle to cmdDeleteInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V IntervalIni IntervalEnd t OxPeakV OxPeak OxPeakV_2 OxPeak_2 hPointsSP hPointsPP hPointsEP
global OxPeakFiltered Hd DisplaySignal hzoom hplt ModifiedData SelectedRow
global Saved_Data_Array 

ModifiedData=1;
if IntervalIni==1
    NewSaved_Data=Saved_Data_Array((IntervalEnd-1)*V.PointsPerCycle+1:V.N_Cycles*V.PointsPerCycle);
elseif IntervalEnd==V.N_Cycles
    NewSaved_Data=Saved_Data_Array(1:(IntervalIni)*V.PointsPerCycle);
else
    NewSaved_Data=[Saved_Data_Array(1:(IntervalIni-1)*V.PointsPerCycle) Saved_Data_Array((IntervalEnd-1)*V.PointsPerCycle+1:V.N_Cycles*V.PointsPerCycle)];
end

Saved_Data_Array=NewSaved_Data;
V.N_Cycles=V.N_Cycles-(IntervalEnd-IntervalIni);
NewInjections=V.Injections;
NewInjectionLabel=V.InjectionLabel;
NewN_Injections=0;
for i=1:V.N_Injections
    if (V.Injections(i)<IntervalIni) || (V.Injections(i)>=IntervalEnd)
        NewN_Injections=NewN_Injections+1;
        NewInjectionLabel(NewN_Injections)=V.InjectionLabel(i);
        NewInjections(NewN_Injections)=V.Injections(i);
    end
end
V.Injections=NewInjections;
V.InjectionLabel=NewInjectionLabel;
V.N_Injections=NewN_Injections;
for i=1:V.N_Injections
    if V.Injections(i)>IntervalEnd
        V.Injections(i)=V.Injections(i)-(IntervalEnd-IntervalIni);
    end
end

NewV.SP_Peaks=V.SP_Peaks;
NewV.PP_Peaks=V.PP_Peaks;
NewV.EP_Peaks=V.EP_Peaks;
NewV.PeaksLabel=V.PeaksLabel;
NewV.N_Peaks=0;
for i=1:V.N_Peaks
    if ((V.SP_Peaks(i)<IntervalIni) || (V.SP_Peaks(i)>=IntervalEnd)) && ((V.PP_Peaks(i)<IntervalIni) || (V.PP_Peaks(i)>=IntervalEnd)) && ((V.EP_Peaks(i)<IntervalIni) || (V.EP_Peaks(i)>=IntervalEnd))
        NewV.N_Peaks=NewV.N_Peaks+1;
        NewV.PeaksLabel(NewV.N_Peaks)=V.PeaksLabel(i);
        NewV.SP_Peaks(NewV.N_Peaks)=V.SP_Peaks(i);
        NewV.PP_Peaks(NewV.N_Peaks)=V.PP_Peaks(i);
        NewV.EP_Peaks(NewV.N_Peaks)=V.EP_Peaks(i);
    end
end
V.N_Peaks=NewV.N_Peaks;
V.PeaksLabel=NewV.PeaksLabel;
V.SP_Peaks=NewV.SP_Peaks;
V.PP_Peaks=NewV.PP_Peaks;
V.EP_Peaks=NewV.EP_Peaks;
for i=1:V.N_Peaks
    if V.SP_Peaks(i)>IntervalEnd
        V.SP_Peaks(i)=V.SP_Peaks(i)-(IntervalEnd-IntervalIni);
    end
    if V.PP_Peaks(i)>IntervalEnd
        V.PP_Peaks(i)=V.PP_Peaks(i)-(IntervalEnd-IntervalIni);
    end
    if V.EP_Peaks(i)>IntervalEnd
        V.EP_Peaks(i)=V.EP_Peaks(i)-(IntervalEnd-IntervalIni);
    end
end

OxPeak=0;
for i=1:V.N_Cycles
    OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV); 
end
OxPeakFiltered=filter(Hd,OxPeak);
N=length(Hd.Numerator)-1;
OxPeakFiltered=OxPeakFiltered(round(N/2):length(OxPeakFiltered));
OxPeakFiltered(1:round(N/2))=OxPeakFiltered(round(N/2)+1:2*round(N/2));

cla(handles.pltOxPeak);
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
%zoom(handles.pltOxPeak,'reset');
hold on;
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
    LimitesY=handles.pltOxPeak.YLim;
    t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
    t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
end
if (DisplaySignal==1)
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
else
   for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end 
end
hzoom.ActionPostCallback = @mypostcallback;
hplt=handles.pltOxPeak;
SelectedRow=0;
UpdateTable(handles);
handles.cmdCancelEdit.Enable='off';
handles.cmdDeleteInterval.Enable='off';
handles.cmdSelectInterval.Enable='on';
handles.cmdSignalAnalyzer.Enable='on';
handles.cmdAddPeakValues.Enable='on';
handles.cmdAddInjStimPeaks.Enable='on';
handles.sldOxPeakV.Enable='on';
handles.tblPeaks.Enable='on';
if V.N_Cycles>=500
    handles.optOriginal.Enable='on';
    handles.optFiltered.Enable='on';
    handles.optBoth.Enable='on';
    handles.sldFilterFrec.Enable='on';
end
if V.N_Peaks>0
    handles.cmdCopyTable.Enable='on';
    handles.chkCommaDecimalDelimiter.Enable='on';
    handles.chkAverageSignals.Enable='on';
    handles.txtAverageInterval.Enable='on';
    handles.lblAverageInterval.ForegroundColor=[0 0 0];
else
    handles.cmdCopyTable.Enable='off';
    handles.chkCommaDecimalDelimiter.Enable='off';
    handles.chkAverageSignals.Value=0;
    handles.chkAverageSignals.Enable='off';
    handles.txtAverageInterval.Enable='off';
    handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
end
handles.cmdSaveData.Enable='on';
handles.cmdLoadData.Enable='on';
handles.cmdDeletePeakValues.Enable='off';
handles.cmdMovePeakUp.Enable='off';
handles.cmdMovePeakDown.Enable='off';
handles.cmdEditPeakLabel.Enable='off';


% --- Executes on button press in cmdCancelEdit.
function cmdCancelEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCancelEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global l1 l2 V

%remove the lines, enable buttons
delete(l1);
delete(l2);
handles.cmdCancelEdit.Enable='off';
handles.cmdDeleteInterval.Enable='off';
handles.cmdSelectInterval.Enable='on';
handles.cmdSignalAnalyzer.Enable='on';
handles.cmdAddPeakValues.Enable='on';
handles.cmdAddInjStimPeaks.Enable='on';
handles.sldOxPeakV.Enable='on';
handles.tblPeaks.Enable='on';
if V.N_Cycles>=500
    handles.optOriginal.Enable='on';
    handles.optFiltered.Enable='on';
    handles.optBoth.Enable='on';
    handles.sldFilterFrec.Enable='on';
end
handles.cmdSaveData.Enable='on';
handles.cmdLoadData.Enable='on';


% --- Executes on slider movement.
function sldOxPeakV_Callback(hObject, eventdata, handles)
% hObject    handle to sldOxPeakV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global V t OxPeakV OxPeak OxPeakV_2 OxPeak_2 hPointsSP hPointsPP hPointsEP OxPeakFiltered DisplaySignal 
global Hd hplt hzoom SelectedRow

global Saved_Data_Array

OxPeakV=round(handles.sldOxPeakV.Value);
if OxPeakV==0
    OxPeakV=1; 
end
handles.lblOxPeakV.String=OxPeakV;
for i=1:V.N_Cycles
    OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV);
end
OxPeak=0;
for i=1:V.N_Cycles
    OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV); 
end
OxPeakFiltered=filter(Hd,OxPeak);
N=length(Hd.Numerator)-1;
OxPeakFiltered=OxPeakFiltered(round(N/2):length(OxPeakFiltered));
OxPeakFiltered(1:round(N/2))=OxPeakFiltered(round(N/2)+1:2*round(N/2));

cla(handles.pltOxPeak);
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
zoom(handles.pltOxPeak,'out');
zoom(handles.pltOxPeak,'reset');
hold on;
t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
    t(i)=text(V.Injections(i),handles.pltOxPeak.YLim(2),V.InjectionLabel{i});
    t(i).Position(2)=handles.pltOxPeak.YLim(2)-t(i).Extent(4)/2;
end
if (DisplaySignal==1)
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
else
   for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end 
end
hzoom.ActionPostCallback = @mypostcallback;
hplt=handles.pltOxPeak;
SelectedRow=0;
UpdateTable(handles);
handles.cmdDeletePeakValues.Enable='off';
handles.cmdMovePeakUp.Enable='off';
handles.cmdMovePeakDown.Enable='off';
handles.cmdEditPeakLabel.Enable='off';


% --- Executes during object creation, after setting all properties.
function sldOxPeakV_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldOxPeakV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sldOxPeakV_2_Callback(hObject, eventdata, handles)
% hObject    handle to sldOxPeakV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global V t_2 OxPeakV_2 OxPeak_2 hPointsSP hPointsPP hPointsEP OxPeakFiltered DisplaySignal 
global Hd hplt_2 hzoom_2 SelectedRow

global Saved_Data_Array

OxPeakV_2=round(handles.sldOxPeakV_2.Value);
if OxPeakV_2==0
    OxPeakV_2=1; 
end
handles.lblOxPeakV_2.String=OxPeakV_2;
for i=1:V.N_Cycles
    OxPeak_2(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV_2);
end
OxPeak_2=0;
for i=1:V.N_Cycles
    OxPeak_2(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV_2); 
end
% OxPeakFiltered=filter(Hd,OxPeak_2);
% N=length(Hd.Numerator)-1;
% OxPeakFiltered=OxPeakFiltered(round(N/2):length(OxPeakFiltered));
% OxPeakFiltered(1:round(N/2))=OxPeakFiltered(round(N/2)+1:2*round(N/2));

cla(handles.pltOxPeak_2);
%if (DisplaySignal==1) || (DisplaySignal==3)
plot(handles.pltOxPeak_2,V.Gain*OxPeak_2,'color',[0.8,0.4,0]);

% if (DisplaySignal==2) || (DisplaySignal==3)
%     plot(handles.pltOxPeak_2,V.Gain*OxPeakFiltered,'color','b');

hzoom_2=zoom(handles.pltOxPeak_2);
hzoom_2.ActionPostCallback = '';
zoom(handles.pltOxPeak_2,'out');
zoom(handles.pltOxPeak_2,'reset');
hold on;
t_2=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak_2.YLim,'Color','r')
    t_2(i)=text(V.Injections(i),handles.pltOxPeak_2.YLim(2),V.InjectionLabel{i});
    t_2(i).Position(2)=handles.pltOxPeak_2.YLim(2)-t_2(i).Extent(4)/2;
end
% if (DisplaySignal==1)
%     for i=1:V.N_Peaks
%         hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
%         hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
%         hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
%     end
% else
%    for i=1:V.N_Peaks
%         hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
%         hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
%         hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
%     end 
%end
hzoom_2.ActionPostCallback = @mypostcallback_2;
hplt_2=handles.pltOxPeak_2;
% SelectedRow=0;
% UpdateTable(handles);
% handles.cmdDeletePeakValues.Enable='off';
% handles.cmdMovePeakUp.Enable='off';
% handles.cmdMovePeakDown.Enable='off';
% handles.cmdEditPeakLabel.Enable='off';


% --- Executes during object creation, after setting all properties.
function sldOxPeakV_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldOxPeakV_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in cmdAddInjStimPeaks.
function cmdAddInjStimPeaks_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddInjStimPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tx1 OxPeak V hzoom hPointsSP hPointsPP hPointsEP FilterFrec DisplaySignal
global OxPeakFiltered ModifiedData PlotMouseMoveMode t SelectedRow SignalFreq

%initialize fixed interval flag
FixedInterval=0;

%user input
Answer = questdlg('Do you want to use automatic fixed time intervals from injection/stimulation?','Add Inj./Stim. Peaks','Yes','No','Yes');

if strcmp(Answer,'Yes')==1
    %set flag, get user input
    FixedInterval=1;
    Fields = {'Time interval from injection/stimulation to Start Point (sec):'...
        ,'Time interval from injection/stimulation to Peak Point (sec):'...
        ,'Time interval from injection/stimulation to End Point (sec):'};
    Title = 'Input';
    R = inputdlg(Fields,Title);
    
    %if all fields empty, return
    if isempty(R)
        return;
    end
    
    %ensure no missing or non integer fields
    if isempty(R{1}) || isempty(R{2}) || isempty(R{3}) || isnan(str2double(R{1})) || isnan(str2double(R{2})) || isnan(str2double(R{3}))
        msgbox('Error introducing data; empty or non-numerical fields');
        return;
    end
    
    %ensure peaks are ordered correctly
    if str2double(R{1}) >= str2double(R{2}) || str2double(R{2}) >= str2double(R{3}) || str2double(R{1}) >= str2double(R{3})
        msgbox('Start/peak point cannot be before or equal to peak/end point');
        return;
    end
    
    SP_TimeInterval=round(str2double(R{1}))*SignalFreq;
    PP_TimeInterval=round(str2double(R{2}))*SignalFreq;
    EP_TimeInterval=round(str2double(R{3}))*SignalFreq;
end

ModifiedData=1; %set flag

%enable buttons
hzoom.Enable='off';
handles.cmdZoom.Enable='off';
handles.cmdAddPeakValues.Enable='off';
handles.cmdAddInjStimPeaks.Enable='off';
handles.cmdSelectInterval.Enable='off';
handles.cmdSignalAnalyzer.Enable='off';
handles.sldOxPeakV.Enable='off';
handles.tblPeaks.Enable='off';
handles.optOriginal.Enable='off';
handles.optFiltered.Enable='off';
handles.optBoth.Enable='off';
handles.sldFilterFrec.Enable='off';
handles.cmdSaveData.Enable='off';
handles.cmdLoadData.Enable='off';

if FixedInterval==1 %automatically add all injections as peaks
    for k=1:V.N_Injections
        V.N_Peaks=V.N_Peaks+1; %each injection becomes a peak
        V.PeaksLabel(V.N_Peaks)=V.InjectionLabel(k); %each peak is labeled as the injection label
        V.SP_Peaks(V.N_Peaks)=V.Injections(k)+SP_TimeInterval; %convert time interval
        
%         if V.SP_Peaks(V.N_Peaks)>(V.N_Cycles-201) %start point cannot be closer than 201 cycles from the end 
%             V.SP_Peaks(V.N_Peaks)=V.N_Cycles-201;
%         end
        
        %plot peak on correctly filtered signal
        if DisplaySignal==1 
            hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,V.SP_Peaks(V.N_Peaks),V.Gain*OxPeak(V.SP_Peaks(V.N_Peaks)),'rx');
        else
            hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,V.SP_Peaks(V.N_Peaks),V.Gain*OxPeakFiltered(V.SP_Peaks(V.N_Peaks)),'rx');
        end
        
        V.PP_Peaks(V.N_Peaks)=V.Injections(k)+PP_TimeInterval;%convert time interval
        
%         if V.PP_Peaks(V.N_Peaks)>(V.N_Cycles-201)%peak point cannot be closer than 201 cycles from the end
%             V.PP_Peaks(V.N_Peaks)=V.N_Cycles-201;
%         end
        
        %plot peak on correctly filtered signal
        if DisplaySignal==1
            hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,V.PP_Peaks(V.N_Peaks),V.Gain*OxPeak(V.PP_Peaks(V.N_Peaks)),'m*');
        else
            hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,V.PP_Peaks(V.N_Peaks),V.Gain*OxPeakFiltered(V.PP_Peaks(V.N_Peaks)),'m*');
        end
        
        V.EP_Peaks(V.N_Peaks)=V.Injections(k)+EP_TimeInterval;%convert time interval
        
%         if V.EP_Peaks(V.N_Peaks)>(V.N_Cycles-201) %end point cannot be closer than 201 cycles from the end
%             V.EP_Peaks(V.N_Peaks)=V.N_Cycles-201;
%         end

        %plot peak on correctly filtered signal
        if DisplaySignal==1
            hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,V.EP_Peaks(V.N_Peaks),V.Gain*OxPeak(V.EP_Peaks(V.N_Peaks)),'k+');
        else
            hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,V.EP_Peaks(V.N_Peaks),V.Gain*OxPeakFiltered(V.EP_Peaks(V.N_Peaks)),'k+');
        end
    end
    
    %set up table
    SelectedRow=0;
    UpdateTable(handles);
    
else %individually aska bout each injections as a peak
    for k=1:V.N_Injections
        %set axes limits
        handles.pltOxPeak.XLim(1)=0; 
        if k==V.N_Injections
            %handles.pltOxPeak.XLim(2)=V.N_Cycles-201;
            handles.pltOxPeak.XLim(2)=V.N_Cycles-1;
        else
            handles.pltOxPeak.XLim(2)=V.Injections(k+1);
        end
        handles.pltOxPeak.XLim(1)=V.Injections(k)-20;
        handles.pltOxPeak.YLim(1)=min(V.Gain*OxPeak(handles.pltOxPeak.XLim(1):handles.pltOxPeak.XLim(2)));
        handles.pltOxPeak.YLim(2)=max(V.Gain*OxPeak(handles.pltOxPeak.XLim(1):handles.pltOxPeak.XLim(2)));
       
        %plot injection labels if they are between axes limits
        for i=1:V.N_Injections
            if (V.Injections(i)>handles.pltOxPeak.XLim(1)) && (V.Injections(i)<handles.pltOxPeak.XLim(2))
                line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
                t(i).Position=[V.Injections(i) handles.pltOxPeak.YLim(2)-t(i).Extent(4)/2];
                t(i).Visible='on';
            else
                t(i).Visible='off';
            end
        end
        
        %ask about an individual injection
        QuestionString=['Do you want to add Inj./Stim. peak ' V.InjectionLabel(k)];
        Answer = questdlg(QuestionString, 'Add Inj./Stim. Peaks','Yes','Skip','Cancel','Yes');
        
        % If the user cancels the process, exit the function
        if strcmp(Answer,'Cancel')==1 
            handles.cmdZoom.Enable='on';
            handles.cmdAddPeakValues.Enable='on';
            handles.cmdAddInjStimPeaks.Enable='on';
            handles.cmdSelectInterval.Enable='on';
            handles.cmdSignalAnalyzer.Enable='on';
            handles.sldOxPeakV.Enable='on';
            handles.tblPeaks.Enable='on';
            if V.N_Cycles>=500
                handles.optOriginal.Enable='on';
                handles.optFiltered.Enable='on';
                handles.optBoth.Enable='on';
                handles.sldFilterFrec.Enable='on';
            end
            handles.cmdSaveData.Enable='on';
            handles.cmdLoadData.Enable='on';
            if V.N_Peaks>0
                handles.cmdCopyTable.Enable='on';
                handles.chkCommaDecimalDelimiter.Enable='on';
                handles.chkAverageSignals.Enable='on';
                handles.txtAverageInterval.Enable='on';
                handles.lblAverageInterval.ForegroundColor=[0 0 0];
            else
                handles.cmdCopyTable.Enable='off';
                handles.chkCommaDecimalDelimiter.Enable='off';
                handles.chkAverageSignals.Value=0;
                handles.chkAverageSignals.Enable='off';
                handles.txtAverageInterval.Enable='off';
                handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
            end
            return;
        end
        
        % Hitting skip just iterates to next injection
        
        % If the user wants to add the peak
        if strcmp(Answer,'Yes')==1
            R=inputdlg('Introduce peak label:','Peak Label',1,{char(V.InjectionLabel(k))});
            if ~isempty(R) %ensure user input
                ModifiedData=1; %set flag
                V.N_Peaks=V.N_Peaks+1; %add to peak counter
                V.PeaksLabel(V.N_Peaks)=R(1,1); %set input as label
                PlotMouseMoveMode=1; % Time since injection + Peak text are are display
                
                %prompt and wait for user input of start point
                tx1=text(handles.pltOxPeak,0,0,'Click on Start Point');
                while 1
                    k=waitforbuttonpress;
                    D = get (handles.pltOxPeak, 'CurrentPoint');
                    if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
                        break
                    end
                end
                SPx=round(tx1.Position(1));
%                 if SPx<201
%                     SPx=201;
%                 end
                delete(tx1);
                
c
                if DisplaySignal==1
                    hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,SPx,V.Gain*OxPeak(SPx),'rx');
                else
                    hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,SPx,V.Gain*OxPeakFiltered(SPx),'rx');
                end
                
                V.SP_Peaks(V.N_Peaks)=SPx;%add start point to SP array
                
                %prompt and wait for user input of peak point
                tx1=text(handles.pltOxPeak,0,0,'Click on Peak Point');
                while 1
                    k=waitforbuttonpress;
                    D = get (handles.pltOxPeak, 'CurrentPoint');
                    if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
                        break
                    end
                end
                PPx=round(tx1.Position(1));
                delete(tx1);
                
                %plot start point as magenta star
                if DisplaySignal==1
                    hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,PPx,V.Gain*OxPeak(PPx),'m*');
                else
                    hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,PPx,V.Gain*OxPeakFiltered(PPx),'m*');
                end
                
                V.PP_Peaks(V.N_Peaks)=PPx;%add peak point to PP array
                
                %prompt and wait for user input of end point
                tx1=text(handles.pltOxPeak,0,0,'Click on End Point');
                while 1
                    k=waitforbuttonpress;
                    D = get (handles.pltOxPeak, 'CurrentPoint');
                    if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
                        break
                    end
                end
                EPx=round(tx1.Position(1));
%                 if EPx>(V.N_Cycles-201)
%                     EPx=V.N_Cycles-201;
%                 end
                
                %plot end point as black cross
                if DisplaySignal==1
                    hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,EPx,V.Gain*OxPeak(EPx),'k+');
                else
                    hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,EPx,V.Gain*OxPeakFiltered(EPx),'k+');
                end
                
                V.EP_Peaks(V.N_Peaks)=EPx;%add end point to EP array
                
                PlotMouseMoveMode=0; % Only time since injection is display
                delete(tx1);
                
                %set colors of points
                for i=1:V.N_Peaks
                    hPointsSP(i).Color='r';
                    hPointsPP(i).Color='m';
                    hPointsEP(i).Color='k';
                end
                
                %set up table, enable buttons
                SelectedRow=0;
                UpdateTable(handles);
                handles.cmdDeletePeakValues.Enable='off';
                handles.cmdMovePeakUp.Enable='off';
                handles.cmdMovePeakDown.Enable='off';
                handles.cmdEditPeakLabel.Enable='off';
            end
        end
    end
end

%enable buttoms
handles.cmdZoom.Enable='on';
handles.cmdAddPeakValues.Enable='on';
handles.cmdAddInjStimPeaks.Enable='on';
handles.cmdSelectInterval.Enable='on';
handles.cmdSignalAnalyzer.Enable='on';
handles.sldOxPeakV.Enable='on';
handles.tblPeaks.Enable='on';
if V.N_Cycles>=500
    handles.optOriginal.Enable='on';
    handles.optFiltered.Enable='on';
    handles.optBoth.Enable='on';
    handles.sldFilterFrec.Enable='on';
end
handles.cmdSaveData.Enable='on';
handles.cmdLoadData.Enable='on';
if V.N_Peaks>0
    handles.cmdCopyTable.Enable='on';
    handles.chkCommaDecimalDelimiter.Enable='on';
    handles.chkAverageSignals.Enable='on';
    handles.txtAverageInterval.Enable='on';
    handles.lblAverageInterval.ForegroundColor=[0 0 0];
else
    handles.cmdCopyTable.Enable='off';
    handles.chkCommaDecimalDelimiter.Enable='off';
    handles.chkAverageSignals.Value=0;
    handles.chkAverageSignals.Enable='off';
    handles.txtAverageInterval.Enable='off';
    handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
end





% --- Executes on button press in cmdAddPeakValues.
function cmdAddPeakValues_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddPeakValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global tx1 OxPeak V hzoom hPointsSP hPointsPP hPointsEP FilterFrec DisplaySignal
global OxPeakFiltered ModifiedData PlotMouseMoveMode SelectedRow

%enable buttons
hzoom.Enable='off';
handles.cmdZoom.Enable='off';
handles.cmdAddPeakValues.Enable='off';
handles.cmdAddInjStimPeaks.Enable='off';
handles.cmdSelectInterval.Enable='off';
handles.cmdSignalAnalyzer.Enable='off';
handles.sldOxPeakV.Enable='off';
handles.tblPeaks.Enable='off';
handles.optOriginal.Enable='off';
handles.optFiltered.Enable='off';
handles.optBoth.Enable='off';
handles.sldFilterFrec.Enable='off';
handles.cmdSaveData.Enable='off';
handles.cmdLoadData.Enable='off';

R=inputdlg('Introduce peak label:');%get user input
if ~isempty(R) %ensure input not empty
    ModifiedData=1; %set flag
    V.N_Peaks=V.N_Peaks+1; %add to peak counter
    V.PeaksLabel(V.N_Peaks)=R(1,1); %set input as label
    PlotMouseMoveMode=1; % Time since injection + Peak text are are display
    
    %prompt and wait for user input of start point
    tx1=text(handles.pltOxPeak,0,0,'Click on Start Point');
    while 1
        k=waitforbuttonpress;
        D = get (handles.pltOxPeak, 'CurrentPoint');
        if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
            break
        end
    end
    SPx=round(tx1.Position(1));
%     if SPx<201 
%         SPx=201;
%     end
    delete(tx1);
    %disp(SPx);
    
    %plot SP as red x
    if DisplaySignal==1
        hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,SPx,V.Gain*OxPeak(SPx),'rx');
    else
        hPointsSP(V.N_Peaks)=plot(handles.pltOxPeak,SPx,V.Gain*OxPeakFiltered(SPx),'rx');
    end
    
    V.SP_Peaks(V.N_Peaks)=SPx;%add start point to SP array
    
    %prompt and wait for user input of peak point
    tx1=text(handles.pltOxPeak,0,0,'Click on Peak Point');
    while 1
        k=waitforbuttonpress;
        D = get (handles.pltOxPeak, 'CurrentPoint');
        if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
            break
        end
    end
    PPx=round(tx1.Position(1));
    delete(tx1);
    %disp(PPx);
    
    %plot peak point as magenta star
    if DisplaySignal==1
        hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,PPx,V.Gain*OxPeak(PPx),'m*');
    else
        hPointsPP(V.N_Peaks)=plot(handles.pltOxPeak,PPx,V.Gain*OxPeakFiltered(PPx),'m*');
    end
    
    V.PP_Peaks(V.N_Peaks)=PPx;%add peak point to PP array

    %prompt and wait for user input of end point
    tx1=text(handles.pltOxPeak,0,0,'Click on End Point');
    while 1
        k=waitforbuttonpress;
        D = get (handles.pltOxPeak, 'CurrentPoint');
        if (k==0) && (D(1,1)>handles.pltOxPeak.XLim(1)) && (D(1,1)<handles.pltOxPeak.XLim(2)) && (D(1,2)>handles.pltOxPeak.YLim(1)) && (D(1,2)<handles.pltOxPeak.YLim(2))
            break
        end
    end
    
    EPx=round(tx1.Position(1));
    %disp(EPx);
%     if EPx>(V.N_Cycles-201)
%         EPx=V.N_Cycles-201;
%     end

    %plot end point as black cross
    if DisplaySignal==1
        hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,EPx,V.Gain*OxPeak(EPx),'k+');
    else
        hPointsEP(V.N_Peaks)=plot(handles.pltOxPeak,EPx,V.Gain*OxPeakFiltered(EPx),'k+');
    end
    
    V.EP_Peaks(V.N_Peaks)=EPx;%add end point to EP array
    
    PlotMouseMoveMode=0; % Only time since injection is display
    delete(tx1);
    
    %set point colors
    for i=1:V.N_Peaks
        hPointsSP(i).Color='r';
        hPointsPP(i).Color='m';
        hPointsEP(i).Color='k';
    end
    
    %set up table
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end

%enable buttons
handles.cmdZoom.Enable='on';
handles.cmdAddPeakValues.Enable='on';
handles.cmdAddInjStimPeaks.Enable='on';
handles.cmdSelectInterval.Enable='on';
handles.cmdSignalAnalyzer.Enable='on';
handles.sldOxPeakV.Enable='on';
handles.tblPeaks.Enable='on';
if V.N_Cycles>=500 
    handles.optOriginal.Enable='on';
    handles.optFiltered.Enable='on';
    handles.optBoth.Enable='on';
    handles.sldFilterFrec.Enable='on';
end
handles.cmdSaveData.Enable='on';
handles.cmdLoadData.Enable='on';
if V.N_Peaks>0
    handles.cmdCopyTable.Enable='on';
    handles.chkCommaDecimalDelimiter.Enable='on';
    handles.chkAverageSignals.Enable='on';
    handles.txtAverageInterval.Enable='on';
    handles.lblAverageInterval.ForegroundColor=[0 0 0];
else
    handles.cmdCopyTable.Enable='off';
    handles.chkCommaDecimalDelimiter.Enable='off';
    handles.chkAverageSignals.Value=0;
    handles.chkAverageSignals.Enable='off';
    handles.txtAverageInterval.Enable='off';
    handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
end

% --- Executes when selected cell(s) is changed in tblPeaks.
function tblPeaks_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to tblPeaks (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global V OxPeak hPointsSP hPointsPP hPointsEP SelectedRow DisplaySignal
global OxPeakFiltered

%set the selected rows and points to cyan
%disp(eventdata.Indices);
if ~isempty(eventdata.Indices)
    SelectedRows=eventdata.Indices;
    SelectedRow=SelectedRows(1);
    UpdateTable(handles);
    for i=1:V.N_Peaks
        if i==SelectedRow
            hPointsSP(i).Color='c';
            hPointsPP(i).Color='c';
            hPointsEP(i).Color='c';
        else
            hPointsSP(i).Color='r';
            hPointsPP(i).Color='m';
            hPointsEP(i).Color='k';
        end
    end
    handles.cmdDeletePeakValues.Enable='on';
    handles.cmdMovePeakUp.Enable='on';
    handles.cmdMovePeakDown.Enable='on';
    handles.cmdEditPeakLabel.Enable='on';
end


% --- Executes on button press in cmdDeletePeakValues.
function cmdDeletePeakValues_Callback(hObject, eventdata, handles)
% hObject    handle to cmdDeletePeakValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V SelectedRow hPointsSP hPointsPP hPointsEP DisplaySignal
global OxPeakFiltered OxPeak t hzoom hplt ModifiedData

ModifiedData=1;%set flag

%reindex all peaks less a deleted one 
for i=1:V.N_Peaks-1
    if SelectedRow>i %peaks above deleted peak are not affected 
        V.PeaksLabel{1,i}=V.PeaksLabel{1,i};
        V.SP_Peaks(i)=V.SP_Peaks(i);
        V.PP_Peaks(i)=V.PP_Peaks(i);
        V.EP_Peaks(i)=V.EP_Peaks(i);
    else %peaks below deleted peak are moved reindexed by 1
        V.PeaksLabel{1,i}=V.PeaksLabel{1,i+1};
        V.SP_Peaks(i)=V.SP_Peaks(i+1);
        V.PP_Peaks(i)=V.PP_Peaks(i+1);
        V.EP_Peaks(i)=V.EP_Peaks(i+1);
    end
end

%remove empty indices
V.PeaksLabel(end)=[];
V.SP_Peaks(end)=[];
V.PP_Peaks(end)=[];
V.EP_Peaks(end)=[];
 
V.N_Peaks=V.N_Peaks-1;%decrease counter by 1

%TODO: remove deleted peak values from PeakLabel, Sp, Ep, PP, etc
%replot
cla(handles.pltOxPeak);
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
%zoom(handles.pltOxPeak,'reset');
hold on;
t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
    LimitesY=handles.pltOxPeak.YLim;
    t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
    t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
end
hzoom.ActionPostCallback = @mypostcallback;
hplt=handles.pltOxPeak;

if (DisplaySignal==1)
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
else
   for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end 
end

%update table
UpdateTable(handles);

%set colors
for i=1:V.N_Peaks
    if i==SelectedRow
        hPointsSP(i).Color='c';
        hPointsPP(i).Color='c';
        hPointsEP(i).Color='c';
    else
        hPointsSP(i).Color='r';
        hPointsPP(i).Color='m';
        hPointsEP(i).Color='k';
    end
end

%enable buttons
if V.N_Peaks>0
    handles.cmdCopyTable.Enable='on';
    handles.chkCommaDecimalDelimiter.Enable='on';
    handles.chkAverageSignals.Enable='on';
    handles.txtAverageInterval.Enable='on';
    handles.lblAverageInterval.ForegroundColor=[0 0 0];
    handles.cmdDeletePeakValues.Enable='on';
    handles.cmdMovePeakUp.Enable='on';
    handles.cmdMovePeakDown.Enable='on';
    handles.cmdEditPeakLabel.Enable='on';
else
    handles.cmdCopyTable.Enable='off';
    handles.chkCommaDecimalDelimiter.Enable='off';
    handles.chkAverageSignals.Value=0;
    handles.chkAverageSignals.Enable='off';
    handles.txtAverageInterval.Enable='off';
    handles.lblAverageInterval.ForegroundColor=[0.5 0.5 0.5];
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes on button press in cmdEditPeakLabel.
function cmdEditPeakLabel_Callback(hObject, eventdata, handles)
% hObject    handle to cmdEditPeakLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V SelectedRow ModifiedData

R=inputdlg('Introduce new peak label:','Peak Label',1,{char(V.PeaksLabel(SelectedRow))});
if ~isempty(R)
    ModifiedData=1;
    V.PeaksLabel(SelectedRow)=R(1,1);
    %SelectedRow=0; %leave selected row as selected
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% Function that displays the time from the current point to the closest
% previous injection and, when when peaks data are introduced, the text 
% "Start Point", "Peak Point" and "End Point"
function PlotMouseMove (object, eventdata)
global hplt tx1 PlotMouseMoveMode V hlblTimeSinceInjection SignalFreq
C = get (hplt, 'CurrentPoint');
if (C(1,1)>hplt.XLim(1)) && (C(1,1)<hplt.XLim(2)) && (C(1,2)>hplt.YLim(1)) && (C(1,2)<hplt.YLim(2))
    if PlotMouseMoveMode==1
        tx1.Position(1)=C(1,1);
        tx1.Position(2)=C(1,2);
    end
    if V.N_Injections>0
        TimeSinceInjectionValue=1000000000000;
        for i=1:V.N_Injections
            NewTimeSinceInjectionValue=C(1,1)-V.Injections(i);
            if (NewTimeSinceInjectionValue>0) && (NewTimeSinceInjectionValue<TimeSinceInjectionValue)
                TimeSinceInjectionValue=NewTimeSinceInjectionValue;
            end
        end
        if TimeSinceInjectionValue==1000000000000
            hlblTimeSinceInjection.String=strcat('Time since injection: --');
        else
            hlblTimeSinceInjection.String=strcat('Time since injection: ',num2str(TimeSinceInjectionValue/SignalFreq),' seg');%TODO:check..
        end
    end
end


% --- Executes on button press in cmdSaveData.
function cmdSaveData_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSaveData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V ModifiedData FileName C

global Saved_Data_Array

[FileName,PathName]=uiputfile('*.dat','Introduce the name of the measurement data file',strcat(C.PathDataFiles,FileName));
if FileName~=0
    C.PathDataFiles=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    N_Cycles=V.N_Cycles;
    Saved_Data=Saved_Data_Array;
    Execution_Time=V.Execution_Time;
    Injections=V.Injections;
    N_Injections=V.N_Injections;
    InjectionLabel=V.InjectionLabel;
    Gain=V.Gain;
    PointsPerCycle=V.PointsPerCycle;
    Signal_Cycle=V.Signal_Cycle;
    OxPeakVM=V.OxPeakVM;
    N_Peaks=V.N_Peaks;
    SP_Peaks=V.SP_Peaks;
    PP_Peaks=V.PP_Peaks;
    EP_Peaks=V.EP_Peaks;
    IgnoreSelected=V.IgnoreSelected;
    PeaksLabel=cell(1);
    for i=1:N_Peaks
        PeaksLabel{i}=V.PeaksLabel{i};
    end
    ModifiedData=0;
    save(strcat(PathName,FileName),'N_Cycles','Saved_Data','Execution_Time','Injections','N_Injections','InjectionLabel','Gain','PointsPerCycle','Signal_Cycle','OxPeakVM','N_Peaks','SP_Peaks','PP_Peaks','EP_Peaks','PeaksLabel','Saved_Data_Array','IgnoreSelected');
end


% --- Executes on slider movement.
function sldFilterFrec_Callback(hObject, eventdata, handles)
% hObject    handle to sldFilterFrec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global DisplaySignal V hPointsSP hPointsPP hPointsEP FilterFrec Hd OxPeakFiltered 
global OxPeakV t OxPeak hzoom hplt SelectedRow

global Saved_Data_Array

FilterFrec=get(hObject,'Value');
Fpass = FilterFrec;            % Passband Frequency

Fstop = FilterFrec+0.05;% Stopband Frequency
Dpass = 0.057501127785;  % Passband Ripple
Dstop = 0.0001;          % Stopband Attenuation
flag  = 'scale';         % Sampling Flag
% Calculate the order from the parameters using KAISERORD.
[N,Wn,BETA,TYPE] = kaiserord([Fpass Fstop], [1 0], [Dstop Dpass]);
% Calculate the coefficients using the FIR1 function.
b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
Hd = dfilt.dffir(b);
%disp(N);
OxPeak=0;
for i=1:V.N_Cycles
    OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV);
end
OxPeakFiltered=filter(Hd,OxPeak);
OxPeakFiltered=OxPeakFiltered(round(N/2):length(OxPeakFiltered));
OxPeakFiltered(1:round(N/2))=OxPeakFiltered(round(N/2)+1:2*round(N/2));

cla(handles.pltOxPeak);
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end
if (DisplaySignal==2) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
end
hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
%zoom(handles.pltOxPeak,'reset');
hold on;
t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
    LimitesY=handles.pltOxPeak.YLim;
    t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
    t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
end

if (DisplaySignal==1)
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
else
   for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end 
end
hzoom.ActionPostCallback = @mypostcallback;
hplt=handles.pltOxPeak;
SelectedRow=0;
UpdateTable(handles);
handles.cmdDeletePeakValues.Enable='off';
handles.cmdMovePeakUp.Enable='off';
handles.cmdMovePeakDown.Enable='off';
handles.cmdEditPeakLabel.Enable='off';


% --- Executes during object creation, after setting all properties.
function sldFilterFrec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldFilterFrec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in optOriginal.
function optOriginal_Callback(hObject, eventdata, handles)
% hObject    handle to optOriginal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of optOriginal

global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeak
global hzoom hplt t SelectedRow

if hObject.Value==1
    DisplaySignal=1;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes on button press in optOriginal.
function optOriginal_2_Callback(hObject, eventdata, handles)
% hObject    handle to optOriginal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of optOriginal

global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeak_2
global hzoom_2 hplt_2 t_2 SelectedRow

if hObject.Value==1
    DisplaySignal=1;
    cla(handles.pltOxPeak_2);
    plot(handles.pltOxPeak_2,V.Gain*OxPeak_2,'color',[0.8,0.4,0]);
    hzoom_2=zoom(handles.pltOxPeak_2);
    hzoom_2.ActionPostCallback = '';
    %zoom(handles.pltOxPeak_2,'reset');
    hold on;
    t_2=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak_2.YLim,'Color','r')
        LimitesY_2=handles.pltOxPeak_2.YLim;
        t_2(i)=text(V.Injections(i),LimitesY_2(2),V.InjectionLabel{i});
        t_2(i).Position(2)=LimitesY_2(2)-t_2(i).Extent(4)/2;
    end
    hzoom_2.ActionPostCallback = @mypostcallback_2;
    hplt_2=handles.pltOxPeak_2;
   
end


% --- Executes on button press in optFiltered.
function optFiltered_Callback(hObject, eventdata, handles)
% hObject    handle to optFiltered (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optFiltered
global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeakFiltered OxPeakV
global hzoom hplt t SelectedRow
if hObject.Value==1
    DisplaySignal=2;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end



% --- Executes on button press in optMA.
function optMA_Callback(hObject, eventdata, handles)
% hObject    handle to optMA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optMA
global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeakFilteredMA OxPeakV OxPeak
global hzoom hplt t SelectedRow FilterFrecMA coeffMA

FilterFrecMA = str2double(handles.txtMAinterval.String);
coeffMA = ones(1,FilterFrecMA)/FilterFrecMA;
OxPeakFilteredMA = filter(coeffMA,1,OxPeak); 

if hObject.Value==1
    DisplaySignal=4;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeakFilteredMA,'color','black');
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFilteredMA(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFilteredMA(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFilteredMA(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes on button press in optBoth.
function optBoth_Callback(hObject, eventdata, handles)
% hObject    handle to optBoth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optBoth
global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeakFiltered OxPeak
global hzoom hplt t SelectedRow
if hObject.Value==1
    DisplaySignal=3;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    plot(handles.pltOxPeak,V.Gain*OxPeakFiltered,'color','b');
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFiltered(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFiltered(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFiltered(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes on button press in cmdMovePeakDown.
function cmdMovePeakDown_Callback(hObject, eventdata, handles)
% hObject    handle to cmdMovePeakDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V SelectedRow OxPeak OxPeakFiltered DisplaySignal 
global hPointsSP hPointsPP hPointsEP ModifiedData

if SelectedRow~=V.N_Peaks
    ModifiedData=1;
    Lab=V.PeaksLabel{1,SelectedRow+1};
    SP=V.SP_Peaks(SelectedRow+1);
    PP=V.PP_Peaks(SelectedRow+1);
    EP=V.EP_Peaks(SelectedRow+1);
    
    V.PeaksLabel{1,SelectedRow+1}=V.PeaksLabel{1,SelectedRow};
    V.SP_Peaks(SelectedRow+1)=V.SP_Peaks(SelectedRow);
    V.PP_Peaks(SelectedRow+1)=V.PP_Peaks(SelectedRow);
    V.EP_Peaks(SelectedRow+1)=V.EP_Peaks(SelectedRow);
    
    V.PeaksLabel{1,SelectedRow}=Lab;
    V.SP_Peaks(SelectedRow)=SP;
    V.PP_Peaks(SelectedRow)=PP;
    V.EP_Peaks(SelectedRow)=EP;
    
    hSP = gobjects(1);
    hPP = gobjects(1);
    hEP = gobjects(1);
    
    hSP=hPointsSP(SelectedRow+1);
    hPP=hPointsPP(SelectedRow+1);
    hEP=hPointsEP(SelectedRow+1);
    
    hPointsSP(SelectedRow+1)=hPointsSP(SelectedRow);
    hPointsPP(SelectedRow+1)=hPointsPP(SelectedRow);
    hPointsEP(SelectedRow+1)=hPointsEP(SelectedRow);
    
    hPointsSP(SelectedRow)=hSP;
    hPointsPP(SelectedRow)=hPP;
    hPointsEP(SelectedRow)=hEP;
    

    SelectedRow=SelectedRow+1;
    UpdateTable(handles);
    for i=1:V.N_Peaks
        if i==SelectedRow
            hPointsSP(i).Color='c';
            hPointsPP(i).Color='c';
            hPointsEP(i).Color='c';
        else
            hPointsSP(i).Color='r';
            hPointsPP(i).Color='m';
            hPointsEP(i).Color='k';
        end
    end
end


% --- Executes on button press in cmdMovePeakUp.
function cmdMovePeakUp_Callback(hObject, eventdata, handles)
% hObject    handle to cmdMovePeakUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V SelectedRow OxPeak OxPeakFiltered DisplaySignal 
global hPointsSP hPointsPP hPointsEP ModifiedData

if SelectedRow~=1
    ModifiedData=1;
    Lab=V.PeaksLabel{1,SelectedRow-1};
    SP=V.SP_Peaks(SelectedRow-1);
    PP=V.PP_Peaks(SelectedRow-1);
    EP=V.EP_Peaks(SelectedRow-1);
    
    V.PeaksLabel{1,SelectedRow-1}=V.PeaksLabel{1,SelectedRow};
    V.SP_Peaks(SelectedRow-1)=V.SP_Peaks(SelectedRow);
    V.PP_Peaks(SelectedRow-1)=V.PP_Peaks(SelectedRow);
    V.EP_Peaks(SelectedRow-1)=V.EP_Peaks(SelectedRow);
    
    V.PeaksLabel{1,SelectedRow}=Lab;
    V.SP_Peaks(SelectedRow)=SP;
    V.PP_Peaks(SelectedRow)=PP;
    V.EP_Peaks(SelectedRow)=EP;
    
    hSP = gobjects(1);
    hPP = gobjects(1);
    hEP = gobjects(1);
    
    hSP=hPointsSP(SelectedRow-1);
    hPP=hPointsPP(SelectedRow-1);
    hEP=hPointsEP(SelectedRow-1);
    
    hPointsSP(SelectedRow-1)=hPointsSP(SelectedRow);
    hPointsPP(SelectedRow-1)=hPointsPP(SelectedRow);
    hPointsEP(SelectedRow-1)=hPointsEP(SelectedRow);
    
    hPointsSP(SelectedRow)=hSP;
    hPointsPP(SelectedRow)=hPP;
    hPointsEP(SelectedRow)=hEP;
    
    SelectedRow=SelectedRow-1;
    UpdateTable(handles);
    for i=1:V.N_Peaks
        if i==SelectedRow
            hPointsSP(i).Color='c';
            hPointsPP(i).Color='c';
            hPointsEP(i).Color='c';
        else
            hPointsSP(i).Color='r';
            hPointsPP(i).Color='m';
            hPointsEP(i).Color='k';
        end
    end
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes when user attempts to close frmMain.
function frmMain_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to frmMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ModifiedData


if ModifiedData==1
    Answer = questdlg('Do you want to exit without saving data?', 'Warning','Yes', 'No','No');
    if strcmp(Answer,'Yes')==1
        % Hint: delete(hObject) closes the figure
        delete(hObject);
    end
    
else
    delete(hObject);
end


% --- Executes on button press in cmdSignalAnalyzer.
function cmdSignalAnalyzer_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSignalAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% We turn the interface off for processing.
global V OxPeak OxPeakFiltered DisplaySignal C FileName

setappdata(0,'hfrmMain',gcf);
hfrmMain=getappdata(0,'hfrmMain');
setappdata(hfrmMain,'V',V);
setappdata(hfrmMain,'OxPeak',OxPeak);
setappdata(hfrmMain,'OxPeakFiltered',OxPeakFiltered);
setappdata(hfrmMain,'DisplaySignal',DisplaySignal);
setappdata(hfrmMain,'FileName',FileName);
hfrmMain.Visible='off';
SignalAnalyzer;


function y=FormatCellCyan(CellValue)
y=strcat('<html><table border=0 width=400 bgcolor="#00DEFF"><TR><TD>',cellstr(num2str(CellValue)),'</TD></TR> </table></html>');


function y=FormatCellWhite(CellValue)
y=strcat('<html><table border=0 width=400 bgcolor="#FFFFFF"><TR><TD>',cellstr(num2str(CellValue)),'</TD></TR> </table></html>');


% --- Executes on button press in cmdSavepltOxpeak.
function cmdSavepltOxpeak_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSavepltOxpeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global C
[FileName,PathName]=uiputfile('*.fig','Introduce the name of the figure file',C.PathFigures);
if FileName~=0
    C.PathFigures=PathName;
    PathDataFiles=C.PathDataFiles;
    PathFigures=C.PathFigures;
    PathSignals=C.PathSignals;
    save('Config.cfg','PathDataFiles','PathFigures','PathSignals');
    InterfaceObj=findobj(gcf,'Enable','on'); % Disable all the objects of the window
    set(InterfaceObj,'Enable','off');
    Fig1 = figure('Visible','off');
    copyobj(handles.pltOxPeak,Fig1);
    set(gca,'ActivePositionProperty','Position');
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);
    set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
    set(Fig1, 'Position', get(0,'Screensize'));
    set(Fig1, 'Visible','on');
    hgsave(Fig1, strcat(PathName,FileName));
    delete(Fig1);
    set(InterfaceObj,'Enable','on');
end

% --- Executes on button press in cmdCopypltOxPeak.
function cmdCopypltOxPeak_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCopypltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
InterfaceObj=findobj(gcf,'Enable','on');
set(InterfaceObj,'Enable','off');
Fig1 = figure('Visible','off');
copyobj(handles.pltOxPeak,Fig1);
set(gca,'ActivePositionProperty','Position');
set(gca,'Units','normalized');
set(gca,'Position',[0 0 1 1]);
set(gca,'position',[0.1300 0.1100 0.7750 0.8150]);
set(Fig1, 'Position', get(0,'Screensize'));
hgexport(Fig1,'-clipboard');
delete(Fig1);
set(InterfaceObj,'Enable','on');


% --- Executes on button press in cmdCopyTable.
function cmdCopyTable_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCopyTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V DisplaySignal OxPeak OxPeakFiltered FileName OxPeakV

global Saved_Data_Array

str = ''; 
str = sprintf('%s%s\n', str, FileName(1:length(FileName)-4) );
for i=1:V.N_Peaks
    str = sprintf('%s%s\t', str, V.PeaksLabel{1,i} );
    if (handles.chkAverageSignals.Value==1)
        AverageInterval=str2double(handles.txtAverageInterval.String);
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.SP_Peaks(i)+j)*V.PointsPerCycle+OxPeakV);
        end
        AverageData=AverageData/(2*AverageInterval+1);
        str=sprintf('%s%f\t',str,AverageData);
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.PP_Peaks(i)+j)*V.PointsPerCycle+OxPeakV);
        end
        AverageData=AverageData/(2*AverageInterval+1);
        str=sprintf('%s%f\t',str,AverageData);
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.EP_Peaks(i)+j)*V.PointsPerCycle+OxPeakV);
        end
        AverageData=AverageData/(2*AverageInterval+1);
        str=sprintf('%s%f\t',str,AverageData);
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.PP_Peaks(i)+j)*V.PointsPerCycle+OxPeakV)-V.Gain*Saved_Data_Array((V.SP_Peaks(i)+j)*V.PointsPerCycle+OxPeakV);
        end
        AverageData=AverageData/(2*AverageInterval+1);
        str=sprintf('%s%f',str,AverageData);
    else
        if (DisplaySignal==1)
            str=sprintf('%s%f\t',str,V.Gain*OxPeak(V.SP_Peaks(i)));
            str=sprintf('%s%f\t',str,V.Gain*OxPeak(V.PP_Peaks(i)));
            str=sprintf('%s%f\t',str,V.Gain*OxPeak(V.EP_Peaks(i)));
            str=sprintf('%s%f',str,V.Gain*OxPeak(V.PP_Peaks(i))-V.Gain*OxPeak(V.SP_Peaks(i)));
        else
            str=sprintf('%s%f\t',str,V.Gain*OxPeakFiltered(V.SP_Peaks(i)));
            str=sprintf('%s%f\t',str,V.Gain*OxPeakFiltered(V.PP_Peaks(i)));
            str=sprintf('%s%f\t',str,V.Gain*OxPeakFiltered(V.EP_Peaks(i)));
            str=sprintf('%s%f',str,V.Gain*OxPeakFiltered(V.PP_Peaks(i))-V.Gain*OxPeakFiltered(V.SP_Peaks(i)));
        end
    end
    str = sprintf('%s\n',str);
end
if handles.chkCommaDecimalDelimiter.Value==1
    str(str=='.')=',';
end
clipboard('copy', str );


% --- Executes on button press in chkCommaDecimalDelimiter.
function chkCommaDecimalDelimiter_Callback(hObject, eventdata, handles)
% hObject    handle to chkCommaDecimalDelimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkCommaDecimalDelimiter


% --- Executes on button press in chkAverageSignals.
function chkAverageSignals_Callback(hObject, eventdata, handles)
% hObject    handle to chkAverageSignals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkAverageSignals
global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeak
global hzoom hplt t SelectedRow

if handles.chkAverageSignals.Value==1
    % Disable any filter mode (average cannot be done in filtered signals
    handles.optOriginal.Value=1;
    handles.optFiltered.Enable='off';
    handles.optBoth.Enable='off';
    DisplaySignal=1;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    DisplaySignal=1;
else
    handles.optFiltered.Enable='on';
    handles.optBoth.Enable='on';
    if SelectedRow==0
        handles.cmdDeletePeakValues.Enable='off';
        handles.cmdMovePeakUp.Enable='off';
        handles.cmdMovePeakDown.Enable='off';
        handles.cmdEditPeakLabel.Enable='off';
    end
end
UpdateTable(handles);
     

function txtAverageInterval_Callback(hObject, eventdata, handles)
% hObject    handle to txtAverageInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAverageInterval as text
%        str2double(get(hObject,'String')) returns contents of txtAverageInterval as a double
UpdateTable(handles);


% --- Executes during object creation, after setting all properties.
function txtAverageInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtAverageInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function UpdateTable(handles)
global V SelectedRow OxPeak OxPeakFiltered DisplaySignal 
global OxPeakV

global Saved_Data_Array


AverageInterval=str2double(handles.txtAverageInterval.String);
TableData=cell(V.N_Peaks,5);
if DisplaySignal==1
    PresentData=OxPeak;
else
    PresentData=OxPeakFiltered;
end
for i=1:V.N_Peaks
    if i==SelectedRow
        TableData(i,1)=FormatCellCyan(V.PeaksLabel{1,i});
    else
        TableData(i,1)=FormatCellWhite(V.PeaksLabel{1,i});
    end
    if handles.chkAverageSignals.Value==1
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.SP_Peaks(i)+j-1)*V.PointsPerCycle+OxPeakV);
        end
        FinalData=AverageData/(2*AverageInterval+1);
    else
        FinalData=V.Gain*PresentData(V.SP_Peaks(i));
    end
    if i==SelectedRow
        TableData(i,2)=FormatCellCyan(FinalData);
    else
        TableData(i,2)=FormatCellWhite(FinalData);
    end
    if handles.chkAverageSignals.Value==1
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.PP_Peaks(i)+j-1)*V.PointsPerCycle+OxPeakV);
        end
        FinalData=AverageData/(2*AverageInterval+1);
    else
        FinalData=V.Gain*PresentData(V.PP_Peaks(i));
    end
    if i==SelectedRow
        TableData(i,3)=FormatCellCyan(FinalData);
    else
        TableData(i,3)=FormatCellWhite(FinalData);
    end
    if handles.chkAverageSignals.Value==1
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.EP_Peaks(i)+j-1)*V.PointsPerCycle+OxPeakV);
        end
        FinalData=AverageData/(2*AverageInterval+1);
    else
        FinalData=V.Gain*PresentData(V.EP_Peaks(i));
    end
    if i==SelectedRow
        TableData(i,4)=FormatCellCyan(FinalData);
    else
        TableData(i,4)=FormatCellWhite(FinalData);
    end
    if handles.chkAverageSignals.Value==1
        AverageData=0;
        for j=-AverageInterval:AverageInterval
            AverageData=AverageData+V.Gain*Saved_Data_Array((V.PP_Peaks(i)+j-1)*V.PointsPerCycle+OxPeakV)-V.Gain*Saved_Data_Array((V.SP_Peaks(i)+j-1)*V.PointsPerCycle+OxPeakV);
        end
        FinalData=AverageData/(2*AverageInterval+1);
    else
        FinalData=V.Gain*PresentData(V.PP_Peaks(i))-V.Gain*PresentData(V.SP_Peaks(i));
    end
    if i==SelectedRow
        TableData(i,5)=FormatCellCyan(FinalData);
    else
        TableData(i,5)=FormatCellWhite(FinalData);
    end
end
set(handles.tblPeaks,'Data',TableData);


% --- Executes on button press in cmdExportExcelpltOxPeak.
function cmdExportExcelpltOxPeak_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExportExcelpltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DisplaySignal V OxPeakFiltered 
global OxPeak  C FileName

FileNameWithoutExtension=strsplit(FileName,'.');
Answer = questdlg('What type of file do you want to generate?','Format File','Excel','CSV (.)','CSV (,)','Excel');
if Answer~=0
    if strcmp(Answer,'Excel')==1
        ExportFileName=strcat(FileNameWithoutExtension{1},'.xlsx');
        [ExportFileName,PathName]=uiputfile('*.xlsx','Introduce the name of the Excel file',strcat(C.PathDataFiles,ExportFileName));
    else
        ExportFileName=strcat(FileNameWithoutExtension{1},'.csv');
        [ExportFileName,PathName]=uiputfile('*.csv','Introduce the name of the CSV file',strcat(C.PathDataFiles,ExportFileName));
    end
    
    if ExportFileName~=0
        if (DisplaySignal==1) || (DisplaySignal==3)
            for i=1:V.N_Cycles
                ExcelData{i,2}=V.Gain*OxPeak(i);
            end
        else
            for i=1:V.N_Cycles
                ExcelData{i,2}=V.Gain*OxPeakFiltered(i);
            end
        end
        for i=1:V.N_Injections
            ExcelData{V.Injections(i),1}=V.InjectionLabel{i};
        end
        if strcmp(Answer,'Excel')==1
            xlswrite(strcat(PathName,ExportFileName),ExcelData)
        else
            fileID = fopen(strcat(PathName,ExportFileName),'w');
            formatSpec = '%s\n';
            for row = 1:V.N_Cycles
                ValueStr=num2str(ExcelData{row,2});
                if strcmp(Answer,'CSV (,)')==1
                    ValueStr(ValueStr=='.')=',';
                    rowText=[ExcelData{row,1} ';' ValueStr];
                else
                    rowText=[ExcelData{row,1} ',' ValueStr];
                end
                fprintf(fileID,formatSpec,rowText);
            end
            fclose(fileID);
        end
    end
end


% --- Executes on button press in btn_extract_segment.
function btn_extract_segment_Callback(hObject, eventdata, handles)
% hObject    handle to btn_extract_segment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Extract_ms_Before Extract_ms_After Extract_StimNumber V OxPeak
global SignalPeriod_ms


Extract_ms_Before = str2double(handles.txt_extract_msbefore.String);
Extract_ms_After = str2double(handles.txt_extract_msafter.String);

Extract_Points_Before = Extract_ms_Before / SignalPeriod_ms;
Extract_Points_After = Extract_ms_After / SignalPeriod_ms; 

%disp(Extract_Points_Before);
%disp(Extract_Points_After);

Extract_StimNumber = str2double(handles.txt_extract_stimNumber.String);

% TODO: error checking on extract strings

%disp(V.InjectionLabel{Extract_StimNumber});
extract_injection_label = V.InjectionLabel{Extract_StimNumber};

%disp(V.Injections(Extract_StimNumber));

mark = V.Injections(Extract_StimNumber);
extract_start = mark - Extract_Points_Before;
extract_end = mark + Extract_Points_After;

if (extract_start < 0)
    extract_start = 0;
end

if (extract_end > (V.N_Cycles * V.PointsPerCycle)) % TODO: check...
    extract_end = V.N_Cycles * V.PointsPerCycle;
end

%disp(extract_start);
%disp(extract_end);

extract_data = V.Gain*OxPeak(extract_start:extract_end);

[FileName,PathName]=uiputfile('*.mat','Introduce the name of the extract segment data file');
save(strcat(PathName,FileName),'extract_data', 'extract_injection_label', 'SignalPeriod_ms', 'mark', 'extract_start', 'extract_end');

figure
plot((extract_start:extract_end),V.Gain*OxPeak(extract_start:extract_end),'color',[0.8,0.4,0]);


function txt_extract_msbefore_Callback(hObject, eventdata, handles)
% hObject    handle to txt_extract_msbefore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_extract_msbefore as text
%        str2double(get(hObject,'String')) returns contents of txt_extract_msbefore as a double
global Extract_ms_Before

Extract_ms_Before = str2double(get(hObject,'String'));



% --- Executes during object creation, after setting all properties.
function txt_extract_msbefore_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_extract_msbefore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_extract_msafter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_extract_msafter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_extract_msafter as text
%        str2double(get(hObject,'String')) returns contents of txt_extract_msafter as a double
global Extract_ms_After

Extract_ms_After = str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function txt_extract_msafter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_extract_msafter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_extract_stimNumber_Callback(hObject, eventdata, handles)
% hObject    handle to txt_extract_stimNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_extract_stimNumber as text
%        str2double(get(hObject,'String')) returns contents of txt_extract_stimNumber as a double
global Extract_StimNumber

Extract_StimNumber = str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function txt_extract_stimNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_extract_stimNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.
function pltOxPeak_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on mouse press over axes background.
function pltOxPeak_2_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function pltOxPeak_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function pltOxPeak_2_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to pltOxPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over cmdSignalAnalyzer.
function cmdSignalAnalyzer_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to cmdSignalAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function tblPeaks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tblPeaks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axesLabLogo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesLabLogo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesLabLogo



% --- Executes on button press in cmdStimDataProcess.
function cmdStimDataProcess_Callback(hObject, eventdata, handles)
% hObject    handle to cmdStimDataProcess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global V OxPeak OxPeakFiltered DisplaySignal C FileName

setappdata(0,'hfrmMain',gcf);
hfrmMain=getappdata(0,'hfrmMain');
setappdata(hfrmMain,'V',V);
setappdata(hfrmMain,'OxPeak',OxPeak);
setappdata(hfrmMain,'OxPeakFiltered',OxPeakFiltered);
setappdata(hfrmMain,'DisplaySignal',DisplaySignal);
setappdata(hfrmMain,'FileName',FileName);
hfrmMain.Visible='off';
StimulationDataProcess;



function txtMAinterval_Callback(hObject, eventdata, handles)
% hObject    handle to txtMAinterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMAinterval as text
%        str2double(get(hObject,'String')) returns contents of txtMAinterval as a double



% --- Executes during object creation, after setting all properties.
function txtMAinterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMAinterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sldFilterFrecIIR_Callback(hObject, eventdata, handles)
% hObject    handle to sldFilterFrecIIR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global DisplaySignal V hPointsSP hPointsPP hPointsEP FilterFrecIIR Hd OxPeakFilteredIIR 
global OxPeakV t OxPeak hzoom hplt SelectedRow SignalFreq

global Saved_Data_Array df1

FilterFrecIIR=get(hObject,'Value');
handles.lblFilterFrecIIR.String=FilterFrecIIR;

%design the filter based on frequency response desired
df1 = designfilt('highpassiir', 'FilterOrder', 2, 'HalfPowerFrequency', ...
                 FilterFrecIIR, 'SampleRate', SignalFreq,'DesignMethod', 'butter');

OxPeak=0;
N=2; %TODO: what is this for
for i=1:V.N_Cycles
    OxPeak(i)=Saved_Data_Array((i-1)*V.PointsPerCycle+OxPeakV);
end
OxPeakFilteredIIR=filtfilt(df1,OxPeak);%zero-phase digital filter 
OxPeakFilteredIIR=OxPeakFilteredIIR(round(N/2):length(OxPeakFilteredIIR));
OxPeakFilteredIIR(1:round(N/2))=OxPeakFilteredIIR(round(N/2)+1:2*round(N/2));

cla(handles.pltOxPeak);

DisplaySignal=5;%TODO:Update 6 to show multiple
if (DisplaySignal==1) || (DisplaySignal==3)
    plot(handles.pltOxPeak,V.Gain*OxPeak,'color',[0.8,0.4,0]);
end

if (DisplaySignal==5) || (DisplaySignal==6) %TODO:Update 6 to show multiple
    plot(handles.pltOxPeak,V.Gain*OxPeakFilteredIIR,'color','g');
end

hzoom=zoom(handles.pltOxPeak);
hzoom.ActionPostCallback = '';
%zoom(handles.pltOxPeak,'reset');
hold on;
t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
for i=1:V.N_Injections
    line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
    LimitesY=handles.pltOxPeak.YLim;
    t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
    t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
end

if (DisplaySignal==1)
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeak(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeak(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeak(V.EP_Peaks(i)),'k+');
    end
else
   for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.EP_Peaks(i)),'k+');
    end 
end
hzoom.ActionPostCallback = @mypostcallback;
hplt=handles.pltOxPeak;
SelectedRow=0;
UpdateTable(handles);
handles.cmdDeletePeakValues.Enable='off';
handles.cmdMovePeakUp.Enable='off';
handles.cmdMovePeakDown.Enable='off';
handles.cmdEditPeakLabel.Enable='off';


% --- Executes during object creation, after setting all properties.
function sldFilterFrecIIR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldFilterFrecIIR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




% --- Executes on button press in optIIRFilter.
function optIIRFilter_Callback(hObject, eventdata, handles)
% hObject    handle to optIIRFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optIIRFilter
global DisplaySignal V hPointsSP hPointsPP hPointsEP OxPeakFilteredIIR OxPeakV
global hzoom hplt t SelectedRow
if hObject.Value==1
    DisplaySignal=5;
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeakFilteredIIR,'color','g');
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakFilteredIIR(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes on button press in optCustomFilter.
function optCustomFilter_Callback(hObject, eventdata, handles)
% hObject    handle to optCustomFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optCustomFilter
global customFilterFlag

filterbuilder

if customFilterFlag == 0
    customFilterFlag = 1;
else
    customFilterFlag = 0;
end 



function txtCustomFilterName_Callback(hObject, eventdata, handles)
% hObject    handle to txtCustomFilterName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtCustomFilterName as text
%        str2double(get(hObject,'String')) returns contents of txtCustomFilterName as a double
global myCustomFilter Gain OxPeakCustom V hPointsSP hPointsEP hPointsPP SelectedRow hplt hzoom OxPeak customFilterFlag

myCustomFilterName=get(hObject,'String');
myCustomFilter=evalin('base',myCustomFilterName);

OxPeakCustom = filter(myCustomFilter,OxPeak);

if customFilterFlag == 1
    %DisplaySignal=5; TODO: update all display signals
    cla(handles.pltOxPeak);
    plot(handles.pltOxPeak,V.Gain*OxPeakCustom,'color','magenta');
    hzoom=zoom(handles.pltOxPeak);
    hzoom.ActionPostCallback = '';
    %zoom(handles.pltOxPeak,'reset');
    hold on;
    t=text(zeros(1,V.N_Injections),zeros(1,V.N_Injections),'');
    for i=1:V.N_Injections
        line([V.Injections(i) V.Injections(i)],handles.pltOxPeak.YLim,'Color','r')
        LimitesY=handles.pltOxPeak.YLim;
        t(i)=text(V.Injections(i),LimitesY(2),V.InjectionLabel{i});
        t(i).Position(2)=LimitesY(2)-t(i).Extent(4)/2;
    end
    for i=1:V.N_Peaks
        hPointsSP(i)=plot(handles.pltOxPeak,V.SP_Peaks(i),V.Gain*OxPeakCustom(V.SP_Peaks(i)),'rx');
        hPointsPP(i)=plot(handles.pltOxPeak,V.PP_Peaks(i),V.Gain*OxPeakCustom(V.PP_Peaks(i)),'m*');
        hPointsEP(i)=plot(handles.pltOxPeak,V.EP_Peaks(i),V.Gain*OxPeakCustom(V.EP_Peaks(i)),'k+');
    end
    hzoom.ActionPostCallback = @mypostcallback;
    hplt=handles.pltOxPeak;
    SelectedRow=0;
    UpdateTable(handles);
    handles.cmdDeletePeakValues.Enable='off';
    handles.cmdMovePeakUp.Enable='off';
    handles.cmdMovePeakDown.Enable='off';
    handles.cmdEditPeakLabel.Enable='off';
end


% --- Executes during object creation, after setting all properties.
function txtCustomFilterName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtCustomFilterName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
