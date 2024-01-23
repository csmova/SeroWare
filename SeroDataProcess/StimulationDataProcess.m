function varargout = StimulationDataProcess(varargin)
% STIMULATIONDATAPROCESS MATLAB code for StimulationDataProcess.fig
%      STIMULATIONDATAPROCESS, by itself, creates a new STIMULATIONDATAPROCESS or raises the existing
%      singleton*.
%
%      H = STIMULATIONDATAPROCESS returns the handle to a new STIMULATIONDATAPROCESS or the handle to
%      the existing singleton*.
%
%      STIMULATIONDATAPROCESS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STIMULATIONDATAPROCESS.M with the given input arguments.
%
%      STIMULATIONDATAPROCESS('Property','Value',...) creates a new STIMULATIONDATAPROCESS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before StimulationDataProcess_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to StimulationDataProcess_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StimulationDataProcess

% Last Modified by GUIDE v2.5 01-Sep-2022 15:39:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StimulationDataProcess_OpeningFcn, ...
                   'gui_OutputFcn',  @StimulationDataProcess_OutputFcn, ...
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


% --- Executes just before StimulationDataProcess is made visible.
function StimulationDataProcess_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StimulationDataProcess (see VARARGIN)

% Choose default command line output for StimulationDataProcess
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StimulationDataProcess wait for user response (see UIRESUME)
% uiwait(handles.frmStimDataProcess);

global baseline_criterion
global log_count
global analysis_log
global release_filterspan peak_filterspan reuptake_filterspan
global V hfrmMain ColorArray N_Signals OxPeak OxPeakFiltered DisplaySignal
global C FileName 
global Saved_Data_Array

%set the logo
axes(handles.axesLabLogo)
matlabImage = imread('StimDataProcessLogo.jpg');
image(matlabImage)
axis off
axis image

%load data from SeroDataProcess 
C=load('Config.cfg','-mat');
hfrmMain=getappdata(0,'hfrmMain');
V=getappdata(hfrmMain,'V');
OxPeak=getappdata(hfrmMain,'OxPeak');
OxPeakFiltered=getappdata(hfrmMain,'OxPeakFiltered');
DisplaySignal=getappdata(hfrmMain,'DisplaySignal');
FileName=getappdata(hfrmMain,'FileName');


baseline_criterion = 1; %set initial value
analysis_log = struct; % initialize data storage structure array

handles.sld_BasalStart.Enable = 'off';
handles.sld_BasalEnd.Enable = 'off';
handles.sld_InitiationEnd.Enable = 'off';
handles.sld_ReleaseEnd.Enable = 'off';
handles.sld_ReuptakeStart.Enable = 'off';
handles.sld_ReuptakeEnd.Enable = 'off';
handles.txt_baselinedef.Enable = 'off';
handles.btn_AnalyzeData.Enable = 'off';

release_filterspan = str2num(handles.txt_increaseFilter.String);
peak_filterspan = str2num(handles.txt_peakFilter.String);
reuptake_filterspan = str2num(handles.txt_reuptakeFilter.String);

log_count = 0;


% --- Outputs from this function are returned to the command line.
function varargout = StimulationDataProcess_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function plot_basic()
global hplot
global V
global BasalStartPoint BasalEndPoint InitiationEndPoint ReleaseEndPoint
global ReuptakeStartPoint ReuptakeEndPoint
global origdata_plotobject stimpos_plotobject

cla(hplot);
origdata_plotobject = plot(hplot, V.extract_data);
hold on;
zoom on;
stimpos = (V.mark - V.extract_start + 1);
yl = ylim(hplot);
stimpos_plotobject = line(hplot, [stimpos stimpos], [yl(1) yl(2)], 'Color','red');
hold on;
    
signal_period_label = strcat('Time ( x',num2str(V.SignalPeriod_ms), ' ms )'); %TODO: temporary..we really should get this data from the saved file...

xlabel(hplot,signal_period_label,'FontSize',10); 
ylabel(hplot,'Current (nA)', 'FontSize',10);
title(hplot, V.extract_injection_label);

line(hplot, [BasalStartPoint BasalStartPoint], [yl(1) yl(2)], 'Color', [0.4940 0.1840 0.5560]);
text(BasalStartPoint, yl(2), 'BSP','FontSize',8);
hold on;

