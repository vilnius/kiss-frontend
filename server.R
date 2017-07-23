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
library(rgdal)
library(data.table)
library(sp)
library(geosphere)
library(DT)
library(plyr)
library(dplyr)
library(dtplyr)
library(lubridate)
library(readxl)
library(jsonlite)
darzeliai <- readRDS("darzeliai.RDS") %>% sort
# browser()
# zz <- fread("https://raw.githubusercontent.com/vilnius/darzeliai/master/data/darzeliai_grupes.csv", encoding = "UTF-8")
allkg <- fread("data/istaigos.csv", encoding = "UTF-8")
allkg1 <- data.frame(allkg) %>% filter(LABEL %in% darzeliai) %>% 
  select(LABEL, GIS_X, GIS_Y) %>% filter(GIS_X != 0)
coordinates(allkg1) <- c("GIS_X", "GIS_Y")
proj4string(allkg1) <- CRS("+init=epsg:3346")
tmp <- spTransform(allkg1, CRS("+proj=longlat +datum=WGS84"))
#apply(tmp@data, 1, function(x, ))
seniunija <- fread("data/seniunijos.csv", encoding = "UTF-8")

d <- read.csv(file = "data/priority_from_json.csv",
              check.names = FALSE, stringsAsFactors = FALSE)

gat <- read.csv(file = "data/GROUP_AGE_TYPE.csv",
                sep = ";", encoding = "UTF-8", na.strings = c("", "NA"),
                check.names = FALSE, stringsAsFactors = FALSE)

laukiantys <- read.csv(file = "data/laukianciuju_eileje_ataskaita.csv",
                       sep = ";", encoding = "UTF-8", na.strings = c("", "NA"),
                       check.names = FALSE, stringsAsFactors = FALSE)

# this input comes from karolis&raminta
empty.slots <- read.csv(file = "data/vietos.csv",
                        sep = ",", encoding = "UTF-8", na.strings = c("", "NA"),
                        check.names = FALSE, stringsAsFactors = FALSE) %>% 
  select(SCH, LANG, NEEDS, all.from.1.to.3, all.from.3.to.inf, 
         slots.from.1.to.3, slots.from.3.to.inf)

d <- d[,c("SCH","GLOBALID","GROUPTYPE","ID","ALGORITHM_ID","SCH_ORDERING",
          "PRIORITY_SUM","ROWNUM","BIRTHDATE","FINAL_PRIORITY")]

# adding group age type info to main dataset

d <- merge(d, gat[,c("ID","AGEFROM","AGETO")],
           by.x = "GROUPTYPE",
           by.y = "ID", all.x = T)

d$BIRTHDATE <- date(d$BIRTHDATE)

# adding birth date

# rename.matrix.laukiantys <- read.csv(file = "rename_matrix_laukiantys.csv", check.names = F, stringsAsFactors = F)
# names(laukiantys) <- rename.matrix.laukiantys$changed.names

# laukiantys$born.date <- as.Date(laukiantys$born.date)
d$age.of.child <- ((date("2017-01-01") - d$BIRTHDATE) / 365) %>% floor %>% as.numeric
d$is.from.1.to.3 <- ifelse(d$age.of.child < 3,"below.3","more.3")

empty.slots <- ddply(empty.slots, ~ SCH, function(xframe) {
  return(apply(xframe[,-1:-3],2,sum))
})




