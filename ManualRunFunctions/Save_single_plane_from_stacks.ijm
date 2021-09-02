
setBatchMode(true);

//  There are two options for running over different folders: The first is to run over all folders within a directory "topdir" , the second is to run over all folders listed manually in "dirlist".
//  Uncomment according to the option you choose.

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

out_topdir = "\\\\phhydra\\phhydraB\\Analysis\\users\\Yonit\\Movie_Analysis\\Labeled_cells\\";
stack_topdir = "\\\\phhydra\\phhydraB\\Analysis\\users\\Yonit\\Movie_Analysis\\Labeled_cells\\"; // Top directory where your folders are saved.
out_dirlist = newArray("2021_06_21_pos2\\"+"/","2021_06_21_pos4\\"+"/");  // Insert list of folders here. "/" in the end is important for consistency with option 1.
stack_dirlist = out_dirlist;  // Insert list of folders here. "/" in the end is important for consistency with option 1.


// If your original images are stacks (for example, output from the matlab surface projections), then select the plane to keep as a single plane from the stack:

plane1 = 6;
plane2 = 8;



for (j = 0; j < stack_dirlist.length; j++){

	out_dirname = substring(out_dirlist[j],0,lengthOf(out_dirlist[j])-1);
	stack_dirname = substring(stack_dirlist[j],0,lengthOf(stack_dirlist[j])-1);
	
	 stack_indir = stack_topdir+stack_dirname+"\\Layer_Separation\\Output\\Matlab_Projections_0\\" ;
//	 stack_indir = stack_topdir+stack_dirname+"\\Layer_Separation\\Output\\Matlab_Projections_1\\" ;
	
	 outdir = out_topdir+out_dirname+"\\Orientation_Analysis\\Raw Images\\";
//	 outdir = out_topdir+out_dirname+"\\Cells\\Raw Cortices\\";
	
	File.makeDirectory(out_topdir+out_dirname+"\\Orientation_Analysis");
	File.makeDirectory(out_topdir+out_dirname+"\\Cells");
	File.makeDirectory(outdir);
		
	list = getFileList(stack_indir);
		
	sortedlist = Array.sort(list);
	print(sortedlist.length);

	 for (i = 0; i < list.length; i++){
	
		open(stack_indir+list[i]);

		print(stack_indir+list[i]);
		//Make single plane
		run("Duplicate...", "duplicate range=&plane1-&plane2"); // Choose plane that provides the best image of the desired surface
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Tiff", outdir+list[i]);
		run("Close All");
	
	
	 }
 }
