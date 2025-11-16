
function y = randwalk(N, sigma, start)
%RANDWALK Gaussian random walk
%   y(k) = y(k-1) + sigma*randn
    if nargin < 2, sigma = 1.0; end
    if nargin < 3, start = 0.0; end
    y = zeros(N,1);
    y(1) = start;
    if N >= 2
        y(2:end) = cumsum(sigma*randn(N-1,1)) + start;
    end
end
