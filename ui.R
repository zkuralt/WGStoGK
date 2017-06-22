library(shiny)
library(leaflet)

shinyUI(fluidPage(
  
  titlePanel("WGStoGK - version 0.9"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("text", label = h5(strong("Coordinates input")), value = "46.05120 14.47035"),
      actionButton("convertText", label = "Convert coordinates"), ### Make button display converted coords.
      h6("Paste your coordinates as displayed above."),
      h6("Multiple coordinates in mixed format and separated by space are accepted."),
      br(),
      h6("Accepted input formats:"),
      h6("dd°mm'ss.ss''	dd°mm'ss.ss''"),
      h6("dd°mm.mmm'	dd°mm.mmm'"),
      h6("dd.dddd°	dd.dddd°"),
      hr(),
      h5(strong("Upload file (CSV or GPX)")),
      fileInput('file', label = NULL, accept=c('text/csv', 
                                               'text/comma-separated-values,text/plain', 
                                               '.csv', '.gpx')),
      radioButtons("sep", "Separator (only for CSV files)", c(Comma = ",", Semicolon = ";", 
                                                              Tab = "\t", Period = "."), ","),
      # checkboxInput("header", label = h6("Header"), value = FALSE),
      actionButton("convertFile", label = "Convert coordinates"), ### Make button display converted coords.
      br(),
      br(),
      h6("CSV files should have latitude in first column, longitude in second column, no header row."),
      h6("Multiple coordinates in mixed format are accepted."),
      width = 3),
    
    mainPanel(
      tabsetPanel(
        tabPanel("View locations on map",
                 br(),
                 fluidRow(
                   column(3,
                          actionButton("pickFromMap", label = "Pick coordinates from map")),
                   column(3, 
                          checkboxInput("cluster", label = h5("Cluster locations"), value = TRUE))),
                 leafletOutput("leaflet")),
        tabPanel("Configure output",
                 fluidRow(
                   column(2,
                          selectInput("crs", h5(strong("Select output CRS")), 
                                      choices = ui.crs),
                          h6("Search for the desired CRS by typing its code above or find it in the dropdown menu."),
                          tags$a(href="https://epsg.io/", h6("Which CRS is used in my area?"), target="_blank")),
                   column(6, 
                          h5(strong("Converted coordinates")),
                          tableOutput("coordsElevation"),
                          hr(),
                          h6(textOutput("selected.crs"))),
                   column(4,
                          h5(strong("Download file")),
                          br(),
                          downloadButton("download", label = "Download CSV file"),
                          br(),
                          checkboxInput("append", label = h6("Add original coordinates to downloaded file"),
                                        value = FALSE),
                          checkboxInput("add.elevation", label = h6("Add elevation to converted coordinates")),
                          hr(),
                          h6("Elevation data in meters above sea level. (source: Google Elevation API)"),
                          h6("You can pick elevation for up to 512 locations per request.")))),
        # tabPanel("Check input", 
        #          h5(strong("Original coordinates")),
        #          tableOutput("coords")),
        tabPanel("List of available CRS", tableOutput("epsg"))
      ), width = 9)
  )
)
)

