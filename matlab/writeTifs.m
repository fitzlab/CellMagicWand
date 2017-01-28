function [ ] = writeTifs(tifSet, outDir)

if ~exist(outDir,'dir')
    mkdir(outDir);
end

%delete any tifs sitting in this dir
files = dir(outDir);
for i=1:length(files)
    if strendswith(files(i).name,'.tif')
        delete([outDir, '/', files(i).name]);        
    end
end

[x y z] = size(tifSet);
for i=1:z
    filename = [outDir, '/', num2str(i, '%04i'), '.tif'];
    imwrite(uint16(squeeze(tifSet(:,:,i))),filename,'tif');
end
