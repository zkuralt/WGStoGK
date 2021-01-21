# This chunk will create EPSG codes and display it in desired order.
library(rgdal)

epsg <- make_EPSG()
epsg$pretty.name <- paste("EPSG:", epsg$code, sep = "")
ui.crs <- as.character(epsg$prj4)
names(ui.crs) <- epsg$pretty.name
top.choice <- "3794" # that is currenly the offical national CRS

find.important <- which(grepl(paste(top.choice, collapse = "|"), x = names(ui.crs)))
ui.crs <- c(ui.crs[find.important], ui.crs[-find.important])

ui.crs <- split(ui.crs, f = c(rep(1, length.out = length(top.choice)), rep(2, length.out = length(ui.crs) - 1)))
names(ui.crs) <- c("Slovenia", "Other")
