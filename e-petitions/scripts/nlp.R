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

tdm = TermDocumentMatrix(vcorpus, control = list(tokenize = allTheGramsTokenizer, weighting = weightTfIdf))
freq = rowSums(as.matrix(tdm))
data.frame(word = names(freq), freq = freq) %>% arrange(desc(freq)) %>% head(10)

# didn't end up making much difference. The results are still dominated by shorter phrases

configurableTokenizer = function(grams) {
  function(x) {
    return(unlist(sapply(grams, function(n) lapply(ngrams(words(x), n), paste, collapse=" ")), use.names = FALSE))
  }
}

tdm = TermDocumentMatrix(vcorpus, control = list(tokenize = configurableTokenizer(2:3), weighting = weightTfIdf))
freq = rowSums(as.matrix(tdm))
data.frame(word = names(freq), freq = freq) %>% arrange(desc(freq)) %>% head(10)

# Successful / Unsuccessful n-grams
successCorpus = createCorpus(success %>% select(action))
success_tdm = TermDocumentMatrix(successCorpus, list(tokenize = configurableTokenizer(2)))   
freq = rowSums(as.matrix(success_tdm))
data.frame(word = names(freq), freq = freq) %>% arrange(desc(freq)) %>% head(10)

notSuccessCorpus = createCorpus(not_success %>% select(action))
notSuccess_tdm = TermDocumentMatrix(notSuccessCorpus, list(tokenize = configurableTokenizer(2)))   
freq = rowSums(as.matrix(notSuccess_tdm))
data.frame(word = names(freq), freq = freq) %>% arrange(desc(freq)) %>% head(10)

# log likelihood
logLikely = function(n1, t1, n2, t2) {
  n1=n1+1
  n2=n2+1 
  
  e1 = t1 * 1.0 * (n1 + n2) / (t1 + t2)
  e2 = t2 * 1.0 * (n1 + n2) / (t1 + t2)
  LL = 2 * ((n1 * log(n1 / e1)) + n2 * log(n2/e2))
  
  if(n2 * 1.0 / t2 > n1 * 1.0 / t1) {
    return(-LL)
  } else {
    return(LL)
  }
}

successCorpus = createCorpus(success %>% select(action))
success_tdm = TermDocumentMatrix(successCorpus)   
succcess_freq = rowSums(as.matrix(success_tdm))
df_success = data.frame(word = names(succcess_freq), freq = succcess_freq)

notSuccessCorpus = createCorpus(not_success %>% select(action))
notSuccess_tdm = TermDocumentMatrix(notSuccessCorpus)   
notSuccess_freq = rowSums(as.matrix(notSuccess_tdm))
df_notSuccess = data.frame(word = names(notSuccess_freq), freq = notSuccess_freq)

successWords = rownames(success_tdm)
notSuccessWords = rownames(notSuccess_tdm)

calculateLL = function(word) {
  success_index = match(word, successWords)[1]
  successFreq = df_success[success_index,]$freq
  
  notSuccess_index = match(word, notSuccessWords)[1]
  notSuccessFreq = df_notSuccess[notSuccess_index,]$freq
  
  successFreq=ifelse(is.na(successFreq), 0, successFreq)
  notSuccessFreq=ifelse(is.na(notSuccessFreq), 0, notSuccessFreq)
  
  ll = logLikely(successFreq, sum(df_success$freq), notSuccessFreq, sum(df_notSuccess$freq))
  
  return(ll)
}

lls = sapply(successWords, calculateLL)
result = data.frame(word = names(lls), score = lls)
result %>% arrange(desc(score)) %>% head()

# At the moment we are counting words multiple times per document whereas in the Whitehouse blog post
# they only count once per document - http://www.prooffreader.com/2016/03/most-characteristic-words-in-successful.html?m=1

# content(tm_map(vcorpus, content_transformer(toupper))[[1]])

uniqueWords = function(d) {
  return(paste(unique(strsplit(d, " ")[[1]]), collapse = ' '))
}

vcorpus = content(tm_map(vcorpus, content_transformer(uniqueWords))[[1]])

successCorpus = createCorpus(success %>% select(action))
successCorpus = tm_map(successCorpus, content_transformer(uniqueWords))
success_tdm = TermDocumentMatrix(successCorpus)   
succcess_freq = rowSums(as.matrix(success_tdm))
df_success = data.frame(word = names(succcess_freq), freq = succcess_freq)

notSuccessCorpus = createCorpus(not_success %>% select(action))
notSuccessCorpus = tm_map(notSuccessCorpus, content_transformer(uniqueWords))
notSuccess_tdm = TermDocumentMatrix(notSuccessCorpus)   
notSuccess_freq = rowSums(as.matrix(notSuccess_tdm))
df_notSuccess = data.frame(word = names(notSuccess_freq), freq = notSuccess_freq)

successWords = rownames(success_tdm)
notSuccessWords = rownames(notSuccess_tdm)

lls = sapply(successWords, calculateLL)
result = data.frame(word = names(lls), score = lls)
result %>% arrange(desc(score)) %>% head()

#frequency per 1000 words