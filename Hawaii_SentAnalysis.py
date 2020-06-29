
import requests
import json
import csv


listingsfile = 'listings3.csv'
inputm = []

#Each row is a list item.
with open(listingsfile, "r") as f:
    reader = csv.reader(f, delimiter="\t")
    for row in reader:
        inputm.append(row)

del inputm[0] #removes the first row of column headers

#IBM Watson Natural Language API to retrieve sentiment of description.
def getSentiment(text):
    headers = {
    'Content-Type': 'application/json',
    }
    endpoint = "https://gateway.watsonplatform.net/natural-language-understanding/api/v1/analyze"
    username = "apikey"
    password = "P3eGE6SdofmM9DXPcrQnSUD9KVT8pkqlGIT4Voda5Md0" 
    parameters = {
        'features': 'emotion,sentiment',
        'version' :  '2019-07-12',
        'text': text,
        'language' : 'en',        
    }
    resp = requests.get(endpoint, headers=headers, params=parameters, auth=(username, password))
    data = resp.json()
    return data

file = open('sentiment_analysis.txt','a+')
#n = 'listing\tdescription\tlength (ch)\tnumber_of_reviews\treview_scores_rating\tsentiment\n'
#file.write(n) #the input has to be a string and cannot work with multiple parameters

def createRow(row, description):
    data = getSentiment(description)
    score = str(data['sentiment']['document']['score'])
    last_str = row[-1] 
    last = last_str.split(',')
    rating = str(last[-8])
    reviews = str(last[-9])
    n = row[0] + '\t' + description + '\t' + str(len(description)) + '\t' + reviews + '\t' + rating + '\t' + score + '\n'
    file.write(n)
#Using negative indices is easier here.

for i  in range(23363,len(inputm)): #Each listing row is a string item in the list.
    i = inputm[i]
    string = i[0] 
    row = string.split('"')
#id is index 0. description is index 1. neighborhood is 3 unless data unclean, then it's inside 2. Analyze neighborhood instead of description, if blank, which is denoted by 'n'.
    if row[1] != 'n': # check if description is not blank
        description = row[1]
        createRow(row, description)
    elif row[3] != 'n': # check if neighborhood is not blank. if it's inside 2, then this would be an error.
        description = row[3]
        createRow(row, description)
    elif row[2] != 'n': # includes cases where neighborhood is with the other info, assuming I perfectly put 'n' in all blank cells
        if row[2] == ',': # no description information at all; both description & neighborhood are 'n'
            last = row[-1]
            last = last.split(',')
            rating = str(last[-8])
            reviews = str(last[-9])
            n = row[0] + '\t' + 'n/a' + '\t' + 'n/a' + '\t' + reviews + '\t' + rating + '\t' + 'n/a' + '\n'
            file.write(n)
        else:
            last_str = row[-1] 
            last = last_str.split(',')  
            description = last[1]
            createRow(row, description)

file.close()

#Note: for the originally blank cells, I entered "n" into them, because parsing the string for the description column was too difficult. 
#I first put "n" in the Excel version, which shows up as """n""" in .csv, so in the .csv itself, I replaced them with "n". We need the single double quotation mark do .split method.
#Triple double quotation marks were everywhere, and I had to replace these too. UGH some parts I had to ADD double quotation marks. ex. ctrl+F ",A" etc. to find the start of description 
#Large blocks of whitespace in row[1] would lead to the rest of the row not being included in the list. 
#line breaks were not included, so I also replaced them with ''.
#A lot of the corrupted characters were due to Asian/Hawaiian/Spanish lang, which I removed or changed to "n". I removed "Phone/Email hidden by Airbnb" because I think the word "hidden" may impact the score.

#MOST DESCRIPTIONS SCRAPED ARE INCOMPLETE. I also switched a few descriptions and neighborhoods, because the latter was more descriptive.
#I also could've used a try loop then parsed the description out of the first item. 
