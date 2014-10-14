options(shiny.maxRequestSize=100*1024^2)
library(lubridate)
if (!require("lubridate")) {
  install.packages("lubridate", repos="http://cran.rstudio.com/") 
  library("lubridate") 
}

if (!require("googleVis")) {
  install.packages("googleVis", repos="http://cran.rstudio.com/") 
  library("googleVis") 
}

if (!require(devtools)) {
  install.packages("devtools")
  devtools::install_github("rstudio/shiny-incubator")
}
library(shinyIncubator)

shinyServer(function(input, output, session) {
  observe({
    inFile<-input$dbfile
    print(inFile)
    if(is.null(inFile))
      return(NULL)
    connectSQL(inFile$datapath)
    dbtbl <- dbListTables(con)
    
    output$stream <- renderDataTable({
      isolate({
        q <- dbGetQuery(con, "SELECT * FROM stream ORDER BY date DESC")
        DF <<- as.data.frame.matrix(q)
        DF$date <- as.POSIXct(DF$date,format = "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC")
        DF$date <- with_tz(DF$date, "Europe/Paris")
        DF
      })
      DF[, input$show_vars, drop = FALSE]
    })
    output$influence <- renderDataTable({
      withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
      Sys.sleep(1)
      graph <- cbind(DF$object_id,DF$actor_id)
      na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
      g <<- graph.data.frame(graph, directed = F)
      V(g)$size=degree(g)*5
      V(g)$color=degree(g)+1
      sg <<- simplify(g)
      dg <- degree(sg, v=V(g), mode = c("total"), loops = TRUE, normalized = FALSE) 
      dg <- as.data.frame(as.table(dg))
      names(dg) <- c('Username','Degree')
      dg <<- dg
      pr <- page.rank(sg)$vector
      pr <- as.data.frame(as.table(pr))
      names(pr) <- c('Username','PageRank')
      ev <- evcent(sg,directed = FALSE, scale = TRUE, weights = NULL, options = igraph.arpack.default)$vector
      ev <- as.data.frame(as.table(ev))
      names(ev) <- c('Username','Eigenvector centrality')
      mn <- tapply(graph,INDEX = graph,FUN=table)
      mn <- as.data.frame(as.table(mn))
      names(mn) <- c('Username','Freq')
      user <- as.data.frame(unique(DF$actor_id))
      names(user) <- c('Username')
      person <- cbind(DF$actor,DF$actor_id)
      person <- as.data.frame(unique(person))
      names(person) <- c('Name','Username')
      dd <- merge(user, person, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, mn, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, dg, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, pr, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, ev, by = 'Username',incomparables = NULL, all.x = TRUE)
      
      dd[is.na(dd)] <- 0
      tbl <- dd
      names(tbl) <- c('Account','Name','Frequency','Degree','PageRank','Eigenvector')
      tbl <- tbl[order(tbl$Frequency, decreasing = T),]
      df <- tbl
      })
    })
    output$newGraph <- suppressWarnings(renderPlot({
     

#       graph <- cbind(DF$actor_id,DF$object_id)
#       na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
#       g <- graph.data.frame(graph, directed = F)
#       set.seed(111)
#       bad.vs <- V(g)[degree(g) < as.numeric(input$visibleNodes)]
#       ng <- delete.vertices(g, bad.vs)
#       V(ng)$size[degree(ng) > as.integer(input$highDegree)] = as.integer(input$nodeSizeHighDegree)
#       V(ng)$size[degree(ng) < as.integer(input$highDegree)] = as.integer(input$nodeSizeLowDegree)
#       #V(ng)$size = 2
#       V(ng)$color = degree(ng)+1
#       #V(ng)$label.cex[degree(ng) > 20] = 3
#       #input$highDegree
#       V(ng)$label.cex[degree(ng) > as.integer(input$highDegree)] = as.integer(input$labelSizeHighDegree)
#       V(ng)$label.cex[degree(ng) < as.integer(input$highDegree)] = as.integer(input$labelSizeLowDegree)
#       if(input$labelSizeLowDegree == 0) {
#         V(ng)$label.cex[degree(ng) < as.integer(input$highDegree)] = 0.1
#       }
#       else {
#         V(ng)$label.cex[degree(ng) < as.integer(input$highDegree)] = as.integer(input$labelSizeLowDegree)  
#       }
# #       if(input$hideNodes == T) {
# #         bad.vs <- V(ng)[degree(ng) < 2]
# #         ng <- delete.vertices(ng, bad.vs)
# #       }
#       V(ng)$label.color[degree(ng) > as.integer(input$highDegree)] = 'red'
#       V(ng)$label.color[degree(ng) < as.integer(input$highDegree)] = 'black'
#       V(ng)$label.family <- "Arial"
#       layout1 <- layout.fruchterman.reingold(ng)
#       ng <<- simplify(ng)
#       setProgress(detail = "Generating plot ...")
#       plot(ng, layout = layout1)
        withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
        Sys.sleep(0.5)
        graph <- cbind(DF$actor_id,DF$object_id)
        na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
        g <- graph.data.frame(graph, directed = F)
        set.seed(111)
        bad.vs <- V(g)[degree(g) < 2]
        ng <- delete.vertices(g, bad.vs)
        # V(ng)$size[degree(ng) > 10] = 3
        # V(ng)$size[degree(ng) < 10] = 2
        setProgress(detail = "Generating nodes and edges ...")
        Sys.sleep(1)
        V(ng)$size = 3
        V(ng)$color = degree(ng)+1
        #V(ng)$label.cex[degree(ng) > 20] = 3
        #input$highDegree
        V(ng)$label.cex[degree(ng) > 20] = 3
        V(ng)$label.cex[degree(ng) < 20] = 0.75
        #if(input$labelSizeLowDegree == 0) {
        #  V(ng)$label.cex[degree(ng) < 20] = 0.1
        #}
        #else {
        #  V(ng)$label.cex[degree(ng) < 20] = 4  
        #}
        #       if(input$hideNodes == T) {
        #         bad.vs <- V(ng)[degree(ng) < 2]
        #         ng <- delete.vertices(ng, bad.vs)
        #       }
        setProgress(detail = "Generating labels ...")
        Sys.sleep(1)
        V(ng)$label.color[degree(ng) > 20] = 'red'
        V(ng)$label.color[degree(ng) < 20] = 'black'
        V(ng)$label.family <- "Arial"
        setProgress(detail = "Generating graph layout ...")
        Sys.sleep(1)
        layout1 <- layout.fruchterman.reingold(ng)
        ng <<- simplify(ng)
        setProgress(detail = "Generating graph output ...")
        plot(ng, layout = layout1)
      })
      }))
    output$downloadGraph = downloadHandler(
      filename = "network.graphml",
      content = function(file) {
        V(g)$size=degree(g)*5
        V(g)$color=degree(g)+1
        V(g)$label.cex <- degree(g)*0.8
      write.graph(g, file, format <- 'graphml')
  })
  })
})