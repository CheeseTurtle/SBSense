function [I,xs1,res1,xs2,res2,msk1,msk2] =  imadjlog(I) %, logBase)
arguments(Input)
     I {mustBeNumeric};
     % logBase=10;
 end
prcts = prctile(I, [5 25 50 75 95], 'all', 'Method', 'exact');

mid = sum(prcts([2 3 4]).*[3;2;1], 'all', 'omitnan')/6;
loSpan = mid - prcts(1);
hiSpan = prcts(5) - mid;

% I(I<prctile(1)) = prcts(1);
% I(I>prctile(5)) = prcts(5);
% I = min(prcts(5), max(I, prcts(1)));

msk2 = I>mid;
msk1 = I<mid;

if isinteger(I)
    max2 = intmax(class(I));
    mid2 = idivide(max2, 2, 'fix');
else
    mid2 = 0.5;
    max2 = 1.0;
end

n = numel(I);
xs = 1:n;
xs1 = xs(msk1); xs2 = xs(msk2);
res1 = mid2 - mid2*10.^((loSpan\(mid-max(prcts(1), I(msk1)))) - 1);
res2 = mid2 + (max2-mid2)*10.^(hiSpan\((min(I(msk2), prcts(5)) - mid)) - 1);

% figure(2);
% cla;
% yyaxis left;
% plot(xs(msk1), res1, ...
%     xs(msk2), res2);
% hold on;
% yyaxis right;
% plot(xs, I(:));
% hold off;

I(msk1) = res1;
I(msk2) = res2;
end