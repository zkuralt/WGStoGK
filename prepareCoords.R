prepareCoords <- function(x) {
  x <- sapply(x, gsub, pattern = ",", replacement = ".")
  print("\U00B0|'|''")
  x <- sapply(x, gsub, pattern = "\U00B0|'|''", replacement = " ")
  x
}
