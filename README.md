The objective was to take on a perspective of one of the main Airbnb stakeholders--Airbnb manager, host, and guest--and
imagine how Airbnb data from http://insideairbnb.com/ could be used to answer a question.

My team and I wanted to take on the perspective of an Airbnb host and understand which listing attributes most strongly 
contribute to high guest ratings.

#### Part 1:
We initially chose Hawaii, because one member suggested the seasonality may be interesting to examine. At this point in class, we had only learned how to do univariate, multivariate analysis (linear, logistic regression)

Using Python, I ran the descriptions of Hawaii Airbnb listings through the IBM Watson Natural Language Understanding API to get a sentiment score of each description. For some of the listings that didn't have a description, I analyzed the "neighborhood" information instead. I cleaned up the data significantly in the original .csv file of the listings (inserting commas and quotation marks, removing foreign languages, replacing empty cells with placeholder phrase "N/A," etc.) but there were still many incomplete or inconsistent lines of data. For the listings with neither description nor neighborhood information, I set their sentiment scores to 10; the typical range from the API is -1 to 1.

In JMP Pro, a SAS software, I filtered out the listings with a sentiment score of 10 by limiting the range to -1 to 1. I also filtered out the ones without ratings, which I set to 0, by limiting the range to 1 to 100. I did this in JMP Pro to preserve the original text file created from Python. From there, I conducted univariate analysis, bivariate analysis, and semi-log regression. 

I decided to switch to Chicago at this point, for a few reasons:
1. There wasn't actually much seasonal variation for Hawaii https://www.hawaii-guide.com/hawaii-tourism-statistics, because its temperatures range 26°C to 31°C all year long. 
2. There was not much of a spread in the prices and ratings of Hawaii's Airbnb listings, despite there being over 23,000.
3. Reviews for Hawaii are more likely to have non-English characters, especially in Japanese, rendering many reviews either unusable or partially corrupted.

#### Part 2
Because the descriptions didn't yield much information, I analyzed the sentiment of the reviews instead using the SentimentAnalysis package in R. I was able to also examine the word frequency, correlation and clusters using the TextMining package. 

In order for R to handle the commands, I had to reduce the data set from over 350,000 rows into two subsets of low scores (<90) and high scores (=100), which had 23,000 and 26,000 rows respectively. The word frequency analysis told me what users were mentioning the most in their reviews, and the word correlation displayed which words were associated with keywords, such as locat (the stem of location, located). Word clusters conveyed the main topics that reviewers were covering. 

The purpose of the sentiment analysis was to understand the relationship between polarity and rating. Overall, the trend of increasing mean polarity with increasing rating score made sense. However, the low rating scores did not have a negative mean polarity, which surprised me, because I would have expected it to be below 0. Further examination of the individual reviews also showed that there were many positive ratings with negative sentiment scores. 

The former was because... 
* In the mid-range of rating scores (60-75), the guests' words sometimes were sparse, mentioning only the positive, e.g. "Loved it," "Easy fast and very clean," and "Don was really helpful and welcoming." I have witnessed this before on Google Maps and Yelp where reviewers would dock stars, yet not provide valid reasoning for doing so.
* Reviews in Spanish or French, which were unable to be accounted for in the initial data cleaning, were not interpreted to be negative.

The latter was because...
* Some words such as "da bomb" or "crazy" were interpreted as negative, even though colloquially, they may have positive connotation.
* Some positive reviews were extremely detailed and factual. This causes the reviews' sentiment scores to appear more neutral.

All this to say that sentiment analysis itself is not a perfect process.

#### Conclusion
After examining all of our models (my team members took on PCA, factor analysis, clustering analysis, and machine learning models), we had three main insights we recommend for Airbnb hosts: 
Hosts do not need to invest in large, expensive properties and lavish furnishings. These attributes do not show signs of significantly increasing review score ratings as seen in our clustering analysis. However, clusters with the cheapest average listing price tended to have average review scores of under 90. Hosts should invest in a property that is comfortable and able to cover all the basics well.

As seen in our text mining data, customers care a lot about the location of the Airbnb. Factors such as closeness to public transit and walkability to restaurants and tourist hotspots greatly increase the ratings and overall customer experience. So instead of allocating your budget into luxurious amenities, focus on finding a property that is as close as possible to the city center and other hotspots in Chicago. The convenience that customers experience outside of the Airbnb will directly translate into your listing’s ratings.

Both our machine learning models and text mining data show that the customer’s emotional experience, particularly their host experience, has a greater weight than the physical experience they have in the property. Factors related to the host’s qualities dominate the top column contributions in our machine learning models. The word “host” is also frequently mentioned in positive reviews. So in addition to investing in a great property, hosts need to invest in themselves and make sure they are easy to reach, can provide local recommendations, offer cancellation policies, and provide overall excellent customer service.  

