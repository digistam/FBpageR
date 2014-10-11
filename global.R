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
DF <- data.frame(replicate(12,sample(0:1,20,rep=TRUE)))
names(DF) <- c("id",         "object_id",        "object_name",   "post_id",   
               "actor",      "actor_id",         "date",          "message",   
               "story",     "comments",         "likes",    "application")  

as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}

textMine <- function(x) {
  DF.corpus <- Corpus(VectorSource(x))
  DF.corpus <- tm_map(DF.corpus, removePunctuation)
  DF.stopwords <- c(stopwords('english'), stopwords('dutch'))
  DF.corpus <- tm_map(DF.corpus, removeWords, DF.stopwords)
  DF.dtm <<- TermDocumentMatrix(DF.corpus,control = list(wordLengths = c(2,10)))
}

# plotMe <- function(x,y) {
#   g <- graph.data.frame(x, directed=F)
#   ## set seed to make the layout reproducible
#   set.seed(111)
#   layout1 <- layout.auto(g)
#   bad.vs <- V(g)[degree(g) < as.numeric(y)]
#   ng <- delete.vertices(g, bad.vs)
#   V(ng)$size=degree(ng)*5
#   V(ng)$color=degree(ng)+1
#   V(ng)$label.cex <- degree(ng)*0.8
#   V(ng)$weight=degree(ng)
#   ng <<- simplify(ng)
# }