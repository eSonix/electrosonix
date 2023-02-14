function autoAEScan
%This is a process function to be used in VSX to set parameters automatically and to run AE Scan automatically 
bScanParm = evalin('base','bScanParm');
v  = evalin('base','v');
nstp = v.niparams.ni_stimparams;
ndp  = v.niparams.ni_daqparams;
nscp = v.niparams.ni_scanparams;
gp = v.genparams;
up = v.usparams;
%% Set Focus
bScanParm.latFocus = up.us_focX;
bScanParm.ElFocus  = up.us_focY;
bScanParm.AxialFocus = up.us_focZ;
%% Set AEScan Parameters
a = mfilename('fullpath');
S = dbstack();
b = length(S(1).file);
bScanParm.script = a(1:end-b+2);
bScanParm.ScriptRoot     = fileparts(which('BScan'));
%Creates scan parameter settings
InitFile = fullfile(bScanParm.ScriptRoot,'Init.mat');
if exist(InitFile)
  Parm = load(InitFile,'bScanParm');
 % bScanParm.script = Parm.bScanParm.script;
  bScanParm.Format = Parm.bScanParm.Format;
  bScanParm.Daq = Parm.bScanParm.Daq;
  bScanParm.Scan = Parm.bScanParm.Scan;
  bScanParm.Stim = Parm.bScanParm.Stim;
  bScanParm.Velmex = Parm.bScanParm.Velmex;
  bScanParm.ActiveScan = Parm.bScanParm.ActiveScan;
  bScanParm.Fast = Parm.bScanParm.Fast;
  bScanParm.Source = Parm.bScanParm.Source;
  bScanParm.Destination = Parm.bScanParm.Destination;
  bScanParm.auto = Parm.bScanParm.auto;
end

bScanParm.Scan.Xpt = nscp.ni_scan_xPts;
bScanParm.Scan.XDist = nscp.ni_scan_xRng;
bScanParm.Scan.Ypt = nscp.ni_scan_yPts;
bScanParm.Scan.YDist = nscp.ni_scan_yRng;
bScanParm.Scan.SlowAxis = 0; % may have to change this
bScanParm.Scan.FastAxis = 0; % may have to change this
bScanParm.Scan.Duration_ms = ndp.ni_daq_dur;
bScanParm.Scan.Sound_Speed = 1.485; %mm/us
bScanParm.Daq.HF.PulseRate = ndp.ni_daq_prf; 
bScanParm.Scan.Tpt = bScanParm.Daq.HF.PulseRate/1e3*bScanParm.Scan.Duration_ms;
bScanParm.Scan.steps = bScanParm.Scan.Xpt*bScanParm.Scan.Ypt;

bScanParm.Scan.Avg = ndp.ni_daq_ave;
scantypes = {'Focus','Plane','Cone','TR','Custom','CustomB','Hadamard'};
bScanParm.Scan.Type = scantypes{nscp.ni_scan_type}; %'Focus'; 

bScanParm.Daq.HF.Rate_mhz = ndp.ni_daq_hfFs;
bScanParm.Scan.ZDist = ndp.ni_daq_dep;
bScanParm.Daq.HF.Samples = ceil(bScanParm.Daq.HF.Rate_mhz/bScanParm.Scan.Sound_Speed*bScanParm.Scan.ZDist);
bScanParm.Daq.HF.Gain = ndp.ni_daq_hfGain;
bScanParm.Daq.HF.Range = ndp.ni_daq_hfDynR;
if numel(ndp.ni_daq_hfChans) == 1
    bScanParm.Daq.HF.Channels = num2str(ndp.ni_daq_hfChans); 
else
    bScanParm.Daq.HF.Channels = [num2str(ndp.ni_daq_hfChans(1)) ':' num2str(ndp.ni_daq_hfChans(end))]; 
