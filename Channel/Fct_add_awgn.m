function [rx_AWGN, noise_gen]=Fct_add_awgn(input_signal, ParamGNSS, ParamSim, CN0_dBHz, gnssband)

%%Variables allocation              
CNR_dBHz   = CN0_dBHz;   
SF         = ParamGNSS.SF(gnssband);
Ns         = ParamSim.Ns;

%Add AWGN to an input GNSS signal, eg the signal with jamming
SNR_dB    = CNR_dBHz-30;					     
SNR       = 10.^((SNR_dB-10*log10(Ns)-10*log10(SF))/10);
noisestd  = sqrt(1./SNR);
Len_sign  = length(input_signal);
noise_gen = 1/sqrt(2)*(randn(1,Len_sign)+1i*randn(1,Len_sign));
noise_gen = noise_gen/sqrt(mean(abs(noise_gen).^2))*noisestd; 
rx_AWGN   = input_signal+noise_gen;


  