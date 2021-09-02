/*
This code runs on single z stack files and produces height maps for two detected layers within a certain distance range.
IMPORTANT: READ COMMENTS CAREFULLY AND MAKE SURE YOU CHOOSE THE OPTIONS THAT FULFILL YOUR REQUIREMENTS. 

*/
setBatchMode(true);

//  There are two options for running over different folders: The first is to run over all folders within a directory "topdir" , the second is to run over all folders listed manually in "dirlist".
//  Uncomment according to the option you choose.

// Option 1: Run over all subfolders in top directory, assumes that subfolders are identical in the original directory:
/*
 topdir = "\\\\phhydra\\data-new\\phhydra\\Analysis\\users\\Yonit\\Movie_Analysis\\";
orig_topdir = "\\\\phhydra\\data-new\\phhydra\\spinning-disk\\DATA\\Yonit\\2018\\2018_11\\2018_11_15\\TIFF Files\\";

dirlist = getFileList(topdir);
orig_dirlist = dirlist;
*/

// Option 2: List folders manually:

topdir = "\\\\phhydra\\phhydraB\\Analysis\\users\\Yonit\\Movie_Analysis\\Labeled_cells\\";
orig_topdir = "\\\\phhydra\\phhydraB\\SD2\\Users\\Yonit\\2021_06\\2021_06_21\\TIFF Files\\"; // Top directory where your folders are saved.
orig_dirlist = newArray("Pos_2\\C0\\"+"/","Pos_4\\C0\\"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.
dirlist = newArray("2021_06_21_pos2\\"+"/","2021_06_21_pos4\\"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.

dz = 3 ; // Distance in um between z slices - Change to appropriate value for your image stacks.

// Parameters for min cost z surface detection
rescalexy = 0.5;
rescalez = 1;
display = 0;

maxdz = round((3/dz)+0.49);

min = 15; // Minimum distance in um to use for detection
interval = 30; // Distance between layeres for detection in um

min=(round(min*rescalez/dz));
max = min+(round(interval*rescalez/dz));
print(min);
print(max);

//Run over folders in dirlist and perform surface detection.

for (j = 0; j < dirlist.length; j++){

	dirname = substring(dirlist[j],0,lengthOf(dirlist[j])-1);
	orig_dirname = substring(orig_dirlist[j],0,lengthOf(orig_dirlist[j])-1);
	print(dirname);
	print(orig_dirname);
	
	orig_indir = orig_topdir+orig_dirname ;
	cost_indir = topdir+dirname+"\\Layer_Separation\\Gradient\\";
	outdir = topdir+dirname+"\\Layer_Separation\\Output\\";
	File.makeDirectory(outdir);
	print(orig_indir);
	print(cost_indir);
		
	list = getFileList(orig_indir);
		
	sortedlist = Array.sort(list);
	print(sortedlist.length);

// IF FILENAMES CONTAIN SPACES, UNCOMMENT TO DELETE SPACES
/* for (i = 0; i < sortedlist.length; i++){
	
			nname = replace(sortedlist[i]," ","");
			File.rename(orig_indir+sortedlist[i], orig_indir+nname);	
			File.rename(cost_indir+"Grad"+sortedlist[i], cost_indir+"Grad"+nname);
	 } 
	 */
	 


	 for (i = 0; i < sortedlist.length; i++){
	
		print(sortedlist[i]);
		
// Uncomment the following loop if you only want to run over files with a particular string in their name.
			
		//if( matches(sortedlist[i], ".*" + "C0"+ ".*")) {  
				orig_name = sortedlist[i]; 
				cost_name = "Grad"+sortedlist[i];
			//	cost_name = "Grad"+sortedlist[i]+"f";
	
						if (File.exists(orig_indir+orig_name)){
							
							if (File.exists(cost_indir+cost_name)){
								
							
								open(orig_indir+orig_name);
								open(cost_indir+cost_name);
							
								run("Min cost Z Surface", "input="+orig_name+" cost="+cost_name+" rescale_x,y=&rescalexy rescale_z=&rescalez max_delta_z=&maxdz display_volume(s) volume=&display two_surfaces max_distance=&max min_distance=&min");
								// Uncomment the following section if you would like to save images of detected surfaces directly.
								/* 
								File.makeDirectory(outdir+"Layers\\");
								saveAs("Tiff", outdir+"Layers\\"+"layer0_Min_"+min+"_"+orig_name);
								run("Close");
								saveAs("Tiff", outdir+"Layers\\"+"layer1_Min_"+min+"_"+orig_name);
								run("Close");
								*/
								File.makeDirectory(outdir+"\\Height_Maps_0\\");
								File.makeDirectory(outdir+"\\Height_Maps_1\\");
								selectWindow("altitude map1");
								saveAs("Tiff", outdir+"Height_Maps_0\\HM"+orig_name);	
								selectWindow("altitude map2");
								saveAs("Tiff", outdir+"Height_Maps_1\\HM"+orig_name);
								run("Close All");
							}
							
						}
					
				}
		// }
	
	}