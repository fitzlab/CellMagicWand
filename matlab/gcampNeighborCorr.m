% looks at the 4-connected neighborhood of each pixel 
% calculates the correlation in time between each pixel and its neighbors
% makes displays for me to play with
% yay

%% read in data
tifs = double(readTifs('I:\gcampEdge\t16-reg'));
[width height depth] = size(tifs);

%% make correlation graph image
tic;
corrImg = zeros(size(outImg));
for x=1:width-1
    if mod(x,10)==9
        disp([num2str(100*x/width) '% done']);
    end
    for y=1:height-1
        pxTrace = squeeze(tifs(x,y,:));
        
        An=bsxfun(@minus,pxTrace,mean(pxTrace,1)); %%% zero-mean
        An=bsxfun(@times,An,1./sqrt(sum(An.^2,1))); %% L2-normalization
        
        
        % find correlation with south and west neighbors
        % correlation is symmetric, so we don't need to go both ways
        traceWest = squeeze(tifs(x+1,y,:));
        Bn=bsxfun(@minus,traceWest,mean(traceWest,1)); %%% zero-mean
        Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1))); %% L2-normalization
        C=sum(An.*Bn,1); %% correlation
        corrImg(x+1,y) = C;
        
        traceSouth = squeeze(tifs(x,y+1,:));
        Bn=bsxfun(@minus,traceSouth,mean(traceSouth,1)); %%% zero-mean
        Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1))); %% L2-normalization
        C=sum(An.*Bn,1); %% correlation
        corrImg(x,y+1) = C;
        
    end
end

toc

meanVal = mean(mean(corrImg));
corrImg(1,1:height) = meanVal;
corrImg(1:width,1) = meanVal;

%% 

derivTifs = tifs(:,:,2:depth) - tifs(:,:,1:depth-1);
derivProj = max(derivTifs,[],3);

derivCorr = corrImg .* derivProj;
writeDoubleTif(derivCorr,'derivCorr.tif');

edgeImg = edge(corrImg, 'canny', 0.2, 2.5); imagesc(edgeImg);
writeDoubleTif(edgeImg,'edgeImg.tif');

%get a gradient image of derivcorr, see where that gets you
% probably somewhere good!

