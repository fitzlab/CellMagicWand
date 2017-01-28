tifs = double(readTifs('./F1344-t04-filtered')); %replace with UI folder select
[height width depth] = size(tifs);

% Enter the expected diameter of your cells here. 
% Numbers are in pixels. You can get these numbers by opening your images
% in an image editor and counting how many pixels across some typical cells
% are.
cellDiameterMin = 12;
cellDiameterMax = 20;

% ================================================================ %
% Find the maximum value of the derivative in t at each pixel
% This will be used as the image we find the cells on

% compare frames that are "dt" apart to determine derivative
% If your fluorescence signal rises are faster than your framerate, this
% will be 1 (usually the case)
% If your framerate is faster than your signal rise, set dt to your signal
% rise time in frames.
dt = 2; 
disp('Calculating derivative projection (max derivative)');

% OK, this is a slightly better way to do a derivative filter.
% It might be the same as mean-filtering XY and then subtracting the Z
% frames. Pretty sure it is, actually. But it runs fast, so, that's still
% cool.
zEdgeFilter = zeros(3,3,3);

zEdgeFilter(:,:,1) = [
    -1 -1 -1
    -1 -1 -1
    -1 -1 -1];
zEdgeFilter(:,:,2) = [
     0 0 0
     0 0 0
     0 0 0];
zEdgeFilter(:,:,3) = [
     1 1 1
     1 1 1
     1 1 1
 ];

zEdgeTifs = imfilter(tifs,zEdgeFilter);
zEdgeTifs = zEdgeTifs(:,:,2:end-1);
writeTifs(uint16(zEdgeTifs),'./zEdgeTifs/');

zEdgeProj = double(max(zEdgeTifs, [], 3));


derivProj = zEdgeProj;
% derivProj = double(max(derivativeTifs, [], 3));

% It would be really nice if there was some way to divide the derivative
% projection by an estimation of the noise. However, we can't use the mean
% or median of the pixel value as a noise estimate, because some cells will
% fire to ANYTHING. Maybe a std would work, actually. Try that.

writeDoubleTif(derivProj,'derivProj.tif');

%% 
% ================================================================ %
% Find the correlation between adjacent pixels in the time series
% This allows us to separate adjacent cells that have different t-signals
% It also reduces noise without too much averaging. High compute cost, but
% worth it.

disp('Calculating correlations between adjacent pixels');
corrX = zeros(height,width-1);
corrY = zeros(height-1,width);
for y=1:height
    if mod(y,10)==9
        disp(['  ' num2str(100*y/height) '% done']);
    end
    for x=1:width
        pyTrace = squeeze(tifs(y,x,:));
        
        % the bsxfun stuff is just a faster way to do corr, compared to
        % Matlab's built-in corr. It gives the same result.
        An=bsxfun(@minus,pyTrace,mean(pyTrace,1)); %%% zero-mean
        An=bsxfun(@times,An,1./sqrt(sum(An.^2,1))); %% L2-normalization
        
        % find correlation to east neighbor
        if y < height
            traceSouth = squeeze(tifs(y+1,x,:));
            Bn=bsxfun(@minus,traceSouth,mean(traceSouth,1)); %%% zero-mean
            Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1))); %% L2-normalization
            C=sum(An.*Bn,1); %% correlation
            corrY(y,x) = C;
        end
        
        % find correlation to south neighbor
        if x < width
            traceEast = squeeze(tifs(y,x+1,:));
            Bn=bsxfun(@minus,traceEast,mean(traceEast,1)); %%% zero-mean
            Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1))); %% L2-normalization
            C=sum(An.*Bn,1); %% correlation
            corrX(y,x) = C;
        end
    end
end

writeDoubleTif(corrX, 'corrX.tif');
writeDoubleTif(corrY, 'corrY.tif');

%% 
% run an FFT high-pass, then read image back in
fftBandpassMin = 0;
fftBandpassMax = 50;

% fft filter derivProj image
infile = ['derivProj.tif'];
outfile = ['derivProj-fft-0-50.tif'];
cmd = ['java -jar ' pwd '/java-image-fft/TwoPhotonTools.jar fft-bandpass ' infile ' ' outfile ' -filterSmall ' num2str(fftBandpassMin) ' -filterLarge ' num2str(fftBandpassMax)];
disp(cmd);
dos(cmd);

derivProj = double(imread(outfile));

