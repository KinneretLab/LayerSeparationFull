function CreateCost_Single_Layer(thisFileImName, inputDir, analysisDir,maskDir, z_scale, xy_scale, outputZScale,use_CLAHE, norm_window,saveDiffused)
% runFrameInverse(thisFileImName, inputDir, analysisDir, scalingxy);
% this function takes a 3D stack and makes a 3D image of the image
% gradients (after anistorpic smoothing) that is inversed and provides the
% input for the min-cost imageJ plugin to separate the cell layer and the
% fiber layer.
%
% function takes the 3D stack named "thisFileImName" in "inputDir" and
% first downscales it by scalingxy (which typically is taken so that the
% scaled xy-resolution matches the z resolution). then we use non-isotropic
% diffusion to smooth the layer, and then takes the image gradient which
% roughly gives the top and bottom surfaces of the layer.
% The function saves the output images:
% downsampled gradient in analysisDir\DS_Gradient
% downsampled gradient in analysisDir\DS_Original
% gradient in original resolution analysisDir\Gradient
%% Resize image, perform close operation, and anisotropic diffusion.
% parameters used
umdiskRadius = 25; % the disk radius in microns that is used for the close operation used to make the labeled regions within the sheet more continuous
ds_scale = 4 ; % Distance in um between pixels in resized image.
diskRadius = round(umdiskRadius/ds_scale);
% diskRadius = 5;
numberOfIterations = 5 ; % this is the number of iterations used for the anisotropic diffusion

%read original 3D stack
try
    image3D = read3Dstack ([thisFileImName,'.tif'],inputDir);
catch
    image3D = read3Dstack ([thisFileImName,'.tiff'],inputDir);
end

try
    cd (maskDir); thisMask =importdata([thisFileImName,'.tif']);
catch
    cd (maskDir); thisMask =importdata([thisFileImName,'.tiff']);
end

% reduce sampling in x-y to match z axis
image3D_RS = imresize(image3D,(xy_scale/z_scale));
% rescale to create 3d image with constant scale in um.
image3D_DS = imresize(image3D_RS,1/(ds_scale/z_scale));
% define a disk with radius and preform imclose (dilate+erode) to close
% holes within the sheet
se = strel('disk',diskRadius);
image3D_RS2=imclose(image3D_DS,se);
% use anistropic diffusion to smooth the image within the layers; works
% only in matlab2018
diffusedImage = imdiffusefilt(image3D_RS2,'NumberOfIterations',numberOfIterations);
% Added another step of closing to smooth inside tissue layer
diffusedImage = imclose(diffusedImage, se);
% diffusedImage = imdiffusefilt(diffusedImage,'NumberOfIterations',numberOfIterations);
% diffusedImage = imclose(diffusedImage, se);

%%
% save the diffused image

if saveDiffused == 1
    
    cd(analysisDir)
    cd('Diffused')
    
    d_first_frame = diffusedImage(:,:,1);
    d_ImageName = strcat('d_',thisFileImName,'.tiff');
    imwrite(d_first_frame,d_ImageName,'tiff');
    for i = 2:size(diffusedImage,3),
        d_next_frame = diffusedImage(:,:,i);
        imwrite(d_next_frame,d_ImageName,'WriteMode','append');
    end
    
end
%%
% now take the smoothed image and erode to obtain a thinner layer, from
% which an offset can be taken for separating the fibre and cell cortex
% signals.
se3d = strel('disk',diskRadius/3);
Gmag = double(imerode(diffusedImage,se3d)); 

%% normalize gradient intensity using "adapthisteq" (CLAHE filter) and save gradient images
% adapthisteq parameters for CLAHE analysis of incoming image
% this seems to be better for generating nicer gradient over larger
% portions of the image by equalizing the intensity locally over regions of
% norm_window*blocksigma
blocksigma=5*1.28/xy_scale;
imSize1 = size(image3D,1); imSize2 = size(image3D,2); maxZ=size (image3D,3);
NumTiles = [ round(imSize1/blocksigma/norm_window), round(imSize2/blocksigma/norm_window)]; % split the image into blocks of size norm_window*blocksigma where the histograms will be equalized. Default: norm_window = 4;
Distribution = 'Rayleigh'; % this is a peaked distribution

% make the gradient image 16 bit:
Gmag_uint16= uint16(Gmag/max(Gmag(:))/2*65535);

% this step equilibrates the layer intensity localy using CLAHE filter implemented
% in adapthisteq in every layer

if use_CLAHE ==1
    for i=1:size(Gmag_uint16,3),
        GmagEq(:,:,i)= adapthisteq(Gmag_uint16(:,:,i), 'NumTiles', NumTiles, 'Distribution',Distribution,'Alpha',0.4, 'ClipLimit', 0.01); % Alpha and ClipLimit are taken at defualt values
    end
else 
    GmagEq = Gmag_uint16;
end
%% Invert the image
DS_GmagInv=imcomplement(GmagEq); % invert the image
%%
% save the downsampled original image and gradient image
cd(analysisDir)
% save the downsampled original image
% cd('DS_Originals')
% first_frame = image3D_RS(:,:,1);
% DS_ImageName = strcat('DS_',thisFileImName,'.tiff');
% imwrite(first_frame,DS_ImageName,'tiff');
% for i = 2:size(image3D_RS,3),
%     next_frame = image3D_RS(:,:,i);
%     imwrite(next_frame,DS_ImageName,'WriteMode','append');
% end

% save the downsampled gradient image
% cd ..; cd('DS_Gradient')
% first_frame = DS_GmagInv(:,:,1);
% DSgrad_ImageName = strcat('DSgrad_',thisFileImName,'.tiff');
% imwrite(first_frame,DSgrad_ImageName,'tiff');
% for i = 2:size(DS_GmagInv,3),
%     next_frame = DS_GmagInv(:,:,i);
%     imwrite(next_frame,DSgrad_ImageName,'WriteMode','append');
% end
%%
% save the gradient image in the original resolution in xy and  using interpolation
% cd ..;
cd('Gradient_1Layer')
% resample image back to original size
V=double(DS_GmagInv);
[X1,Y1,Z1] = size(V);
% Notice: for meshgrid, need to exchange Y and Z, because the size of the
% returned array is size(y) X size(x) X size(Z)
[X,Y,Z] = meshgrid(0:(Y1-1),0:(X1-1),0:(Z1-1));
x_res = (X1-1)/(size(image3D,1)-1);
y_res = (Y1-1)/(size(image3D,2)-1);
z_res = 1/outputZScale;

[Xq,Yq,Zq] = meshgrid(0:y_res:(Y1-1),0:x_res:(X1-1),0:z_res:(Z1-1));

Vq = interp3(X,Y,Z,V,Xq,Yq,Zq);
% Vq = interp3(X,Y,Z,V,Xq,Yq,Zq,'cubic');
% normalize Vq by its maximum- we might want to normalize in another way
Vq_uint16= uint16(Vq/max(Vq(:))/2*65535);

 first_frame = Vq_uint16(:,:,1);
 first_frame(thisMask==0)= 65535 ;
 
 Grad_ImageName = strcat('Grad',thisFileImName,'.tiff');
 imwrite(first_frame,Grad_ImageName,'tiff');
   for i = 2:size(Vq_uint16,3)
         next_frame = Vq_uint16(:,:,i);    
         next_frame(thisMask==0)= 65535 ;
         imwrite(next_frame,Grad_ImageName,'WriteMode','append');
   end
end
