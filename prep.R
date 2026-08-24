library(tidyverse)
library(shiny)
library(nflreadr)
library(modelr)

load("data/nflgames.RData")

teams<- nflreadr::load_teams()|> 
  select(team_abbr, team_name, team_conf, team_division)
save(teams, file = "nflteams.RData")
postseason_games <- nflreadr::load_schedules(1999:2025) 


updated_postseason<- postseason_games|>
  filter(game_type!="REG")
save(updated_postseason, file = "postseasongames.RData")

all_info_postseason <- updated_postseason|>
  mutate(margin = home_score - away_score)|>
  mutate(home_win = case_when(
    margin > 0 ~ 1,
    .default = 0 ))|>
  mutate(neutral = ifelse(game_type == "SB", TRUE, FALSE))

old_teams <- data.frame(
  team_abbr = c("SD", "STL", "OAK"), 
  team_name=c("San Diego Chargers", "Saint Louis Rams", "Oakland Raiders"), 
  team_conf= c("AFC", "NFC", "AFC"), 
  team_division = c("AFC West", "NFC West", "AFC West")
  )
final_teams<-rbind(teams, old_teams)

rbind(nflgames, all_info_postseason)|>
  left_join(final_teams, by = c("home_team" = "team_abbr"))|>
  left_join(final_teams, by = c("away_team" = "team_abbr")) -> master_nflschedule

master_nflschedule|>
  save(file = "master_nflschedule.RData")