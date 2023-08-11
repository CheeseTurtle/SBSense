function [ME,ret] = errordisp_test()
A1 = int8(randi(intmax('int8') + int8([-9 0]),10,'single'));
A2 = int32(randi(intmax('int32') + int32([-9 0]),10,'single'));
try
    ret = arrayfun(@(x1,x2) errordisp_test_subfun1a(x1,x2), A1, A2, 'UniformOutput', false);
    ME = [];
catch ERR
    ME = MException('errordisp_test:mainfun:InducedError', 'Error occurred in subfunction.');
    ME = ME.addCause(ERR);
    ret = [];
end
end

function y = errordisp_test_subfun1a(x1,x2)
try
    y = errordisp_test_subfun2a(x1,x2);
catch ME
    if ME.identifier=="MATLAB:mixedClasses"
        ERR = MException('errordisp_test:subfun:InducedError', 'Error induced via subfun2.');
        ERR = ERR.addCause(ME);
        ERR = ERR.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection(...
            'errordisp_test_subfun1a', 'errordisp_test_subfun1b'));
        throwAsCaller(ERR);
    else
        rethrow(ME);
    end
end
end

function y = errordisp_test_subfun1b(x1,x2) %#ok<DEFNU> 
%try
    y = errordisp_test_subfun2b(x1,x2);
%catch ME
%    if ME.identifier=="MATLAB:mixedClasses"
%        ERR = MException('errordisp_test:InducedError', 'Error induced via subfun2.');
%        ERR.addCause(ME);
%        throwAsCaller(ERR);
%    else
%        rethrow(ME);
%    end
%end
end


function y = errordisp_test_subfun2a(x1,x2)
y = x1 * x2;
end

function y = errordisp_test_subfun2b(x1,x2)
s1 = sizeof(x1); 
s2 = sizeof(x2);
if s1 < s2
    x1 = cast(x1, class(x2));
elseif s1 > s2
    x2 = cast(x2, class(x1));
end
y = errordisp_test_subfun2a(x1,x2);
end

function numBits = sizeof(x)
xx = typecast(x, 'uint64');
xxx = bitor(xx,bitcomp(xx), "uint64");
numBits = uint8(log2(single(xxx + 1)));
end
