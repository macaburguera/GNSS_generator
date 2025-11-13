function [K_factor_dB, PDP_linear] = Initialize_ch_Galileo(av_powers_dB, Rice_exp)


%starting point was :  Three_GPP_Cases.m function of Schumacher;
%now we have only 1 tx and 1 rx, with random number of paths and
%random average powers.
%CALL:
%
% Starting point: (c) Laurent Schumacher, AAU-TKN/IES/KOM/CPK/CSys - February 2002
% Modified: Simona Lohan, March 2004
%uses the functions:
%# correlation.m
%(/home/simona/MATLAB6/MIMO_CH/MATLAB_MIMO/Matlab/work/Correlation_Multiple_Cluster/correlation.m)


%some fixed parameters (doesn't matter the values since we use only
%SISO case)
% Antenna configuration at Node B

%number of paths
Lpaths=length(av_powers_dB);
for l=1:Lpaths,
    PDP_dB_init(l)=av_powers_dB(l);
end;

% Rice factor generation
for l=1:length(Rice_exp)
    if Rice_exp(l)>0,
        K_factor_dB(l)=exprnd(Rice_exp(l),1,1);
    else
        K_factor_dB(l)=-100;
    end;
end;

% PDP in linear values
PDP_linear = [10.^(.1.*PDP_dB_init(1,:))];
% Normalisation of PDP
PDP_linear(1,:) = PDP_linear(1,:)./sum(PDP_linear(1,:));

% Initialisation of the Rice vector
%Rice_matrix = sqrt(10.^(.1*K_factor_dB));

