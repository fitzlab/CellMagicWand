function [ img ] = seedPointImage( seeds, imgWidth, imgHeight )
% displays the seed positions on an image

img = zeros(imgWidth, imgHeight);
for s=1:length(seeds)
    if seeds(s).removed
        img(seeds(s).edgeSeedPoint(1), seeds(s).edgeSeedPoint(2)) = 2;
        continue;
    end
    img(seeds(s).edgeSeedPoint(1), seeds(s).edgeSeedPoint(2)) = 1;
end

strelMatrix = [
    0 0 1 0 0
    0 0 1 0 0
    1 1 1 1 1
    0 0 1 0 0
    0 0 1 0 0
    ];

img = imdilate(img, strel('arbitrary',strelMatrix));
    
end

