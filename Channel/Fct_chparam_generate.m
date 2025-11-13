function [L_paths, channel_delays_chip, del, av_powers_dB] = Fct_chparam_generate(ChannelParam, SimParam, xmax, L_paths_max, random_paths_flag)

%% Variables Definition
Ns_NBOC_product    = SimParam.Ns;
Min_delay_in_chips = ChannelParam.Min_delay_in_chips;

if random_paths_flag == 1 
    % generate "dynamic" number of paths
    L_paths = round((L_paths_max-1)*rand(1,1)+1);
else
    % generate "fixed number of paths"
    L_paths = L_paths_max;
end
%% Generate the random delays for each path;

delta_decayPDP      = 2/Ns_NBOC_product;
channel_delays_chip = zeros(1, L_paths);


%when calling the function only with random_paths_flag as input
for k = 1:L_paths
    if k == 1
        channel_delays_chip(k) = rand(1,1) + Min_delay_in_chips + 2;%いいいいいいいいいいいいいいい ASK. before was: rand() + 3
    else
        channel_delays_chip(k) = channel_delays_chip(k-1) + xmax*rand(1,1);
        while  channel_delays_chip(k) == channel_delays_chip(k-1)
            channel_delays_chip(k) = channel_delays_chip(k-1) + xmax*rand(1,1);
        end
    end
end

%generate delays in samples and av power
del                 = zeros(1, L_paths);
av_powers_exp       = zeros(1, L_paths);
for k = 1:L_paths
    if k == 1
       del(k) = round(channel_delays_chip(k)*Ns_NBOC_product);
       av_powers_exp(k) = 1;
    else
       del(k) = round(channel_delays_chip(k)*Ns_NBOC_product);
       av_powers_exp(k) = exp(-delta_decayPDP*(del(k) - del(1)));
    end
end
av_powers_dB = 10*log10(av_powers_exp);
end

