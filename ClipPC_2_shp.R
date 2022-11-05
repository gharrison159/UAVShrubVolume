library(sp)
library(sf)
library(raster)
library(rLiDAR)
library(lidR)
library(rgdal)
library(terra)

### IMPORTING point cloud as LAS catalog (easier to clip multifeature polygon)
las <- readLAScatalog("C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\DATA\\FullModel_PC6340\\FullModel_PC6340.las")
## setting CRS for LAScatalog (Point Cloud data) 
st_crs(las) <- 4152 #set to NAD83 Z11 (same as shapefile)

### Importing shapefile for clipping in spatial 'simple feature' (sf) class
sf <- st_read(dsn = "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\DATA\\shrubs_arc.shp", layer = "shrubs_arc")
# sf_6340 <- st_transform(sf, st_crs(6340))
# spdf <- as_Spatial(sf_6340)
# 
# writeOGR(obj=spdf, dsn="C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\DATA", layer="shrubs_6340", driver="ESRI Shapefile")

## sf class has XYZ dimension, 'clip_roi' function only works for 'SpatialPolygons' (sp) class with 2 dimensions.
## NEED to convert to 2 dimension (XY) 'SpatialPolygon' class
#sf_rmZ <- st_zm(sf) #removes Z dimension

SpP <- as(st_geometry(sf), "Spatial") #converts sf to sp class

### Set destination file path and filenaming rule (based on 'ID' feature of 'SpP' dataset)
opt_output_files(las) <- "C:\\Users\\shre9292\\OneDrive - University of Idaho\\Documents\\GitHub\\UAVShrubVolume\\ClipPC_2_shp_Exports\\shrub_{Shrub_ID}"
clipped_las <- clip_roi(las,sf)

SpP@proj4string
