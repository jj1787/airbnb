setwd("/Users/Jenny/Documents/Senior Year/D3M/Final Project")

library(dplyr)
library(ggplot2)
library(tidyr)
library(ggmap)
library(cluster)   
library(tm)
library(topicmodels)
library(slam)
library(SnowballC)

#########################################################################################

### SUBSET LOW RATINGS ### What did they not talk about? What drove the guests so strongly to give a negative rating?
reviews <- read.csv("reviews big.csv", header=TRUE, sep=",")
reviews <- data.frame(reviews %>% select('doc_id','text','review_scores_rating'))
low_rating <- reviews %>% filter(review_scores_rating < 90 ) # Trimmed data down 
# low_rating <-- low_rating %>% mutate(doc_id=listing_id, text=comments) 
#This made all the values negative and removed the comments...so I just revised the column names to doc_id and text.

#########################################################################################
# 1) Cleaning data
###########################################################################################
reviews.corpus <- VCorpus(DataframeSource(low_rating)) 

reviews_clean <- tm_map(reviews.corpus, content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte'))) #on Mac, to avoid the "transformation document dropped" message
reviews_clean <- tm_map(reviews_clean, content_transformer(tolower)) #to lowercase
removeSpec <- function(x) gsub("[^a-zA-Z]"," ",x) #double check that all extra stuff is removed. ^\t\n\r\v\f is not necessary since you are replacing special characters with a whitespace anyway.
combineWords <- function(x) gsub("([a])\\1+", "\\1",x) 
reviews_clean <- tm_map (reviews_clean, content_transformer(removeSpec)) 
reviews_clean <- tm_map (reviews_clean, content_transformer(combineWords)) 
reviews_clean <- tm_map(reviews_clean, stripWhitespace) #collapses multiple whitespace
reviews_clean <- tm_map(reviews_clean, removeWords, stopwords("english")) #wrap c (combine) function around stopwords to add other words
reviews_clean <- tm_map(reviews_clean, stemDocument, language="english")
dtm <- DocumentTermMatrix(reviews_clean)
reviews_dtm <- removeSparseTerms(dtm, 0.9975)

#runs faster
saveRDS(reviews_dtm, file="reviews_low.rds") #already done once. Creating a new file also makes it so I don't have to run the entire previous code each time.
reviews_dtm <- readRDS(file="reviews_low.rds") #OPENS file to operate on

#########################################################################################
# 2) Word frequency and word cloud
#########################################################################################
##Save to .csv file to conduct PCA analysis?
# matrix <- as.matrix(reviews_dtm) 
# write.csv(matrix,file="reviews_matrix.csv")

##Frequency
freq <- colSums(as.matrix(reviews_dtm)) 
freq[1:10] #first 10 words, alphabetical

#plot high frequency
term.count <- as.data.frame(as.table(reviews_dtm)) %>% 
  group_by(Terms) %>%
  summarize(n=sum(Freq)) 

term.count %>% 
  filter(cume_dist(n) > 0.95) %>% #cume_dist is the cumulative distribution function which gives the proportion of values less than or equal to the current rank
  #prints terms that appear at least 95% in the text
  ggplot(aes(x=reorder(Terms,n),y=n)) + geom_bar(stat='identity') + 
  coord_flip() + xlab('Term') + ylab('Count')

#another way to find the frequent terms 
findFreqTerms(reviews_dtm, lowfreq=500) #appear at least 500 times in the dtm

##Find terms correlated with "place" 
place <- data.frame(findAssocs(reviews_dtm, "place", 0.15))
place %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,place),y=place)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with place')

##Find terms correlated with "great" 
great <- data.frame(findAssocs(reviews_dtm, "great", 0.1))
great %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,great),y=great)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with great')

##Find terms correlated with "locat" 
locat <- data.frame(findAssocs(reviews_dtm, "locat", 0.1))
locat %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,locat),y=locat)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with locat')

##Find terms correlated with "host" 
host <- data.frame(findAssocs(reviews_dtm, "host", 0.15))
host %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,host),y=host)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with host')

##Find terms correlated with "room" 
room <- data.frame(findAssocs(reviews_dtm, "room", 0.2))
room %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,room),y=room)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with room')

##Find terms correlated with "neighborhood" 
neighborhood <- data.frame(findAssocs(reviews_dtm, "neighborhood", 0.1))
neighborhood %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,neighborhood),y=neighborhood)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with neighborhood')

##Make wordcloud
library(wordcloud)
popular.terms <- filter(term.count, n > 500) #words that appear more than 500 times
wordcloud(popular.terms$Terms,popular.terms$n,colors=brewer.pal(8,"Dark2"))

###########################################################################################
# 3) Sentiment Analysis
# R package: "SentimentAnalysis"
###########################################################################################
#Note: Done on the original text. 
install.packages("SentimentAnalysis")
library(SentimentAnalysis)

#sentiment <- analyzeSentiment(as.character(low_rating$text)) 

#if the above line does not work and you have a MAC, try this
recode <-function(x) {iconv(x, to='UTF-8-MAC', sub='byte')}
sentiment <- analyzeSentiment(recode(low_rating$text))

