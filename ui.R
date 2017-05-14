library(shiny)
library(leaflet)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

shinyUI(fluidPage(
  titlePanel("WGStoGK - version 0.5"),
  sidebarLayout(
    sidebarPanel(
      textInput("coords", label = "Coordinates input", value = ""),
      # selectInput("CRS", 
      # label = "Select preffered CRS",
      # choices = list("EPSG:3787", "EPSG:3912",
      # "EPSG:3794")),
      h5(strong("Points on map")),
      leafletOutput("leaflet"),
      h6("CRS used: +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel
         +towgs84=426.9,142.6,460.1,4.91,4.49,\n-12.42,17.1 +units=m +no_defs")
      ),
    
    mainPanel(
      # textOutput("selected.format"),
      textOutput("coords"),
      # textOutput("new.coords")
      h5(strong("Converted coordinates")),
      tableOutput("new.coords")
    )
  )
  ))
