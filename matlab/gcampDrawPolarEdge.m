function [img, polarEdge, edgeValues] = gcampDrawPolarEdge(gradientImg, cx, cy, polarAngles, polarRadii, minRadius, maxRadius)
    % Testing - a form of gcampDrawPolarEdge that takes the gradient magnitude
    % image as input instead of the raw image. This seems obvious, and a lot
    % smarter than the current way -- let's find out if it works!
    
    
    % set up variables
    polarTif = double(imgpolarcoord(gradientImg, cx, cy, polarAngles, maxRadius-1)); 
    polarTif = polarTif(minRadius:end,:);
    
    % Since dynamic programming doesn't constrain its edges well, we run
    % edge detection on a double-image (0:360) and take 360 degrees from
    % the middle of the range.
    polarTif = [polarTif polarTif];
    
    % draw the polar edge
    polarEdge = gcampPolarEdge(polarTif);
    polarEdge = polarEdge(:,polarAngles/2:polarAngles*3/2); 
    polarTif = polarTif(:,polarAngles/2:polarAngles*3/2);
    
    % transform back to XY coordinates
    [radius degrees] = size(polarEdge);
    img = zeros(maxRadius*2, maxRadius*2);
    imgCenterX = maxRadius;
    imgCenterY = maxRadius;
    degIncrement = 360/polarAngles;
    
    % draw edge pixels into an image
    pixelsList = [];
    p = 1;
    for deg=1:degIncrement:360
        polarEdgePos = max(1,round(deg/degIncrement));
        [val r]=max(polarEdge(:,polarEdgePos));
        edgeValues(p) = polarTif(r,polarEdgePos);
        edgeValues(p+1) = polarTif(r,polarEdgePos);
        edgeValues(p+2) = polarTif(r,polarEdgePos);
        edgeValues(p+3) = polarTif(r,polarEdgePos);
        
        %find pixels nearest to that point
        r=r+minRadius-1;
        xFloor = floor(imgCenterX+r*cosd(deg));
        xCeil = ceil(imgCenterX+r*cosd(deg));
        yFloor = floor(imgCenterY+r*sind(deg));
        yCeil = ceil(imgCenterY+r*sind(deg));
        
        img(xFloor,yFloor) = 1;
        img(xFloor,yCeil) = 1;
        img(xCeil,yFloor) = 1;
        img(xCeil,yCeil) = 1;
        
        % record the edge value for each marked pixel
        pixelsList(p,:) = [xFloor,yFloor];
        pixelsList(p+1,:) = [xFloor,yCeil];
        pixelsList(p+2,:) = [xCeil,yFloor];
        pixelsList(p+3,:) = [xCeil,yCeil];
        p=p+4;
    end
    
    %skeletonize to strip out extraneous pixels
    img = double(bwmorph(img>0,'skel'));
    
    img = imrotate(img,180); 
    
    [vals,positions] = unique(pixelsList,'rows');
    edgeValues = edgeValues(positions);
end
