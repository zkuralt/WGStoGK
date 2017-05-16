library(shiny)
library(sp)
library(measurements)
library(rgdal)
library(leaflet)
source("anyWGStoDec.R")
source("testElements.R")
source("convertBackToWGS.R")
source("convertToGK.R")

shinyServer(function(input, output) {
  
  observeEvent(input$convertText{
    
    ## Original coordinates
    origCoords <- reactive({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      x <- data.frame(matrix(x, ncol = 2, byrow = TRUE))
      names(x) <- c("lat", "long")
      x[,1:2]
    }) 
    
    origInput <- reactive({
      x <- read.table(text = input$text, stringsAsFactors = FALSE)
      convertBackToWGS(x)
    })
    
    ## Coords imported via textInput
    coordTextInput <- reactive({
      # if(is.null(input$file)) {
      x <- read.table(text = input$coords, stringsAsFactors = FALSE)
      x <- convertToGK(x)
      coordinates(x)
      # }
    })    
  })
  
  # observeEvent(input$convertFile {
  #   
  #   sepInput <- reactive({
  #     print(input$sep)
  #   })
  #   
  #   headInput <- reactive({
  #     print(input$header)
  #   })
  #   
  #   coordFileInput  <- reactive({
  #     x <- read.table(file = input$file, sep = sepInput, header = headInput)
  #     x <- convertToGK(x)
  #     coordinates(x)
  #     
  #   })
  # })
  
  ## Getting original (input) coords displayed
  output$coords <- renderTable({
    coordinates(origCoords())
  }, digits = 7)
  
  ## Getting converted coords displayed
  # if(is.null(input$file)){
    output$new.coords <- renderTable({
      coordinates(coordTextInput())
    }, digits = 2)
  #   }
  # else {
  #   output$new.coords <- renderTable({
  #     coordinates(coordFileInput())
  #   }, digits = 2)}
  
  
  output$leaflet <- renderLeaflet({
    
    coordLabel<- apply(coordinates(origInput()), MARGIN = 1, FUN = function(z) {
      sprintf("long: %s lat: %s", z[1], z[2])
    })
    
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)) %>%
      addMarkers(data = origInput(), clusterOptions = markerClusterOptions(),
                 label = coordLabel) %>%
      addScaleBar(position = "bottomleft", scaleBarOptions(metric = TRUE, imperial = FALSE))
    
  })
})