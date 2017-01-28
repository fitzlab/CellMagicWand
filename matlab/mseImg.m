tifs = double(readTifs('./t16-reg')); %replace with UI folder select
[width height depth] = size(tifs);

derivativeTifs = tifs(:,:,1+dt:depth) - tifs(:,:,dt:depth-dt);
depth=depth-1;
mseX = zeros(width-1,height);
mseY = zeros(width,height-1);
for w=1:width-1
    if mod(w,9) == 0
        disp([num2str(w/width*100) '% done']);
    end
    
    for h=1:height-1
        % find MSE to east pixel
        for d=1:depth
            mseX(w,h) = sum((derivativeTifs(w,h,d)-derivativeTifs(w+1,h,d))^2);
        end
        
        % find MSE to south pixel
        for d=1:depth
            mseY(w,h) = sum((derivativeTifs(w,h,d)-derivativeTifs(w,h+1,d))^2);
        end
        
    end
end
%% 
figure, imagesc(log(1./(mseX+0.001)));
figure, imagesc(log(1./(mseY+0.001)));
