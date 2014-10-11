options(shiny.maxRequestSize=100*1024^2)
library(lubridate)
if (!require("lubridate")) {
  install.packages("lubridate", repos="http://cran.rstudio.com/") 
  library("lubridate") 
}
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
    output$newGraph <- suppressWarnings(renderPlot({
      graph <- cbind(DF$actor_id,DF$object_id)
      na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
      g <- graph.data.frame(graph, directed = F)
      set.seed(111)
      bad.vs <- V(g)[degree(g) < as.numeric(2)]
      ng <- delete.vertices(g, bad.vs)
      V(ng)$size = 2
      V(ng)$color = degree(ng)+1
      V(ng)$label.cex = 0.9
      layout1 <- layout.fruchterman.reingold(ng)
      ng <- simplify(ng)
      plot(ng, layout = layout1)
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