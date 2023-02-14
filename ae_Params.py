# This program will allow for all parameters to be placed in their respective 
# GUIs for AE
import numpy as np
from scipy.io import savemat
from datetime import datetime
import matlab.engine
import sys
import paramiko

vantagePath = r'C:\Users\Administrator\Documents\Vantage-4.7.6-2206101100'
savePath    = r'D:\Users\Yexian\Projects\BrainImaging\ParamFiles' # Change as needed
psPath      = r'C:\Users\EUNIL_ABI\Documents\MATLAB' # Update Accoridingly
PSIP     = '192.168.0.101' # IP Address for the ES Laptop

### Flags
runMode = 1 # 0 = real-time, 1 = Scan #real-time is currently deprecated
daqs    = 3 # 0 = NI, 1 = PS, 2 = Both
pause   = 0 # Flag to add 5 second pause on VSX side

### Set Params
## Gen Params
saveName = "auto3" # Name will be appended with datetime string
recTime  = 30 # ms (total recording time)
avg      = 10   # Number of averages at each point
xRng     = 5   # mm of recording in X 
yRng     = 0   # mm of recording in Y
xSpac    = 0.25   # mm spacing in X
ySpac    = 1    # mm spacing in Y
lf_fs    = 20   # kHz (sampling frequency)
hf_fs    = 20   # MHz (sampling frequency)
hf_prf   = 4    # kHz (pulse repetition frequency)
hf_sDep  = 0    # mm (start depth for recording)
hf_eDep  = 90   # mm (end depth for recording)

## US Tx/Tw Params
us_trans     = 1   # 1 = P4-1, 2 = P4-2v, 3=L7-4, 4 = L11-4v, 5 = H235, 6 = H247, 7 = MPT74
us_sDep      = 0   # mm (start depth)
us_eDep      = 90  # mm (end depth)
us_focX      = 0   # mm (Azi)
us_focY      = 0   # mm (Ele); make sure is 0 if a linear trans
us_focZ      = 45  # mm (Dep)
us_transV    = 25  # Transmit Voltage (V)
us_transW    = 1   # 0 = Parametric, 1 = Chirp
#us_numCyc    = 10  # Number of Cycles for chirp pulse; #Currently will just auto-set number of cycles based on transducer
us_reconFlag = 0   # flag to reconstruct ultrasound data
us_txonly    = 0   # flag to only tx without receive
us_rawPE     = 0   # flag to save raw PE
us_reconPE   = 0   # flag to save reconstructed PE
us_sweep     = 0   # flag to sweep
us_Tpt       = 0.5 # Sweeping number of points 

## Stim Params
stim_shape    = 0    # 0 = 'sine', 1 = 'rect', 2 = 'Pls', 3= 'Arb'
stim_timeOn   = 5  # ms time on for the waveform
stim_numCyc   = 3    # number of repeats of the shape
stim_timeOff  = 85    # ms time off for the waveform
stim_amp      = 3    # V amplitude of stimulation

## AEScan Params
# Stim Params
ni_stim_amp       = stim_amp
ni_stim_numCyc    = stim_numCyc
ni_stim_shape     = stim_shape
ni_stim_pWidth    = 0             # time in us (leave at 0)
ni_stim_rec_delay = 0             # time in ms to wait to start recording (leave at 0)
ni_stim_ip        = "192.168.0.27" # IP Address for stimulator (leave as is)

# DAQ Params
ni_daq_lfFs     = lf_fs
ni_daq_hfFs     = hf_fs
ni_daq_lfChans  = [25,26] # 16:31 or 32 for all; CSV for channels
ni_daq_hfChans  = [0,1]      # 0:7 or 8 for all; CSV for channels
ni_daq_lfDynR   = 6                # V Must choose 0.05V, 0.2V, 1V, 6V *** need to adjust accordingly
ni_daq_hfDynR   = 1                # V Must choose 0.05V, 0.2V, 1V, 6V *** need to adjust accordingly
ni_daq_dur      = recTime
ni_daq_ave      = avg
ni_daq_saveAvg  = 0                # Flag for saving only the averaged data on NI
ni_daq_fastFilt = 0                # Flag for turning on fast-time filter in display (typically leave at 0)
ni_daq_slowFilt = 0                # Flag for turning on slow-time filter in display (typically leave at 0)
ni_daq_vsxIP    = "192.168.0.25"    # IP address for verasonics
ni_daq_niIP     = "192.168.0.26"    # IP address for NI 
ni_daq_lsn      = 1                # Flag for if you are in LSN scanning
ni_daq_lfGain   = 80               #Adjust based on hardware
ni_daq_hfGain   = 440             # Adjust based on hardware

