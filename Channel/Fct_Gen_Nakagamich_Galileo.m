function [NakaChannelCoefficients, Max_Doppler_shift,fax]=Fct_Gen_Nakagamich_Galileo(SamplingRate_Hz,...
						  CarrierFrequency_Hz, ...
						  MobileSpeed_kmh, No_of_stored_ChannelSamples, ...
						  av_powers_dB, correl_type,rho_correl, alpha_correl,type_ch, parameter_ch)

%Fading channel generation for Galileo models; Nakagami-m channels (type_ch='nakakami', parameter_ch=m_naka)
%Rayleigh (type_ch='rayleigh', parameter_ch can be anything) and
%Rician (type_ch='Rician', parameter_ch=Rice_exp) are particular cases; 
%correlated fading case included; starting point is the Clarke Doppler spectrum
%
%OUTPUTS:
%ChannelCoefficients_correlated1 =2-D matrix of correlated Fading coefficients, size L x
%                                 No_of_stored_ChannelSamples;
%                                 L=number of channel paths 
%Max_Doppler_shift               = Maximum Doppler shift or spread,
%                                  due to the TERMINAL Velocity 
%fax                              =frequency axis; needed if we
%                                  want to plot the Doppler spectrum.
%INPUTS:
% SamplingRate_Hz                 = SamplingRate; e.g., for Galileo
%                                  SamplingRate_Hz=chip_rate*Ns,
%                                  where chip_rate =10.23e+6 Hz
%                                  (for example), and Ns=
%                                  oversampling factor (typically
%                                  an integer >=1); the sampling
%                                  rate fixes the rate of change of
%                                  the channel 
% CarrierFrequency_Hz             = CarrierFrequency, e.g, for
%                                   Galileo is between 1e+9 and
%                                   2e+9, e.g. around 1.18e+9 for E5
% MobileSpeed_kmh                  = the relative  Speed between tx and
%                                     receiver
%                                  the speed value
%                                  determines the maximum Doppler
%                                  spread 
% No_of_stored_ChannelSamples     = number of channel coefficients generated
%                                 for each random realization; the total number of channel values
%                                 will be No_of_stored_ChannelSamples;
%                                 %No_of_stored_ChannelSamples should be high enough
%                                 (higher than 500) if correlated fading is
%                                 wanted; otherwise there might be some errors
%                                 introduced)
% av_powers_dB                   = vector of  average tap powers of
%                                  all channel taps (in dB)
%                                  size 1 x NumberOfPaths;
%The following three parameters are used only if we want to model
%correlated fading; for uncorrelated fading, we can keep them as:
%correl_type ='zero', rho_correl =1, alpha_correl=1
% correl_type                    = type of the correlation (string
%                                  value: 'exponential' or 'constant' or 'zero' (no correlation)
% rho_correl                     = Envelope correlation coefficient
%                                  rho (scalar); it gives
%                                 the values used for 'exponential' (i.e., rho^(alpha*i) or
%                                 'constant' (i.e., rho) correlation coefficients; should be
%                                  less than 1
% alpha_correl                   = the power value  used for    'exponential'
%                                  correlation coefficients
%                                  (i.e. in    rho^(alpha*i)) 
%type_ch      =channel type, can be 'rayleigh', rician' or 'nakagami'
%parameter_ch  =channel parameter: doesn't matter if type_ch='rayleigh', it is
%equal with Rice_exp if 'rician', and equal to M_Naka' if 'nakagami'

if strcmp(type_ch,'rayleigh')||strcmp(type_ch,'nakagami')
    Rice_exp=zeros(1,length(av_powers_dB)); %in Nakagami case, the channel is first initialezd to Rayleigh, then a
    %transform is applied
else
    if strcmp(type_ch,'rician')
        %if channel is 'rician', only the first path is Rician, the others
        %are Rayleigh-distributed
        Rice_exp=[parameter_ch zeros(1,length(av_powers_dB)-1)];
    end
end

[K_factor_dB, PDP_linear] = Initialize_ch_Galileo(av_powers_dB, Rice_exp);
PDP_dB_init=10*log10(PDP_linear);
NumberOfPaths=length(av_powers_dB);

[FadingMatrix, Max_Doppler_shift,fax] = ...
    init_fadingClarke(SamplingRate_Hz,  NumberOfPaths, MobileSpeed_kmh, ...
		      No_of_stored_ChannelSamples, CarrierFrequency_Hz);
%normalize the power of the rows of FadingMatrix;
for ll=1:size(FadingMatrix,1)
  FadingMatrix(ll,:)=FadingMatrix(ll,:)/sqrt(mean(abs(FadingMatrix(ll,:)).^2));
end
%plot(abs(FadingMatrix(1,:))); hold on; plot(abs(FadingMatrix(2,:)),'r--'); ...
%    drawnow; pause(0.1); hold off; 

% Initalisation of normalisation diagonal matrix
pdp_coef = [];
for ii = 1:size(PDP_linear,2)
  pdp_coef = [pdp_coef, sqrt(PDP_linear(1,ii)).*ones(1,size(FadingMatrix,1)/size(PDP_linear,2))];
end
% Normalisation of the correlated fading processes
FadingMatrix= diag(pdp_coef)*FadingMatrix;

% Addition of the Rice component on the first path 
Rice_meanampl = sqrt(10.^(.1*K_factor_dB));
L_vector = size(FadingMatrix,2);
%generate random Rice means, such that their amplitude is equal to  Rice_meanampl 

%CASE 1: different Rician means at each sample; the result will be
%some noisy variation around a fading trend; maybe it's not the
%best model
%for ll=1:NumberOfPaths,
%  if Rice_meanampl(ll)<1e-4,
%    Rice_vector(ll,:)=zeros(1,L_vector); %Rayleigh fading
%  else
%    Xpart=rand(1,L_vector)*Rice_meanampl(ll);%Rician fading
%    Ypart=sqrt(Rice_meanampl(ll)^2-Xpart.^2);
%    Rice_vector(ll,:)=Xpart+sqrt(-1)*Ypart;
%  end;
%end;

%CASE 2: the means are constant for all the samples; 
Rice_vector=zeros(NumberOfPaths, L_vector);
for ll=1:NumberOfPaths,
  if Rice_meanampl(ll)<1e-4,
    Rice_vector(ll,:)=zeros(1,L_vector); %Rayleigh fading
  else
    Xpart=randn(1,1);
    while sqrt(Rice_meanampl(ll)^2-Xpart.^2)<0,
      Xpart=randn(1,1);
    end;
    Ypart=sqrt(Rice_meanampl(ll)^2-Xpart.^2);
    Rice_vector(ll,:)=(Xpart+sqrt(-1)*Ypart)*ones(1,L_vector);
  end;
end;

    
FadingMatrix_Rice = FadingMatrix + Rice_vector;
% Sum over all paths equal to 1
FadingMatrix_Rice= FadingMatrix_Rice./sqrt((sum(sum(abs(FadingMatrix_Rice).^2))/size(FadingMatrix_Rice,2)));

ChannelCoefficients(1:NumberOfPaths,:)=  FadingMatrix_Rice;
av_powers_dB1(1:NumberOfPaths)=transpose(PDP_dB_init);
ChannelCoefficients_correlated= Coloured_noise(ChannelCoefficients, correl_type, av_powers_dB1, rho_correl, alpha_correl);  

ChannelCoefficients_correlated1=ChannelCoefficients_correlated(:,1: No_of_stored_ChannelSamples);

%in channel is Nakagami, apply Beaulieu transform
if strcmp(type_ch,'nakagami'),
    M_Naka=parameter_ch;
    Naka_5coeff=Naka_Beaulieu_coeff(M_Naka);
    for ll=1:size(ChannelCoefficients_correlated1,1),
        [Phase, Ampl]=cart2pol(real(ChannelCoefficients_correlated1(ll,:)), ...
			 imag(ChannelCoefficients_correlated1(ll,:))); 
         sigmar=mean(Ampl.^2);
         r=1-exp(-(Ampl).^2/(2*sigmar));
         eta1=sqrt(-2*sigmar*log(1-r)).^(1/M_Naka);
         Naka_ampl=eta1+(Naka_5coeff(1)*eta1+Naka_5coeff(2)*eta1.^2+ ...
		   Naka_5coeff(3)*eta1.^3)./(1+Naka_5coeff(4)*eta1+Naka_5coeff(5)*eta1.^2);

      [xtemp, ytemp]=pol2cart(Phase, Naka_ampl);
      NakaChannelCoefficients(ll,:)=xtemp+j*ytemp;
  end;
else, %we do not need m_naka
   NakaChannelCoefficients=ChannelCoefficients_correlated1;
end;
