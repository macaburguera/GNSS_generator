
function n = pinknoise(N)
%PINKNOISE Generate 1/f pink-ish noise using Voss-McCartney algorithm (approx).
%   Returns column vector length N, unit variance approximately.
    nrows = 16;
    n = zeros(N,1);
    vals = zeros(nrows,1);
    masks = 2.^(0:nrows-1)';
    for i = 1:N
        % flip a random set of rows
        k = 1 + floor(log2(1+floor(rand()*2^nrows)));
        idx = 1:k;
        vals(idx) = randn(k,1);
        n(i) = sum(vals ./ masks);
    end
    n = n / std(n);
end
