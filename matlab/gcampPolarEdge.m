function polarEdge = gcampPolarEdge(polarImage)

polarImage = double(polarImage); %prevent overflows
polarEdge = zeros(size(polarImage));
[width height] = size(polarImage);

%cut off top and bottom to reduce filter artifacts
img = polarImage(3:width-2,:);
[m n] = size(img);

% Find the highest-value path through the image from left to right
% At each step you can go up-right (-1), right (0), or down-right (+1)

directionMatrix = zeros(size(img));
valueMatrix = zeros(size(img));
valueMatrix(:,n) = img(:,n);
for j=n-1:-1:1
    for i=1:m
        upRightTotal=0;
        downRightTotal=0;
        if i==1
            %only directions are right and down-right
            rightTotal = img(i,j) + valueMatrix(i,j+1);
            downRightTotal = img(i,j) + valueMatrix(i+1,j+1);
        elseif i==m
            %only directions are right and up-right
            upRightTotal = img(i,j) + valueMatrix(i-1,j+1);
            rightTotal = img(i,j) + valueMatrix(i,j+1);
        else
            upRightTotal = img(i,j) + valueMatrix(i-1,j+1);
            rightTotal = img(i,j) + valueMatrix(i,j+1);
            downRightTotal = img(i,j) + valueMatrix(i+1,j+1);
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

pathMatrix = zeros(size(img));
[val pos] = max(valueMatrix(:,1));
pathMatrix(pos,1) = 1;
for j=2:n
    pos = pos + directionMatrix(pos,j-1);
    if pos==0
       pos = 1; 
    end
    if pos>size(directionMatrix,1)
       pos = size(directionMatrix,1); 
    end
    pathMatrix(pos,j) = 1;
end

polarEdge(3:width-2,:) = pathMatrix;
