Univariate Analysis
* Almost ¼ of the listings don’t have ratings (5600 out of 23700)
<img alt="Univariate Analysis" src="https://github.com/jj1787/airbnb/blob/master/images/Univariate.png?raw=true">

Graph of review_scores_rating vs. sentiment
* The negatively rated listings all have neutral to positive sentiment, whereas positive reviews have  range of sentiment values.
* Note: the axes are a result of range checks for review_scores_rating to a=1, b=100 (a<=x<=b) and for sentiment to a=-1, b=1 (a<=x<=b)
<img alt="Graph" src="https://github.com/jj1787/airbnb/blob/master/images/Graph.png?raw=true">

Bivariate Analysis
* The Adjusted R Squared is extremely low, indicating poor model fit.
<img alt="Bivariate Analysis" src="https://github.com/jj1787/airbnb/blob/master/images/Bivariate.png?raw=true">

Semi-log Regression
* Even after I reversed the review_score_ratings and transformed to log, the Adjusted R Squared is still extremely low.
<img alt="Semi-log Regression" src="https://github.com/jj1787/airbnb/blob/master/images/Semilog.png?raw=true">

The data is ultimately inconclusive, but I would hypothesize hosts of negatively rated listings tried to compensate by dressing the descriptions with overly positive words, as opposed to offering a thorough, neutral assessment of their listing.
