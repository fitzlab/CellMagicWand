function [ seed ] = gcampSeedStats2( cx, cy, img, gradientImg, cellDiameterMin, cellDiameterMax )
    % Calculates statistics of a neun seed
    % requires only that the seed structure contain a centroid
    [height,width] = size(img);
    
    % The polar image needs at least enough angles to represent the 
    % circumference of the cell at maximum radius. 
    angleSubSampling = 2; % give each angle a few pixels, not just 1.
    numAngles = round(cellDiameterMax * pi * angleSubSampling); 
    degreesPerAngle = 360/numAngles;
    degreeValues = 1:degreesPerAngle:360;
    
    % Allow the cell's boundary to extend outside of the user-supplied
    % radius, if needed. 
    radiusTolerance = 1.5;
    minRadius = round((cellDiameterMin / 2) / radiusTolerance);
    maxRadius = round((cellDiameterMax / 2) * radiusTolerance);
    
    radiusSubSampling = 4; % each pixel represents 0.25 in radius
    radiusValues = minRadius:(1/radiusSubSampling):maxRadius;
    numRadii = length(radiusValues);
    
    % draw the polar image according to the angle and radius sampling given
    polarImg = zeros(numRadii,numAngles);
    for thetaIndex=1:numAngles
        for rIndex=1:numRadii
            r = radiusValues(rIndex);
            posX = cx + r*cosd(degreeValues(thetaIndex));
            posY = cy + r*sind(degreeValues(thetaIndex));
            
            pxVal = 0; %if we're outside the image, pixel value is 0
            if floor(posX) >= 1 && floor(posY) >= 1 && ceil(posX) <= height && ceil(posY) <= width
                % pos is inside the image
                % take the distance-weighted average of the four nearest pixels
                valNE = gradientImg(ceil(posX),ceil(posY)) * sqrt((ceil(posX)-posX)^2+(ceil(posY)-posY)^2);
                valNW = gradientImg(floor(posX),ceil(posY)) * sqrt((floor(posX)-posX)^2+(ceil(posY)-posY)^2);
                valSE = gradientImg(ceil(posX),floor(posY)) * sqrt((ceil(posX)-posX)^2+(floor(posY)-posY)^2);
                valSW = gradientImg(floor(posX),floor(posY)) * sqrt((floor(posX)-posX)^2+(floor(posY)-posY)^2);
                pxVal = (valNE+valNW+valSE+valSW)/2;
            end
            
            polarImg(rIndex,thetaIndex) = pxVal;
        end
    end
    
    num = round(rand(1)*1000);
    writeDoubleTif(polarImg,['I:\findGCaMP\polarImages\' num2str(num) '.tif']);
    
    % Use dynamic programming to find the best path through the polar image
    rPositions = dpEdge(polarImg);
    
    % Untransform the path back onto the original image
    edgeValues = zeros(numAngles,1);
    cellOutline = zeros(numAngles,2);
    for thetaIndex=1:numAngles
        rIndex = rPositions(thetaIndex);
        r = radiusValues(rIndex);
        posX = cx + r*cosd(degreeValues(thetaIndex));
        posY = cy + r*sind(degreeValues(thetaIndex));
        
        if round(posX) < 1
            posX = 1;
        end
        if round(posY) < 1
            posY = 1;
        end
        if round(posX) > width
            posX = width;
        end
        if round(posY) > height
            posY = height;
        end
        
        cellOutline(thetaIndex,1) = round(posX);
        cellOutline(thetaIndex,2) = round(posY);
        edgeValues(thetaIndex) = gradientImg(round(posX),round(posY));
    end
    cellOutline = unique(cellOutline,'rows');
    
    seed.outlineX = cellOutline(:,1);
    seed.outlineY = cellOutline(:,2);
    
    % make sure the edge meets up with itself, with no gap
    seed.edgeGap = abs(rPositions(1) - rPositions(end)); 

    seed.removed = 0;
    if seed.edgeGap > 1
        %This is a really bad seed, can't find anything cell-like anywhere
        %in it. Just give up here.
        seed.removed = 1;
        return; 
    end

    %Let's calculate some stats on this seed.

    % Now fill in the gaps so the cell is a solid shape, not just an
    % outline.
%     imgClosed = img;
%     enclosedImg = imfill(imgClosed,'holes');
%     [enclosedX,enclosedY] = (ind2sub(size(enclosedImg),find(enclosedImg>0)));
%     enclosedX = enclosedX + startX;
%     enclosedY = enclosedY + startY;
%     goodIndices = find(enclosedX>0 & enclosedX<=width & enclosedY>0 & enclosedY<=width);
%     seed.enclosedX = enclosedX(goodIndices);
%     seed.enclosedY = enclosedY(goodIndices); 
%     enclosedIndices = sub2ind(size(img),seed.enclosedX,seed.enclosedY);
%     enclosedValues = double(img(enclosedIndices));
    
    % STAAAAAAAAAATS
%     seed.enclosedCVar = std(enclosedValues)/mean(enclosedValues); % <-- This is probably the most useful stat, lower is better
%     seed.edgeStrength = mean(polarTif(find(polarEdge>0))); % <--- this one's good too, higher is better
%     seed.enclosedMean = mean(enclosedValues);
%     seed.edgeStrengthOverMean = mean(polarTif(find(polarEdge>0)))/ mean(enclosedValues); %Rewards high CVar cells, be careful!
%     seed.edgeMeanRadius = mean(pathR);
%     seed.edgeMaxRadius = max(pathR);
%     seed.edgeStdRadius = std(pathR);
%     
    %This is a potentially interesting stat that takes a lot of calculation
    %time. Maybe useful later.
%     tifOtsu = otsu(img);
%     enclosedValuesThresh = tifOtsu(enclosedIndices);
%     seed.enclosedThresh = length(find(enclosedValuesThresh>1)) / length(enclosedValuesThresh);
    
    % Experimental - can we develop a sindgle meaningful score of how good a
    % seed is? Let's find out!
    % NOTE! You can increase the edge strength without changing the edge,
    % if you move the seed closer to a strong edge. This is bad if you're
    % trying to fish around for higher scores by moving the seed around.
    % Otherwise it's fine.
    seed.score = mean(edgeValues) / std(edgeValues);
end