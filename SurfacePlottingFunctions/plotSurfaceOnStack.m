function plotSurfaceOnStack(thisFileImName, inputDir, heightDir, outputDir );
% plotSurfaceOnStack(thisFileImName, inputDir, heightDir, outputDir, scalingxy, offset, nProject, typeProject );
%
% this function takes a 3D image matrix data from file thisFileImName in inputDir [N x M x Planes] and a
% heightMap z(x,y) from a file in "heightDir" .
% The function generates a stack which contains the original image and
% draws the surface on it.
%
% Input variables:
% thisFileImName    the (base) file name
% inputDir          the full directory name of the input 3D image
% heightDir         the full directory name of the input height map
% outputDir         the full directory name of the output (projection images)

% read input 3D image

try
    image3D = read3Dstack ([thisFileImName,'.tiff'],inputDir);
catch
    image3D = read3Dstack ([thisFileImName,'.tif'],inputDir);
end


% read the height image in dir heightdir with name THAT CONTAINS thisFileImName
cd(heightDir); S = dir(fullfile(heightDir,'*.tif*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
heightMap = imread (fullfile(heightDir,N{X}));


% make heightmap discrete and within range of 3D image
maxZ=size (image3D,3);
heightZ = round(heightMap); heightZ (find(heightZ<1)) = NaN; heightZ (find(heightZ>maxZ)) = NaN; % discretized heightMap and makesure it is within range
[Y,X] = meshgrid(1:size(heightMap,1),1:size(heightMap,2)); % Y=size(heightMap,2)+1-Y; X=size(heightMap,1)+1-X;% do we need to flip the Y-axis?
drawRegion=find(~isnan(heightZ(:))); % define points to draw on

% now draw the surface on the image
newImage3D=image3D;
for i=1:length(drawRegion),
    newImage3D(X(drawRegion(i)),Y(drawRegion(i)), heightZ(drawRegion(i)))=65535;
end

mkdir(outputDir);
%save the 3D image if desired
write3Dstack (newImage3D, [thisFileImName,'.tiff'], outputDir);
end

