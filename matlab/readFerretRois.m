load('Site1');
numCells = length(celllist);
img = zeros(512,512);

coords = zeros(numCells,2);
for i=1:numCells
    y = round(mean(celllist(i).xi));
    x = round(mean(celllist(i).yi));
    img(x,y) = 65535;
    coords(i,1) = x;
    coords(i,2) = y;    
end
cross = [
    0 0 1 0 0;
    0 0 1 0 0;
    1 1 1 1 1;
    0 0 1 0 0;
    0 0 1 0 0;
    ];
se = strel('arbitrary', cross);
img = imdilate(img, se);
imagesc(img);
writeDoubleTif(img,'F1344-t04-cells.tif');