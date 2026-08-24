library(tidyverse)
library(shiny)
library(modelr)


master_nflschedule <- readRDS("data/master_nflschedule.rds")


ui<-fluidPage(title = "NFL Upset Predictor", 
              titlePanel("NFL Upset Predictor"),
              sidebarLayout(
                sidebarPanel(
                  selectInput("team", "NFL Team (Select a team for more options)", 
                              c("All", sort(unique(master_nflschedule$home_team)))),
                  conditionalPanel(
                    "input.team != 'All'",
                    radioButtons("location", "Home vs. Away", c("Both", "Home", "Away")),
                    selectInput("rest_time", "Maxiumum Rest Time (Days)", c(21, 14, 7))
                  ),
                  sliderInput("year", "Season", 1999, 2025, c(1999, 2025), sep = ""),
                  selectInput("outdoors", "Indoors vs. Outdoors", c("Both", "Indoors", "Outdoors")),
                  conditionalPanel(
                    "input.outdoors != 'Indoors'",
                    sliderInput("temp", "Temperature", -10, 110, c(-10,110)),
                    sliderInput("wind", "Wind Speed", 0, 75, c(0,75))
                  ),
                  radioButtons("rival", "Rivalry Games", c("Both", "Rivalries", "Non-Rivalries")),
                  radioButtons("playoff", "Select:", c("Both", "Regular Season Games", "Postseason Games")),
                  
                ),
                mainPanel(
                  tabsetPanel(
                    tabPanel("Plots", 
                             plotOutput("h"), 
                             plotOutput("l")
                    ),
                    tabPanel("Upset Regression (Must Pick A Team)",
                             verbatimTextOutput("model"),
                             tableOutput("prob"),
                             textOutput("disclaimer")
                    ),
                    tabPanel("Upset Calculator (Must Pick A Team)",
                             verbatimTextOutput("calculator_model"),
                             tableOutput("calculator_prob"),
                             textOutput("calc_disclaimer"),
                             plotOutput("calculator_histogram")
                    ),
                    tabPanel("About",
                             a("Visit Our GitHub Repository and README File", 
                               href = "https://github.com/gkobrossy/nfl-upset-predictor", target ="_blank"),
                             tableOutput("div_table")
                    )
                  )
                )
              )
)