line(hplot, [BasalEndPoint BasalEndPoint], [yl(1) yl(2)], 'Color', [0.4940 0.1840 0.5560]);
text(BasalEndPoint, yl(2), 'BEP','FontSize',8);
hold on;

line(hplot, [InitiationEndPoint InitiationEndPoint], [yl(1) yl(2)], 'Color', [0.960 0.4250 0.0780]);
text(InitiationEndPoint, yl(2), 'IEP','FontSize',8);
hold on;

line(hplot, [ReleaseEndPoint ReleaseEndPoint], [yl(1) yl(2)], 'Color', [0.960 0.4250 0.0780]);
text(ReleaseEndPoint, yl(2), 'REP','FontSize',8);
hold on;

line(hplot, [ReuptakeStartPoint ReuptakeStartPoint], [yl(1) yl(2)], 'Color', [0.8290 0.7940 0.0250]);
text(ReuptakeStartPoint, yl(2), 'USP','FontSize',8);
hold on;

line(hplot, [ReuptakeEndPoint ReuptakeEndPoint], [yl(1) yl(2)], 'Color', [0.8290 0.7940 0.0250]);
text(ReuptakeEndPoint, yl(2), 'UEP','FontSize',8);
hold on;




% --- Executes on button press in btn_loadData.
function btn_loadData_Callback(hObject, eventdata, handles)
% hObject    handle to btn_loadData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hplot
global FileName PathName
global stimpos
global data_NumPts data_TotalTime
global V
global BasalStartPoint BasalEndPoint InitiationEndPoint ReleaseEndPoint 
global ReuptakeStartPoint ReuptakeEndPoint

hplot = handles.dataplot;

[FileName,PathName]=uigetfile('*.mat','Select the extracted data file');

if FileName~=0
    V=load(strcat(PathName, FileName)); % TODO: protect method against empty PathName and FileName...

    data_size_matrix = size(V.extract_data);
    data_NumPts = data_size_matrix(2);
    data_TotalTime = data_NumPts * V.SignalPeriod_ms;

    handles.sld_BasalStart.Min = 1;
    handles.sld_BasalStart.Max = data_NumPts;
    handles.sld_BasalStart.Value = 1;
    handles.sld_BasalStart.SliderStep(1) = 1 / data_NumPts;
    handles.sld_BasalStart.SliderStep(2) = 1 / data_NumPts;

    handles.sld_BasalEnd.Min = 1;
    handles.sld_BasalEnd.Max = data_NumPts;
    handles.sld_BasalEnd.Value = 2;
    handles.sld_BasalEnd.SliderStep(1) = 1 / data_NumPts;
    handles.sld_BasalEnd.SliderStep(2) = 1 / data_NumPts;

    handles.sld_InitiationEnd.Min = 1;
    handles.sld_InitiationEnd.Max = data_NumPts;
    handles.sld_InitiationEnd.Value = 3;
    handles.sld_InitiationEnd.SliderStep(1) = 1 / data_NumPts;
    handles.sld_InitiationEnd.SliderStep(2) = 1 / data_NumPts;

    handles.sld_ReleaseEnd.Min = 1;
    handles.sld_ReleaseEnd.Max = data_NumPts;
    handles.sld_ReleaseEnd.Value = 4;
    handles.sld_ReleaseEnd.SliderStep(1) = 1 / data_NumPts;
    handles.sld_ReleaseEnd.SliderStep(2) = 1 / data_NumPts;

    handles.sld_ReuptakeStart.Min = 1;
    handles.sld_ReuptakeStart.Max = data_NumPts;
    handles.sld_ReuptakeStart.Value = 5;
    handles.sld_ReuptakeStart.SliderStep(1) = 1 / data_NumPts;
    handles.sld_ReuptakeStart.SliderStep(2) = 1 / data_NumPts;

    handles.sld_ReuptakeEnd.Min = 1;
    handles.sld_ReuptakeEnd.Max = data_NumPts;
    handles.sld_ReuptakeEnd.Value = 6;
    handles.sld_ReuptakeEnd.SliderStep(1) = 1 / data_NumPts;
    handles.sld_ReuptakeEnd.SliderStep(2) = 1 / data_NumPts;

    handles.sld_BasalStart.Enable = 'on';
    handles.sld_BasalEnd.Enable = 'on';
    handles.sld_InitiationEnd.Enable = 'on';
    handles.sld_ReleaseEnd.Enable = 'on';
    handles.sld_ReuptakeStart.Enable = 'on';
    handles.sld_ReuptakeEnd.Enable = 'on';
    handles.txt_baselinedef.Enable = 'on';
    handles.btn_AnalyzeData.Enable = 'on';

    BasalStartPoint = handles.sld_BasalStart.Value;
    BasalEndPoint = handles.sld_BasalEnd.Value;
    InitiationEndPoint = handles.sld_InitiationEnd.Value;
    ReleaseEndPoint = handles.sld_ReleaseEnd.Value;
    ReuptakeStartPoint = handles.sld_ReuptakeStart.Value;
    ReuptakeEndPoint = handles.sld_ReuptakeEnd.Value;

    plot_basic();
