function I = getPeakInclusionImage(xs, peakHgts, peakLocs, peakWids, peakPrms, peakScores)
wd = length(xs);
if length(peakHgts)==1
    peakHgts = 1;
    peakPrms = 1;
    peakScores = 1;
else
    peakHgts = repmat(rescale(peakHgts', 0, 1), 1, wd);
    peakPrms = repmat(rescale(peakPrms', 0, 1), 1, wd);
    peakScores = repmat(rescale(peakScores', 0, 1), 1, wd);

    peakLocs = repmat(peakLocs', 1, wd);
    peakWids = repmat(ceil((2\peakWids))', 1, wd);
end

facts = (peakWids-min(peakWids,abs(double(xs) - peakLocs))) ./ peakWids;
I = normalize(sum(facts .* (peakHgts + peakPrms + 3*peakScores), 1), 'range');
end