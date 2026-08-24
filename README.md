# NFL Upset Predictor
Welcome to the NFL Upset Predictor! In this R Shiny app, explore the history of your NFL team against the spread. We have provided many plots that show being involved in an upset, the proportion of upsets over the years, as well as tables and regression models that can predict the probability of being involved in an upset, and also being upset by another team. 
A game was considered an upset when a team was favored by at least 3.5 points in the spread line, but does not win the game. 
# Packages and Data required for use: 
tidyverse, shiny, modelr (data was obtained from nflreadr)\
nflgames.RData, postseasongames.RData, nflteams.RData, master_nflschedule.RData\
All data is available on this Github Repository.

nflgames.RData was provided as part of the course and contains NFL game data originally obtained from the nflverse project using nflreadr. The original code used to create this .RData file was not provided with the course materials. prep.R contains the code developed for this project to process the course-provided data and create the additional datasets used by the application.

# Project Overview
 - Loads an NFL Master schedule of games from 1999-2025
 - Filters data by team, home vs. away, year, rivalries, regular season vs. postseason games, rest time, indoors vs. outdoors, temperature, and wind speed
    - Selecting "All" or "Both will keep all data
    - Indoor games receive temperature and wind speed of 0 to avoid NA bias
    - Criteria involving empty data is handled with validate(need())
    - Filters are reactive to every change and are handled through reactive({})
 - Displays visuals of upsets against the spread, and upset proportion over the years (An upset is when a team is favored by at least 3.5 points in the spread line and does not win that game)
 - Two logistic regression models are run. The first model runs a regression for the probability of being involved in an upset (team either upsets someone or is upset by someone else), and the second model runs a regression for the probability of being upset by another team. The first model can be found in the 'Upset Regression' tab, and the second model can be found in the 'Upset Calculator' tab. These regression models only work when a team is selected
 - These models are also used to predict the chances of a future upset (See limitations for potential errors)
 
# How to Work the App
Use the sliders and various selection tools on the sidebar in the app to filter the data provided by nflreadr for your selected conditions. All plots are reactive and display the filtered data.

# How to Run the App (Local)
 - Download prep.R and shinyapp.R as well as the data folder
 - shinyapp.R is the actual app, while prep.R is the code that was used to create postseasongames.RData, nflteams.RData, and master_nflschedule.RData (using nflgames.RData)
 - nflgames.RData was a dataset provided in class, obtained from nflreadr, that contains regular season games from 1999 to 2025
 - All of these data files are saved to the data folder already, so running prep.R before shinyapp.R is not necessary for the app to function
 - In RStudio, open the shinyapp.R file and click 'Run App'
 
# Limitations
 - Some teams joined and some franchises moved later than 1999, so some data may be missing for these respective teams\
 - Our prediction table uses the maximum wind speed and temperature selected using the sliders on the sidebar. Because there is not prevalent data involving high temperatures and high wind speeds, this could result in inaccurate predictions.

# File Layout
/
├── shinyapp.R                # Shiny app\
├── prep.R          # Data creation script\
├── data/\
│   └── master_nflschedule.RData\
│   └── nflgames.RData\
│   └── nflteams.RData\
│   └── postseasongames.RData\
├── README.md\
└── finalproject.qmd

# Main contributors
Duncan Lowe and George Kobrossy\
App made with R Shiny
