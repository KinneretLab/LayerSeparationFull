November 2019 – updated February 2020 – updated February 2021

**(Notice:  This is the same documentation for all parts of the layer separation pipeline)**

# Layer Separation – Manual
The process takes 3D image stacks of actin structures in Hydra tissue and detects the two surfaces containing the signal from the actin fibres and cell cortices.

The final output is the two heightmaps which define the two surfaces, as well as projected images of the signal from the two surfaces.

There is also a possibility to perform the sequence of steps to detect a single layer, and not two layers. The instructions and function names to use for a single layer are marked in *italic. If not otherwise specified, folder names for single layer are identical two double layer, but with an added label “_1Layer” at the end of the folder name.*

 The process includes three steps:

1. Calculating cost images for surface detection algorithm (Matlab).
2. Running the surface detection algorithm and producing the height maps defining the surfaces (ImageJ).
3. Creating the surface projections (Matlab).


## 0.	Create masks from image stacks for cost calculation
The layer separation pipeline is built to run over folders of images and respective masks that mark the region of the image to be analysed. To create masks, please see “Masks_Manual” in this folder. After creating the masks, you can proceed with layer separation. The masks should be saved under the movie directory, in a folder titled “Display/Masks”.

## 1.	Calculating cost images: 

In this step we take a 3D image stack and its mask, and make a masked 3D stack of the image gradients (after anistorpic smoothing) that is inverted and provides the input for the min-cost imageJ plugin to separate the cell surface and the fiber surface.

**Main function: “runCreateCost”**

*(Single layer: runCreateCost_Single_Layer)*

This is the function you need to make a copy of and use your own copy. All other functions are called from the general code folder, and do not require you to have a local copy of them.
(Sub-functions: CreateCost_with_CLAHE)

In general, the function can run on a list of folders of original image stacks, and create the cost images in appropriate folders in a different directory.

**The loops that run over separate timepoints are “parfor” loops, meaning they run multiple processes in parallel according to the default number of workers set in your matlab. This means the analysis is considerably faster than a normal “for” loop, but notice it doesn’t necessarily happen in sequence. Since all calculations are performed independently for every frame, this is not a problem.**

### Input Folder structure:

#### Top input directory (original image stacks): 

topMainDir – Top directory in which all folders containing original stacks on which you want to run the code are found. 
For example:
```matlab
topMainDir='\\phhydra\data-new\phhydra\spinning-disk\DATA\Yonit\2018\2018_11\2018_11_15\TIFF Files\'
```

####Subfolders within top input directory: 

mainDirList – This is a list of the subfolders inside topMainDir over which you want to run. 
For example:
```matlab 
mainDirList= { ... % enter in the following line all the  movie dirs for cost calculation.
'Pos_3\C0\', ...
'Pos_18\C0', ... 
```
####Output folder structure:

Top output directory:  Main directory for saving the analysis output.

For Example: 
```matlab
topAnalysisDir='\\phhydra\data-new\phhydra\Analysis\users\Yonit\Movie_Analysis\'; % main folder for layer separation results
```
Subfolders within top output directory: 
Make sure the output subfolders are in the same order as the input subfolders.

For Example: 
```matlab
mainAnalysisDirList= { ... % enter in the following line all the output dirs for cost calculation.
'2018_11_15_pos3\', ...
'2018_11_15_pos18\', ...
};
```
#### Input parameters:

```matlab
% Calibration for z and xy of image stacks:
z_scale = 3; % um/pixel
% xy_scale = 0.99; % um/pixel for 10x lens with 1.6x magnification
xy_scale = 1.28; % um/pixel for 10x lens with 1x magnification
outputZScale = 1; % Default: 1, can change if you want to downsample.
use_CLAHE = 1;  % Default: 1, set to 0 if don't want to use CLAHE to normalise gradients.
norm_window = 4; % Default: 4. Length scale for normalisation of gradient using CLAHE. Decreasing can sometimes help prevent jumps between surfaces.
saveDiffused = 0; % Set to one to save diffused images, and to zero to not save.  
```

