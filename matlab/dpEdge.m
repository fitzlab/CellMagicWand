function [ rPositions ] = dpEdge( polarImg )
    % Uses dynamic programming to find a path from left to right along the given
    % polar image (coordinates r and theta).
    % Returns the position of R for each value of theta along the path.

    [numRadii,numAngles] = size(polarImg);
    
    % Dynamic programming is less robust at the far left and far right of
    % the image. To improve this behavior, we extend the polar image
    % on both ends. 
    % So instead of covering 0 to 360 degrees, the polar image will cover
    % something like -90 degrees to 450 degrees. (That's just an example; 
    % actual numbers will depend on theta interval.)
    % This will be trimmed off the final path, it's just here to add
    % some robustness to DP.
    extendBy = 10;
    if extendBy > numAngles
        extendBy = numAngles / 2;
    end
    polarImg = [polarImg(:,numAngles-extendBy:numAngles), polarImg, polarImg(:,1:extendBy)];
    
    % draw the edge
    polarEdge = zeros(size(polarImg));
    [m n] = size(polarImg);

    % Find the highest-value path through the image from left to right
    % At each step you can go up-right (-1), right (0), or down-right (+1)
    directionMatrix = zeros(size(polarImg));
    valueMatrix = zeros(size(polarImg));
    valueMatrix(:,n) = polarImg(:,n);
    for j=n-1:-1:1
        for i=1:m
            upRightTotal=0;
            downRightTotal=0;
            if i==1
                %only directions are right and down-right
                rightTotal = polarImg(i,j) + valueMatrix(i,j+1);
                downRightTotal = polarImg(i,j) + valueMatrix(i+1,j+1);
            elseif i==m
                %only directions are right and up-right
                upRightTotal = polarImg(i,j) + valueMatrix(i-1,j+1);
                rightTotal = polarImg(i,j) + valueMatrix(i,j+1);
            else
                upRightTotal = polarImg(i,j) + valueMatrix(i-1,j+1);
                rightTotal = polarImg(i,j) + valueMatrix(i,j+1);
                downRightTotal = polarImg(i,j) + valueMatrix(i+1,j+1);
            end

            if upRightTotal > rightTotal && upRightTotal > downRightTotal
                directionMatrix(i,j) = -1;
                valueMatrix(i,j) = upRightTotal;
            elseif downRightTotal > rightTotal && downRightTotal > upRightTotal
                directionMatrix(i,j) = 1;
                valueMatrix(i,j) = downRightTotal;
            elseif downRightTotal == upRightTotal && upRightTotal > rightTotal
                %in a tie between up-right and down-right, just go up-right 
                %(both paths are optimal).
                directionMatrix(i,j) = 1;
                valueMatrix(i,j) = upRightTotal;
            else
                %right is the default in case of a tie
                directionMatrix(i,j) = 0;
                valueMatrix(i,j) = rightTotal;
            end
        end
    end
    
    % draw the path according to the directionMatrix
    pathMatrix = zeros(size(polarImg));
    rPositions = zeros(size(polarImg,1),1);    
    [val pos] = max(valueMatrix(:,1));
    pathMatrix(pos,1) = 1;
    rPositions(1) = pos;
    for j=2:n
        pos = pos + directionMatrix(pos,j-1);
        if pos==0
           pos = 1; 
        end
        if pos>size(directionMatrix,1)
           pos = size(directionMatrix,1); 
        end
        pathMatrix(pos,j) = 1;
        rPositions(j) = pos;
    end
    
    % remove stability extensions
    rPositions = rPositions(extendBy+1:end-extendBy);
end