end
bScanParm.Daq.LF.Rate_hz = ndp.ni_daq_lfFs;
bScanParm.Daq.LF.Samples = 0; % May need to change this
bScanParm.Daq.LF.Gain = ndp.ni_daq_lfGain;
bScanParm.Daq.LF.Range = ndp.ni_daq_lfDynR;
if numel(ndp.ni_daq_hfChans) == 1
    bScanParm.Daq.LF.Channels = num2str(ndp.ni_daq_lfChans); 
else
    bScanParm.Daq.LF.Channels = [num2str(ndp.ni_daq_lfChans(1)) ':' num2str(ndp.ni_daq_lfChans(end))]; 
end
bScanParm.Daq.PulseMode = 1; %may need to change this
bScanParm.Daq.UseNI = ndp.ni_daq_useNI;
bScanParm.Daq.FilterDisplay = 0; % may need to change
bScanParm.Daq.STimeFilt = 0; % may need to change

bScanParm.Scan.Zpt = bScanParm.Daq.HF.Samples;
bScanParm.Scan.pts = bScanParm.Scan.Xpt*bScanParm.Scan.Ypt*bScanParm.Scan.Tpt*bScanParm.Scan.Zpt;

bScanParm.Format.local = 'D:\Users\Yexian\Projects\BrainImaging';
bScanParm.Format.remote = bScanParm.Format.local; % AMA Mod '\\192.168.0.191\BrainImaging'; %Might need to use \\ after IP rather than before
bScanParm.Format.date = datestr(now,'yyyy-mm-dd');
bScanParm.Format.filename = gp.paramfileroot; 
bScanParm.Format.raw_pe = up.us_rawPE;
bScanParm.Format.reconstructed_pe = up.us_reconPE;    
bScanParm.Format.ae_dir = fullfile(bScanParm.Format.local,bScanParm.Format.date,'ExpData');
bScanParm.Format.pe_dir = fullfile(bScanParm.Format.remote,bScanParm.Format.date,'PEData');
bScanParm.Format.verasonics_IP = ndp.ni_daq_vsxIP; % '192.168.0.191';
bScanParm.Format.NI_IP = ndp.ni_daq_niIP; % '192.168.0.190';
bScanParm.Format.Save_One = 1; % leave this at 1
bScanParm.Format.Save_Avg = ndp.ni_daq_saveAvg;
bScanParm.Format.PE_Pulse = 0; % may need to change

if nscp.ni_scan_motor == 0
    bScanParm.Velmex.X = 1;
    bScanParm.Velmex.Y = 2;
else
    bScanParm.Velmex.X = 2;
    bScanParm.Velmex.Y = 1;
end
bScanParm.Velmex.Speed = nscp.ni_scan_speed;
bScanParm.Velmex.Pause = 50; % Leave for now
bScanParm.Velmex.Port = nscp.ni_scan_Port;

if up.us_transW == 1
    bScanParm.Stim.IsChirp =  1; %may need to change
else
    bScanParm.Stim.IsChirp = 0;
end
bScanParm.Stim.Amplitude = nstp.ni_stim_amp;
bScanParm.Stim.Duration = bScanParm.Scan.Duration_ms;
if nstp.ni_stim_shape == 0
    bScanParm.Stim.Waveform = 'Sin'; % may need to change name 
elseif nstp.ni_stim_shape == 1
    bScanParm.Stim.Waveform = 'Rect'; % may need to change name
elseif nstp.ni_stim_shape == 2
    bScanParm.Stim.Waveform = 'Pls'; % may need to change name
else
    bScanParm.Stim.Waveform = 'Arb'; % may need to change name
end
bScanParm.Stim.Width = nstp.ni_stim_pWidth;
bScanParm.Stim.Cycles = nstp.ni_stim_numCyc;
bScanParm.Stim.Frequency = nstp.ni_stim_freq;
bScanParm.Stim.Delay = nstp.ni_stim_rec_delay;
bScanParm.Stim.Period = nstp.ni_stim_T;
bScanParm.Stim.IP = nstp.ni_stim_ip;
save(InitFile,'bScanParm');

%% Init
Init(0,0);
%% Click scan
scanBut = findobj('Tag','Scan');
feval(get(scanBut,'Callback'),scanBut,[]);

end

