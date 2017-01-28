% read in images
gradientMag = imread('grdMagMax.tif');
frame = imread('derivMax.tif');
accum = imread('accumMax.tif');

houghCutoff = 50000;
cellDiameterMin = 6;
cellDiameterMax = 12;
scoreThresh = 1.5;
s=1;

% get seed points from local maxima of accumulator
accumThresh = accum > houghCutoff; % this is OK for now; think about it later
CC = bwconncomp(accumThresh);
STATS = regionprops(CC,'Centroid');
cellOutline = zeros(size(gradientMag));
foundCell = false;
for i=1:length(STATS)
    cx = STATS(i).Centroid(2);
    cy = STATS(i).Centroid(1);
    
    seedStats = gcampSeedStats2(cx, cy, frame, gradientMag, cellDiameterMin, cellDiameterMax);
    
    if seedStats.removed==1
        % bad ROI; couldn't fit a circular edge to it. 
        continue;
    end
    if seedStats.score < scoreThresh
        % We managed to fit a circular edge, but it was a crappy one.
        continue;
    end

    % Take the polar image at each seed point
    seeds{s}.edgeSeedPoint = [round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1))];
    seeds{s}.outlineX = seedStats.outlineX;
    seeds{s}.outlineY = seedStats.outlineY;
%     seeds{s}.enclosedX = seedStats.enclosedX;
%     seeds{s}.enclosedY = seedStats.enclosedY;
    seeds{s}.score = seedStats.score;

    %draw cellOutline image for cells with a good score
    X=seeds{s}.outlineX;
    Y=seeds{s}.outlineY;
    for j=1:length(X)
        x=Y(j);
        y=X(j);
        cellOutline(y,x) = 1;
    end

    s=s+1;
    foundCell = true;
end
if foundCell
    disp(['  ' num2str(length(seeds)) ' cell events found.']);
end
writeDoubleTif(cellOutline,'cellOutlineTest.tif');
