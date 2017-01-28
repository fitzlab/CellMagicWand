function [outputDir] = fftBandpass(inputDir, minCutoff, maxCutoff)

% runs FFT bandpass on a dir of images
% this executes a Java program.

%params
outputDir = ['./fftFiltered'];
codeDir = '.';

inputImages = dir([inputDir '/*.tif']); 

%check if preprocessing was already done
alreadyDone = 0;
try
    filteredfiles = dir([outputDir '/*.tif']);  
    if length(filteredfiles) >= length(inputImages)-1
       %1 file is allowed to be missing (reference image file).
       alreadyDone = 1;
    end
catch
    %if this hit an exception, the files didn't exist
end

% if not done, run
if ~alreadyDone
    mkdir(outputDir);
    delete([outputDir '/*.tif']);
    for i=1:length(inputImages)
        %we can't handle spaces; remove them if they exist.
        newName = strrep(inputImages(i).name, ' ', '');
        if ~strcmp(inputImages(i).name,newName)
            movefile([inputDir '/' inputImages(i).name], [inputDir '/' newName]);
        end
        
        if mod(i,10) == 0
            disp([num2str(i) ' of ' num2str(length(inputImages)) ' images filtered']);
        end
        if strfind(newName, 'Reference')
            %We don't use the reference image for anything; skip it
            continue; 
        end
        infile = [inputDir '/' newName];
        outfile = [outputDir '/' newName];
        cmd = ['java -jar ' codeDir '/java-image-fft/TwoPhotonTools.jar fft-bandpass ' infile ' ' outfile ' -filterSmall ' num2str(minCutoff) ' -filterLarge ' num2str(maxCutoff)];
        %disp(cmd);
        dos(cmd);
    end
end
