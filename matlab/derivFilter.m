
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
writeTifs(uint16(zEdgeTifs),'./zEdgeTifs/');

zEdgeProj = double(max(zEdgeTifs, [], 3));
