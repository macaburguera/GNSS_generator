function [FadingMatrixTime_fin, Max_Doppler_shifttrue,fax] = ...
    init_fadingClarke(SamplingRate_Hz,  NumberOfPaths, MobileSpeed_kmh,Nch_samples, CarrierFrequency_Hz)
%
if Nch_samples>1000000
    MobileSpeed_kmh_init = 300;
else
    MobileSpeed_kmh_init = 1000;
end

%interpolation factor to model a lower mobile speed;
interp_vfactor = ceil(MobileSpeed_kmh_init/MobileSpeed_kmh);

% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FadingSamplingTime   = 1/SamplingRate_Hz;
Wavelength_m   = 3e8/CarrierFrequency_Hz;
MobileSpeed_ms       = MobileSpeed_kmh_init/3.6;

FadingOversamplingFactor = Wavelength_m /(FadingSamplingTime*2 * MobileSpeed_ms);

%we need some normalization factors in order to avoid out of memory
%and mismatch errors
if SamplingRate_Hz>2048000*10
    a_factor = 500;
    b_factor = 16;
else
    if SamplingRate_Hz>2048000
        a_factor = 1500;
        b_factor = 200;
    else
        a_factor = 4000;
        b_factor = 200;
    end
end

if MobileSpeed_kmh>=9
    %FadingNumberOfIterations = 4000*FadingOversamplingFactor^2/ ...
    %    Wavelength_m;
    FadingNumberOfIterations = a_factor*FadingOversamplingFactor^2/Wavelength_m;
else
    % FadingNumberOfIterations = 200*FadingOversamplingFactor^2/Wavelength_m;
    FadingNumberOfIterations = b_factor*FadingOversamplingFactor^2/Wavelength_m;
end
% Initialisation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters' conversion
Max_Doppler_shift = MobileSpeed_ms/Wavelength_m;
Max_Doppler_shifttrue = MobileSpeed_kmh/3.6/Wavelength_m;

% Parameters assessment
FadingSamplingTime = Wavelength_m / (2 * FadingOversamplingFactor * ...
    MobileSpeed_ms);

FadingLength  = ceil(FadingNumberOfIterations * FadingSamplingTime* MobileSpeed_ms);

%generation of  Classical Doppler spectrum, at velocity MobileSpeed_ms
CutOff = floor(FadingLength/(2*FadingOversamplingFactor))-1;
tmp = sqrt(1/(pi*FadingLength))...
    ./sqrt((1+1e-9)...
    .*ones(size(1:1:CutOff))-((1:1:CutOff)./CutOff).^2);

FadingMatrixFreq = ones(NumberOfPaths,1)...
    *[tmp(1:CutOff-1),...
    zeros(1,FadingLength-2*CutOff+3),...
    fliplr(tmp(2:CutOff-1))];

% Addition of a random phase
FadingMatrixFreq = FadingMatrixFreq...
    .*exp((2*pi*1i).*rand(NumberOfPaths, ...
    FadingLength));
FadingMatrixTime = ifft(FadingMatrixFreq,FadingLength,2);
% Normalisation to 1
FadingMatrixTime = FadingMatrixTime./sqrt(mean(abs(FadingMatrixTime).^2,2)*...
    ones(1,size(FadingMatrixTime, ...
    2)));

%small correction factor (such that the peak in Doppler spectrum
%corresponds to the Max_Doppler_shif
fax_init=[-SamplingRate_Hz/2:SamplingRate_Hz/size(FadingMatrixTime,2):SamplingRate_Hz/2-SamplingRate_Hz/size(FadingMatrixTime,2)];
[~,xpos] = max(abs(fftshift(fft(FadingMatrixTime(1,:)))));
%correction factor
corr_factor = abs(fax_init(xpos))/Max_Doppler_shift;
TrueSamplingRate_Hz = SamplingRate_Hz/corr_factor;

%Now use interpolation to obtain velocities smaller than 1000 km/h
%(due to memory limitations, it is not possible to model small
%velocities& High sampling rates directly with Schumacher MIMO
%model; that is why interpolation is needed;
xinit = [1:ceil(2*Nch_samples/interp_vfactor)];
xinterp = [1:1/interp_vfactor:ceil(2*Nch_samples/interp_vfactor)];

% a_factor
% size(FadingMatrixTime)
% ceil(2*Nch_samples/interp_vfactor)
yinterp = zeros(1,length(xinterp));
for l = 1:NumberOfPaths
    yinit = FadingMatrixTime(l,1:ceil(2*Nch_samples/interp_vfactor));
    yinterp(l,:) = interp1(xinit,  yinit, xinterp, 'linear');
end
FadingMatrixTime_fin = yinterp(:, 1:Nch_samples);
fft_length = size(FadingMatrixTime_fin,2);
%frequency axis (if we want to plot the Doppler spectrum)
fax = [-TrueSamplingRate_Hz/2:TrueSamplingRate_Hz/fft_length:TrueSamplingRate_Hz/2-TrueSamplingRate_Hz/fft_length];
%example: plot(fax, abs(fftshift(fft(FadingMatrixTime_fin(1,:)))),  'r--');