end 


% --- Executes on slider movement.
function sld_BasalStart_Callback(hObject, eventdata, handles)
% hObject    handle to sld_BasalStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global BasalStartPoint hplot

BasalStartPoint = round(get(hObject,'Value'));
handles.txt_BasalStart.String = num2str(BasalStartPoint);
plot_basic();

% --- Executes during object creation, after setting all properties.
function sld_BasalStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_BasalStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sld_BasalEnd_Callback(hObject, eventdata, handles)
% hObject    handle to sld_BasalEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global BasalEndPoint

BasalEndPoint = round(get(hObject,'Value'));
handles.txt_BasalEnd.String = num2str(BasalEndPoint);
plot_basic();


% --- Executes during object creation, after setting all properties.
function sld_BasalEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_BasalEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sld_InitiationEnd_Callback(hObject, eventdata, handles)
% hObject    handle to sld_InitiationEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global InitiationEndPoint

InitiationEndPoint = round(get(hObject,'Value'));
handles.txt_InitiationEnd.String = num2str(InitiationEndPoint);
plot_basic();


% --- Executes during object creation, after setting all properties.
function sld_InitiationEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_InitiationEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sld_ReleaseEnd_Callback(hObject, eventdata, handles)
% hObject    handle to sld_ReleaseEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global ReleaseEndPoint

ReleaseEndPoint = round(get(hObject,'Value'));
handles.txt_ReleaseEnd.String = num2str(ReleaseEndPoint);
plot_basic();


% --- Executes during object creation, after setting all properties.
function sld_ReleaseEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_ReleaseEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sld_ReuptakeStart_Callback(hObject, eventdata, handles)
% hObject    handle to sld_ReuptakeStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global ReuptakeStartPoint

ReuptakeStartPoint = round(get(hObject,'Value'));
handles.txt_ReuptakeStart.String = num2str(ReuptakeStartPoint);
plot_basic();


% --- Executes during object creation, after setting all properties.
function sld_ReuptakeStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_ReuptakeStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sld_ReuptakeEnd_Callback(hObject, eventdata, handles)
% hObject    handle to sld_ReuptakeEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global ReuptakeEndPoint

ReuptakeEndPoint = round(get(hObject,'Value'));
handles.txt_ReuptakeEnd.String = num2str(ReuptakeEndPoint);
plot_basic();


% --- Executes during object creation, after setting all properties.
function sld_ReuptakeEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sld_ReuptakeEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in btn_AnalyzeData.
function btn_AnalyzeData_Callback(hObject, eventdata, handles)
% hObject    handle to btn_AnalyzeData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global BasalStartPoint BasalEndPoint InitiationEndPoint ReleaseEndPoint 
global ReuptakeStartPoint ReuptakeEndPoint
global release_filterspan peak_filterspan reuptake_filterspan auc_filterspan
global V
global baseline_criterion
global hplot
global origdata_plotobject stimpos_plotobject
global has_peak_average

global release_fit reuptake_fit peak_average auc


%  the points must be in the following order:
%  1. BasalStartPoint
%  2. BasalEndPoint
%  3. InitiationEndPoint
%  4. ReleaseEndPoint
%  5. ReuptakeStartPoint
%  6. ReuptakeEndPoint

if (BasalEndPoint > BasalStartPoint)
    if (InitiationEndPoint > BasalEndPoint)
        if (ReleaseEndPoint > InitiationEndPoint)
%             if (ReuptakeStartPoint > ReleaseEndPoint)
            if (ReuptakeEndPoint > ReuptakeStartPoint)
                %disp('Analysis Points in right order');

                plot_basic();

%                 a = inputdlg('Enter Release Phase Filter Span (integer)', 'Release Phase Filter');
%                 release_filterspan = str2num(a{1});
                release_filterspan = str2num(handles.txt_increaseFilter.String);
                %disp(release_filterspan);
                release_smoothdata = smooth(V.extract_data, release_filterspan, 'moving');

