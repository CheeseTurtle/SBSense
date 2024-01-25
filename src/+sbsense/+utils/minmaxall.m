function [mn mx] = minmaxall(A)
mn = min(A, [], "all");
mx = max(A, [], "all");
end