% fft filter x corr image
infile = ['corrX.tif'];
outfile = ['corrX-fft-0-50.tif'];
cmd = ['java -jar ' pwd '/java-image-fft/TwoPhotonTools.jar fft-bandpass ' infile ' ' outfile ' -filterSmall ' num2str(fftBandpassMin) ' -filterLarge ' num2str(fftBandpassMax)];
disp(cmd);
dos(cmd);

corrX = double(imread(outfile));

% fft filter y corr image
infile = ['corrY.tif'];
outfile = ['corrY-fft-0-50.tif'];
cmd = ['java -jar ' pwd '/java-image-fft/TwoPhotonTools.jar fft-bandpass ' infile ' ' outfile ' -filterSmall ' num2str(fftBandpassMin) ' -filterLarge ' num2str(fftBandpassMax)];
disp(cmd);
dos(cmd);

corrY = double(imread(outfile));



%% 
% ================================================================ %
% Purely informational: Write out an image of what the correlation looks
% like, same size as the original image. This will NOT be used in
% calculations; the mean filtering used to make a nice image out of it
% destroys some data.
filterX = [0.5 0.5];
filterY = [0.5; 0.5];
xImg = conv2(corrX, filterX, 'valid');
yImg = conv2(corrY, filterY, 'valid');


xImg(find(xImg==0)) = mean2(xImg);
yImg(find(yImg==0)) = mean2(yImg);
xImg = addBorder(xImg, mean2(xImg)); %pad to size
yImg = addBorder(yImg, mean2(yImg)); %pad to size

corrImg = xImg+yImg;

writeDoubleTif(corrImg, 'corrImg.tif');

%% 
% ================================================================ %
% Combine the derivative max projection image with the correlation image.
% We will use this derivCorrImg for drawing cell outlines in the final
% step.

%rescale
derivProjMin = min(min(derivProj));
derivProj = (derivProj-derivProjMin) / (max(max(derivProj)) - derivProjMin);
corrImgMin = min(min(corrImg));
corrImg = (corrImg-corrImgMin) / (max(max(corrImg))-corrImgMin);

% Max isn't a great idea theoretically because the corr image should
% contain dark spots that separate pairs of cells.
% derivCorrImg = max(derivProj,corrImg);

% Geometric mean should work the best.
derivCorrImg = sqrt(derivProj .* corrImg);
writeDoubleTif(derivCorrImg, 'derivCorrImg.tif');

% ================================================================ %
% Detect edges in the correlations using the gradient (Prewitt)

% Use a 2x1 version of the Prewitt for corrX and 1x2 for corrY. 
% This allows us to correct for the fact that corrX and corrY are 
% different sizes.
% The very small size of this filter is good; using a larger filter size
% will produce a blur in the gradient magnitude image. And we don't need
% the integration we'd get from the averaging, because we're about to do a
% Hough on this data; that's a better way to integrate anyway.

prewittX = [
    1 0 -1
    1 0 -1
    1 0 -1];
prewittY = [
    1 1 1
    0 0 0
    -1 -1 -1];

corrGradientX = conv2(corrImg, prewittX, 'valid');
corrGradientY = conv2(corrImg, prewittY, 'valid');

corrGradientX = addBorder(corrGradientX,0); %pad to original image size
corrGradientY = addBorder(corrGradientY,0); %pad to original image size

writeDoubleTif(corrGradientX,'corrGradientX.tif');
writeDoubleTif(corrGradientY,'corrGradientY.tif');

corrGradientMag = sqrt(corrGradientX.^2 + corrGradientY.^2);
writeDoubleTif(corrGradientMag,'corrGradientMag.tif');

% ================================================================ %
% Detect edges in the derivative projection using the gradient (Prewitt)
% Here a bit more averaging is actually good (?)
prewittX = [
    1 0 -1
    1 0 -1
    1 0 -1];
prewittY = [
    1 1 1
    0 0 0
    -1 -1 -1];

derivGradientX = conv2(derivProj, prewittX, 'valid');
derivGradientY = conv2(derivProj, prewittY, 'valid');

derivGradientX = addBorder(derivGradientX,0);
derivGradientY = addBorder(derivGradientY,0);

writeDoubleTif(derivGradientX,'derivGradientX.tif');
writeDoubleTif(derivGradientY,'derivGradientY.tif');

derivGradientMag = sqrt(derivGradientX.^2 + derivGradientY.^2);
writeDoubleTif(derivGradientMag,'derivGradientMag.tif');

% ================================================================ %
% Combine the gradients. This is not quite as easy as it sounds, we
% need to make sure they're in the same scale first. (OK, it's still pretty
% easy.)
derivGradientMax = max(max(abs([derivGradientX derivGradientY])));
corrGradientMax = max(max(abs([corrGradientX corrGradientY])));

