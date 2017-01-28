function [ seed ] = gcampSeedStats( seed, cellTif, cellDiameterMin, cellDiameterMax )
    % Calculates statistics of a neun seed
    % requires only that the seed structure contain a centroid
    [width height] = size(cellTif);
    
    cx = seed.edgeSeedPoint(2);
    cy = seed.edgeSeedPoint(1);

    % make polar image and find edge of cell
    % polar image construction parameters
    polarAngles = 180;
    [img, polarEdge, polarTif, edgeValues] = gcampDrawPolarEdgeGradient(cellTif, cx, cy, polarAngles, cellDiameterMin, cellDiameterMax);
    polarTif = cellTif;
    
    polarDist = round(cellDiameterMax/2) + 5;
    
    %calculate how polar edge fits back into original tif
    startX = cx-polarDist-1;
    startY = cy-polarDist-1;

    [X,Y] = ind2sub(size(img),find(img>0));
    X=X+startX;
    Y=Y+startY;
    seed.outlineX = X;
    seed.outlineY = Y;
    
    % make sure the edge meets up with itself, with no gap
    [pathR pathD] = ind2sub(size(polarEdge),find(polarEdge==1));
    edgeStart = pathR(1);
    edgeEnd = pathR(length(pathR));
    seed.edgeGap = abs(edgeStart - edgeEnd); 

    seed.removed = 0;
    if seed.edgeGap > 1
        %This is a really bad seed, can't find anything cell-like anywhere
        %in it. Just give up here.
        seed.removed = 1;
        return; 
    end

    %check if the edge touches the boundary of the image
    %If so, we will discard it; we don't use cells unless they're fully inside
    seed.inBounds = 1;
    for j=1:length(X)
        x=X(j);
        y=Y(j);
        if ~(x>1 && x<height && y>1 && y<width)
            seed.inBounds = 0;
            %Seed is too near the image edge. Give up.
            seed.removed = 1;
            return;
        end
    end
    
    %OK, we're pretty sure this seed doesn't completely suck.
    %Let's calculate some stats on it.
    
    % Some pixels get skipped, especially on higher radius cells. 
    % First, make sure we have a solid line around the cell.
%     imgClosed = imdilate(img,strel('disk',3));
%     imgClosed = imerode(imgClosed,strel('disk',2));
%     

    % Now fill in the gaps so the cell is a solid shape, not just an
    % outline.
    imgClosed = img;
    enclosedImg = imfill(imgClosed,'holes');
    [enclosedX,enclosedY] = (ind2sub(size(enclosedImg),find(enclosedImg>0)));
    enclosedX = enclosedX + startX;
    enclosedY = enclosedY + startY;
    goodIndices = find(enclosedX>0 & enclosedX<=width & enclosedY>0 & enclosedY<=width);
    seed.enclosedX = enclosedX(goodIndices);
    seed.enclosedY = enclosedY(goodIndices); 
    enclosedIndices = sub2ind(size(cellTif),seed.enclosedX,seed.enclosedY);
    enclosedValues = double(cellTif(enclosedIndices));
    
%     
    % STAAAAAAAAAATS
    seed.enclosedCVar = std(enclosedValues)/mean(enclosedValues); % <-- This is probably the most useful stat, lower is better
    seed.edgeStrength = mean(polarTif(find(polarEdge>0))); % <--- this one's good too, higher is better
    seed.enclosedMean = mean(enclosedValues);
    seed.edgeStrengthOverMean = mean(polarTif(find(polarEdge>0)))/ mean(enclosedValues); %Rewards high CVar cells, be careful!
    seed.edgeMeanRadius = mean(pathR);
    seed.edgeMaxRadius = max(pathR);
    seed.edgeStdRadius = std(pathR);
%     
    %This is a potentially interesting stat that takes a lot of calculation
    %time. Maybe useful later.
%     tifOtsu = otsu(cellTif);
%     enclosedValuesThresh = tifOtsu(enclosedIndices);
%     seed.enclosedThresh = length(find(enclosedValuesThresh>1)) / length(enclosedValuesThresh);
    
    % Experimental - can we develop a single meaningful score of how good a
    % seed is? Let's find out!
    % NOTE! You can increase the edge strength without changing the edge,
    % if you move the seed closer to a strong edge. This is bad if you're
    % trying to fish around for higher scores by moving the seed around.
    % Otherwise it's fine.
    seed.score = mean(edgeValues) / std(edgeValues);
end


