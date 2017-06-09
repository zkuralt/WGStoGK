prepareCoords <- function(x) {
  x <- sapply(x, gsub, pattern = ",", replacement = ".")
  x <- sapply(x, gsub, pattern = "N|E", replacement = "")
  x <- sapply(x, gsub, pattern = "\U00B0|'|''|\U0022|\U2033|\U2032|\U0301|´|°|´´", replacement = " ")
  x
}