derivGradientXScaled = derivGradientX / derivGradientMax;
derivGradientYScaled = derivGradientY / derivGradientMax;

corrGradientXScaled = corrGradientX / corrGradientMax;
corrGradientYScaled = corrGradientY / corrGradientMax;

% Currently combining by taking the max; seems cleaner than the mean
gradientX = max(derivGradientXScaled, corrGradientXScaled);
gradientY = max(derivGradientYScaled, corrGradientYScaled);

gradientMag = sqrt(gradientX.^2 + gradientY.^2);
writeDoubleTif(gradientMag,'gradientMag.tif');

% ================================================================ %
% Run the gradient Hough transform to detect circles using the 
% gradient image.
% This uses a modified version of Tao Peng's code, from: 
% http://www.mathworks.com/matlabcentral/fileexchange/9168-detect-circles-with-various-radii-in-grayscale-image-via-hough-transform

rMin = cellDiameterMin / 2;
rMax = cellDiameterMax / 2;
radrange = [rMin,rMax];

% cut out junk pixels using Otsu's threshold
gradientMag = sqrt(gradientX.^2+gradientY.^2);
writeDoubleTif(gradientMag,'gradientMag.tif');

threshImg = otsu(gradientMag);
minAboveThresh = min(gradientMag(find(threshImg > 1)));
maxBelowThresh = max(gradientMag(find(threshImg == 1)));
grdthresh = mean([minAboveThresh, maxBelowThresh]);

accum = CircularHough_Grd(gradientX, gradientY, radrange, grdthresh);

% ================================================================ %
% The Hough accumulator space contains several pixel blobs. The centroid
% of each blob makes an excellent seed point that will land about in the
% middle of the cell.

% convolve with a small Gaussian to combine nearby blobs
f = fspecial('gaussian',7,1.2);
accum = imfilter(accum,f);
writeDoubleTif(accum, 'houghAccumulator.tif');

% find nonzero portions of image, we don't care about the rest
epsilon = median(accum(find(accum)));
accumGoodPixelsIdx = find(accum>epsilon);

% Threshold using Otsu's method on nonzero parts of image
accumThreshIndex = find(otsu(accum(accumGoodPixelsIdx))>1);
accumThresh = zeros(size(accum));
accumThresh(accumGoodPixelsIdx(accumThreshIndex)) = 1;
writeDoubleTif(accumThresh,'accumThresh.tif');

% the centroids of each blob will be our seeds
accumThreshValues = accum.*(accumThresh>0);
CC = bwconncomp(accumThresh);
STATS = regionprops(CC,'Centroid');
centroidImg = zeros(size(accumThresh));
for i=1:length(STATS)
    cellSize = length(CC.PixelIdxList{i});
    cellValues = accumThreshValues(CC.PixelIdxList{i});
    centroidImg(round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1))) = sum(cellValues);
end
writeDoubleTif(centroidImg,'centroidImg.tif');

% ================================================================ %
% Starting from the seed points, find the cell boundaries. We use the
% derivProj to draw the cell boundaries on.

disp('drawing cell boundaries');

tif = derivCorrImg; % Pretty solid choice for a target image, really

disp([num2str(length(STATS)) ' regions found.']);
clear seeds;
for i=1:length(STATS)
    seeds(i).edgeSeedPoint = [round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1))];
    seeds(i).removed = 0;
    seeds(i).score = 0;
    seeds(i).outlineX = [];
    seeds(i).outlineY = [];
end

% Take the polar image at each seed point
for s=1:length(seeds)
    if seeds(s).removed==1
        continue;
    end

    seedStats = gcampSeedStats(seeds(s), tif, cellDiameterMin, cellDiameterMax);
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

scoreThresh = 1.9;

%draw cellOutline image
cellOutline = zeros(size(tif));
numDrawn = 0;
for s=1:length(seeds)
    if seeds(s).score < scoreThresh
        continue;
    end
    X=seeds(s).outlineX;
    Y=seeds(s).outlineY;
    for j=1:length(X)
        x=Y(j);
        y=X(j);
        %cellOutline(x,y) = cellOutline(x,y) + seeds(s).score;
        cellOutline(x,y) = 1;
    end
    numDrawn = numDrawn+1;
end

disp([num2str(numDrawn) ' outlines drawn.']);
writeDoubleTif(double(cellOutline),'cellOutline.tif');

disp('done');