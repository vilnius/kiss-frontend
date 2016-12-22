#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
library(magrittr)
library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  # output$distPlot <- renderPlot({
  #   
  #   # generate bins based on input$bins from ui.R
  #   x    <- faithful[, 2] 
  #   bins <- seq(min(x), max(x), length.out = input$bins + 1)
  #   
  #   # draw the histogram with the specified number of bins
  #   hist(x, breaks = bins, col = 'darkgray', border = 'white')
  #   
  # })
  observeEvent(input$go, {
    output$table <- renderTable({
      data.frame(a = 1:2, b = 3:4)
    })
  })
  output$google_maps_API <- renderUI({
    connection_info <- readLines('private/google-api-key.csv')
    HTML(paste0(
            '<script async defer src=" https://maps.googleapis.com/maps/api/js?key=',
            connection_info,'&callback=initMap"></script>'
                )
        )
  })
  
  output$coords <- renderUI({
    
    req(input$marker_id, input$marker_lat, input$marker_lng)
    tagList(
      div(input$marker_id),
      div(input$marker_lat),
      div(input$marker_lng)
    )
    
    #browser()
  })
  
})