#### Explanantion and details:

As explained above, the purpose of this step is to generate a “cost” image from the original image stacks that will enable the detection of the two surfaces at the basal and apical sides of the fluorescent ectodermal cell layer. Although the strongest fluorescent signal is usually that of the actin fibres at the basal side of the cell layer, the combined signal from the fibres, cell cortices, and other actin structures in the cell form a fluorescent shell roughly the thickness of the cell layer. Therefore, to detect the top and bottom surfaces of this shell, a good approach is to calculate the gradients in signal intensity (brightness) in the original image stacks, and identify the inner and outer edges of the fluorescent surface where the gradients are highest.
However, due to the variability of the structures and their brightness, some additional processing is required. The calculation of the cost image is therefore as follows:

(1) Rescale the 3-dimensional image stack so the dimensions of each pixel are isotropic in x,y,z and represent the true scale of the sample. This is important because typically the resolution in the z direction is roughly 1/4-1/3 of the resolution in the xy plane. Then, we isotropically rescale the image to a constant distance of  4um between pixels. This keeps the consistency of the spatial resolution of the next steps. (2) Perform a “close” operation on the image to filll gaps in the fluorescent signal within the epithelial layer (operation is “imclose” with a structure element of a disk with radius spacified by “diskRadius”). (3) Smooth the image using the anisotropic diffusion filter in Matlab, which preferentially smooths the image in the direction of minimal gradient (along surfaces of similar signal intensity). The function is “imdiffusefilt“, which is built into Matlab 2018a and onwards. Another “close” operation is then performed after the anisotropic diffusion. (4) Calculate the gradient of the resulting smoothed image, using the function “imgradient3“. (5) Use CLAHE to locally equilibrate the signal intensity of the gradient image (“adapthisteq”). (6) Invert the gradient image, so the resulting cost image has lowest value signal along the apical and basal sides of the epithelial surface, where the signal gradient is highest.  (7) Resize the gradient images to the original image stack dimenstions (using “interp3”).

Comments:

-	By default, the function saves the final cost images, but doesn’t save the diffused images (before the gradient calculation), which can be useful for identifying problems etc (you can set them by choosing saveDiffused = 1). Two more possibilities for saving the downsized gradient and original images are written in the function but commented out, can be uncommented if required.
-	The histogram equilibration step (CLAHE) is performed before image resizing back to original size. The results seem to be marginally better performing the equilibration step at this point (compared to not performing it at all or doing so after resizing). It is important to note that if the equilibration is done after resizing, the number of tiles needs to be adjusted accordingly to maintain the same spatial resolution. 

It is always worth checking that the gradient images look reasonable before proceeding to the next step!

## 2.	Detecting the separate surfaces:

Next, the cost images are used to detect the two surfaces within the 3D image stacks. This is done using the imageJ plug-in “Min Cost Z Surface” (see imageJ documentation for references). The plugin is called through a macro function called **“Layer_Separation_multiple_folders”** (*for a single layer, use “Layer_Separation_multiple_folders_single_layer”*). The plugin implements an algorithm that works by mapping the image stack to a paritally-connected
graph, and assigning a cost function to each vertex. The algorithm then searches for the surface/s whose map accumulates minimal cost.

The macro runs over multiple folders containing the cost images produced in step 1 and the original image stacks (saved as separate timepoints). For each image, it calculates the two surfaces that are supposed to represent the inner and outer surfaces of the fluorescent layer in the original image stacks, containing the best representation of the fibers and cell-cortices respectively. 

The macro code contains important comments which should be read before running.
Folder structure:

There are two options for running over multiple folders: The first is to run over all subfolders within a directory "topdir" , the second is to run over all folders listed manually in "dirlist". The relevant option should be uncommented, and the unused option should remain as a comment.

Option 1: Run over all subfolders in top directory. You will need to insert two top directories: “topdir” – top directory which contains the cost images, and “orig_topdir”, directory which contains original image stacks. NOTICE: This option assumes that subfolders in the cost directory and the original image stack directory are identical.

