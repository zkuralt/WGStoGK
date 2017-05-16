library(shiny)
library(leaflet)

shinyUI(fluidPage(
  titlePanel("WGStoGK - version 0.6"),
  sidebarLayout(
    sidebarPanel(
      textInput("text", label = "Coordinates input", value = "46.05116 14.46990"),
      h6("Paste your coordinates as displayed above."),
      h6("Multiple coordinates in mixed format are accepted."),
      br(),
      h6("Accepted input formats:"),
      h6("dd°mm'ss.ss''	dd°mm'ss.ss''"),
      h6("dd°mm.mmm'	dd°mm.mmm'"),
      h6("dd.dddd	dd.dddd"),
      hr(),
      fileInput("file", label = "CSV file input", multiple = FALSE),
      selectInput("sep", label = "Separator", choices = c(".", ",", ";")),
      selectInput("header", label = "Header", choices = c(TRUE, FALSE))
      # selectInput("CRS",
      #             label = "Select preffered CRS",
      #             choices = list("EPSG:3787", "EPSG:3912",
      #                            "EPSG:3794")),
    ),
    
    mainPanel(
      fluidRow(
        splitLayout(cellWidths = c("40%", "40%"),
                    h5(strong("Original coordinates (WGS)")),
                    h5(strong("Converted coordinates (GK)"))
        ),
        fluidRow(
          splitLayout(cellWidths = c("40%", "40%"), tableOutput("coords"), tableOutput("new.coords"))
        ),
        h5(strong("Points on map")),
        leafletOutput("leaflet"),
        br(),
        h6("CRS used: +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel
         +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")
      )
    )
  )))
