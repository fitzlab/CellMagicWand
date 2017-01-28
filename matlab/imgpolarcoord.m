function pcimg=imgpolarcoord(img,cx,cy,angle,radius)
% IMGPOLARCOORD converts a given image from cartesian coordinates to polar
% coordinates.
%
% Input:
%        img  : bidimensional image.
%      radius : radius length (# of pixels to be considered).
%      angle  : # of angles to be considered for decomposition.
%
% Output:
%       pcimg : polar coordinate image.
%
% Usage Example:
% imagesc(imgpolarcoord(rice,150,150,360,150))
%
% Improvements added by Theo Walker 2013-05-24.
%
% Notes:
%  The software is provided "as is", without warranty of any kind.
%  Javier Montoya would like to thank prof. Juan Carlos Gutierrez for his
%  support and suggestions, while studying polar-coordinates.
%  Authors: Juan Carlos Gutierrez & Javier Montoya.

   if nargin < 1
      error('Please specify an image!');
   end
   
   img         = double(img);
   [rows,cols] = size(img);
   
   if exist('radius','var') == 0
      radius = min(round(rows/2),round(cols/2))-1;
   end
   
   if exist('cx','var') == 0
      cx = round(rows/2);
   end
   if exist('cy','var') == 0
      cy = round(cols/2);
   end
   
   if exist('angle','var') == 0
      angle = 360;
   end
  
   pcimg = ones(radius+1,angle)*65535;
   i     = 1;
   
   for r=0:radius
      j = 1;
      for a=0:2*pi/angle:2*pi-2*pi/angle
         srcCoordX = cy+round(r*sin(a));
         srcCoordY = cx+round(r*cos(a));
         if srcCoordX > 0 && srcCoordX <= rows
             if srcCoordY > 0 && srcCoordY <= cols
                pcimg(i,j) = img(srcCoordX,srcCoordY);
             end
         end
         
         j = j + 1;
      end
      i = i + 1;
   end
end