library(shiny)
library(leaflet)

shinyUI(fluidPage(
  titlePanel("WGStoGK - version 0.6"),
  sidebarLayout(
    sidebarPanel(
      textInput("coords", label = "Coordinates input", value = "46.05116 14.46990"),
      # selectInput("CRS",
      #             label = "Select preffered CRS",
      #             choices = list("EPSG:3787", "EPSG:3912",
      #                            "EPSG:3794")),
      # fileInput("file", label = "CSV file input", multiple = FALSE),
      h6("CRS used: +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel
         +towgs84=426.9,142.6,460.1,4.91,4.49,\n-12.42,17.1 +units=m +no_defs")
      ),
    
    mainPanel(
      fluidRow(
        splitLayout(cellWidths = c("50%", "50%"), 
                    h5(strong("Original coordinates (WGS)")), 
                    h5(strong("Converted coordinates (GK)"))
      ),
      fluidRow(
        splitLayout(cellWidths = c("50%", "50%"), tableOutput("coords"), tableOutput("new.coords"))
      ),
      h5(strong("Points on map")),
        leafletOutput("leaflet")
     
      
    )
  )
  )))
