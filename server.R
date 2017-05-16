library(shiny)
library(sp)
library(measurements)
library(leaflet)
source("anyWGStoDec.R")
source("testElements.R")
source("convertBackToWGS.R")
source("convertToGK.R")
source("prepareCoords.R")

shinyServer(function(input, output) {
  
  coordInput <- reactive({
    x <- read.table(text = input$text, stringsAsFactors = FALSE)
    x <- prepareCoords(x)
    x
  })
  
  origCoords <- reactive({
    x <- read.table(text = input$text, stringsAsFactors = FALSE)
    x <- data.frame(matrix(x, ncol = 2, byrow = TRUE))
    names(x) <- c("lat", "long")
    x[,1:2]
  })
  
  convertedCoords <- reactive({
    coordinates(convertToGK(coordInput()))
  })
  
  coordsForLeaflet <- reactive({
    coordinates(convertBackToWGS(convertToGK(coordInput())))
  })
  
  output$coords <- renderTable({
    origCoords()
  }, digits = 5)
  
  output$new.coords <- renderTable({
    coordinates(convertedCoords())
  }, digits = 2)
  
  output$leaflet <- renderLeaflet({
    
    coordLabel <- apply(coordinates(coordsForLeaflet()), MARGIN = 1, FUN = function(z) {
      sprintf("long: %s lat: %s", z[1], z[2])
    })
    
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)) %>%
      addMarkers(data = coordsForLeaflet(), clusterOptions = markerClusterOptions(),
                 label = coordLabel) %>%
      addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE))
    
  })
})
