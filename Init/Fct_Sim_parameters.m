function ParamSim = Fct_Sim_parameters(ParamGNSS, option)


ParamSim.Nrandompoints             = 3;%Total number of iterations
ParamSim.Nrandompoints_Calibration = 1e1;
ParamSim.Nc                        = 0.1;%Coherent integration length in ms
ParamSim.Ns                        = 40;%Oversampling factor(NS minimum 10 in case of 10.23e6 ChirpRate, because Fs has to be equal or bigger than the chirprate) 
ParamSim.Fs                        = ParamSim.Ns*1.023*1e6;%Sampling frequency (taking maximum ChirpRate)
ParamSim.SamplesPerms              = ParamSim.Fs*1e-3*(ParamGNSS.SF/1023);
ParamSim.TotalSamples              = round(ParamSim.Nc*ParamSim.SamplesPerms);%Total number of samples per iteration
ParamSim.PdfBasedMethod_true       = 1;
ParamSim.CFAMethod_true            = 1;
ParamSim.StatisticalMethod_true    = 1;
ParamSim.Load_threhold_true        = 0;
ParamSim.EstimatedCNR_true         = 1;


%Plots enabled
ParamSim.PlotCheckfiles_true    = 0;
ParamSim.TestStatisticPlot_true = 1;
ParamSim.EffectiveCNRPlot_true  =1;

if option == 2
   
    ParamSim.DataTypeStr      = 'int16';
    ParamSim.Nc               = 5;%Coherent integration length in ms
    ParamSim.Ns               = 10;%NO Oversampling factor?
    ParamSim.Fs               = 20e6;%Sampling frequency of the recorded data
    ParamSim.TimeToDiscard    = 60;%seconds of the date to discard at the begining
    ParamSim.SamplesToDiscard = ParamSim.TimeToDiscard*ParamSim.Fs*2;
    ParamSim.SamplesPerms     = ParamSim.Fs*1e-3*(ParamGNSS.SF/1023);
    ParamSim.TotalSamples     = round(ParamSim.Nc*ParamSim.SamplesPerms);%Total number of samples per iteration

    pos=1;
    for scenario=[ParamGNSS.ScenarioVec]%determine the parameters according tot he specified spcenarios
        
         switch scenario 
        %Files and path location for each signal (acording to specified number of cases)
        case 1
            fileNameGNSS = 'GPSL1_2019-04-02_16-00-56.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL1+AMtone\';
            fileNameJammer = 'AMtone_2019-04-02_16-00-56.bin';
        case 2
            fileNameGNSS = 'GPSL1_2019-04-02_16-20-58.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL1+Chirp10MHz\';
            fileNameJammer = 'Chirp10MHz_2019-04-02_16-20-58.bin';
        case 3
            fileNameGNSS = 'GPSL1_2019-04-02_16-38-04.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL1+Chirp20MHz\';
            fileNameJammer = 'Chirp20MHz_2019-04-02_16-38-04.bin';
        case 4
            fileNameGNSS = 'GPSL5_2019-04-02_17-36-52.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL5+AMtone\';
            fileNameJammer = 'AMtone_2019-04-02_17-36-52.bin';
        case 5
            fileNameGNSS = 'GPSL5_2019-04-02_17-44-57.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL5+Chirp10MHz\';
            fileNameJammer = 'Chirp10MHz_2019-04-02_17-44-57.bin';
        case 6
            fileNameGNSS = 'GPSL5_2019-04-02_17-52-44.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GPSL5+Chirp20MHz\';
            fileNameJammer = 'Chirp20MHz_2019-04-02_17-52-44.bin';
        case 7
            fileNameGNSS = 'GALE1_2019-04-02_16-55-33.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GALE1+AMtone\';
            fileNameJammer = 'AMtone_2019-04-02_16-55-33.bin';
        case 8
            fileNameGNSS = 'GALE1_2019-04-02_17-03-21.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GALE1+Chirp10MHz\';
            fileNameJammer = 'Chirp10MHz_2019-04-02_17-03-21.bin';
        case 9
            fileNameGNSS = 'GALE1_2019-04-02_17-11-08.bin';
            pathName = 'S:\81105_Gateman\recorded_data\20MS_s-16bit\GALE1+Chirp20MHz\';
            fileNameJammer = 'Chirp20MHz_2019-04-02_17-11-08.bin';
         end
         ParamSim.FileNameGNSS{pos}   = fileNameGNSS;
         ParamSim.FileNameJammer{pos} = fileNameJammer;
         ParamSim.PathName{pos}       = pathName;
         pos=pos+1;
         
    end
    
end