# Scan Params
ni_scan_xRng    = xRng # mm Range for x/azimuthal scanning
ni_scan_yRng    = yRng # mm Range for y/elevational scanning
ni_scan_type    = 1    # 1 = Focus, 2 = Plane, 3 = Cone, 4 = TR, 5 = Custom, 6 = CustomB, 7 = Hadamard
ni_scan_speed   = 1000 # motor speed (leave at 1000)
ni_scan_motor   = 0    # 0 = X orientation of motor; 1 = Y orientation of motor
ni_scan_VelmDel = 100  # delay in motor (leave at 100)
ni_scan_Port    = 8    # USB Port (can be found in device manager)

## PS Params
# ADC Params
ps_adc_hpfCut3   = 0  # Flag to divide HPF cutoff by 3
ps_adc_lowNoise  = 0  # Flag for low noise figure mode enabled (always leave at 1)
ps_adc_pgaHPF    = 0  # Flag for disabling PGA HPF (always leave at 0)
ps_adc_lnaHPF    = 0  # Flag for disabling LNA HPF (always leave at 0)
ps_adc_pgaClamp  = 0  # Flag for enabling -6dB PGA clamp (always leave at 0)
ps_adc_lpfCut5   = 1  # Flag for enabling 5MHz LPF
ps_adc_tgcAttenF  = 1  # Flag for enabling TGC attenuation (always leave at 1)
ps_adc_powerMode = 1  # Power Mode 1 = low noise, 2 = low power, 3 = medium power
ps_adc_hpfCutF   = 3  # HPF Cutoff 1 = 100 kHz, 2 = 50 kHz, 3 = 200 kHz, 4 = 150 kHz
ps_adc_lpfCutF   = 6  # LPF Cutoff 1 = 15 MHz, 2 = 20 MHz, 3 = 35 MHz, 4 = 30 MHz, 5 = 50 MHz, 6 = 10 MHz
ps_adc_tgcAtten  = 5  # TGC Attenuation Select 1 = 0 dB, 2 = 6 dB, 3 = 12 dB, 4 = 18 dB, 5 = 24 dB, 6 = 30 dB, 7 = 36 dB
ps_adc_lnaGain   = 2  # LNA Global Gain Select 1 = 18 dB, 2 = 24 dB, 3 = 12 dB
ps_adc_pgaGain   = 2  # PGA Global Gain Select 1 = 24 dB, 2 = 30 dB
##Deprecated: ps_adc_confADCs  = 2  # Configured ADC Flags; 0 = 1, 1 = 2, 2 = Both
##Deprecated: ps_adc_confDevs  = 1  # Configured Device Flag; Always leave as 1
ps_adc_sameSets  = 1  # Flag to have same settings on both VCAs (always leave as 1) 

# Trig Params
ps_trig_enab      = 2 # Trigger Source Enabled; 0 = Generator, 1 = PD, 2 = SMA
ps_trig_invert    = 0 # Flag for inverting trigger detection threshold
ps_trig_out       = 0 # Flag for enabling output trigger with same settings as input trigger
ps_trig_invertOut = 0 # Flag for inverting output trigger
ps_trig_slave     = 0 # Flag for controlling slave delays (always leave at 0)