%                 a = inputdlg('Enter Peak/Plateau Filter Span (integer)', 'Peak/Plateau Phase Filter');
%                 peak_filterspan = str2num(a{1});
                peak_filterspan = str2num(handles.txt_peakFilter.String);
                %disp(peak_filterspan);
                peak_smoothdata = smooth(V.extract_data, release_filterspan, 'moving');

%                 a = inputdlg('Enter Reuptake Phase Filter Span (integer)', 'Reuptake Phase Filter');
%                 reuptake_filterspan = str2num(a{1});
                reuptake_filterspan = str2num(handles.txt_reuptakeFilter.String);
                %disp(reuptake_filterspan);
                reuptake_smoothdata = smooth(V.extract_data, reuptake_filterspan, 'moving');

%                 a = inputdlg('Enter AUC Filter Span (integer)', 'AUC Filter');
%                 auc_filterspan = str2num(a{1});
                auc_filterspan = str2num(handles.txt_aucFilter.String);
                %disp(auc_filterspan);
                auc_smoothdata = smooth(V.extract_data, auc_filterspan, 'moving');

                basal_data = V.extract_data(BasalStartPoint:BasalEndPoint);
                release_phase_data = release_smoothdata(InitiationEndPoint:ReleaseEndPoint);
%                 peak_phase_data = peak_smoothdata(ReleaseEndPoint:ReuptakeStartPoint);
                reuptake_phase_data = reuptake_smoothdata(ReuptakeStartPoint:ReuptakeEndPoint);
                auc_included_data = auc_smoothdata(InitiationEndPoint:ReuptakeEndPoint);

                % calculate basal mean
                basal_mean = mean(basal_data);

                % calculate baseline from baseline_criteron and basal_mean
                baseline_criterion = str2num(handles.txt_baselinedef.String);
                basal_stdev = std(basal_data);
                baseline = baseline_criterion * basal_stdev + basal_mean;
                xl = xlim(hplot);
                baseline_plotobject = line(hplot, [xl(1) xl(2)], [baseline baseline], 'LineWidth', 1.5, 'Color', [0.4940 0.1840 0.5560]);
                hold on;

                % release phase linear fit
                release_phase_samples = [InitiationEndPoint:ReleaseEndPoint];
                release_phase_samples = release_phase_samples.';
                release_fit = polyfit(release_phase_samples, release_phase_data, 1);
                releasefit_plotobject = plot(hplot,release_phase_samples,polyval(release_fit,release_phase_samples), 'LineWidth', 1.5, 'Color',  [0.960 0.4250 0.0780],'LineStyle',':'); %TODO:add to legend
                handles.txtReleaseFit.String = release_fit;

                % plot release phase smoothed data
                release_plotobject = plot(hplot, release_phase_samples, release_phase_data, 'LineWidth', 1.5, 'Color',  [0.8500 0.3250 0.0980]);
                hold on;

                % TODO: average in peak/plateau phase
                if (ReuptakeStartPoint > ReleaseEndPoint)
                    has_peak_average = 1;
                    peak_average = mean(peak_smoothdata(ReleaseEndPoint:ReuptakeStartPoint));
                    handles.txtPeakAvg.String = peak_average;
                else
                    has_peak_average = 0;
                end
                
                % reuptake phase exponential fit
                %TODO: display gof 
                ft = fittype('a*exp(b*t) + c','indep','t');
                reuptake_phase_samples = [ReuptakeStartPoint:ReuptakeEndPoint];
                reuptake_phase_samples = reuptake_phase_samples.';
                [reuptake_fit,reuptake_gof] = fit(reuptake_phase_samples, reuptake_phase_data,ft,'start',[peak_average,-0.01,basal_mean]);
                reuptakefit_plotobject = plot(hplot,reuptake_phase_samples,reuptake_fit(reuptake_phase_samples),'LineWidth', 1.5, 'Color', [0.8290 0.7940 0.0250],'LineStyle',':');
                reuptake_fit_vals = coeffvalues(reuptake_fit);

                handles.txtReuptakeFitA.String = num2str(reuptake_fit_vals(1));
                handles.txtReuptakeFitB.String = num2str(reuptake_fit_vals(2));
                handles.txtReuptakeFitC.String = num2str(reuptake_fit_vals(3));
                %plot reuptake phase smoothed data
                reuptake_plotobject = plot(hplot, reuptake_phase_samples, reuptake_phase_data, 'LineWidth', 1.5, 'Color', [0.9290 0.6940 0.1250]);
                hold on;

                % AUC
                auc_data_baseline_adjusted = auc_included_data - baseline;
                auc = trapz(auc_data_baseline_adjusted) * V.SignalPeriod_ms;
                handles.txtAUC.String = auc;


                
                handles.txtPeakAvg.String = peak_average;
                legend([origdata_plotobject stimpos_plotobject baseline_plotobject release_plotobject releasefit_plotobject reuptake_plotobject reuptakefit_plotobject], 'Original data', 'Stimulation mark', 'Baseline', 'Release phase smoothed', 'Release function fit', 'Reuptake phase smoothed', 'Reuptake function fit','Location','northeast');


            else
                f = errordlg('Reuptake End Point not greater than Reuptake Start Point');
            end
