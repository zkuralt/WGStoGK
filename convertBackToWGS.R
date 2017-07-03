convertBackToWGS <- function(x, crs){
  # Define input and output coordinate systems.
  proj4string(x) <- CRS(crs)
  wgs <- CRS("+init=epsg:4326")
  x.map <- spTransform(x, wgs)
  x.map
}