# Capture Params
ps_cap_ppT       = 10 # packets per transfer (always leave at 10)
ps_cap_useMAT    = 0  # Flag for using .mat format (leave at 0)
ps_cap_waitTrig  = 1  # Flag to wait for trigger  before recording (always leave at 1)
ps_cap_writeFile = 1  # Flag to write data to a file (always leave on 1)
ps_cap_limitTrig = 1  # Flag to limit file based on trigger events (always leave on 1)
ps_cap_limitTime = 0  # Flag to limit file based on capture time (always leave at 0)
ps_cap_limitSize = 0  # Flag to limit file based on file size (always leave at 0)
ps_cap_adcs      = 2  # 0 = ADC 1 (0:15); 1 = ADC 2 (16:31); 2 = Both

# Data Viewer Params
ps_dv_plot      = 1  # Flag to plot photosound data in real time 0 = No plot; 1 = A-line 2 = M-Mode
ps_dv_chansDisp = [32]   # 0:31 or 32 for all; CSV for channels
ps_dv_xMin      = 0      # Always leave at 0
ps_dv_yMin      = -32767 # Always leave at this number
ps_dv_yMax      = 32767  # Always leave at this number


## Intan Params
int_chans = [32]             # 0:31 or 32 for all; CSV for channels

### Calculate Params

## Stim Params
stim_timeT = (stim_timeOn*stim_numCyc)+stim_timeOff

## AEScan Params
# Stim Params
ni_stim_freq = 1/stim_timeOn * 1000 # Frequency based on on time
ni_stim_T    = stim_timeT    # Period based on total stimulation time

# DAQ Params
ni_daq_dep = hf_eDep-hf_sDep    # Calculate the total depth from end depth and start depth
ni_daq_prf = hf_prf*1000        # Calculate PRF in Hz   
if daqs != 1:                  # if-else statement for using NI or not depending on flag above
    ni_daq_useNI = 1
else:
    ni_daq_useNI = 0

# Scan Params
ni_scan_xPts = np.floor(xRng/xSpac)+1 # Calculate the number of points to scan based on the range and spacing
ni_scan_yPts = np.floor(yRng/ySpac)+1 # Calculate the number of points to scan based on the range and spacing


## PS Params
# 5818 Params
ps_adc_tgcOps    = [0,6,12,18,24,30,36] # TGC Atten options
ps_adc_lnaOps    = [18,24,12]              # LNA Gain options
ps_adc_pgaOps    = [24,30]              # PGA Gain options
ps_adc_totalGain = 39 + ps_adc_lnaOps[ps_adc_lnaGain-1] + ps_adc_pgaOps[ps_adc_pgaGain-1] - ps_adc_tgcOps[ps_adc_tgcAtten-1] # Formula for total gain

# Trigger Params
ps_trig_delay = hf_sDep/1.54 * hf_fs;   # Calculate the trigger delay for photosound based on start depth

# Capture Params
ps_cap_samps      = np.floor((hf_eDep-hf_sDep)*hf_fs/1.54)     # Calculate the number of samples based on start/end depth and sampling frequency
ps_cap_decF       = np.floor(80/hf_fs)                         # Calculate the decimation factor based on the sampling frequency
ps_cap_trigEvents = (recTime*hf_prf*avg*ni_scan_xPts*ni_scan_yPts) # Calculate the number of trigger events based on recording duration, pulse rate, averages, x/y points

# Data Viewer Params
if ps_dv_chansDisp == 32:
    ps_dv_chansDisp = np.linspace(0,31,1)
    ps_dv_xMax = np.floor((hf_eDep-hf_sDep)*hf_fs/1.54)
else:
    ps_dv_xMax = 1000
## Intan Params
#*** need to update accordingly

## Gen Params
now = datetime.now()
dtstring = now.strftime("%Y%m%d_%H%M")
paramfileroot = saveName + '_' + dtstring 
if ni_scan_xPts > 1 and ni_scan_yPts > 1:
    scanType = str(int(ni_scan_xPts)) + 'X' + str(int(ni_scan_yPts)) + 'Y'
elif ni_scan_xPts > 1 and ni_scan_yPts == 1:
    scanType = str(int(ni_scan_xPts)) + 'X'