%             else
%                 f = errordlg('Reuptake Start Point not greater than Release End Point');
%             end
        else
            f = errordlg('Release End Point not greater than Initiation End Point', 'Error');
        end
    else
        f = errordlg('Initiation End Point not greater than Basal End Point', 'Error');
    end
else
    f = errordlg('Basal End Point not greater than Basal Start Point', 'Error');
end


function txt_baselinedef_Callback(hObject, eventdata, handles)
% hObject    handle to txt_baselinedef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_baselinedef as text
%        str2double(get(hObject,'String')) returns contents of txt_baselinedef as a double
global baseline_criterion

baseline_criterion = str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function txt_baselinedef_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_baselinedef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function txt_increaseFilter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_increaseFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_increaseFilter as text
%        str2double(get(hObject,'String')) returns contents of txt_increaseFilter as a double


% --- Executes during object creation, after setting all properties.
function txt_increaseFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_increaseFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function txt_peakFilter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_peakFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_peakFilter as text
%        str2double(get(hObject,'String')) returns contents of txt_peakFilter as a double


% --- Executes during object creation, after setting all properties.
function txt_peakFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_peakFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function txt_reuptakeFilter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_reuptakeFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_reuptakeFilter as text
%        str2double(get(hObject,'String')) returns contents of txt_reuptakeFilter as a double


% --- Executes during object creation, after setting all properties.
function txt_reuptakeFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_reuptakeFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function txt_aucFilter_Callback(hObject, eventdata, handles)
% hObject    handle to txt_aucFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_aucFilter as text
%        str2double(get(hObject,'String')) returns contents of txt_aucFilter as a double


% --- Executes during object creation, after setting all properties.
function txt_aucFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_aucFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_logResults.
function btn_logResults_Callback(hObject, eventdata, handles)
% hObject    handle to btn_logResults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global analysis_log log_count 
global release_filterspan peak_filterspan reuptake_filterspan auc_filterspan
global baseline_criterion
global release_fit reuptake_fit peak_average auc
global has_peak_average

%disp('log results');
log_count = log_count + 1;

% append results of current analysis to log
analysis_log(log_count).log_number = log_count;
analysis_log(log_count).baseline_nsd = baseline_criterion;
analysis_log(log_count).release_filter = release_filterspan;
analysis_log(log_count).peak_filter = peak_filterspan;
analysis_log(log_count).reuptake_filter = reuptake_filterspan;
analysis_log(log_count).auc_filter = auc_filterspan;
analysis_log(log_count).release_fit_params = release_fit;
analysis_log(log_count).reuptake_fit_params = reuptake_fit;
analysis_log(log_count).area_under_curve = auc;

if (has_peak_average == 1)
    analysis_log(log_count).peak_avg = peak_average;
end


% --- Executes on button press in btn_saveAnalysis.
function btn_saveAnalysis_Callback(hObject, eventdata, handles)
% hObject    handle to btn_saveAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%TODO: save analysis_log to file in some data table format

global analysis_log

[FileName,PathName]=uiputfile('*.mat','Introduce the name of the save data file');
save(strcat(PathName, FileName), 'analysis_log');


% --- Executes when user attempts to close frmStimDataProcess.
function frmStimDataProcess_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to frmStimDataProcess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hfrmMain

%close StimulationDataProcess, open SeroDataProcess 
hfrmMain.Visible='on';
% Hint: delete(hObject) closes the figure
delete(hObject);