server<-function(input, output, session){
  filtered_data<-reactive({
    data<- master_nflschedule
    if (input$team != "All"){
      data <- master_nflschedule |> 
        filter(home_team == input$team | away_team == input$team)
    }
    if(input$playoff == "Regular Season Games") {
      data <- data |> 
        filter(game_type == "REG")
    } else if(input$playoff == "Postseason Games") {
      data <- data |> 
        filter(game_type != "REG")
    }
    data <- data |> 
      filter(between(season, input$year[1], input$year[2])) 
    if(input$outdoors == "Indoors") {
      data <- data |> 
        filter((roof == "dome" | roof == "closed"))
    } else if(input$outdoors == "Outdoors") {
      data <- data |> 
        filter(between(temp, input$temp[1], input$temp[2])) |>
        filter(between(wind, input$wind[1], input$wind[2]))
    } else {
      data <- data |> 
        filter(
          between(temp, input$temp[1], input$temp[2]) | 
            (roof == "dome" | roof == "closed")) |>
        filter(between(wind, input$wind[1], input$wind[2]) | 
                 (roof == "dome" | roof == "closed"))
    }
    if (input$rival == "Rivalries") {
      data <- data |> 
        filter(team_division.x == team_division.y)
    } else if (input$rival == "Non-Rivalries") {
      data <- data |> 
        filter(team_division.x != team_division.y)
    }
    if(input$team != "All") {
      if (input$location == "Home") {
        data <- data |> 
          filter(home_team == input$team)
      } else if (input$location == "Away") {
        data <- data |> 
          filter(away_team == input$team)
      }
      
      if(input$rest_time == "7") {
        data <- data |> 
          filter(
            (home_team == input$team & home_rest <= 7) | 
              (away_team == input$team & away_rest <= 7)) 
        
      } else if (input$rest_time == "14") {
        data <- data |> 
          filter((home_team == input$team & home_rest <= 14) | 
                                 (away_team == input$team & away_rest <= 14))
      } else if (input$rest_time == "21") {
        data <- data |> 
          filter((home_team == input$team & home_rest <= 21) | 
                                 (away_team == input$team & away_rest <= 21))
      }
    }
    #print(nrow(data))
    data
  })
  output$h <- renderPlot({
    validate(need(nrow(filtered_data()) > 0, "No data available for the selected filters. Please adjust your criteria.")
    )
    upsets<- filtered_data() |> 
      mutate(upset = ((spread_line >= 3.5 & margin < 0) | 
                        (spread_line <= -3.5 & margin > 0)))
    
    upsets|> 
      ggplot(aes(x = spread_line, fill = upset)) + 
      geom_histogram() +
      labs(
        title = "Upsets based on Spread Line over Selected Parameters",
        x = "Spread Line",
        caption = "(Positive spread means home team is favored)",
        y = "Count", fill = "Was the Selected Team Involved in an Upset?"
        ) +
      scale_fill_discrete(labels = c("FALSE" = "No", "TRUE" = "Yes")) +
      theme(plot.caption = element_text(size = 12))
  })
  output$l <- renderPlot({
    validate(need(nrow(filtered_data()) > 0, "No data available for the selected filters. Please adjust your criteria.")
    )
    upsets<- filtered_data() |> 
      mutate(upset = ((spread_line >= 3.5 & margin < 0) | 
                        (spread_line <= -3.5 & margin > 0)))
    upsets |> 
      group_by(season) |> 
      summarize(upset_prop = mean(upset)) |>
      ggplot(aes(x = season, y = upset_prop)) + 
      geom_line() + 
      geom_smooth(method = "lm") + 
      labs(
        title = "Upset Proportion over Selected Parameters",
        x = "Season",
        y = "Upset Proportion"
        )
  })
  
  
  upsetModel<-reactive({
    modeldata <- master_nflschedule
    if (input$team != "All"){
      modeldata <- master_nflschedule |> 
        filter(home_team == input$team | away_team == input$team)
    }
    modeldata <- modeldata |> mutate(
      upset = as.numeric(
        ((spread_line >= 3.5 & margin < 0) | (spread_line <= -3.5 & margin > 0))
        ),
      outdoors = (roof != "dome" & roof != "closed"),
      home = (home_team == input$team), 
      playoff = (game_type != "REG"),
      rival = (team_division.x == team_division.y),
      rest_time = case_when(
        home_team == input$team ~ home_rest,
        away_team == input$team ~ away_rest,
        .default = NA
        ),
      temp_outdoor = ifelse(outdoors == 1, temp, 0),
      wind_outdoor = ifelse(outdoors == 1, wind, 0))
    modeldata
    
  })
  logmodel <- reactive ({
    glmModel <- glm(upset ~ outdoors + home + playoff + rival + rest_time + temp_outdoor + wind_outdoor,family = "binomial", data = upsetModel())
    glmModel
  })
  
  textModel <- reactive ({
    if(input$team == "All" | input$outdoors == "Both" | input$rival == "Both" | input$playoff == "Both" | input$location == "Both") {
      "Must pick parameters other than \"Both\" for all of the parameters to receive a prediction."
    } else {
      tmodel <- data.frame(
        team = input$team, 
        outdoors = ifelse(input$outdoors == "Outdoors", T, F), 
        home = ifelse(input$location == "Home", T, F), 
        playoff = ifelse(input$playoff != "Regular Season Games", T, F),
        rival = ifelse(input$rival == "Rivalries", T, F),
        rest_time = as.numeric(input$rest_time), 
        temp_outdoor = ifelse(input$outdoors == "Outdoors", max(input$temp), 0),
        wind_outdoor = ifelse(input$outdoors == "Outdoors", max(input$wind), 0)
        )
      tmodel
    }
    
  })
  
  disclaimer <- "Temperature and Wind predictors used to calculate the probability of an upset are the maxiumum value of \"Wind Speed\" and \"Temperature\" selected in the sliders. The data for high wind speeds and temperatures is not as prevalent, which could result in inaccurate predictions at these values."
  
  output$disclaimer <- renderText ({
    disclaimer
  })
  
  output$model <- renderPrint({
    if(input$team != "All") {
      summary(logmodel())
    } else {
      "Please select a team."
    }
  })
  
  output$prob <- renderTable({
    if(input$team == "All" | input$outdoors == "Both" | input$rival == "Both" | input$playoff == "Both" | input$location == "Both") {
      "Must pick parameters other than \"Both\" for all of the parameters to receive a prediction."
    }
    else{
      prob_output<-textModel() |> 
        add_predictions(logmodel()) |> 
        mutate(exppred = exp(pred)) |> 
        mutate(upsetprob = exppred / (1+exppred)) |>
        rename("Probability of Being Involved in an Upset" = upsetprob)
      prob_output|>
        select(ncol(prob_output))
    }
  })  
  
  
  
  
  calculator_table<-reactive({
    calculator_tab<-upsetModel()|>
      mutate(
        was_upset = as.numeric(
          (home_team == input$team & margin < 0 & spread_line >= 3.5)|
          (away_team == input$team & margin > 0 & spread_line <= -3.5))
        )
    calculator_tab
  })
  
  
  calc_logmodel <- reactive ({
    calc_glmModel <- glm(was_upset ~ outdoors + home + playoff + rival + rest_time + temp_outdoor + wind_outdoor,family = "binomial",data = calculator_table())
    
    calc_glmModel
  })
  
  output$calculator_model<-renderPrint({
    if (input$team != "All"){
      summary(calc_logmodel())
    }
    else{
      "Please select a team."
    }
  })
  
  output$calc_disclaimer <- renderText ({
    disclaimer
  })
  
  output$calculator_prob<-renderTable({
    if(input$team == "All" | input$outdoors == "Both" | input$rival == "Both" | input$playoff == "Both" | 
       input$location == "Both") {
      "Must pick parameters other than \"Both\" for all of the parameters to receive a prediction."
    }
    else{
      calc_prob_output<-textModel() |> 
        add_predictions(calc_logmodel()) |> 
        mutate(exppred = exp(pred)) |> 
        mutate(upsetprob = exppred / (1+exppred)) |>
        rename("Probability of Being Upset by Another Team" = upsetprob)
      calc_prob_output|>
        select(ncol(calc_prob_output))
    }
  })
  
  output$calculator_histogram <- renderPlot({
    validate(need(nrow(filtered_data()) > 0, "No data available for the selected filters. Please adjust your criteria.")
    )
    filtered_data()|>
      mutate(was_upset = (home_team == input$team & margin < 0 & spread_line >= 3.5)|
               (away_team == input$team & margin > 0 & spread_line <= -3.5))|>
      ggplot(aes(x = spread_line, fill = was_upset)) +
      geom_histogram() +
      labs(
        x = "Spread Line", 
        y = "Count", 
        caption = "(Positive spread means home team is favored)", 
        title = "Games Where Your Selected Team was Upset by Another Team (Must Pick a Team)", 
        fill = "Was the selected team upset?"
        ) + 
      scale_fill_discrete(labels = c("FALSE" = "No", "TRUE" = "Yes")) + 
      theme(plot.caption = element_text(size = 12))
  })
  
  output$div_table <- renderTable({
    master_nflschedule |> 
      distinct(home_team, team_division.x) |> 
      rename("Team" = home_team, "Division" = team_division.x) |>
      arrange(Division, Team)
  })   
}

shinyApp(ui, server)
