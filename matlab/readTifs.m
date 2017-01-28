function [images] = readTifs(dirname)
imagefiles = dir([dirname '/*.tif']);      
nfiles = length(imagefiles);

%get size of first file
firstImg = imread([dirname '/' imagefiles(1).name]);
[h w] = size(firstImg);

images = uint16(zeros(h,w,nfiles)); %change this to fit img resolution
for ii=1:nfiles
   currentfilename = [dirname '/' imagefiles(ii).name];
   image = imread(currentfilename);
   images(:,:,ii) = image;
end