Option 2: List subfolders manually. This enables using different subfolders for the cost directory and original image stack directory, and choosing only specific subfolders in the top folder.  You will still need to enter the top directory for the cost images and for the original image stacks (“topdir” and “orig_topdir”), and in addition, add a list of the subfolders for each over which you want to run.  These appear as “dirlist” and ”orig_dirlist”, and should only contain the ending that is distinct from subfolder to subfolder (and not the top directory). Make sure the order of subfolders in the two lists is matching.

For example:
```
dirlist = newArray("2018_11_15_pos3"+"/","2018_11_15_pos18"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.
orig_dirlist = newArray("Pos_3\\C0\\"+"/","Pos_18\\C0\\"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.
```
####Parameters for min cost z surface detection (can also be found in imageJ documentation):
```
dz = 3 ;  Distance in um between z slices. Change according to your image stacks.
rescalexy = 0.5;  This is our default value, rescaling to a smaller factor can be less accurate, but faster. 
rescalez = 1;  Our default value.
```
NOTICE: If you change the two rescaling parameters, you may need to change “maxdz” in accordance to maintain the same size in rescaled pixels. Not recommended.
```display = 0;  This is the number of planes representing detected layers you want to save. The default is not to save the raw output at all, but to create the projections separately using Matlab (step 3). If you want to save the raw output, uncomment section in the loop that runs the plugin  and select the number of planes you want.
maxdz = round((3/dz)+0.49);  This is the maximum step-size in z (in rescaled pixels) allowed between surfaces in the surface detection algorithm. This value was found to best work for Hydra ecto images.
min = 15; Minimum distance in um to use for detection – this was found to be suitable for most Hydra ecto images.
interval = 30;  Distance between layeres for detection in um – this was found to be suitable for most Hydra ecto images.
max = min+(round(interval*rescalez/dz));  Maximum distance between surfaces to use for detection – calculated here from the other parameters.
```

#### Output:
The output of this step is the two altitude maps reperesenting the two detected surfaces from the imageJ plugin. These are saved under the analysis directory (same as where the cost images are saved, under a folder called “Output”. Inside it are two separate folders, “Height_Maps_0” (outer surface – cell cortices) and  “Height_Maps_1” (inner surface – fibres). File names are “HM”+ original file name (no spaces). NOTICE: Surfaces from the lightsheet can be switched, if the image stack starts from middle of the tissue rather that the outside.

Comments:
-	The macro and imageJ plugin can also be used for detecting a single surface rather than two surfaces. The input cost images need to be adapted accordingly (as instructed above).

## 3.	Creating projection images of the detected surfaces:

**Main function: “runFrameProjection”** (*or for single layer “runFrameProjection_1Layer”*)

The final step is creating projection images from the original image stacks of the separate detected surfaces, based on the height maps calculated using the ImageJ plugin. In principal, you could create projection images of just the detected surface. However, the detected surface is given in discrete values, and therefore contains large steps which lead to artifacts in the projected image and other calculations for the geometry of the surface. In addition, the actual surface best showing the desired features (fibres or cortices) is often at an offset to the detected planes. Therefore, we first smooth the height maps (details below), and include options for creating projection images from a number of planes and at different offsets. You can try a wider range of options, and then choose a smaller range that best sutis your data. The surface smoothing and creation of projection images require the same masks that were used for the creation of the original cost images (saved under “Display/Masks”).

**The loops that run over separate timepoints are “parfor” loops, meaning they run multiple processes in parallel according to the default number of workers set in your matlab. This means the analysis is considerably faster than a normal “for” loop, but notice it doesn’t necessarily happen in sequence. Since all calculations are performed independently for every frame, this is not a problem.**

#### Smoothing the height maps (function – smoothHeightMap)
The first step is creating a binarised image (with value 1 below the surface and 0 above the surface), then convolve with a Gaussian kernel of sigma =1, and select the isosurface with I=0.5). This gives a list of values for z(x,y) describing the surface, but the points are not arranged on a regular grid. We then use interpolation to find the z(x,y) on a grid matching the original image size, resulting in a smoothed height map, which is saved as a “.mat” file under folders “smoothed_Height_Maps_0/1” (for the inner and outer surfaces) in the output directory of the layer separation folder.
#### Creating projected images (function - makeFrameProjection_smoothedHM)
The next step is creating the projected image using the smoothed height map. Since the values z(x,y) are now generally not whole numbers, the intensity for each pixel in xy for creating the projected image is taken by weighting the intensities of all pixels along the z direction according to a Gaussian distribution centred at the given z(x,y) with sigma = 0.5 pixel. Effectively, values more than 5 pixels away have zero weight, and the main contributors are the nearest pixels to the centre. The resulting image is saved under the folder “matlab_projections_0/1” (for the inner and outer surfaces).

