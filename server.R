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

library(sqldf)
if (!require("sqldf")) {
  install.packages("sqldf", repos="http://cran.rstudio.com/") 
  library("sqldf") 
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
        DFcontent <<- as.data.frame.matrix(q)
        q <- dbGetQuery(con, "SELECT * FROM likes")
        DFlikes <<- as.data.frame.matrix(q)  
        DF <<- merge(DFcontent, DFlikes, by = 'post_id',incomparables = NULL, all.x = TRUE)
        names(DF) <- c("post_id","id","object_id","type","object_name","actor","actor_id","date","message","story","link","description","comments","likes","application","like_id","liker","liker_id")
        DF$date <- as.POSIXct(DF$date,format = "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC")
        DF$date <- with_tz(DF$date, "Europe/Paris")
        DF <<- DF
      })
      DF[, input$show_vars, drop = FALSE]
    })
    output$likers <- renderDataTable({
      withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
      Sys.sleep(1)
#      graph <- cbind(DF$object_id,DF$actor_id)
#      graph <- cbind(DF$post_id,DF$actor_id)
      set.seed(111)
      graph <- cbind(DF$liker_id,DF$post_id)
      na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
      g <- graph.data.frame(graph, directed = T)
      g <- delete.vertices(g, which(is.na(V(g)$name))) 
      bad.vs <- V(g)[degree(g) < 1]
      g <- delete.vertices(g, bad.vs)
      V(g)$size=degree(g)*5
      V(g)$color=degree(g)+1
      g <- simplify(g)
      dg <- degree(g, v=V(g), mode = c("total"), loops = TRUE, normalized = FALSE) 
      dg <- as.data.frame(as.table(dg))
      names(dg) <- c('Username','Degree')
      dg <<- dg
      pr <- page.rank(g)$vector
      pr <- as.data.frame(as.table(pr))
      names(pr) <- c('Username','PageRank')
      ev <- evcent(g,directed = FALSE, scale = TRUE, weights = NULL, options = igraph.arpack.default)$vector
      ev <- as.data.frame(as.table(ev))
      names(ev) <- c('Username','Eigenvector centrality')
      mn <- tapply(graph,INDEX = graph,FUN=table)
      mn <- as.data.frame(as.table(mn))
      names(mn) <- c('Username','Freq')
      user <- as.data.frame(unique(DF$liker_id))
      names(user) <- c('Username')
      person <- cbind(DF$liker,DF$liker_id)
      person <- as.data.frame(unique(person))
      names(person) <- c('Name','Username')
      dd <- merge(user, person, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, mn, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, dg, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, pr, by = 'Username',incomparables = NULL, all.x = TRUE)
      dd <- merge(dd, ev, by = 'Username',incomparables = NULL, all.x = TRUE)
      
      dd[is.na(dd)] <- 0
      tbl <<- dd
      names(tbl) <- c('Account','Name','Frequency','Degree','PageRank','Eigenvector')
      tbl <<- tbl[order(tbl$Frequency, decreasing = T),]
      df <- tbl
      df[!df$PageRank == 0, ]
      })
    })

    output$stat_likers <- renderGvis({
      withProgress(session, {setProgress(message = "Creating bubble chart", detail = "This may take a few moments...")
                         Sys.sleep(0.5)
                         gvisBubbleChart(tbl[tbl$Degree > 1,],idvar = "Account", xvar="Degree", yvar="Frequency", options=list( hAxis='{title: "Degree"}',vAxis='{title: "Frequency"}' ,width = '100%', height=800) )
    })})
    output$stat_objectLikes <- renderGvis({
      withProgress(session, {setProgress(message = "Creating pie chart", detail = "This may take a few moments...")
      Sys.sleep(0.5)  
      objectLikes <- as.data.frame(cbind(DFcontent$object_id,as.numeric(DFcontent$likes)))
      objectLikes <- na.omit(objectLikes)
      names(objectLikes) <- c('object_id','likes')
      objectLikes <- sqldf("select object_id,sum(likes) from objectLikes group by object_id")
      names(objectLikes) <- c('object_id','likes')
      gvisPieChart(objectLikes,options=list(
        #slices="{4: {offset: 0.2}, 0: {offset: 0.3}}",
        title='Likes per object',
        pieSliceText='label',
        legend.position = 'labeled',
        pieSliceText = 'value',
        pieHole=0.2
      )
      )
      })
    })
    output$stat_objectPosts <- renderGvis({
      withProgress(session, {setProgress(message = "Creating pie chart", detail = "This may take a few moments...")
                         Sys.sleep(0.5)  
#                          objectLikes <- as.data.frame(cbind(DFcontent$object_id,as.numeric(DFcontent$likes)))
#                          objectLikes <- na.omit(objectLikes)
#                          names(objectLikes) <- c('object_id','likes')
                         objectPosts <- sqldf("select object_id,count(object_id) from DFcontent group by object_id")
                         names(objectPosts) <- c('object_id','posts')
                         gvisPieChart(objectPosts,options=list(
                           #slices="{4: {offset: 0.2}, 0: {offset: 0.3}}",
                           title='Posts per object',
                           pieSliceText='label',
                           legend.position = 'labeled',
                           pieSliceText = 'value',
                           pieHole=0.2
                         )
                         )
      })
    })