elif ni_scan_yPts > 1 and ni_scan_xPts == 1:
    scanType = str(int(ni_scan_yPts)) + 'Y'
else:
    scanType = 'M'
paramfilename = paramfileroot + '_' + str(int(avg)) + 'A' + scanType + '_Params.mat'
fullparamname = savePath + '/' + paramfilename
### Group and Save Params
# Write all parameters to structural arrays
genparams    =  {"saveName": saveName,"recTime": recTime,"avg": avg, 
                 "hf_sDep": hf_sDep,"hf_eDep": hf_eDep,"xRng": xRng,
                 "yRng": yRng,"xSpac": xSpac,"ySpac": ySpac,"lf_fs": lf_fs,
                 "hf_fs": hf_fs,"hf_prf": hf_prf,"paramfileroot":paramfileroot}
usparams     =  {"us_trans": us_trans,"us_sDep": us_sDep,"us_eDep": us_eDep,
                 "us_focX": us_focX,"us_focY": us_focY,"us_focZ": us_focZ,
                 "us_transV": us_transV,"us_transW": us_transW,
                 "us_txonly": us_txonly,
                 "us_rawPE": us_rawPE,"us_reconFlag": us_reconFlag,
                 "us_reconPE": us_reconPE,"us_sweep": us_sweep,
                 "us_Tpt": us_Tpt}
stimparams    = {"stim_shape": stim_shape,"stim_amp": stim_amp, 
                 "stim_timeOn": stim_timeOn,"stim_timeOff": stim_timeOff,
                 "stim_timeT": stim_timeT,"stim_numCyc": stim_numCyc}
ni_stimparams = {"ni_stim_shape": ni_stim_shape, "ni_stim_amp": ni_stim_amp,
                 "ni_stim_freq": ni_stim_freq,"ni_stim_numCyc": ni_stim_numCyc,
                 "ni_stim_T": ni_stim_T,"ni_stim_pWidth": ni_stim_pWidth,
                 "ni_stim_rec_delay": ni_stim_rec_delay,
                 "ni_stim_ip": ni_stim_ip,}
ni_daqparams  = {"ni_daq_lfFs": ni_daq_lfFs,"ni_daq_hfFs": ni_daq_hfFs,
                 "ni_daq_lfChans": ni_daq_lfChans,
                 "ni_daq_hfChans": ni_daq_hfChans, 
                 "ni_daq_lfDynR": ni_daq_lfDynR, 
                 "ni_daq_hfDynR": ni_daq_hfDynR,"ni_daq_dur": ni_daq_dur,
                 "ni_daq_ave": ni_daq_ave,"ni_daq_saveAvg": ni_daq_saveAvg,
                 "ni_daq_fastFilt": ni_daq_fastFilt,
                 "ni_daq_slowFilt": ni_daq_slowFilt,
                 "ni_daq_vsxIP": ni_daq_vsxIP,"ni_daq_niIP": ni_daq_niIP,
                 "ni_daq_lsn": ni_daq_lsn,"ni_daq_lfGain": ni_daq_lfGain,
                 "ni_daq_hfGain": ni_daq_hfGain,"ni_daq_dep": ni_daq_dep,
                 "ni_daq_prf": ni_daq_prf,"ni_daq_useNI": ni_daq_useNI} 
ni_scanparams = {"ni_scan_xRng": ni_scan_xRng,"ni_scan_yRng": ni_scan_yRng,
                 "ni_scan_xPts": ni_scan_xPts,"ni_scan_yPts": ni_scan_yPts,
                 "ni_scan_type": ni_scan_type,"ni_scan_speed": ni_scan_speed,
                 "ni_scan_motor": ni_scan_motor, 
                 "ni_scan_VelmDel": ni_scan_VelmDel,
                 "ni_scan_Port": ni_scan_Port}
niparams      = {"ni_stimparams": ni_stimparams,"ni_daqparams": ni_daqparams,
                 "ni_scanparams": ni_scanparams}
