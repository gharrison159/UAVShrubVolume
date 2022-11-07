################################################################################

### Programmer: Abhinav Shrestha
### Contact information: abhinavs@uidaho.edu

### Purpose: R-script for clipping point cloud data to shapefile

### Last update: 11/05/2022

################################################################################

library(sp)
library(sf)
library(raster)
library(rLiDAR)
library(lidR)
library(rgdal)
library(terra)

### IMPORTING point cloud as LAS catalog (easier to clip multifeature polygon)
las <- readLAScatalog("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\DATA\\FullModel_PC26911\\PointCloud_26911.las")

las$CRS #to check the CRS of the imported las. Returns 6340 -> EPSG code for NAD83(2011) / UTM zone 11N 

### Importing shapefile for clipping in spatial 'simple feature' (sf) class
sf <- st_read(dsn = "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\DATA\\26911\\Shrub_polygon_handDrawn_26911.shp", layer = "Shrub_polygon_handDrawn_26911") #for this case I imported the shapefile I created in ArcGIS where: 
sf # sf class has XYZ dimension, 'clip_roi' function only works for classes with 2 dimensions

sf_rmZ <- st_zm(sf) #removes Z dimension                                                                                                                                                          # - I imported the final output shapefile from Georgia's script (in EPSG 4152, geographic) into ArcGIS
                                                                                                                                                          # - Used the 'export' feature to export the EPSG 4152 geographic shapefile to EPSG 6340 projected shapefile

sf_rmZ #returns Dimensions as 'XY' and Projected CRS as NAD83(2011) / UTM zone 11N (same as point cloud on line 12), if sf has Dimensions XYZ, refer to NOT RUN section starting from line 37.
st_crs(sf_rmZ) #double checking CRS is same as .las

### Set destination file path and filenaming rule (based on 'ID' feature of 'SpP' dataset)
opt_output_files(las) <- "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\ClipPC_2_shp_Exports_handdrawnPolyArc\\shrub_{Shrub_ID}"
clipped_las <- clip_roi(las,sf_rmZ)

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
### NOT RUN - this section of the script can be used if the imported shapefile has XYZ dimension. This portion of the script removes the Z dimension and converts the sf to Spatial polygons class (SpP)
### IF NEED TO RUN - just un-comment and re-indent script from lines 23 to 28. 

## sf class has XYZ dimension, 'clip_roi' function only works for classes with 2 dimensions.

## NEED to convert to 2 dimension (XY) 'SpatialPolygon' class
#sf_rmZ <- st_zm(sf) #removes Z dimension

#SpP <- as(st_geometry(sf), "Spatial") #converts sf to sp class
