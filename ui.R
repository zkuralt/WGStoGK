library(shiny)
library(leaflet)

shinyUI(fluidPage(
  
  titlePanel("WGStoGK - version 0.7"),
  
  fluidRow(
    column(3,
           textInput("text", label = "Coordinates input", value = "46.05120 14.47035"),
           actionButton("convertText", label = "Convert coordinates"), ### Make button display converted coords.
           h6("Paste your coordinates as displayed above."),
           h6("Multiple coordinates in mixed format and separated by space are accepted."),
           br(),
           h6("Accepted input formats:"),
           h6("dd°mm'ss.ss''	dd°mm'ss.ss''"),
           h6("dd°mm.mmm'	dd°mm.mmm'"),
           h6("dd.dddd°	dd.dddd°"),
           hr(),
           fileInput('file', 'Upload CSV File',
                     accept=c('text/csv', 
                              'text/comma-separated-values,text/plain', 
                              '.csv')),
           actionButton("convertFile", label = "Convert coordinates"), ### Make button display converted coords.
           br(),
           br(),
           h6("Latitude in first column, longitude in second column, no header row."),
           h6("Multiple coordinates in mixed format are accepted."),
           br(),
           # checkboxInput("header", "Header", TRUE),
           radioButtons("sep", "Separator", c(Comma = ",", Semicolon = ";", 
                                              Tab = "\t", Period = "."), ","),
           hr()
           # selectInput("crs",
           #             label = "Select preffered CRS",
           #             choices = list("EPSG:3787", "EPSG:3912",
           #                            "EPSG:3794")),
    ),
    column(5,
           br(),
           leafletOutput("leaflet"),
           hr(),
           h6("CRS used: +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel
              +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs")),
    column(2,
           h5(strong("Original coordinates (WGS)")),
           tableOutput("coords")),
    column(2,
           h5(strong("Converted coordinates (GK)")),
           tableOutput("new.coords"),
           downloadButton("download", label = "Download CSV file"),
           checkboxInput("append", label = "Add original coordinates to downloaded file", value = FALSE))
    )))
  