#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

seniunija <- readRDS("dists.RDS") %>% sort
darzeliai <- readRDS("darzeliai.RDS") %>% sort

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Kindergarten Info System (KISS)"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      dateInput("birthddate", "Gimimo data", min = "2009-01-01",
                max = "2030-01-01"),
      selectizeInput("district", label = "Seniūnija",
                     choices = seniunija),
      selectizeInput(
        "city", label = "Deklaruoti mieste", 
        choices = setNames(1:3, c("Abu tėvai", "Vienas iš tėvų",
                                  "Nei vienas iš tėvų"))),
      checkboxInput(
        "2years", 
        label = "Bent vienas iš tėvų registruotas Vilniuje ne mažiau 2 metų?"),
      checkboxInput(
        "school",
        label = "Vienas iš tėvų mokosi bendrojo ugdymo mokykloje?"),
      # checkboxInput("city", label = "Deklaruotas mieste"),
      checkboxInput("3more", label = "3 ir daugiau"),
      checkboxInput("unable", label = "Žemas darbingumas"),
      conditionalPanel(
        condition = "input.city == 1", 
        checkboxInput("lonely", label = "Augina 1 iš tėvų")
      ),
      checkboxInput("otherkids", label = "Ar turite kitų vaikų Vilniaus darželiuose?"),
      conditionalPanel(
        condition = "input.otherkids",
        selectizeInput("otherkg", label = "Kuriuose?",
                       choices = sort(darzeliai), multiple = TRUE)
      ),
      selectizeInput(
        "language", label = "Kalba", 
        choices = setNames(1:4, c("Hebrajų", "Lenkų", "Lietuvių", "Rusų")),
        selected = 3),
      checkboxInput("special", label = "Specialūs poreikiai"),
      actionButton("go", label = "Prognozuoti")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       #plotOutput("distPlot")
      tableOutput("table")
    )
  )
))
