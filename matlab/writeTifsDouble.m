function [ ] = writeTifsDouble(tifSet, dir)
%WRITETIFS Summary of this function goes here
%   Detailed explanation goes here
if ~exist(dir,'dir')
    mkdir(dir);
end

[x y z] = size(tifSet);
for i=1:z
    filename = [dir, '/', num2str(i, '%04i'), '.tif'];
    imwrite(squeeze(tifSet(:,:,i)),filename,'tif');
end