# names(empty.slots)[6] <- "kg_name"
d <- merge(d, empty.slots, all.x = T)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  rv <- reactiveValues()
  
  observeEvent(input$go, {
    if (!input$disclaimer) {
      # insertUI("#modal", where = "afterBegin",
      #          ui = )
      showModal(modalDialog(
        title = NULL,
        "Paspauskite sutikimą šalia mygtuko prognozuoti!",
        footer = modalButton("Uždaryti")
      ))
    }
    req(input$disclaimer)
    
    output$table <- DT::renderDataTable({
      prio <- input$school + input$threemore +
        input$unable + input$lonely# + (length(input$otherkids) > 0)
      if(input$city == "2") {
        prio <- prio + 1e2
      } else if (input$city == "1") {
        prio <- prio + 1e3
      }
      input.age.of.child <- (Sys.Date() - input$birthdate) %>% 
        as.integer %>% `%/%`(365)
      # req(rv$home)
      # req(rv$work)
      # leaving d columns that we need
      
      output$priority <- renderUI({
        p(strong("Jūsų prioritetas:"), prio)
      })
      
      output$disclaimer <- renderUI({
        disclaim <- 'Žemiau pateikti rezultatai galioja su sąlyga, kad darželis bus nurodytas 1 prioritetu. Registruojantis į eilę, rekomenduojame 1 prioritetu nurodyti darželį, į kurį turite didžiausias galimybes pakliūti pagal žemiau pateiktus rezultatus. Jeigu į jį nepateksite, pakliūti į 2 ir žemesniais prioritetais nurodytus darželius tikimybė bus kur kas mažesnė.'
        div(disclaim, class="warning-disclaimer")
      })
      
      input.add <- allkg %>% select(SCH = ID, elderate = ELDERATE_ID) %>% 
        mutate(add = ifelse(elderate %in% input$district, 1, 0) + 
                 ifelse(SCH %in% input$otherkg, 1, 0)) %>% 
        select(SCH, add) %>% data.frame
      
      input.priority <- prio
      input.birth.date <- input$birthdate
      input.age.type <- ifelse(input.age.of.child <=3,"below.3","more.3")
      # sub.d <- subset(d, input.age.of.child >= AGEFROM & input.age.of.child <= AGETO) 
      
      # estimate rank number in each kg x group
      
      rank.enroll <- ddply(d[d$SCH_ORDERING == 1 & d$is.from.1.to.3 == input.age.type,], ~ SCH, function(xframe) {
        xframe <<- xframe
        # cat(paste("Ranking in: SCH -", xframe$SCH[1], sep = " "),"\n")
        
        from.which.to.remove <- ifelse(input.age.type == "below.3","slots.from.1.to.3","slots.from.3.to.inf")
        free.space <- xframe[1,from.which.to.remove]
        total.space <- xframe[1,paste0("all.",gsub("slots.","",from.which.to.remove))]
        
        add.to.prior <- input.add[input.add$SCH == xframe$SCH[1], 2]
          
        
        # if (free.space == 0 | is.na(free.space)) {
        #   print("No space left")
        # } else {
        
        # filling birth dates, where missing
        # if(any(!is.na(xframe$BIRTHDATE))) {
        #   xframe[is.na(xframe$BIRTHDATE),"BIRTHDATE"] <- max(xframe$BIRTHDATE,na.rm = T)
        # } else {
        #   xframe$born.date <- input.birth.date # if there are kg and group, where all childs birth dates are missing
        # }
        
        # rank.frame <- rbind(data.frame(xframe[,c("FINAL_PRIORITY","BIRTHDATE")],target = 0),
        #                     data.frame(FINAL_PRIORITY = input.priority,BIRTHDATE = input.birth.date, target = 1))
        
        rank.frame <- rbind(data.frame(xframe[,c("FINAL_PRIORITY","BIRTHDATE")],target = 0),
                            data.frame(FINAL_PRIORITY = input.priority + add.to.prior,BIRTHDATE = input.birth.date, target = 1))
        
        rank.frame <- arrange(rank.frame, desc(FINAL_PRIORITY), BIRTHDATE) # after priority, youngest get first in a queue
        
        place.in.queue <- which(rank.frame$target == 1)
        
        enrolled.or.not <- ifelse(place.in.queue <= free.space, "Yes","No")
        
        # output
        
        output <- c("enrolled.or.not" = enrolled.or.not,
                    "place.in.queue" = place.in.queue,
                    "free.slots" = free.space,
                    "total.slots" = total.space,
                    "total.in.queue.with.first.priority" = nrow(rank.frame),
                    "percentile.in.free.slots" = place.in.queue / free.space)
        
        return(output)
        # }
      })
      
      rank.enroll <- rank.enroll %>% mutate(
        place.in.queue = as.numeric(place.in.queue),
        free.slots = as.numeric(free.slots),
        total.slots = as.numeric(total.slots),
        total.in.queue.with.first.priority = as.numeric(total.in.queue.with.first.priority),
        percentile.in.free.slots = as.numeric(percentile.in.free.slots)
      )
      zz <- arrange(rank.enroll, desc(enrolled.or.not),place.in.queue,desc(free.slots))
      
      if (!is.null(rv$work) & !is.null(rv$home)) {
        zz <- zz %>% filter(enrolled.or.not == "Yes") %>% 
          select(SCH, place.in.queue, free.slots, 
                 total.in.queue.with.first.priority,
                 total.slots) %>% 
          left_join(allkg %>% select(ID, LABEL, GIS_X, GIS_Y, BUILDDATE, 
                                     `LEFT(ADDRESS, 256)`), 
                    by = c("SCH" = "ID")) #%>% slice(1:20)
        
        coordinates(zz) <- c("GIS_X", "GIS_Y")
        proj4string(zz) <- CRS("+init=epsg:3346")
        tmp <- spTransform(zz, CRS("+proj=longlat +datum=WGS84"))
        
        kgs <- data.frame(
          Darzelis = tmp@data$LABEL,
          Eile = tmp@data$place.in.queue,
          `Viso eileje` = tmp@data$total.in.queue.with.first.priority,
          laisvos = tmp@data$free.slots,
          total = tmp@data$total.slots,
          `Statybos metai` = tmp@data$BUILDDATE,
          Adresas = tmp@data$`LEFT(ADDRESS, 256)`,
          Namai = round(distVincentyEllipsoid(tmp, rv$home)/1e3, 1),
          Darbas = round(distVincentyEllipsoid(tmp, rv$work)/1e3, 1)
        )
        names(kgs) <- c("Darželis", "Jūsų vieta eilėje", "Iš viso eilėje laukia","Iš viso laisvų vietų",
                        "Iš viso vietų", "Statybos metai","Adresas", "Atstumas nuo namų", "Atstumas nuo darbo")
        removeUI("#no_work_home")
      } else {
        output$no_work_home <- renderUI({
          div("Neįvedėte namų arba darbo adreso, todėl negalime apskaičiuoti atstumų iki darželių")
        })
        zz <- zz %>% filter(enrolled.or.not == "Yes") %>% 
          select(SCH, place.in.queue, free.slots, 
                 total.in.queue.with.first.priority,
                 total.slots) %>% 
          left_join(allkg %>% select(ID, LABEL, BUILDDATE, 
                                     `LEFT(ADDRESS, 256)`), 
                    by = c("SCH" = "ID"))
        
        kgs <- data.frame(
          Darzelis = zz$LABEL,
          Eile = zz$place.in.queue,
          `Viso eileje` = zz$total.in.queue.with.first.priority,
          laisvos = zz$free.slots,
          total = zz$total.slots,
          `Statybos metai` = zz$BUILDDATE,
          Adresas = zz$`LEFT(ADDRESS, 256)`,
          stringsAsFactors = FALSE
        )
        names(kgs) <- c("Darželis", "Jūsų vieta eilėje", "Iš viso eilėje laukia","Iš viso laisvų vietų",
                        "Iš viso vietų", "Statybos metai","Adresas")
      }
      DT::datatable(kgs, options = list(
        language = list(
          search = "Ieškoti",
          lengthMenu = "Rodyti _MENU_ įrašų",
          paginate = list(
            first = "Pirmas",
            `next` = "Kitas",
            previous = "Ankstesnis",
            last = "Paskutinis"
          ),
          info = "Rodomi įrašai nuo _START_ iki _END_ iš _TOTAL_"
        )
      ))
    })
  })
  output$google_maps_API <- renderUI({
    connection_info <- readLines('private/google-api-key.csv')
    HTML(paste0(
            '<script async defer src=" https://maps.googleapis.com/maps/api/js?key=',
            connection_info,'&libraries=places&callback=initMap"></script>'
                )
        )
  })
  
  observeEvent(input$marker_lat, {
    req(input$marker_lat)
    req(input$marker_id == "home-map")
    rv$home <- c(input$marker_lng, input$marker_lat)
  })

  observeEvent(input$marker_lat, {
    req(input$marker_lat)
    req(input$marker_id == "work-map")
    rv$work <- c(input$marker_lng, input$marker_lat)
  })
  
  # output$coords <- renderUI({
  #   req(input$marker_id, input$marker_lat, input$marker_lng)
  #   tagList(
  #     div(input$marker_id),
  #     div(input$marker_lat),
  #     div(input$marker_lng)
  #   )
  #   
  #   #browser()
  # })
  
  
})
