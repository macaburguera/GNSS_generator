function ParamChannel = Fct_Channel_parameters(ParamGNSS, ParamJam)

%% Static/Fading channel
ParamChannel.Static_channel_true = 1;%Flag that determines if the static channel [1] instead of fading channel [0] (mainly for testing purpose)

%% Parameters regarding the movements
ParamChannel.Speed_GNSS_SV_kmh  = 14000 / 3.6; % assuming 14000km/h 
ParamChannel.Speed_aircraft_kmh = 140*1.852; % 140 knots (approach airspeed), 500 knots (cruising). Aircraft speed max is 900 km/h. 1,852 is the conversion factor
ParamChannel.Speed_jammer_kmh   = 0;%Static or slow moving jammer
ParamChannel.C                  = 3*1e+8;%Light speed: %m/s

%% Common Parameters
ParamChannel.Small_freqerr         = 0;
%% Parameters regarding the GNSS channel
ParamChannel.Type_chS2A            = 'rician';%'rician', 'rayleigh', 'nakagami'
ParamChannel.Correl_typeS2A        = 'zero';%correl_type='exponential'; if correl_type is 'zero',  the values of the
ParamChannel.Rho_correlS2A         = 0.9;
ParamChannel.Alpha_correlS2A       = 0.1;% for 'exponential' only 
ParamChannel.Rice_exp1S2A          = 1;%Rician (or Nakagami) factor of first path; the others are 0 and generated inside the loop
ParamChannel.XmaxS2A               = 0.75;%Maximum separation between two consecutive delays in chips 
ParamChannel.L_paths_maxS2A        = 1;
ParamChannel.Random_path_flagS2A   = 0;%If 1, we generate random number of paths at each iteration
ParamChannel.Min_delay_in_chips    = 0;
ParamChannel.Max_delay_in_chips    = max([1 ParamChannel.XmaxS2A])*ParamChannel.L_paths_maxS2A+20;
ParamChannel.Max_Doppler_S2A       = (ParamChannel.Speed_GNSS_SV_kmh/3.6/3e8)*ParamGNSS.CarrierFrequencyGNSS_Hz+ParamGNSS.IF_freq_MHz;
ParamChannel.FDest                 = ParamChannel.Small_freqerr + ParamChannel.Max_Doppler_S2A; 

%% Parameters regarding jammer channel
ParamChannel.Type_ch_jammerG2A     = 'rician';%'rician', 'rayleigh', 'nakagami'
ParamChannel.Correl_typeG2A        = 'exponential';%correl_type='exponential'; if correl_type is 'zero',  the values of the
ParamChannel.Rho_correlG2A         = 0.7;
ParamChannel.Alpha_correlG2A       = 0.4;% for 'exponential' only 
ParamChannel.Rice_exp1_jammerG2A   = 4;%Rician (or Nakagami) factor of first path; the others are 0 and generated inside the loop 
ParamChannel.Xmax_jammerG2A        = 1;%Maximum separation between two consecutive delays in chips
ParamChannel.L_paths_max_jammerG2A = 5;% only LOS path for GNSS (flat fading) 
ParamChannel.Random_path_flagG2A   = 0;%If 1, we generate random number of paths at each iteration
ParamChannel.Max_Doppler_G2A = (ParamChannel.Speed_aircraft_kmh/3.6/3e8)*ParamJam.JammerCarrierFreq_Hz; %this is the max doppler shift 
