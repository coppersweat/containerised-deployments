library(shiny)
library(plotly)
library(DT)
library(bslib)

# Define the UI for the application
fluidPage(
  tags$style(HTML("
    #lastRefresh {
        font-size: 14px;
    }
  ")),
  theme = bs_theme(
    version = 4,           # Use Bootstrap 4
    bootswatch = "minty"   # Apply a modern, clean theme
  ),
  titlePanel(
    "2016 US Presidential Votes Summary",
    windowTitle = "Votes Summary"
  ),
  sidebarLayout(
    sidebarPanel(
      selectInput("state", "Select State:", choices = NULL, width = "100%"),
      textOutput("lastRefresh"), # Label for the last refresh time
      width = 3,  # Slightly wider for better aesthetics
      style = "background-color: #f8f9fa; border-radius: 10px; padding: 20px;"
    ),
    mainPanel(
      fluidRow(
        column(
          width = 12,
          plotOutput("votes_plot", height = "400px"),
          style = "margin-bottom: 20px;"
        )
      ),
      br(),
      fluidRow(
        column(
          width = 12,
          dataTableOutput("summary_table")
        )
      ),
      style = "padding: 20px;"
    )
  )
)