**Parameters for surface projections:**
```matlab


calibrationXY = 1.28; % For 10x lens
% calibrationXY = 0.65; % For 20x lens
% calibrationXY = 0.57; % For lightsheet
calibrationZ = 3;
offset = [-7:3]; % Range of offest from the detected surface to use for projection images. Test a few and choose what range you need.
CLAHE = 0; % Set to 1 if want to normalise intensity in images using CLAHE.
```
**Folder structure:**

* Original image stacks: Same as for initial cost image calculation (step 1).

* Height maps and output: Same as output folder structure in cost image calculation, with subfolders (1 represents outer surface – cortices, 0 represents inner surface – fibres – THIS CAN CHANGE BETWEEN DIFFERENT DATA TYPES).

* fvDir – directory in which the surface data is saved (structure of two arrays of faces and vertices representing the triangulated surface of the smoothed height map).

```matlab
heightDir0=[AnalysisDirList{i},'\Layer_Separation\Output\Height_Maps_0\'];    outputDir0=[AnalysisDirList{i},'\Layer_Separation\Output\Matlab_Projections_0\'];
smoothHeightDir0 = [AnalysisDirList{j},'Layer_Separation\Output\Smooth_Height_Maps_0\'];
fvDir0 = [AnalysisDirList{j},'Layer_Separation\Output\FV_0\'];


heightDir1=[AnalysisDirList{i},'\Layer_Separation\Output\Height_Maps_1\'];    outputDir1=[AnalysisDirList{i},'\Layer_Separation\Output\Matlab_Projections_1\'];
smoothHeightDir1 = [AnalysisDirList{j},'Layer_Separation\Output\Smooth_Height_Maps_1\'];
fvDir1 = [AnalysisDirList{j},'Layer_Separation\Output\FV_1\'];
```
###  Appendix 1: Creating single plane images out of stacks with different offsets (output from matlab layer projections):

ImageJ macro: “Save_single_plane_from_stacks”

Input needed:

1. Directories:
```
out_topdir = "\\\\phhydra\\phhydraB\\Analysis\\users\\Yonit\\Movie_Analysis\\Labeled_cells\\";
stack_topdir = "\\\\phhydra\\phhydraB\\Analysis\\users\\Yonit\\Movie_Analysis\\Labeled_cells\\"; // Top directory where your folders are saved.
out_dirlist = newArray("2020_10_29_pos15\\"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.
stack_dirlist = out_dirlist;  // Insert list of folders here. "/" in the end is important for consistency with option 1.
```
2. Planes to select:
 ```
 // If your original images are stacks (for example, output from the matlab surface projections), then select the plane to keep as a single plane from the stack:
 
plane1 = 6;
plane2 = 7;
``` 
3. Directories for specific input and output (inside first loop):
```
stack_indir = stack_topdir+stack_dirname+"\\Layer_Separation\\Outpu\\Matlab_Projections_0\\" ;
(or Matlab_Projections_1)
outdir = out_topdir+out_dirname+"\\Orientation_Analysis\\Raw Images\\";
(or "\\Cells\\Raw Cortices\\";)
```
### Appendix 2: Additional options for post-visualization:

The function “Run_plotSurfaceOnStack” plots the detected surfaces on the original or gradient image stacks, to visualize how good the layer detection is.