ps_adcparams  = {"ps_adc_lowNoise": ps_adc_lowNoise,
                 "ps_adc_powerMode":ps_adc_powerMode,
                 "ps_adc_hpfCut3": ps_adc_hpfCut3,
                 "ps_adc_hpfCutF": ps_adc_hpfCutF,
                 "ps_adc_lpfCut5": ps_adc_lpfCut5,
                 "ps_adc_lpfCutF": ps_adc_lpfCutF,
                 "ps_adc_pgaHPF": ps_adc_pgaHPF,"ps_adc_lnaHPF": ps_adc_lnaHPF,
                 "ps_adc_pgaClamp": ps_adc_pgaClamp,
                 "ps_adc_tgcAttenF": ps_adc_tgcAttenF,
                 "ps_adc_lnaGain": ps_adc_lnaGain,
                 "ps_adc_pgaGain": ps_adc_pgaGain,
                 "ps_adc_tgcAtten": ps_adc_tgcAtten,
                 "ps_adc_totalGain": ps_adc_totalGain,
                 "ps_adc_sameSets": ps_adc_sameSets}
ps_trigparams = {"ps_trig_enab": ps_trig_enab,"ps_trig_invert": ps_trig_invert,
                 "ps_trig_out": ps_trig_out,
                 "ps_trig_invertOut": ps_trig_invertOut,
                 "ps_trig_slave": ps_trig_slave,"ps_trig_delay": ps_trig_delay}
ps_capparams  = {"ps_cap_samps": ps_cap_samps,"ps_cap_decF": ps_cap_decF,
                 "ps_cap_trigEvents": ps_cap_trigEvents,
                 "ps_cap_ppT": ps_cap_ppT,"ps_cap_useMAT": ps_cap_useMAT,
                 "ps_cap_waitTrig": ps_cap_waitTrig,
                 "ps_cap_writeFile": ps_cap_writeFile,
                 "ps_cap_limitTrig": ps_cap_limitTrig,
                 "ps_cap_limitTime": ps_cap_limitTime,
                 "ps_cap_limitSize": ps_cap_limitSize,
                 "ps_cap_adcs": ps_cap_adcs}
ps_dvparams  = {"ps_dv_chansDisp": ps_dv_chansDisp,"ps_dv_xMin": ps_dv_xMin,
                 "ps_dv_xMax": ps_dv_xMax, "ps_dv_yMin": ps_dv_yMin,
                 "ps_dv_yMax": ps_dv_yMax, "ps_dv_plot": ps_dv_plot}
psparams      = {"ps_adcparams": ps_adcparams,"ps_trigparams": ps_trigparams,
                 "ps_capparams": ps_capparams,"ps_dvparams": ps_dvparams}
intanparams   = {}
aeparams      = {"genparams": genparams,"usparams": usparams,
                 "stimparams": stimparams,"niparams": niparams,
                 "psparams": psparams,"intanparams": intanparams}


savemat(fullparamname, aeparams)

### Run pscon.py on PS Laptop if PS is a DAQ that is selected
# if daqs >= 1:
#     # Connect to remote host
#     client = paramiko.SSHClient()
#     client.load_system_host_keys()
#     client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
#     client.connect(hostname=PSIP, username='EUNIL_ABI', password='EUNIL_ABI')
#     # Setup sftp connection
#     sftp = client.open_sftp()
#     #Transmit Script
#     fullPSfile = psPath + '/' + paramfilename
#     sftp.put(fullparamname,fullPSfile)
#     sftp.close()
#     # Run the transmitted script remotely without args and show its output.
#     # SSHClient.exec_command() returns the tuple (stdin,stdout,stderr)
#     psconFile = psPath + 'pscon.py'
#     pyComm = 'python ' + psconFile
#     stdout = client.exec_command(command=pyComm,bufsize=1,timeout = None,
#                                   get_pty=False,environment=dict(psFile=fullPSfile))
       
#     ### Run mascon.m on Vantage 256
#     eng = matlab.engine.start_matlab()
#     eng.cd(vantagePath)
#     A = eng.mascon(fullparamname)
#     eng.workspace["A"] = A


# ### Close all
# if daqs >= 1:
#     client.close()
#     sys.exit(0)

