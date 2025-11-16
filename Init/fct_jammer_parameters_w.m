function R = fct_jammer_parameters_w(Fs)
% Thin wrapper so newer code can call fct_jammer_parameters(Fs)
% and older code can keep using Fct_Jammer_parameters(Fs).
PJ = Fct_Jammer_parameters(Fs);

% Expose just what the new generator expects from this helper:
R = struct();
R.Fs      = PJ.Fs;
R.burst   = PJ.helpers.burst;
R.wander  = PJ.helpers.wander;

% Also pass through ranges in case you want them there:
R.CNR_dBHz_rng = PJ.helpers.CNR_dBHz_rng;
R.JSR_dB_rng   = PJ.helpers.JSR_dB_rng;
end
