convertClickToGK <- function(x, crs){
  x <- sapply(x, anyWGStoDec)
  x <- data.frame(matrix(x, ncol = 2, byrow = FALSE))
  names(x) <- c("lat", "lon")
  coordinates(x) <- c("lon", "lat")
  
  # Define input and output coordinate systems.
  proj4string(x) <- CRS("+init=epsg:4326") # WGS 84
  CRS.new <- CRS(crs)
  x.new <- spTransform(x, CRS.new)
  x.new
}