library(shiny)
library(leaflet)

shinyUI(fluidPage(
  
  titlePanel("WGStoGK - version 0.6"),
  
  fluidRow(
    column(2,
           textInput("coords", label = "Coordinates input", value = "46.05116 14.46990"),
           actionButton("action", label = "Convert"), ### Make button display converted coords.
           ### add text from thinkpad
           hr(),
           fileInput("file", label = "CSV file input", multiple = FALSE),
           selectInput("sep", "Separator", choices = c(".",",",";")),
           selectInput("header", "Header", choices = c(TRUE, FALSE)),
           actionButton("action", label = "Convert") ### Make button display converted coords.
           # selectInput("crs",
           #             label = "Select preffered CRS",
           #             choices = list("EPSG:3787", "EPSG:3912",
           #                            "EPSG:3794")),
    ),
    column(6,
           br(),
           leafletOutput("leaflet"),
           hr(),
           h6("CRS used: +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel
              +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")),
    column(2,
           h5(strong("Original coordinates (WGS)"),
              tableOutput("coords"))),
    
    column(2,
           h5(strong("Converted coordinates (GK)"),
              tableOutput("new.coords"))
           
    )
  )))
