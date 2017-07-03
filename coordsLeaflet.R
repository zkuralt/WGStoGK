coordsLeaflet <- function(x) {
    x <- sapply(x, anyWGStoDec)
    x <- data.frame(matrix(x, ncol = 2, byrow = FALSE))
    names(x) <- c("lat", "lon")
    coordinates(x) <- c("lon", "lat")
    x
}