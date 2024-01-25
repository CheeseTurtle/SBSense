fpath = "C:\\Users\\stan\\Documents\\code\\temp_mmf.bin";
imgDims = [3840 2160];
numSlots = 60;


%%
if exist("mmf", "var") && isobject(mmf)
    clearvars mmf;
end
fhandle = fopen(fpath, 'w');
try
    zs = false(imgDims, 'logical');
    for i=1:numSlots
        % fwrite(fhandle, uint64(0), "uint64");
        % fwrite(fhandle, double(0), "double");
        % fwrite(fhandle, uint8(zs), 'uint8');
        % fwrite(fhandle, single(zs), 'single');
        % fwrite(fhandle, zs, 'ubit1');
        % fwrite(fhandle, zs, 'ubit1');
        fwrite(fhandle, uint64(0), "uint64");
        fwrite(fhandle, double(0), "double");
        fwrite(fhandle, single(zs), 'single');
    end
catch ME
    try
        fclose(fhandle);
    catch
    end
    rethrow(ME);
end
fclose(fhandle);
%%
fmt = { 'uint64', [1 1], 'Index' ; ...
         'double', [1 1], 'Secs' ; ...
         'uint8',  imgDims, 'Y1' ; ...
         'single', imgDims, 'Yr' ; ...
         'uint8',  [3840 270], 'Mask1Bytes' ; ... % 2160 / 8 = 270
         'uint8', [3840 270], 'Mask2Bytes' }; % 3840 / 8 = 480
mmf = memmapfile(fpath, ...
    'Format', fmt, 'Writable', true, 'Offset', 0, ...
    'Repeat', numSlots);
d = mmf.Data;


%%

% msk1_bytes = randi(255, [3840 270], 'uint8');
% msk2_bytes = randi(255, [3840 270], 'uint8');
msk1_bits = logical(randi(2, imgDims) - 1);
msk2_bits = logical(randi(2, imgDims) - 1);
msk1_bytes = bitsToUint8(msk1_bits);
msk2_bytes = bitsToUint8(msk2_bits);
% msk1_bits = sbsense.utils.uint8ToBits(msk1_bytes);
% msk2_bits = sbsense.utils.uint8ToBits(msk2_bytes);


testdat = struct( ...
    'Index', uint8(2), ...
    'Secs', double(2.5), ...
    'Y1', randi(255, imgDims, 'uint8'), ...
    'Yr', rand(imgDims, 'single'), ...
    'Mask1Bytes', msk1_bytes, ...
    'Mask2Bytes', msk2_bytes ...
);

d(3).Index = testdat.Index;
d(3).Secs = testdat.Secs;
d(3).Y1 = testdat.Y1;
d(3).Yr = testdat.Yr;
d(3).Mask1Bytes = testdat.Mask1Bytes;
d(3).Mask2Bytes = testdat.Mask2Bytes;

msk1 = sbsense.utils.uint8ToBits(d(3).Mask1Bytes);
msk2 = sbsense.utils.uint8ToBits(d(3).Mask2Bytes);

disp([isequal(msk1_bits,msk1), isequal(msk2_bits, msk2)]);
