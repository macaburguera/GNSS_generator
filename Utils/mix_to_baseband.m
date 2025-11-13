function y = mix_to_baseband(x, fs, f0_Hz)
if isempty(f0_Hz) || f0_Hz==0
    y = x; return;
end
t = (0:numel(x)-1).' / fs;
y = x .* exp(1j*2*pi*f0_Hz*t);
end