sent_df = data.frame(polarity=sentiment$SentimentQDAP, business = low_rating, stringsAsFactors=FALSE)

#Correlation between mean polarity score and rating 
summary(sent_df$polarity)
sent_df %>% filter(is.na(polarity)==TRUE)%>%select(business.text)
#correct for NA
sent_df$polarity[is.na(sent_df$polarity)]=0
sent_df$business.review_scores_rating<-as.numeric(sent_df$business.review_scores_rating)
sent_df %>% #show average polarity score for each overall rating
  group_by(business.review_scores_rating) %>%
  summarize(mean.polarity=mean(polarity,na.rm=TRUE)) %>%
  ggplot(aes(x=business.review_scores_rating,y=mean.polarity)) +  geom_bar(stat='identity',fill="blue") +  
  ylab('Mean Polarity') + xlab('Rating < 90')  + theme(text=element_text(size=20))
  cor(sent_df$polarity,sent_df$business.review_scores_rating) 

###########################################################################################
# 4) Topic Modeling
# R package: "topicmodels"
###########################################################################################
#set.up.dtm.for.lda.1
library(topicmodels)
library(slam)

dtm.lda <- removeSparseTerms(reviews_dtm, 0.98) #size down further 
review.id <- low_rating$doc_id[row_sums(dtm.lda) > 0]
dtm.lda <- dtm.lda[row_sums(dtm.lda) > 0,]

##Run LDA algorithm - WARNING: takes a while to run!
lda.aria <- LDA(dtm.lda,k=5,method="Gibbs", #5 topics
                control = list(seed = 2011, burnin = 1000,
                               thin = 100, iter = 5000))
save(lda.aria,file='lda_results1.rda') #k=20 would take too long, plus I do not expect that much variety amongst reviews

#load results (so you don't have to run the algorithm each time)
load('lda_results1.rda')

post.lda.aria <- posterior(lda.aria) #get the posterior probability of the topics for each document and of the terms for each topic

#sum.lda
sum.terms <- as.data.frame(post.lda.aria$terms) %>% #matrix topic * terms
  mutate(topic=1:5) %>% #add a column, has to same as k
  gather(term,p,-topic) %>% #gather makes wide table longer, key=term, value=p, columns=-topic (exclude the topic column)
  group_by(topic) %>%
  mutate(rnk=dense_rank(-p)) %>% #add a column
  filter(rnk <= 10) %>% #top 10 terms
  arrange(topic,desc(p)) 

sum.terms %>%
  filter(topic==1) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 1') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==2) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 2') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==3) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 3') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==4) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 4')

sum.terms %>%
  filter(topic==5) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 5')

###########################################################################################

### SUBSET HIGH RATINGS ### What did they not talk about? What did they credit for their high rating?
high_rating <- reviews %>% filter(review_scores_rating == 100 )

#########################################################################################
# 1) Cleaning data
###########################################################################################
reviews.corpus <- VCorpus(DataframeSource(high_rating)) 

reviews_clean <- tm_map(reviews.corpus, content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte'))) #on Mac, to avoid the "transformation document dropped" message
reviews_clean <- tm_map(reviews_clean, content_transformer(tolower)) #to lowercase
removeSpec <- function(x) gsub("[^a-zA-Z]"," ",x) #double check that all extra stuff is removed. ^\t\n\r\v\f is not necessary since you are replacing special characters with a whitespace anyway.
combineWords <- function(x) gsub("([a])\\1+", "\\1",x) 
reviews_clean <- tm_map (reviews_clean, content_transformer(removeSpec)) 
reviews_clean <- tm_map (reviews_clean, content_transformer(combineWords)) 
reviews_clean <- tm_map(reviews_clean, stripWhitespace) #collapses multiple whitespace
reviews_clean <- tm_map(reviews_clean, removeWords, stopwords("english"))
reviews_clean <- tm_map(reviews_clean, stemDocument, language="english")
dtm <- DocumentTermMatrix(reviews_clean)
reviews_dtm <- removeSparseTerms(dtm, 0.9975)

saveRDS(reviews_dtm, file="reviews_high.rds") #already done once. Creating a new file also makes it so I don't have to run the entire previous code each time.
reviews_high_dtm <- readRDS(file="reviews_high.rds")

#########################################################################################
# 2) Word frequency 
#########################################################################################
##Save to .csv file to conduct PCA analysis?
# matrix <- as.matrix(reviews_dtm) 
# write.csv(matrix,file="reviews_matrix.csv")

##Frequency
freq <- colSums(as.matrix(reviews_high_dtm)) 
freq[1:10] #first 10 words, alphabetical

#plot high frequency
term.count <- as.data.frame(as.table(reviews_high_dtm)) %>% 
  group_by(Terms) %>%
  summarize(n=sum(Freq)) 

term.count %>% 
  filter(cume_dist(n) > 0.95) %>% #cume_dist is the cumulative distribution function which gives the proportion of values less than or equal to the current rank
  #prints terms that appear at least 95% in the text
  ggplot(aes(x=reorder(Terms,n),y=n)) + geom_bar(stat='identity') + 
  coord_flip() + xlab('Term') + ylab('Count')

#another way to find the frequent terms 
findFreqTerms(reviews_high_dtm, lowfreq=500) #appear at least 500 times in the dtm

##Find terms correlated with "place" 
stay <- data.frame(findAssocs(reviews_high_dtm, "stay", 0.15))
stay %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,stay),y=stay)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with stay')

