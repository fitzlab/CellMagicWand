function [padded] = addBorder(img, value)
    % pads an image with "value" on the borders
    % if width < height, pad width; if height < width, pad height
    % if height and width are equal, adds a 1-pixel border to all sides
    [height,width] = size(img);
    
    heightOut = height;
    widthOut = width;
    if height==width
        heightOut = heightOut + 2;
        widthOut = widthOut + 2;
    elseif height < width
        heightOut = heightOut + 2;
    elseif width < height
        widthOut = widthOut + 2;
    end
    
    padded = ones(heightOut,widthOut)*value;
    offsetX = 1+(widthOut-width)/2;
    endX = (width+offsetX-1);
    offsetY = 1+(heightOut-height)/2;
    endY = (height+offsetY-1);
    padded(offsetY:endY, offsetX:endX) = img;
    
end