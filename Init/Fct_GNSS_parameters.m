function ParamGNSS = Fct_GNSS_parameters(Option)

%% General Parameters
    ParamGNSS.IF_freq_MHz         = 0*1e6;
    ParamGNSS.LoadPrnCode_True    = 0;%flag to choose if generate the prn sequence or load it from a previously recorded file
    ParamGNSS.F_symbols           = 50;%Data rate in bps, CHECK FOR REST OF SIGNALS!!
    ParamGNSS.CNR_dBHz            = rand(1,1)*25+25; %Vector/Scalar with CNR; here random between 25 and 50
    ParamGNSS.CNR_dBHz_Length     = length([ParamGNSS.CNR_dBHz]);
%% Only Simulated data
if Option==1
    ParamGNSS.GNSS_Band           = {'E1OS'};  %{'L1CA', 'L5', 'E1OS'};%List of available GNSS signals: 'L1CA', 'L5', 'E1OS', 'E5'
    ParamGNSS.GNSS_Signals_Length = length(ParamGNSS.GNSS_Band);
    ParamGNSS.SV_Length           = 1;%Number of SV in view during simulation
    ParamGNSS.SV_Number           = randi(30, ParamGNSS.SV_Length , ParamGNSS.GNSS_Signals_Length);

%% Only In-lab validation data
else 
    ParamGNSS.SV_Length           = 1;%The recorded signal only contains one SV
    ParamGNSS.ScenarioVec         = [2];%1=AM+GPSL1, 2=Chirp10+GPSL1, 3=Chirp20+GPSL1, 4=AM+GPSL5, 5=Chirp10+GPSL5, 
                                         %6=Chirp20+GPSL5, 7=AM+GALE1, 8=Chirp10+GALE1, 96=Chirp20+GALE1, 
    ParamGNSS.ScenarioVec_Length = length([ParamGNSS.ScenarioVec]);
    pos=1;
    for scenario=[ParamGNSS.ScenarioVec]%determine the parameters according tot he specified spcenarios
        
         switch scenario 
        %Files and path location for each signal (acording to specified number of cases)
        case 1
            nameGNSS = 'GPS L1';
            nameJammer = 'AM tone';
            sv_number = 4;
            gnss_band = 'L1CA';
        case 2
            nameGNSS = 'GPS L1';
            nameJammer = 'Chirp 10 MHz';
            sv_number = 4;
            gnss_band ='L1CA';
        case 3
            nameGNSS = 'GPS L1';
            nameJammer = 'Chirp 20 MHz';
            sv_number = 4;
            gnss_band = 'L1CA';
        case 4
            nameGNSS = 'GPS L5';
            nameJammer = 'AM tone';
            sv_number = 4;
            gnss_band = 'L5';
        case 5
            nameGNSS = 'GPS L5';
            nameJammer = 'Chirp 10 MHz';
            sv_number = 4;
            gnss_band = 'L5';
        case 6
            nameGNSS = 'GPS L5';
            nameJammer = 'Chirp 20 MHz';
            sv_number = 4;
            gnss_band = 'L5';
        case 7
            nameGNSS = 'GAL E1';
            nameJammer = 'AM tone';
            sv_number = 14;
            gnss_band = 'E1OS';
        case 8
            nameGNSS = 'GAL E1';
            nameJammer = 'Chirp 10 MHz';
            sv_number = 14;
            gnss_band = 'E1OS';
        case 9
            nameGNSS = 'GAL E1';
            nameJammer = 'Chirp 20 MHz';
            sv_number = 14;
            gnss_band = 'E1OS';
            case 10
            nameGNSS = 'GPS L1';
            nameJammer = 'AM tone';
            sv_number = 4;
            gnss_band = 'L1CA';
         end
         ParamGNSS.NameGNSS{pos}      = nameGNSS;
         ParamGNSS.NameJammer{pos}    = nameJammer;
         ParamGNSS.SV_Number(pos)     = sv_number;
         ParamGNSS.GNSS_Band{pos}     = gnss_band;
         pos=pos+1;
         
    end
    ParamGNSS.GNSS_signals_Length = length(ParamGNSS.GNSS_Band);
end

%Initialize vectors;
ParamGNSS.CarrierFrequencyGNSS_Hz = NaN*ones(1,length(ParamGNSS.GNSS_Band));
ParamGNSS.SF                      = NaN*ones(1,length(ParamGNSS.GNSS_Band));
ParamGNSS.ChipRate_Hz             = NaN*ones(1,length(ParamGNSS.GNSS_Band));

for gnssband=1:length(ParamGNSS.GNSS_Band)
    if strcmp(ParamGNSS.GNSS_Band(gnssband),'L1CA')

        ParamGNSS.CarrierFrequencyGNSS_Hz(gnssband) = 1.57542e+9;
        ParamGNSS.SF(gnssband)                      = 1023;%Spreading Factor
        ParamGNSS.ChipRate_Hz(gnssband)             = 1.023*1e6;

    elseif strcmp(ParamGNSS.GNSS_Band(gnssband),'E1OS') || strcmp(ParamGNSS.GNSS_Band(gnssband),'E1OS+') || strcmp(ParamGNSS.GNSS_Band(gnssband),'E1OS_B') || strcmp(ParamGNSS.GNSS_Band(gnssband),'E1OS_C')

        ParamGNSS.CarrierFrequencyGNSS_Hz(gnssband) = 1.57542e+9;
        ParamGNSS.SF(gnssband)                      = 4092;%Spreading Factor
        ParamGNSS.ChipRate_Hz(gnssband)             = 1.023*1e6;

    elseif strcmp(ParamGNSS.GNSS_Band(gnssband),{'L5',}) || strcmp(ParamGNSS.GNSS_Band(gnssband),{'L5+'})

        ParamGNSS.CarrierFrequencyGNSS_Hz(gnssband) = 1.117642e+9;
        ParamGNSS.SF(gnssband)                      = 1023;%Spreading Factor
        ParamGNSS.ChipRate_Hz(gnssband)             = 10.023*1e6;

    elseif strcmp(ParamGNSS.GNSS_Band(gnssband),'E5')

        ParamGNSS.CarrierFrequencyGNSS_Hz(gnssband) = 1.117642e+9;
        ParamGNSS.SF(gnssband)                      = 10230;%Spreading Factor
        ParamGNSS.ChipRate_Hz(gnssband)             = 10.023*1e6;
    else
        error('undefined frequency band frequency, please define it')
    end
end

