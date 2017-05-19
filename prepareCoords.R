prepareCoords <- function(x) {
  x <- sapply(x, gsub, pattern = ",", replacement = ".")
  print("°|'|''")
  x <- sapply(x, gsub, pattern = "°|'|''", replacement = " ")
  x
}
