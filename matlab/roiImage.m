derivTifs = readTifs('derivTifs');
roiTifs = zeros(size(derivTifs));


[height,width,numFrames] = size(derivTifs);

for t=1:numFrames
    roiTif = zeros(height,width);
    for r=1:size(roiCoords,1)
        if t ~= roiCoords(r,3)
            continue;
        end
        x=roiCoords(r,2);
        y=roiCoords(r,1);
        roiTif(x,y) = 65535;
    end
    cross = [
        0 0 1 0 0;
        0 0 1 0 0;
        1 1 1 1 1;
        0 0 1 0 0;
        0 0 1 0 0;
        ];
    se = strel('arbitrary', cross);
    roiTif = imdilate(roiTif, se);
    roiTifs(:,:,t) = roiTif;
end
writeTifs(roiTifs,'roiTifs');