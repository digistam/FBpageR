options(shiny.maxRequestSize=200*1024^2)
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
    withProgress(session, {setProgress(message = "Creating dataset", detail = "This may take a few moments...")
    Sys.sleep(1)
    q <- dbGetQuery(con, "SELECT * FROM stream ORDER BY date DESC")
    DFcontent <<- as.data.frame.matrix(q)
    q <- dbGetQuery(con, "SELECT * FROM likes")
    DFlikes <<- as.data.frame.matrix(q)  
    DF <<- merge(DFcontent, DFlikes, by = 'post_id',incomparables = NULL, all.x = TRUE)
    names(DF) <- c("post_id","post_url","id","object_id","type","object_name","actor","actor_url", "actor_id","actor_pic", "date","message","story","link","description","comments","likes","application","like_id","liker","liker_id","liker_pic", "liker_url")
    DF$date <- as.POSIXct(DF$date,format = "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC")
    DF$date <- with_tz(DF$date, "Europe/Paris")
    DF <<- DF
    setProgress(detail = "Generating Likers ...")
    Sys.sleep(1)
    Likers(DF$liker_id,DF$post_id)
    setProgress(detail = "Generating Authors ...")
    Sys.sleep(1)
    Authors(DF$post_id,DF$actor_id)
    })
    
    output$stream <- renderDataTable({
      isolate({
        DF
      })
      DF[, input$show_vars, drop = FALSE]
    })
    output$likers <- renderDataTable({
      withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
      Sys.sleep(1)
      set.seed(111)
      ddL[is.na(ddL)] <- 0 # ddL is een global variable, afkomstig van de Likers functie
      tbl <- ddL
      names(tbl) <- c('Account','Name','Frequency','Degree','PageRank','Eigenvector')
      tbl <- tbl[order(tbl$Frequency, decreasing = T),]
      df <- tbl
      df[!df$PageRank == 0, ]
      })
    })
    output$authors <- renderDataTable({
      withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
      Sys.sleep(1)
      set.seed(111)
      ddA[is.na(ddA)] <- 0 #ddA is een global variable, afkomstig van de Authors functie
      tbl <- ddA
      names(tbl) <- c('Account','Name','Frequency','Degree','PageRank','Eigenvector')
      tbl <- tbl[order(tbl$Frequency, decreasing = T),]
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
      withProgress(session, {setProgress(message = "Likes per object", detail = "This may take a few moments...")
      Sys.sleep(0.5)  
      objectLikes <- as.data.frame(cbind(DFcontent$object_id,as.numeric(DFcontent$likes)))
      objectLikes <- na.omit(objectLikes)
      names(objectLikes) <- c('object_id','likes')
      objectLikes <- sqldf("select object_id,sum(likes) from objectLikes group by object_id")
      names(objectLikes) <- c('object_id','likes')
      gvisColumnChart(objectLikes,options=list(
        width=420,
        height=250,
        title='Likes per object'
#         pieSliceText='label',
#         legend.position = 'labeled',
#         pieSliceText = 'value',
#         pieHole=0.2
      ))
      })
    })
    output$stat_objectPosts <- renderGvis({
      withProgress(session, {setProgress(message = "Posts per object", detail = "This may take a few moments...")
      Sys.sleep(0.5)  
      objectPosts <- sqldf("select object_id,count(object_id) from DFcontent group by object_id")
      names(objectPosts) <- c('object_id','posts')
      gvisColumnChart(objectPosts,options=list(
        width=420,
        height=250,
      title='Posts per object'
#       pieSliceText='label',
#       legend.position = 'labeled',
#       pieSliceText = 'value',
#       pieHole=0.2,
#       slices="{
#       0: {offset: 0.2},
#       1: {offset: 0.2},
#       2: {offset: 0.2},
#       3: {offset: 0.2},
#       4: {offset: 0.2},
#       5: {offset: 0.2}
#       }"
      ))
      })
    })
    output$stat_video <- renderGvis({
      withProgress(session, {setProgress(message = "Popular videos", detail = "This may take a few moments...")
                             Sys.sleep(0.5)  
                             dd <- DF$link[grep('(http://.*meo.com/.*|http://.*tube.com/.*|http://.*tu.be/.*|.*video.*)',DF$link)]
                             dd <- table(dd)
                             dd <- as.data.frame(as.table(dd))
                             gvisColumnChart(dd,options=list(
                               width=420,
                               height=250,
                               title='Popular videos',
                               pieSliceText='label',
                               legend.position = 'labeled'
#                                pieSliceText = 'value',
#                                pieHole=0.2,
#                                slices="{
#                                 0: {offset: 0.2},
#                                 1: {offset: 0.2},
#                                 2: {offset: 0.2},
#                                 5: {offset: 0.2}
#                               }"
                             ))
      })
    })
    link <- head(sort(table(DFcontent$link),decreasing = T, na.rm = T), n <- 10)
    link <- as.data.frame(as.table(link))
    names(link) <- c('Url','Frequency')
    link[link$Url=="",] <- NA
    link <- na.omit(link)
    output$stat_links <- renderGvis({
      withProgress(session, {setProgress(message = "Link analysis", detail = "This may take a few moments...")
      Sys.sleep(0.5)
      gvisColumnChart(link,options=list(
      width=420,
      height=250,
      title='Link analysis'
#       pieSliceText='label',
#       legend.position = 'labeled',
#       pieSliceText = 'value',
#       pieHole=0.2
      ))
    })})
    
    apps <- head(sort(table(DFcontent$application),decreasing = T, na.rm = T), n <- 10)
    apps <- as.data.frame(as.table(apps))
    names(apps) <- c('Application','Frequency')
    apps[apps$Application=="",] <- NA
    apps <- na.omit(apps)
    apps[apps$Application==" ",] <- NA
    apps <- na.omit(apps)
  
    output$stat_apps <- renderGvis({
      withProgress(session, {setProgress(message = "App analysis", detail = "This may take a few moments...")
      Sys.sleep(0.5)
      gvisColumnChart(apps,options=list(
        width=420,
        height=250,
       title='App analysis'
#        pieSliceText='label',
#        pieHole=0.2
    ))
    })})

    dftype <- as.data.frame(table(DFcontent$type))
    output$Types <- renderGvis({
      withProgress(session, {setProgress(message = "Post types", detail = "This may take a few moments...")
      Sys.sleep(0.5)
      gvisColumnChart(dftype,options=list(
        width=420,
        height=250,
        title='Post types'
#         pieSliceText='label',
#         pieHole=0.2,
#         slices="{
#           0: {offset: 0.2}
#           }"
        ))
    })})
    output$likersGraph <- suppressWarnings(renderPlot({
        withProgress(session, {setProgress(message = "Calculating, please wait", detail = "This may take a few moments...")
        Sys.sleep(0.5)
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
        g <<- g
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
    })}))
    output$downloadGraph = downloadHandler(
      filename = "likersnetwork.graphml",
      content = function(file) {
        V(g)$size=degree(g)*5
        V(g)$color=degree(g)+1
        V(g)$label.cex <- degree(g)*0.8
      write.graph(g, file, format <- 'graphml')
  })
  })
})