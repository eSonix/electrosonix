function psRun_beta
% This file combines some of Photosound's basic DLL's for collecting and
% saving data from the Photosound 5818 ADC device. It is intended to be
% used as part of the ae_Params.py pipeline (ae_Params will set all the
% parameters for the run and then will run psRun.m, followed by
% mascon.m). This file must be located in the same folder as the Photosound
% program
% In the next version, control of the intan software will be added.
% Inputs:
%  psParams: struct array from file ae_params.py
%  genParams: struct array from file ae_params.py
% Outputs:
%  success: flag for if data was successfully collected 
% Version 1.0 Alexander Michael Alvarez Last Updated: 01/29/2023
rt = 0;
rtavg = 10;
[file,path] = uigetfile('\\V256-LSN\BrainImaging\ParamFiles\','*_Params.mat');
filename = fullfile(path,file);
load(filename,'psparams','genparams')
gp = genparams;
ptp = psparams.ps_trigparams;
pcp = psparams.ps_capparams;
pap = psparams.ps_adcparams;
pdp = psparams.ps_dvparams;

if rt
    pcp.ps_cap_limitTime = 0;
    pcp.ps_cap_limitTrig = 0;
    pcp.ps_cap_limitSize = 0;
    gp.avg = rtavg;
end

filename = mfilename('fullpath');
app_path = fileparts(filename);
asm_path = fullfile(app_path,'\x64\PhotoSoundClasses.dll');
asm = NET.addAssembly(asm_path);
dev = PhotoSoundClasses.DeviceManager;

disp('Connecting...');
addlistener(dev,'OnError',@onerror);
dev.Connect;
while ~dev.Connected && ~dev.ConnectFailure
    pause(0.1);
end

if dev.Connected
    disp('Successfully connected to device');
    
    PowerMode = System.Enum.GetValues(dev.AFE5818.Vca1.PowerMode.GetType);
    HpfCutoffFreq = System.Enum.GetValues(dev.AFE5818.Vca1.HpfCutoffFreq.GetType);
    LpfCutoffFreq = System.Enum.GetValues(dev.AFE5818.Vca1.LpfCutoffFreq.GetType);
    TgcAttenuation = System.Enum.GetValues(dev.AFE5818.Vca1.TgcAttenuation.GetType);
    LnaGlobalGain = System.Enum.GetValues(dev.AFE5818.Vca1.LnaGlobalGain.GetType);
    PgaGain = System.Enum.GetValues(dev.AFE5818.Vca1.PgaGain.GetType);
    
    dev.AFE5818.AutoUpdate            = false;
    dev.AFE5818.ConfiguredAdcMask     = 2^dev.MaxAdcPerDevice-1; 
    dev.AFE5818.ConfiguredDevicesMask = 2^dev.DevicesCount-1; 
    dev.AFE5818.Vca1EqualsVca2        = pap.ps_adc_sameSets;
    dev.AFE5818.Vca1.HpfCutoffDivided = pap.ps_adc_hpfCut3;
    dev.AFE5818.Vca1.LowNoiseMode     = pap.ps_adc_lowNoise;
    dev.AFE5818.Vca1.PgaHpfDisabled   = pap.ps_adc_pgaHPF;
    dev.AFE5818.Vca1.LnaHpfDisabled   = pap.ps_adc_lnaHPF;
    dev.AFE5818.Vca1.PgaClampEnabled  = pap.ps_adc_pgaClamp;
    dev.AFE5818.Vca1.F5MHzLpfEnabled  = pap.ps_adc_lpfCut5;
    dev.AFE5818.Vca1.TgcAttEnabled    = pap.ps_adc_tgcAttenF;
    dev.AFE5818.Vca1.PowerMode        = PowerMode(pap.ps_adc_powerMode);
    dev.AFE5818.Vca1.HpfCutoffFreq    = HpfCutoffFreq(pap.ps_adc_hpfCutF);
    dev.AFE5818.Vca1.LpfCutoffFreq    = LpfCutoffFreq(pap.ps_adc_lpfCutF);
    dev.AFE5818.Vca1.TgcAttenuation   = TgcAttenuation(pap.ps_adc_tgcAtten);
    dev.AFE5818.Vca1.LnaGlobalGain    = LnaGlobalGain(pap.ps_adc_lnaGain);
    dev.AFE5818.Vca1.PgaGain          = PgaGain(pap.ps_adc_pgaGain);            
    dev.AFE5818.Configure;   
    
    dev.Capture.AutoUpdate       = false;
    dev.Capture.DecimationFactor = pcp.ps_cap_decF;
    dev.Capture.EnabledAdcMask   = 2^dev.MaxAdcPerDevice-1;
    dev.Capture.FramesPerPacket  = 1;
    dev.Capture.SamplesToCapture = pcp.ps_cap_samps;
    dev.Capture.WaitTrigger      = pcp.ps_cap_waitTrig;
    dev.Capture.Configure;
    
    dev.Trigger.AutoUpdate             = false;
    if ptp.ps_trig_enab == 0
        dev.Trigger.ConnectToGenerator = 1;
    else
        dev.Trigger.ConnectToGenerator = 0;
    end
    dev.Trigger.InvertedInputsMask     = ptp.ps_trig_invert;
    if ptp.ps_trig_enab == 1 % optical trigger on without sma on
        dev.Trigger.EnabledInputsMask  = 1;
    elseif ptp.ps_trig_enab == 2 % both optical and sma trigger on
        dev.Trigger.EnabledInputsMask  = 11; %two-bits if both are 1 then both optical and sma inputs can receive trigger
    else
        dev.Trigger.EnabledInputsMask  = 0;
    end
    dev.Trigger.GeneratorFrequency     = 1000; % Leave at 1k; it should not matter 
    if ptp.ps_trig_enab == 1
        dev.Trigger.InputNames(1)      = 'OPT';
    elseif ptp.ps_trig_enab == 2
        dev.Trigger.InputNames(1)      = 'SMA';
    else
        dev.Trigger.InputNames(1)      = 'GEN';
    end
    dev.Trigger.SlaveDelays(1)         = ptp.ps_trig_slave;
    dev.Trigger.InputsDelay            = ptp.ps_trig_delay;
    dev.Trigger.InputsGuard            = 10; % Leave at 10
    dev.Trigger.Configure;
    
    if ptp.ps_trig_out
        dev.Trigger.TriggerOutputs(1).AutoUpdate = false;
        dev.Trigger.TriggerOutputs(1).ConnectToGenerator = 1;
        dev.Trigger.TriggerOutputs(1).PulseWidth = 10;    
        dev.Trigger.TriggerOutputs(1).SourcesMask = 0;
        dev.Trigger.TriggerOutputs(1).Invert = false;
        dev.Trigger.TriggerOutputs(1).Enable = true;
        dev.Trigger.TriggerOutputs(1).Delay = 1;
    else
        dev.Trigger.TriggerOutputs(1).AutoUpdate = false;
        dev.Trigger.TriggerOutputs(1).ConnectToGenerator = false;
        dev.Trigger.TriggerOutputs(1).PulseWidth = 10;    
        dev.Trigger.TriggerOutputs(1).SourcesMask = 0;
        dev.Trigger.TriggerOutputs(1).Invert = false;
        dev.Trigger.TriggerOutputs(1).Enable = false;
        dev.Trigger.TriggerOutputs(1).Delay = 1;
    end
    dev.Trigger.TriggerOutputs(1).Configure;
    
    freq = dev.Trigger.GetInputFrequencies;
    for n = 1:freq.Length
        disp(['Trigger input ' num2str(n) ' frequency is ' num2str(freq(n))]);
    end
    data = NET.createArray('System.Int16',dev.MaxSamplesToCapture);    

    k = 0;
    % Properties for display;
    % Need to update adc and chan based on channels 
    adc = 1;
    chan = 1;  
    if pdp.ps_dv_plot >= 1
        fig = figure('Name','Plot data example');
    end

    % Logger Settings
    logger                  = dev.CreateLogger('Matlab');
    logger.DataFolder       = app_path;
    logger.DevicesMask      = 2^dev.DevicesCount-1;
    logger.MaxFileSize      = 1; % Don't Change
    logger.MaxLoggedFrames  = pcp.ps_cap_trigEvents; 
    logger.LoggingTimeout   = 60;  % Don't change
    logger.LimitLoggingTime = pcp.ps_cap_limitTime;
    logger.LimitNumFrames   = pcp.ps_cap_limitTrig;
    logger.LimitFileSize    = pcp.ps_cap_limitSize;

    logger.StartLoggingToFile(gp.paramfileroot);
    logging = false;
    i = 1;
    if pdp.ps_dv_plot == 1

        if gp.avg > 1
            while i <= gp.avg && logger.NumLoggedFrames < logger.MaxLoggedFrames
                while isvalid(fig)
                   samples = dev.GetPlotData(data,data.Length,0,adc,chan);
                    if samples > 0
                        tmp = int16(data); 
                        tmpavg(:,i) = tmp;
                        i = i+1;
                        if i > gp.avg
                            plot(squeeze(mean(tmpavg(1:samples,:),2)))
                            i = 1;
                        end
                    end
                    for m=1:k
                        fprintf('\b');
                    end
                    k = 0;
                    if logger.Logging
                        k = fprintf('Logging: %d%%, %6.2f MB, %d frames, %6.2f s',...
                        logger.Progress,logger.FileSize,logger.NumLoggedFrames,...
                        logger.LoggingTime);
                    elseif logging            
                        logging = false;
                        fprintf('Logging was finished\n');
                    end
                    pause(0.1);
                end
            end
        else
            while isvalid(fig)
                samples = dev.GetPlotData(data,data.Length,0,adc,chan);
                if samples > 0
                    tmp = int16(data);
                    plot(tmp(1:samples));
                end
                for m=1:k
                    fprintf('\b');
                end
                k = 0;
                if logger.Logging
                    k = fprintf('Logging: %d%%, %6.2f MB, %d frames, %6.2f s',...
                    logger.Progress,logger.FileSize,logger.NumLoggedFrames,...
                    logger.LoggingTime);
                elseif logging            
                    logging = false;
                    fprintf('Logging was finished\n');
                end
                pause(0.1);    
            end
        end                 

    elseif pdp.ps_dv_plot == 2
            % Need to write this section for M-Mode
    else                   
        for m=1:k
            fprintf('\b');
        end
        k = 0;
        if logger.Logging
            k = fprintf('Logging: %d%%, %6.2f MB, %d frames, %6.2f s',...
            logger.Progress,logger.FileSize,logger.NumLoggedFrames,...
            logger.LoggingTime);
        elseif logging            
            logging = false;
            fprintf('Logging was finished\n');
        end
            pause(0.1);            
    end
    logger.StopLogging;
    close all
else
    disp('Failed to connect to device');
end

dev.Disconnect;
disp('Disconnected');