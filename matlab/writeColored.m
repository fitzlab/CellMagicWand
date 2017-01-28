function [ ] = writeColored(tifSet, dir)
%writes a series of colored jpgs

if ~exist(dir,'dir')
    mkdir(dir);
end

[x y z colors] = size(tifSet);
for i=1:z
    filename = [dir, '/', num2str(i, '%04i'), '.tif'];
    imwrite(uint8(squeeze(tifSet(:,:,i,:))),filename,'tif');
end
