library(shiny)
library(pool)
library(ggplot2)
library(dplyr)
library(tidyr)

# Define the server logic
function(input, output, session) {
  # Refresh data every minute
  autoInvalidate <- reactiveTimer(60000)  # 60 seconds
  
  # Reactive value to store the last refresh time
  last_refresh <- reactiveVal(Sys.time())
  
  # Populate the state dropdown
  observe({
    states <- dbGetQuery(pool, "SELECT DISTINCT state FROM summary")
    states <- c("All", states$state)  # Add "All" option
    updateSelectInput(session, "state", choices = states, selected = "All")
  })
  
  # Query and filter data
  filtered_data <- reactive({
    autoInvalidate()  # Trigger data refresh every minute
    
    # Update the last refresh time
    last_refresh(Sys.time())
    
    if (input$state == "All") {
      query <- "SELECT * FROM summary"
    } 
    else {
      query <- paste0("SELECT * FROM summary WHERE state = '", input$state, "'")
    }
    
    dbGetQuery(pool, query)
  })
    
  # Display the summary table
  output$summary_table <- renderDataTable({
    filtered_data()
  })

  # Display the last refresh time
  output$lastRefresh <- renderText({
    paste("Last refreshed at:", format(last_refresh(), "%Y-%m-%d %H:%M:%S"))
  })

  # Plot the vote counts
  output$votes_plot <- renderPlot({
    data <- filtered_data()
    if (nrow(data) > 0) {
      # Aggregate the data for the bar plot
      plot_data <- data %>%
        summarize(
          `Donald Trump` = sum(trump16, na.rm = TRUE),
          `Hillary Clinton` = sum(clinton16, na.rm = TRUE),
          `Other Candidates` = sum(otherpres16, na.rm = TRUE)
        ) %>%
        pivot_longer(cols = everything(), names_to = "Candidate", values_to = "Votes")
          
      ggplot(plot_data, aes(x = Candidate, y = Votes, fill = Candidate)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c("Donald Trump" = "red", 
                                     "Hillary Clinton" = "blue", 
                                     "Other Candidates" = "green")) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(size = 14, face = "bold"), # Bigger x-axis labels (candidates)
          axis.title.x = element_blank(), # Remove x-axis label
          axis.title.y = element_text(size = 16), # Bigger y-axis title
          plot.title = element_text(size = 18, face = "bold"), # Bigger plot title
          plot.background = element_rect(fill = "#ffffff", color = NA), # White background
          panel.grid.major = element_line(color = "#e9ecef"), # Soft grid lines
          legend.position = "none" # Remove legend
        ) +
        labs(
          title = ifelse(input$state == "All", 
                         "Votes Summary for All States", 
                         paste("Votes Summary for", input$state)),
          y = "Votes"
        )
    }
  })
}