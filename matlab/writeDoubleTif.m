function [] = writeDoubleTif( tif, filename )
    % Take an image of type "double" and write it out as a 16-bit tif
    tif = double(tif);
    
    % rescale to 0..65535
    tMin = double(min(min(tif)));
    tMax = double(max(max(tif)));
    tifScaled = (tif - tMin) / (tMax-tMin) * double(65535);
    
    %save as 16-bit tif
    tifScaled = uint16(tifScaled);
    imwrite(tifScaled,filename,'tif');
end

