function chips = prn_mseq(L)
% Minimal m-sequence generator (length >> L). 10-stage LFSR, poly x^10 + x^3 + 1
reg = ones(1,10);
chips = zeros(L,1);
for n = 1:L
    chips(n) = 2*reg(end)-1;
    fb = xor(reg(10-10+1), reg(10-3+1)); % taps 10 and 3
    reg = [fb, reg(1:end-1)];
end
end
