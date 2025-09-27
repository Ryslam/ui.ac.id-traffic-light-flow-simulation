library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)

# Frontend
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = tags$span(style = "font-size: 16px;", "Traffic Light Flow Simulation")),
  dashboardSidebar(
    sliderInput("reaction_time",
                "Driver Reaction Time (seconds):",
                min = 0.5,
                max = 3.0,
                value = 1.5,
                step = 0.5),
    sliderInput("acceleration",
                "Car Acceleration (m/s²):",
                min = 1.0,
                max = 5.0,
                value = 2.5,
                step = 0.1),
    div(
      style = "display: flex; justify-content: centered;",
      actionButton("prev_step", "Prev", icon = icon("step-backward"), style="width: 39%;"),
      actionButton("next_step", "Next", icon = icon("step-forward"), style="width: 39%;")
    ),
    div(
      style = "display: flex; justify-content: centered;",
      actionButton("reset_sim", "Reset", icon = icon("fast-backward"), style="width: 39%;"),
      actionButton("finish_sim", "Finish", icon = icon("fast-forward"), style="width: 39%;")
    )
  ),
  dashboardBody(
    fluidRow(
      valueBoxOutput("cars_passed_box", width = 12),
    ),
    fluidRow(
      box(
        title = "Simulation Visualization",
        solidHeader = TRUE,
        status = "success",
        width = 12,
        plotOutput("position_plot")
      )
    )
  )
)

