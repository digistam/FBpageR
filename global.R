if (!require("RSQLite")) {
  install.packages("RSQLite", repos="http://cran.rstudio.com/") 
  library("RSQLite") 
}
if (!require("igraph")) {
  install.packages("igraph", repos="http://cran.rstudio.com/") 
  library("igraph") 
}
if (!require("tm")) {
  install.packages("tm", repos="http://cran.rstudio.com/") 
  library("tm") 
}
windowsFonts(Arial=windowsFont("TT Arial"))
connectSQL <- function(x) {
  set.seed(111)
  drv <<- dbDriver("SQLite")
  con <<- dbConnect(drv, x)
  dbListTables(con)
}
queryTable <- function(x) {
  set.seed(111)
  q <- dbGetQuery(con, paste("SELECT * FROM ", x, "", sep=""))
  DF <<- as.data.frame(q)
}
DF <- data.frame(replicate(18,sample(0:1,20,rep=TRUE)))
names(DF) <- c("post_id","id","object_id","type","object_name","actor","actor_id","date","message","story","link","description","comments","likes","application","like_id","liker","liker_id")

as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}

textMine <- function(x) {
  DF.corpus <- Corpus(VectorSource(x))
  DF.corpus <- tm_map(DF.corpus, removePunctuation)
  DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
  DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
  DF.dtm <<- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(2,10)))
}

Likers <- function(x,y) {
  graph <- cbind(x,y)
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
  ddL <<- dd
}
Authors <- function(x,y) {
  graph <- cbind(x,y)
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
  dg <- dg
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
  ddA <<- dd
}