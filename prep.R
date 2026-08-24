library(tidyverse)
library(shiny)
library(nflreadr)
library(modelr)

load("data/nflgames.RData")


# Get NFL team information ------------------------------------------------

teams<- nflreadr::load_teams()|> 
  select(team_abbr, team_name, team_conf, team_division)

# Get and prepare postseason data -----------------------------------------

postseason_games <- nflreadr::load_schedules(1999:2025) 

postseason_games <- postseason_games |> 
  filter(game_type!="REG") |> 
  mutate(
    margin = home_score - away_score,
    home_win = if_else(margin > 0, 1L, 0L),
    neutral = game_type == "SB"
  )

# Add historical teams ----------------------------------------------------

old_teams <- data.frame(
  team_abbr = c("SD", "STL", "OAK"), 
  team_name = c("San Diego Chargers", "Saint Louis Rams", "Oakland Raiders"), 
  team_conf = c("AFC", "NFC", "AFC"), 
  team_division = c("AFC West", "NFC West", "AFC West")
  )
final_teams <- rbind(teams, old_teams)

# Combine regular-season and postseason data ------------------------------

master_nflschedule <- rbind(nflgames, postseason_games)|>
  left_join(final_teams, by = c("home_team" = "team_abbr"))|>
  left_join(final_teams, by = c("away_team" = "team_abbr"))

saveRDS(
  master_nflschedule,
  file = "data/master_nflschedule.rds"
)