# Backend
server <- function(input, output, session) {

  # --- Constants ---
  CAR_LENGTH <- 5
  INITIAL_GAP <- 2
  TOTAL_CAR_SPACE <- CAR_LENGTH + INITIAL_GAP
  DT <- 0.5
  MAX_CARS <- 50

  MAX_CARS <- 50

  # --- Function to get initial simulation state ---
  get_initial_state <- function() {
    cars_df <- data.frame(
      id = 1:MAX_CARS,
      position = -(0:(MAX_CARS - 1)) * TOTAL_CAR_SPACE - CAR_LENGTH,
      velocity = 0,
      status = "stationary",
      reaction_start_time = Inf,
      start_time = Inf
    )

    # At t=0, the first car immediately starts reacting to the green light.
    cars_df$status[1] <- "reacting"
    cars_df$reaction_start_time[1] <- 0

    initial_state <- cars_df
    initial_state$time <- 0
    
    list(
      timer = 0,
      plot_data = list("0" = initial_state),
      cars_passed = 0,
      cars_df = cars_df,
      is_finished = FALSE
    )
  }

  # --- Reactive values to store simulation state ---
  sim_state <- reactiveValues(timer = 0, plot_data = NULL, cars_passed = 0, cars_df = NULL, is_finished = FALSE)
  
  # --- Initialize the simulation on startup ---
  observe({
    initial_values <- get_initial_state()
    sim_state$timer <- initial_values$timer
    sim_state$plot_data <- initial_values$plot_data
    sim_state$cars_passed <- initial_values$cars_passed
    sim_state$cars_df <- initial_values$cars_df
    sim_state$is_finished <- initial_values$is_finished
  })

  # --- Observer for the Reset Button ---
  observeEvent(input$reset_sim, {
    initial_values <- get_initial_state()
    sim_state$timer <- initial_values$timer
    sim_state$plot_data <- initial_values$plot_data
    sim_state$cars_passed <- initial_values$cars_passed
    sim_state$cars_df <- initial_values$cars_df
    sim_state$is_finished <- initial_values$is_finished
  })

  # --- Observer for the Previous Step Button ---
  observeEvent(input$prev_step, {
    # Don't run if not initialized or at the beginning
    req(sim_state$cars_df, sim_state$timer > 0)

    # Character representation of the current and previous time steps
    current_t_char <- as.character(sim_state$timer)
    prev_timer_val <- round(sim_state$timer - DT, 2)
    prev_t_char <- as.character(prev_timer_val)

    # Remove current state from history
    sim_state$plot_data[[current_t_char]] <- NULL
    
    # Decrement the timer
    sim_state$timer <- prev_timer_val
    
    # Revert cars_df to the previous state from history
    sim_state$cars_df <- sim_state$plot_data[[prev_t_char]]
    
    # Recalculate passed cars for the previous state
    sim_state$cars_passed <- sum(sim_state$cars_df$position > 0)
    
    # We are no longer in a "finished" state
    sim_state$is_finished <- FALSE
  })

  # --- Observer for the Next Step Button ---
  observeEvent(input$next_step, {
    # Don't run if not initialized or already finished
    req(sim_state$cars_df, !sim_state$is_finished)

    # Increment the timer
    t <- sim_state$timer + DT
    
    # Stop if the green light duration is over
    if (t > 15) {
      sim_state$is_finished <- TRUE
      sim_state$timer <- 15
      return()
    }

    sim_state$timer <- t

    # --- Update car states for the current time step 't' ---
    cars <- sim_state$cars_df
    REACTION_TIME <- input$reaction_time
    ACCELERATION <- input$acceleration

    for (i in 1:nrow(cars)) {
      # Check if a stationary car should start reacting
      if (cars$status[i] == "stationary" && i > 1) {
        car_in_front <- cars[i - 1, ]
        # This car starts reacting when the car in front of it *moves*.
        if (car_in_front$status == "moving" && cars$reaction_start_time[i] == Inf) {
          cars$status[i] <- "reacting"
          cars$reaction_start_time[i] <- car_in_front$start_time
        }
      }
      
      # Check if a reacting car should start moving
      if (cars$status[i] == "reacting") {
        if (t >= cars$reaction_start_time[i] + REACTION_TIME) {
          cars$status[i] <- "moving"
          cars$start_time[i] <- t # It starts moving now, at time t
        }
      }
      
      # Update position for moving cars
      if (cars$status[i] == "moving") {
        time_since_move <- t - cars$start_time[i]
        initial_position <- -(i - 1) * TOTAL_CAR_SPACE - CAR_LENGTH
        
        cars$position[i] <- initial_position + 0.5 * ACCELERATION * time_since_move^2
        cars$velocity[i] <- ACCELERATION * time_since_move
      }
    }
    
    sim_state$cars_df <- cars
    sim_state$cars_passed <- sum(cars$position > 0)

    current_state <- cars
    current_state$time <- t
    sim_state$plot_data[[as.character(t)]] <- current_state
  })

  # --- Observer for the Finish Simulation Button ---
  observeEvent(input$finish_sim, {
    # Don't run if not initialized or already finished
    req(sim_state$cars_df, !sim_state$is_finished)

    # Loop until the simulation reaches 15s
    while (sim_state$timer < 15) {
      # Increment the timer
      t <- sim_state$timer + DT
      sim_state$timer <- t

      # --- Update car states for the current time step 't' ---
      cars <- sim_state$cars_df
      REACTION_TIME <- input$reaction_time
      ACCELERATION <- input$acceleration

      for (i in 1:nrow(cars)) {
        # Check if a stationary car should start reacting
        if (cars$status[i] == "stationary" && i > 1) {
          car_in_front <- cars[i - 1, ]
          # This car starts reacting when the car in front of it *moves*.
          if (car_in_front$status == "moving" && cars$reaction_start_time[i] == Inf) {
            cars$status[i] <- "reacting"
            cars$reaction_start_time[i] <- car_in_front$start_time
          }
        }
        
        # Check if a reacting car should start moving
        if (cars$status[i] == "reacting") {
          if (t >= cars$reaction_start_time[i] + REACTION_TIME) {
            cars$status[i] <- "moving"
            cars$start_time[i] <- t # It starts moving now, at time t
          }
        }
        
        # Update position for moving cars
        if (cars$status[i] == "moving") {
          time_since_move <- t - cars$start_time[i]
          initial_position <- -(i - 1) * TOTAL_CAR_SPACE - CAR_LENGTH

          cars$position[i] <- initial_position + 0.5 * ACCELERATION * time_since_move^2
          cars$velocity[i] <- ACCELERATION * time_since_move
        }
      }

      sim_state$cars_df <- cars
      sim_state$cars_passed <- sum(cars$position > 0)

      current_state <- cars
      current_state$time <- t
      sim_state$plot_data[[as.character(t)]] <- current_state
    }

    # Finalize simulation state
    sim_state$is_finished <- TRUE
    sim_state$timer <- 15
  })

  # --- Render the valueBox ---
  output$cars_passed_box <- renderValueBox({
    current_time_str <- sprintf("%.1f", sim_state$timer)
    subtitle <- paste("Total Car Passed in", current_time_str, "seconds")
    valueBox(
      sim_state$cars_passed,
      subtitle,
      icon = icon("car"),
      color = if (sim_state$is_finished) "green" else "olive"
    )
  })

  # --- Render the plot ---
  output$position_plot <- renderPlot({
    plot_df <- bind_rows(sim_state$plot_data)
    
    # Show the first 25 cars
    cars_to_show <- 1:25
    plot_data_filtered <- filter(plot_df, id %in% cars_to_show)

    y_limits <- if(nrow(plot_data_filtered) > 0) {
      max_y <- max(plot_data_filtered$position)
      c(-150, max(50, max_y + 20))
    } else {
      c(-150, 50)
    }

    ggplot(plot_data_filtered, aes(x = time, y = position, group = id, color = status)) +
      geom_line(linewidth = 1) +
      geom_point(data = . %>% group_by(id) %>% filter(time == max(time)), size = 3) + # Show current position
      geom_hline(yintercept = 0, linetype = "dashed", color = "green", linewidth = 1.2) +
      annotate("text", x = 1, y = 5, label = "Traffic Light Line", color = "green", hjust = 0) +
      labs(
        title = "Car Position vs. Time",
        x = "Time (seconds)",
        y = "Position (meters)",
        color = NULL
      ) +
      coord_cartesian(xlim = c(0, 15), ylim = y_limits) +
      scale_x_continuous(breaks = seq(0, 15, by = 0.5)) +
      scale_color_manual(values = c("stationary" = "#FFB6B6", "reacting" = "#ADD8E6", "moving" = "#9DC183")) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = rel(1.3)),
        axis.title = element_text(size = rel(1.2)),
        legend.text = element_text(size = rel(1.1))
      )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
