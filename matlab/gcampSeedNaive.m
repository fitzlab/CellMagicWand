% just going to try putting a seed point down every 10 pixels
% Attempt to find a cell at each seed point
% recenter at each step; accept recenter if score improves
% iterate to convergence

seedInterval = 30;

tif = imread('dfFProjCorr.tif');
[width height] = size(tif);

startX = mod(width, seedInterval) / 2;
startY = mod(height, seedInterval) / 2;
s=1;
clear seeds;
for x=startX:seedInterval:width
    for y=startY:seedInterval:height
        seeds(s).edgeSeedPoint = [x y];
        seeds(s).removed = 0;
        seeds(s).finished = 0;
        seeds(s).score = 0;
        seeds(s).outlineX = [];
        seeds(s).outlineY = [];
        s=s+1;
    end
end
% 
% seeds(1).edgeSeedPoint = [185 360];
% seeds(1).removed = 0;

% Take the polar image at each seed point
%figure, imagesc(seedPointImage(seeds, width, height));

%figure, imagesc(seedPointImage(seeds, width, height));
% figure, imagesc(seedPointImage(seeds, width, height));
iterations = 10;
for k=1:iterations %iterate
    for s=1:length(seeds)
        if seeds(s).removed==1 || seeds(s).finished==1
            continue;
        end
        
        seedStats = gcampSeedStats(seeds(s),tif);
        
        if seedStats.edgeGap > 1 || seedStats.inBounds == 0
            %this seed is no good, mark it for removal
            seeds(s).removed = 1;
            continue;
        end
        
        if seedStats.score > seeds(s).score
            seeds(s).edgeSeedPoint(1) = round(mean(seedStats.enclosedY));
            seeds(s).edgeSeedPoint(2) = round(mean(seedStats.enclosedX));
            seeds(s).outlineX = seedStats.outlineX;
            seeds(s).outlineY = seedStats.outlineY;
            seeds(s).score = seedStats.score;
        else
            seeds(s).finished = 1;
        end
            
    end
    
%     figure, imagesc(seedPointImage(seeds, width, height));
end

%draw cellOutline image
cellOutline = zeros(size(tif));
for s=1:length(seeds)
    X=seeds(s).outlineX;
    Y=seeds(s).outlineY;
    for j=1:length(X)
        x=Y(j);
        y=X(j);
        cellOutline(x,y) = cellOutline(x,y) + 1;
    end
end

writeDoubleTif(double(cellOutline>0),'cellOutline.tif');
figure, imagesc(cellOutline)

% 
% edgeImg = edge(projImg,'canny',0.1,1);
% imagesc(edgeImg);
% writeDoubleTif(double(edgeImg),'edgeImg.tif');
