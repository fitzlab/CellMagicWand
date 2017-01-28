roiBaseDir = 'I:\findGCaMP\training-labels'
dirs = dir(roiBaseDir)

for d=1:length(dirs)
    if ~dirs(d).isdir 
        continue;
    end
    roiCoords = []; %put coords in here as you find rois
    roiSets{d}.dirName = dirs(d).name;
    roisDir = dirs(d).name;
    if dirs(d).isdir && isempty(findstr('.',roisDir))
        roisDir = [roiBaseDir '/' roisDir]
        files = dir(roisDir);
        for i=1:length(files)
            fname = files(i).name;
            if ~isempty(findstr('roi', fname))
                rois = ReadImageJROI([roisDir '/' fname]);
                x=rois.mnCoordinates(:,1);
                y=rois.mnCoordinates(:,2);
                
                pos = findstr('-',fname);
                z = str2num(fname(1:(pos(1)-1)));
                z = ones(size(x))*z;
                
                roiCoords = [roiCoords; [x y z]];
            end            
        end    
    end
    if ~isempty(roiCoords)
        roiSets{d}.roiCoords = roiCoords;
    end
end
disp('roiSets now has coordinates in it!');