#     output$stat_links <- renderDataTable({
#       link <- head(sort(table(DFcontent$link),decreasing = T, na.rm = T), n <- 10)
#       link <- as.data.frame(as.table(link))
#       names(link) <- c('Url','Frequency')
#       link[link$Url=="",] <- NA
#       link <- na.omit(link)
#       link
#       
#     },options = list(paging = FALSE, searching = FALSE, searchable = FALSE))
    link <- head(sort(table(DFcontent$link),decreasing = T, na.rm = T), n <- 10)
    link <- as.data.frame(as.table(link))
    names(link) <- c('Url','Frequency')
    link[link$Url=="",] <- NA
    link <- na.omit(link)
    output$stat_links <- renderGvis({
      withProgress(session, {setProgress(message = "Creating pie chart", detail = "This may take a few moments...")
                             Sys.sleep(0.5)
      gvisPieChart(link,options=list(
      #slices="{4: {offset: 0.2}, 0: {offset: 0.3}}",
      title='Link analysis',
      pieSliceText='label',
      legend.position = 'labeled',
      pieSliceText = 'value',
      pieHole=0.2
      )
    )
    })})
    apps <- head(sort(table(DFcontent$application),decreasing = T, na.rm = T), n <- 10)
    apps <- as.data.frame(as.table(apps))
    names(apps) <- c('Application','Frequency')
    apps[apps$Application=="",] <- NA
    apps <- na.omit(apps)
    apps[apps$Application==" ",] <- NA
    apps <- na.omit(apps)
  
#     output$stat_apps <- renderDataTable({
#       apps <- head(sort(table(DFcontent$application),decreasing = T, na.rm = T), n <- 10)
#       apps <- as.data.frame(as.table(apps))
#       names(apps) <- c('Application','Frequency')
#       apps[apps$Application=="",] <- NA
#       apps <- na.omit(apps)
#       apps[apps$Application==" ",] <- NA
#       apps <- na.omit(apps)
#       apps
#     },options = list(paging = FALSE, searching = FALSE, searchable = FALSE))
    output$stat_apps <- renderGvis({
      withProgress(session, {setProgress(message = "Creating pie chart", detail = "This may take a few moments...")
                             Sys.sleep(0.5)
      gvisPieChart(apps,options=list(
      #slices="{4: {offset: 0.2}, 0: {offset: 0.3}}",
      title='App analysis',
      pieSliceText='label',
      pieHole=0.2
    ))})
    })

    output$authors <- renderDataTable({
      withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
                         Sys.sleep(1)
                         set.seed(111)
                         graph <- cbind(DF$post_id,DF$actor_id)
                         na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
                         g <- graph.data.frame(graph, directed = T)
                         g <- delete.vertices(g, which(is.na(V(g)$name))) 
                         bad.vs <- V(g)[degree(g) < 1]
                         g <- delete.vertices(g, bad.vs)
                         V(g)$size=degree(g)*5
                         V(g)$color=degree(g)+1
                         g <- simplify(g)
                         dg <- degree(g, v=V(g), mode = c("total"), loops = TRUE, normalized = FALSE) 
                         dg <- as.data.frame(as.table(dg))
                         names(dg) <- c('Username','Degree')
                         dg <<- dg
                         pr <- page.rank(g)$vector
                         pr <- as.data.frame(as.table(pr))
                         names(pr) <- c('Username','PageRank')
                         ev <- evcent(g,directed = FALSE, scale = TRUE, weights = NULL, options = igraph.arpack.default)$vector
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
                         #df[!df$PageRank == 0, ]
      })
    })
    dftype <- as.data.frame(table(DFcontent$type))
    output$Types <- renderGvis({
      withProgress(session, {setProgress(message = "Creating pie chart", detail = "This may take a few moments...")
                             Sys.sleep(0.5)
      gvisPieChart(dftype,options=list(
        title='Post types',
        pieSliceText='label',
        pieHole=0.2)
                   )
    })})
    output$likersGraph <- suppressWarnings(renderPlot({
        withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
        Sys.sleep(0.5)
        #graph <- cbind(DF$liker_id,DF$post_id)
        graph <- cbind(DF$liker_id,DF$actor_id)
        na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
        g <- graph.data.frame(graph, directed = T)
        g <- delete.vertices(g, which(is.na(V(g)$name))) 
        bad.vs <- V(g)[degree(g) < 2]
        ng <- delete.vertices(g, bad.vs)
        setProgress(detail = "Generating nodes and edges ...")
        Sys.sleep(1)
        V(ng)$size = 2 #degree(ng)/4
        V(ng)$color = degree(ng)+1
        V(ng)$label.cex[degree(ng) > 20] = 2
        V(ng)$label.cex[degree(ng) < 20] = 1 #degree(ng)/4
        V(ng)$label.cex[V(ng)$label.cex < 1] = 1
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
output$authorsGraph <- suppressWarnings(renderPlot({
  withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
                         Sys.sleep(0.5)
                         graph <- cbind(DF$actor_id,DF$post_id)
                         na.omit(unique(graph)) # omit pairs with NA, get only unique pairs
                         g <- graph.data.frame(graph, directed = T)
                         g <- delete.vertices(g, which(is.na(V(g)$name))) 
                         bad.vs <- V(g)[degree(g) < 1]
                         ng <- delete.vertices(g, bad.vs)
                         setProgress(detail = "Generating nodes and edges ...")
                         Sys.sleep(1)
                         V(ng)$size = 2 #degree(ng)/4
                         V(ng)$color = degree(ng)+1
                         V(ng)$label.cex[degree(ng) > 20] = 2
                         V(ng)$label.cex[degree(ng) < 20] = 1 #degree(ng)/4
                         V(ng)$label.cex[V(ng)$label.cex < 1] = 1
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