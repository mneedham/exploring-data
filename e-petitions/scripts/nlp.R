library("tm")
data("crude")

BigramTokenizer = function(x) {
  return(unlist(lapply(ngrams(words(x), 2), paste, collapse = " "), use.names = FALSE))  
}

allTheGramsTokenizer = function(x) {
  bigram = lapply(ngrams(words(x), 2), paste, collapse = " ")
  trigram = lapply(ngrams(words(x), 3), paste, collapse = " ")
  allTheGrams = c(bigram, trigram)
  return(unlist(allTheGrams, use.names = FALSE))  
}
    
tdm <- TermDocumentMatrix(crude, control = list(tokenize = BigramTokenizer))
inspect(removeSparseTerms(tdm[, 1:10], 0.7))

s <- "The quick brown fox jumps over the lazy dog"
## Split into words:
w <- strsplit(s, " ", fixed = TRUE)[[1L]]

unlist(lapply(ngrams(w, 2), paste, collapse = " "), use.names = FALSE)

# Output: bi-grams from one title

dfs = DataframeSource(df %>% select(action))
vcorpus = VCorpus(dfs)
vcorpus <- tm_map(vcorpus, removePunctuation)   
vcorpus <- tm_map(vcorpus, removeNumbers) 
vcorpus <- tm_map(vcorpus, tolower)   
vcorpus <- tm_map(vcorpus, removeWords, stopwords("english"))  
vcorpus <- tm_map(vcorpus, stemDocument)   
vcorpus <- tm_map(vcorpus, stripWhitespace)  
vcorpus <- tm_map(vcorpus, PlainTextDocument)  

# Looking in the corpus to find an individual document
as.character(vcorpus[[1]])

tdm = TermDocumentMatrix(vcorpus, control = list(tokenize = BigramTokenizer))
inspect(removeSparseTerms(tdm[, 1:10], 0.1))
findFreqTerms(tdm, lowfreq = 6)[1:25]

dtm = DocumentTermMatrix(vcorpus, control = list(tokenize = BigramTokenizer))

freq <- colSums(as.matrix(dtm))   
wf <- data.frame(word=names(freq), freq=freq)   
wf %>% arrange(desc(freq)) %>% head(10)

freq <- rowSums(as.matrix(tdm))   
wf <- data.frame(word=names(freq), freq=freq)   
wf %>% arrange(desc(freq)) %>% head(10)

# Trying out with bigrams and trigrams together

tdm = TermDocumentMatrix(vcorpus, control = list(tokenize = allTheGramsTokenizer))
freq = rowSums(as.matrix(tdm))
data.frame(word = names(freq), freq = freq) %>% arrange(desc(freq)) %>% head(10)


# I think DocumentTermMatrix and TermDocumentMatrix are the inverse of each other. But then it's weird 
# why I can't get the count of terms from the TermDocumentMatrix since in theory that's in a better format
# to start with

# removing the stop words gives more interesting phrases but it cuts out common phrases in English
# instead of doing pure frequency would getting a TF/IDF score and ordering on that help?

# How do you combine bi-grams of different lengths together?

# Order the bi and tri grams based on TF/IDF score rather than just frequency
# then work out which phrases appear in successful and unsuccessful petitions