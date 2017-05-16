convertBackToWGS <- function(x){
  
  # Define input and output coordinate systems.
  wgs <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  x.map <- spTransform(x, wgs)
  x.map
  
}