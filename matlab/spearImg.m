% Tried out using the Spearman correlation coefficient instead of
% Pearson's. It was shit! A lot of the more noise-infested cells just
% vanished.
% So, Pearson's is still king. Unless maybe there's something that looks
% more MSE-ish. corr(x.^2,y.^2) maybe???


tifs = double(readTifs('./t16-reg')); %replace with UI folder select
[width height depth] = size(tifs);

derivativeTifs = tifs(:,:,1+dt:depth) - tifs(:,:,dt:depth-dt);
depth=depth-1;
spearX = zeros(width-1,height);
spearY = zeros(width,height-1);
for w=1:width-1
    if mod(w,9) == 0
        disp([num2str(w/width*100) '% done']);
    end
    
    for h=1:height-1
        % find spearman corr to east pixel
        A = squeeze(derivativeTifs(w,h,:));
        B = squeeze(derivativeTifs(w+1,h,:));
        spearX(w+1,h) = corr(A,B,'type','spearman');
        
        % find spearman corr to south pixel
        B = squeeze(derivativeTifs(w,h+1,:));
        spearY(w,h+1) = corr(A,B,'type','spearman');
    end
end
%% 
figure, imagesc(spearX);
figure, imagesc(spearY);

writeDoubleTif(spearX,'spearX.tif');
writeDoubleTif(spearY,'spearY.tif');