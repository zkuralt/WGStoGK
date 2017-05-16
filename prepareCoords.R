prepareCoords <- function(x) {
  x <- sapply(x, gsub, pattern = ",", replacement = ".")
  x <- sapply(x, gsub, pattern = "°|'|''", replacement = " ")
  x
}
