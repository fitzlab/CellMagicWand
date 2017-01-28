function [ tifStack ] = readMultiTif( filename )

info = imfinfo(filename);
num_images = numel(info);
[height,width] = size(imread(filename, 1));
tifStack = zeros(height,width,num_images);
for k = 1:num_images
    tifStack(:,:,k) = imread(filename, k);
end

end