##Find terms correlated with "great" 
great <- data.frame(findAssocs(reviews_high_dtm, "great", 0.1))
great %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,great),y=great)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with great')

##Find terms correlated with "locat" 
locat <- data.frame(findAssocs(reviews_high_dtm, "locat", 0.1))
locat %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,locat),y=locat)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with locat')

##Find terms correlated with "host" 
host <- data.frame(findAssocs(reviews_high_dtm, "host", 0.075))
host %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,host),y=host)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with host')

##Find terms correlated with "neighborhood" 
neighborhood <- data.frame(findAssocs(reviews_high_dtm, "neighborhood", 0.1))
neighborhood %>%
  add_rownames() %>%
  ggplot(aes(x=reorder(rowname,neighborhood),y=neighborhood)) + geom_point(size=4) + 
  coord_flip() + ylab('Correlation') + xlab('Term') + 
  ggtitle('Terms correlated with neighborhood')

###########################################################################################
# 3) Sentiment Analysis
# R package: "SentimentAnalysis"
###########################################################################################
#Note: Done on the original text. Maybe with the foreign language reviews gone...? 
install.packages("SentimentAnalysis")
library(SentimentAnalysis)

#sentiment <- analyzeSentiment(as.character(low_rating$text)) 

#if the above line does not work and you have a MAC, try this
recode <-function(x) {iconv(x, to='UTF-8-MAC', sub='byte')}
sentiment <- analyzeSentiment(recode(high_rating$text)) #done on the csv file read into RStudio

sent_df = data.frame(polarity=sentiment$SentimentQDAP, business = high_rating, stringsAsFactors=FALSE)

#Correlation between mean polarity score and rating - are the reviews in line with ratings? as in, how much can we trust reviews?
summary(sent_df$polarity)
sent_df %>% filter(is.na(polarity)==TRUE)%>%select(business.text)
#correct for NA
sent_df$polarity[is.na(sent_df$polarity)]=0
sent_df$business.review_scores_rating<-as.numeric(sent_df$business.review_scores_rating)
sent_df %>% #show polarity score by each individ. listing
  group_by(business.doc_id) %>%
  ggplot(aes(x=business.doc_id,y=polarity)) +  geom_line(color="red") +  
  ylab('Polarity') + xlab('Individual Listings at Rating = 100')  + theme(text=element_text(size=20))
cor(sent_df$polarity,sent_df$business.review_scores_rating) 


###########################################################################################
# 4) Topic Modeling
# R package: "topicmodels"
###########################################################################################
#set.up.dtm.for.lda.2
library(topicmodels)
library(slam)

dtm.lda <- removeSparseTerms(reviews_high_dtm, 0.98) #size down further 
review.id <- low_rating$doc_id[row_sums(dtm.lda) > 0]
dtm.lda <- dtm.lda[row_sums(dtm.lda) > 0,]

##Run LDA algorithm - WARNING: takes a while to run!
lda.aria2 <- LDA(dtm.lda,k=5,method="Gibbs",
                control = list(seed = 2011, burnin = 1000,
                               thin = 100, iter = 5000))
save(lda.aria2,file='lda_results2.rda')

#load results (so you don't have to run the algorithm each time)
load('lda_results2.rda')

post.lda.aria2 <- posterior(lda.aria2) #get the posterior probability of the topics for each document and of the terms for each topic

#sum.lda
sum.terms <- as.data.frame(post.lda.aria2$terms) %>% #matrix topic * terms
  mutate(topic=1:5) %>% #add a column
  gather(term,p,-topic) %>% #gather makes wide table longer, key=term, value=p, columns=-topic (exclude the topic column)
  group_by(topic) %>%
  mutate(rnk=dense_rank(-p)) %>% #add a column
  filter(rnk <= 10) %>% #top 5 terms per topic
  arrange(topic,desc(p)) 

sum.terms %>%
  filter(topic==1) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 1') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==2) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 2') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==3) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 3') + theme(text=element_text(size=20))

sum.terms %>%
  filter(topic==4) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 4')

sum.terms %>%
  filter(topic==5) %>%
  ggplot(aes(x=reorder(term,p),y=p)) + geom_bar(stat='identity') + coord_flip() + 
  xlab('Term')+ylab('Probability')+ggtitle('Topic 5')


#If you want to add topics as features for machine learning
# aria.review.subset <- aria.reviews[aria.reviews$review_id %in% review.id,c("business_id","review_id")]
# topic.df <-post.lda.aria$topics
# temp <- data.frame(aria.review.subset,topic.df)
# combined.df<-temp %>% select(-review_id)%>%group_by(business_id) %>%summarise_all(list(mean))
#Export the dataset to csv
# write.csv(combined.df,file="output.csv")

