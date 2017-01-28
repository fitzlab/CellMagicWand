%% make video of running algorithm
nFrames = 240; %save RAM, just do 240 frames, that's all we need anyway
movie = uint8(zeros(height, width*2, nFrames, 3));
accumulatedCellOutlines = zeros(height,width);
derivMax = max(zEdgeTifs(:,:,1:nFrames),[],3);
for t=1:nFrames
    %left side, gray channel
    derivFrame = zEdgeTifs(:,:,t+1);
    derivFrame = derivFrame * (255.0 / double(max(max(derivFrame))));
    movie(:,1:width,t,1) = derivFrame;
    movie(:,1:width,t,2) = derivFrame;
    movie(:,1:width,t,3) = derivFrame;
    
    %left side, green channel
    cellOutlinesFrame = cellOutlines(:,:,t);
    cellOutlinesFrame = cellOutlinesFrame * 255 / double(max(max(cellOutlinesFrame)));
    movie(:,1:width,t,2) = movie(:,1:width,t,2) + uint8(cellOutlinesFrame);
    
    %right side, gray channel
    maxDerivFrame = derivMax * (255.0 / double(max(max(derivMax))));
    movie(:,width+1:end,t,1) = maxDerivFrame;
    movie(:,width+1:end,t,2) = maxDerivFrame;
    movie(:,width+1:end,t,3) = maxDerivFrame;
    
    %right side, green channel
    accumulatedCellOutlines = accumulatedCellOutlines | cellOutlines(:,:,t);
    accumFrame = accumulatedCellOutlines * 255 / max(max(accumulatedCellOutlines));
    movie(:,width+1:end,t,2) = movie(:,width+1:end,t,2) + uint8(accumFrame);
    
end

%% 
writerObj = VideoWriter('yay.avi');
writerObj.FrameRate = 4;
open(writerObj);
for t=1:nFrames
    frame = movie(:,:,t,:);
    writeVideo(writerObj,squeeze(frame))
end
close(writerObj);
