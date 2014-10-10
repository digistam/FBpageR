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
      #input$goButton
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
      #dg <- degree.distribution(g)
      dg <- degree(sg, v=V(g), mode = c("total"), loops = TRUE, normalized = FALSE) 
      dg <- as.data.frame(as.table(dg))
      names(dg) <- c('Username','Degree')
      dg <<- dg
      #bt <- betweenness(sg)
      #bt <- as.data.frame(as.table(bt))
      #names(bt) <- c('Username','Betweenness')
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
      dd <- merge(user, mn, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, dg, by = 'Username',incomparables = NULL, all.x = TRUE)
      #dd <- merge(dd, bt, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, pr, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, ev, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, person, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd[is.na(dd)] <- 0
      #cc <- table(unlist(paste(ddd[,1],ddd[,2],ddd[,3],ddd[,5],ddd[,4])))
      tbl <- dd
      names(tbl) <- c('Account','Frequency','Degree','PageRank','Eigenvector','Name')
#       tbl$Degree <- as.numeric.factor(tbl$Degree)
#       tbl$PageRank <- as.numeric.factor(tbl$PageRank)
#       tbl$Eigenvector <- as.numeric.factor(tbl$Eigenvector)
      tbl <- tbl[order(tbl$Frequency, decreasing = T),]
      df <- tbl
      #dd <<- as.data.frame(dd)
      #dd[order(!dd$PageRank),]
    })
#     plotMe(dt,2)
    output$newGraph <- suppressWarnings(renderPlot({
      graph <- cbind(DF$actor_id,DF$object_id)
      na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
      g <- graph.data.frame(graph, directed = F)
      set.seed(111)
      #layout1 <- layout.fruchterman.reingold(g)
      #layout1 <- layout.auto(g)
      layout1 <- layout.fruchterman.reingold(ng)#, area=vcount(ng)^2)
      bad.vs <- V(g)[degree(g) < as.numeric(2)]
      ng <- delete.vertices(g, bad.vs)
      V(ng)$size = 2#degree(ng)*0.2
      V(ng)$color = degree(ng)+1
      V(ng)$label.cex = 0.9#degree(ng)*0.1
      #V(ng)$weight=degree(ng)
      ng <<- simplify(ng)
      plot(ng, layout = layout1)
      }))
    output$downloadGraph = downloadHandler(
      filename = "retweetnetwork.graphml",
      content = function(file) {
      write.graph(g, file, format <- 'graphml')
  })
  })
})