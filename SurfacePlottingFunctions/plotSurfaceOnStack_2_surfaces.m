function plotSurfaceOnStack_2_surfaces(thisFileImName, inputDir, heightDir0, heightDir1, outputDir );
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
cd(heightDir0); S = dir(fullfile(heightDir0,'*.tif*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
heightMap0 = imread (fullfile(heightDir0,N{X}));

% read the second height image in dir heightdir with name THAT CONTAINS thisFileImName
cd(heightDir1); S = dir(fullfile(heightDir1,'*.tif*'));
N = {S.name}; X = ~cellfun('isempty',strfind(N,thisFileImName));
heightMap1 = imread (fullfile(heightDir1,N{X}));


% make heightmap discrete and within range of 3D image
maxZ=size (image3D,3);
heightZ = round(heightMap0); heightZ (find(heightZ<1)) = NaN; heightZ (find(heightZ>maxZ)) = NaN; % discretized heightMap and makesure it is within range
[Y,X] = meshgrid(1:size(heightMap0,1),1:size(heightMap0,2)); % Y=size(heightMap,2)+1-Y; X=size(heightMap,1)+1-X;% do we need to flip the Y-axis?
drawRegion=find(~isnan(heightZ(:))); % define points to draw on


% make heightmap discrete and within range of 3D image
maxZ=size (image3D,3);
heightZ1 = round(heightMap1); heightZ1 (find(heightZ1<1)) = NaN; heightZ1 (find(heightZ1>maxZ)) = NaN; % discretized heightMap and makesure it is within range
[Y,X] = meshgrid(1:size(heightMap1,1),1:size(heightMap1,2)); % Y=size(heightMap,2)+1-Y; X=size(heightMap,1)+1-X;% do we need to flip the Y-axis?
drawRegion1=find(~isnan(heightZ1(:))); % define points to draw on

% now draw the surface on the image
newImage3D=image3D;
for i=1:length(drawRegion),
    newImage3D(X(drawRegion(i)),Y(drawRegion(i)), heightZ(drawRegion(i)))=65535;
end

% now draw the second surface on the image
for i=1:length(drawRegion1),
    newImage3D(X(drawRegion1(i)),Y(drawRegion1(i)), heightZ1(drawRegion1(i)))=65535;
end

mkdir(outputDir);
%save the 3D image if desired
write3Dstack (newImage3D, [thisFileImName,'.tiff'], outputDir);
end

