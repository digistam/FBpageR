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
      graph <- cbind(DF$object_name,DF$actor_id)
      g <- graph.data.frame(graph)
      bt <- betweenness(g)
      bt <- as.data.frame(as.table(bt))
      pr <- page.rank(g)$vector
      pr <- as.data.frame(as.table(pr))
      ev <- evcent(g,directed = FALSE, scale = TRUE, weights = NULL, options = igraph.arpack.default)$vector
      ev <- as.data.frame(as.table(ev))
      user <- as.data.frame(unique(DF$actor))
      names(bt) <- c('Username','Betweenness')
      names(pr) <- c('Username','PageRank')
      names(ev) <- c('Username','Eigenvector centrality')
      names(user) <- c('Username')
      dd <- merge(user, bt, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, pr, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, ev, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd[is.na(dd)] <- 0
      dd <<- as.data.frame(dd)
      dd[order(!dd$PageRank),]
    })
  })
})