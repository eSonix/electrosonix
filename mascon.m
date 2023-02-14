function mascon
% cd C:\Users\bojua\OneDrive\Documents\Python
clc
close all
[file, path] = uigetfile('D:\Users\Yexian\Projects\BrainImaging\ParamFiles','*_Params.mat');
filename = fullfile(path,file);
load(filename,'-mat','genparams','niparams','usparams');
up = usparams;

%A = maschirpcyc = up.us_numCyc;
%% Vera Control
set(0,'showhiddenhandles','on');
openfigs = findobj('Type','Figure');
if ~isempty(openfigs)
    openfigsNames = openfigs.Name;
    veracomp = zeros(length(openfigsNames));
    for i = 1:size(openfigsNames)
        veracomp(i) = strcmp(openfigsNames(i),'vera');
    end
else
    veracomp = 0;
end
if sum(veracomp) <= 1
   vera
    us_trans = findobj('Tag','transmenu');
    us_sDep  = findobj('Tag','startdepth');
    us_eDep  = findobj('Tag','enddepth');
    us_zFoc  = findobj('Tag','focusdepth');
    us_tcal  = findobj('Tag','tcal');
    us_rcal  = findobj('Tag','rcal');
    us_chirp = findobj('Tag','chirp');
    us_pemode= findobj('Tag','pemode');
    us_mmode = findobj('Tag','MMode');
    us_multiacq = findobj('Tag','multiacq');
    us_trig_in = findobj('Tag','trig_in');
    us_tc = findobj('Tag','tc');
    us_sim   = findobj('Tag','sim');
    us_bScan = findobj('Tag','ae_bscan');
    us_trans.Value = up.us_trans;
    us_sDep.String = up.us_sDep;
    us_eDep.String = up.us_eDep;
    us_zFoc.String = up.us_focZ;
    us_rcal.String = num2str(0);
    us_tcal.String = num2str(0);
    us_chirp.Value = up.us_transW;
    us_pemode.Value = 0;
    us_mmode.Value = 0;
    us_multiacq.Value = 0;
    us_trig_in.Value = 0;
    us_sim.Value   = 0;
    us_tc.Value    = 0;
    m.usparams = up;
    m.niparams = niparams;
    m.genparams = genparams;
    m.autoscan = 1;
    assignin('base','m',m);
    feval(get(us_bScan,'Callback'),us_bScan,[]);
else
    m.usparams = 0;
    m.niparams = 0;
    m.autoscan = 0;
    assignin('base','m',m);
end


% Set the parameters that will be loaded into VSX

% Change set events for there to be a click of the scan button on VSX



%Change set events for there to be a click of the scan button on AEScan
set(0,'showhiddenhandles','off');
close all


