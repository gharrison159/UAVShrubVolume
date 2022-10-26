##############################################################################
##############################################################################
## Copyright H Greaves 2014
##
## This R script divides each subpplot point cloud into voxel space and counts 
## the number of voxels occupied by laser returns. It provides results for a 
## range of voxel sizes as well as a range of deviation thresholds. (Deviation
## is a point quality metric specific to RIEGL's terrestrial laser scanners.)
##
##############################################################################
##############################################################################
##
## This script expects point cloud files in PTS format - i.e., text files with 
## a first row that gives the number of records in the file, and subsequent 
## rows with four columns: x y z deviation. 
##
##############################################################################
##############################################################################
require(splancs)

##############################################################################
##############################################################################
## Enter user parameters 

## Enter the names of the plots to check
subplots = c("p1_q2","p1_q3","p1_q4","p1_q5","p1_q6","p1_q7","p1_q8",    
          "p2_q1","p2_q2","p2_q3","p2_q4","p2_q5","p2_q6","p2_q7","p2_q8",
          "p3_q1","p3_q2","p3_q3","p3_q4","p3_q5","p3_q6","p3_q7","p3_q8")

## Enter range of deviation thresholds to test
dev.range = seq(20, 80, 2)    

## Enter range of voxel sizes (one side of voxel in meters) to test
vox.range = seq(0.01, 0.20, 0.01)    

## End user parameters (however, note that file paths must be updated below)
##############################################################################
##############################################################################

for (subplot.name in subplots){    ## For each subplot....
  
  ## Get number of rows to read from first line of the PTS file
  num.rows = read.table(sprintf("D:/hgreaves/RieglDataProcessing/PTSsubplotsXYZdev/%s.pts", subplot.name), 
                        header = F, nrows = 1)    
  subplot.scan = read.table(sprintf("D:/hgreaves/RieglDataProcessing/PTSsubplotsXYZdev/%s.pts", subplot.name),
                          header = F, skip = 1, nrows = num.rows$V1, colClasses="numeric")
  colnames(subplot.scan) = c("x","y","z","dev")

  for (dev.threshold in dev.range){
    for (vox.size in vox.range){
              
      ## Ensure that the precision of the voxel boundaries are appropriate to 
	  ## the voxel size
	  precision = nchar(unlist(strsplit(as.character(vox.size),split = ".", fixed = T))[2])    

	  ## Filter by deviation threshold
      current.scan = subplot.scan[subplot.scan$dev <= dev.threshold,]    
    
	  ## Buffer the minimum point value by half the voxel size to find the 
	  ## lower bound for the x,y, and z "voxel coordinates"
      xi = round(min(current.scan$x) - vox.size/2, digits = precision)    
      yi = round(min(current.scan$y) - vox.size/2, digits = precision)
      zi = round(min(current.scan$z) - vox.size/2, digits = precision)
    
	  ## Assign x, y, and z "voxel coordinates" to each point as a point 
	  ## attribute
      current.scan$x_vox = ceiling((current.scan$x-xi)/vox.size)    
      current.scan$y_vox = ceiling((current.scan$y-yi)/vox.size)
      current.scan$z_vox = ceiling((current.scan$z-zi)/vox.size)
    
	  ## Combine the x, y, and z voxel coordinates to make unique xyz voxel 
	  ## coordinates
      current.scan$xyz_vox = paste(current.scan$x_vox, current.scan$y_vox, current.scan$z_vox, sep = "_")    
	  
	  ## Make the unique xyz voxel coordinates into factors
      current.scan$xyz_vox = factor(current.scan$xyz_vox)    
      
	  ## Find the vertices of the scan footprint to use to calculate the area
      vertices = chull(current.scan$x, current.scan$y)    
	  
	  ## create a matrix of the vertex coordinates
      vert.coords = as.matrix(data.frame(current.scan[vertices, "x"], current.scan[vertices, "y"]))    
      
	  ## get the area of the scan footprint polygon
      scan.area = areapl(vert.coords)    
      
	  ## Get the number of occupied voxels per square meter         
      filled.vox = nlevels(current.scan$xyz_vox)/scan.area  
	  
	  ## Add the results from this loop to a vector for output
      add.to.list = c(subplot.name, filled.vox)    
      
      ##  Build the output file name for this loop
      file.name = paste0("D:/hgreaves/RieglDataProcessing/Processing/VoxelMethod/SubplotData/dev-", dev.threshold, "_vsize-", vox.size, ".txt")
      
	  ## Write the output if it doesn't exist already
      if(!file.exists(file.name)){file.create(file.name)}
      
      sink(file.name, append=T)
      cat(add.to.list)
      cat("\n")
      sink()
      
      ## Update the user on the loop progress
      print(paste("Processed", subplot.name, "dev:", dev.threshold, "vsize:", vox.size, ", filledvox:", filled.vox))
    }    
  }
}

