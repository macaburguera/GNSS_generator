function [rx_fading] = Fct_add_ch_to_inputsig(input_signal, alpha_ch, del, Max_Doppler_shift, signal_duration_ms)

%% adds multipath fading channel effect to the input signal
    
         
Len_sign = length(input_signal);

%1. add channel effect 
L_paths = size(alpha_ch,1);
path_pow = zeros(1,L_paths);
%normalize path powers
for l = 1:L_paths
    path_pow(l) = mean(abs(alpha_ch(l,:)).^2);
end
alpha_ch = alpha_ch/sqrt(sum(path_pow));

rx_fading_nonoise = 0;
for l = 1:L_paths
    rx_ch = input_signal.*alpha_ch(l,:); 
    rx_fading_nonoise = rx_fading_nonoise+[zeros(1,del(l)) rx_ch(1,1:end-del(l))];
end
%%2. normalize signal after fading channel to unit power; so that C/N0 is with
%%respect to unit power signal
rx_fading_nonoise=rx_fading_nonoise/sqrt(mean(abs(rx_fading_nonoise).^2));


%3. add Doppler shift
%%Len_sign corresponds to signal_duration_ms, thus a sample means
%(signal_duration_ms*1e-3)/Len_sign seconds
rx_fading = rx_fading_nonoise.*exp(-1i*2*pi* Max_Doppler_shift*[1:Len_sign]*(signal_duration_ms*1e-3)/Len_sign );   


   

