# --- Constants ---
CAR_LENGTH <- 5
INITIAL_GAP <- 2
TOTAL_CAR_SPACE <- CAR_LENGTH + INITIAL_GAP
DT <- 1
MAX_CARS <- 16

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(plotly)

# Frontend
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = tags$span(style = "font-size: 16px;", "Traffic Light Flow Simulation")),
  dashboardSidebar(
    sliderInput("reaction_time",
                "Driver Reaction Time (seconds):",
                min = 1,
                max = 4,
                value = 2,
                step = 1),
    sliderInput("acceleration",
                "Car Acceleration (m/s²):",
                min = 1.0,
                max = 8,
                value = 1,
                step = 1),
    sliderInput("speed_limit",
                "Speed Limit (m/s):",
                min = 1,
                max = 16,
                value = 11,
                step = 1),
    sliderInput("intersection_width",
                "Intersection Width (m):",
                min = 1,
                max = 16,
                value = 12,
                step = 1),
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
        plotlyOutput("position_plot")
      )
    )
  )
)

# Backend
server <- function(input, output, session) {
  
  # --- Function to get initial simulation state ---
  get_initial_state <- function() {
    cars_df <- data.frame(
      id = 1:MAX_CARS,
      position = -(0:(MAX_CARS - 1)) * TOTAL_CAR_SPACE - CAR_LENGTH,
      velocity = 0,
      status = "resting",
      reaction_start_time = Inf,
      start_time = Inf
    )
    
    initial_state <- cars_df
    initial_state$time <- -DT
    
    list(
      timer = -DT,
      plot_data = setNames(list(initial_state), as.character(-DT)),
      cars_passed = 0,
      cars_df = cars_df,
      is_finished = FALSE
    )
  }
  
  # --- Reactive values to store simulation state ---
  sim_state <- reactiveValues(timer = 0, plot_data = NULL, cars_passed = 0, cars_df = NULL, is_finished = FALSE)
  
  # --- Initialize or reset the simulation ---
  observeEvent(c(input$reset_sim, input$reaction_time, input$acceleration, input$speed_limit, input$intersection_width), { #
    initial_values <- get_initial_state()
    sim_state$timer <- initial_values$timer
    sim_state$plot_data <- initial_values$plot_data
    sim_state$cars_passed <- initial_values$cars_passed
    sim_state$cars_df <- initial_values$cars_df
    sim_state$is_finished <- initial_values$is_finished
  }, ignoreInit = FALSE, ignoreNULL = FALSE)
  
  
  # --- Observer for the Previous Step Button ---
  observeEvent(input$prev_step, {
    # Don't run if not initialized or at the beginning
    req(sim_state$cars_df, sim_state$timer >= 0)
    
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
    sim_state$cars_passed <- sum(sim_state$cars_df$position >= input$intersection_width)
    
    # We are no longer in a "finished" state
    sim_state$is_finished <- FALSE
  })
  
  # --- Core Simulation Step Function ---
  run_simulation_step <- function(current_sim_state, reaction_time, acceleration, speed_limit, intersection_width) {
    t <- current_sim_state$timer + DT
    
    if (t > 15) {
      current_sim_state$is_finished <- TRUE
      current_sim_state$timer <- 15
      return(current_sim_state)
    }
    
    current_sim_state$timer <- t
    cars <- current_sim_state$cars_df
    
    if (t == 0) {
      cars$status[1] <- "reacting"
      cars$reaction_start_time[1] <- 0
    }
    
    for (i in 1:nrow(cars)) {
      if (cars$status[i] == "resting" && i > 1) {
        car_in_front <- cars[i - 1, ]
        if (car_in_front$status == "moving" && cars$reaction_start_time[i] == Inf) {
          cars$status[i] <- "reacting"
          cars$reaction_start_time[i] <- car_in_front$start_time
        }
      }
      
      if (cars$status[i] == "reacting") {
        if (t >= cars$reaction_start_time[i] + reaction_time) {
          cars$status[i] <- "moving"
          cars$start_time[i] <- t
        }
      }
      
      if (cars$status[i] == "moving") {
        time_since_move <- t - cars$start_time[i]
        initial_position <- -(i - 1) * TOTAL_CAR_SPACE - CAR_LENGTH
        
        time_to_max_speed <- speed_limit / acceleration
        
        if (time_since_move <= time_to_max_speed) {
          cars$position[i] <- initial_position + 0.5 * acceleration * time_since_move^2
          cars$velocity[i] <- acceleration * time_since_move
        } else {
          distance_during_accel <- 0.5 * acceleration * time_to_max_speed^2
          time_at_max_speed <- time_since_move - time_to_max_speed
          cars$position[i] <- initial_position + distance_during_accel + speed_limit * time_at_max_speed
          cars$velocity[i] <- speed_limit
        }
      }
    }
    
    current_sim_state$cars_df <- cars
    current_sim_state$cars_passed <- sum(cars$position >= intersection_width)
    
    current_state_for_plot <- cars
    current_state_for_plot$time <- t
    current_sim_state$plot_data[[as.character(t)]] <- current_state_for_plot
    
    if (current_sim_state$timer >= 15) {
      current_sim_state$is_finished <- TRUE
    }
    
    return(current_sim_state)
  }
  
  # --- Observer for the Next Step Button ---
  observeEvent(input$next_step, {
    req(sim_state$cars_df, !sim_state$is_finished)
    
    new_state <- run_simulation_step(
      current_sim_state = reactiveValuesToList(sim_state),
      reaction_time = input$reaction_time,
      acceleration = input$acceleration,
      speed_limit = input$speed_limit,
      intersection_width = input$intersection_width
    )
    
    sim_state$timer <- new_state$timer
    sim_state$cars_df <- new_state$cars_df
    sim_state$cars_passed <- new_state$cars_passed
    sim_state$plot_data <- new_state$plot_data
    sim_state$is_finished <- new_state$is_finished
  })
  
  # --- Observer for the Finish Simulation Button ---
  observeEvent(input$finish_sim, {
    req(sim_state$cars_df, !sim_state$is_finished)
    
    local_sim_state <- reactiveValuesToList(sim_state)
    
    while (local_sim_state$timer < 15 && !local_sim_state$is_finished) {
      local_sim_state <- run_simulation_step(
        current_sim_state = local_sim_state,
        reaction_time = input$reaction_time,
        acceleration = input$acceleration,
        speed_limit = input$speed_limit,
        intersection_width = input$intersection_width
      )
    }
    
    sim_state$timer <- local_sim_state$timer
    sim_state$cars_df <- local_sim_state$cars_df
    sim_state$cars_passed <- local_sim_state$cars_passed
    sim_state$plot_data <- local_sim_state$plot_data
    sim_state$is_finished <- local_sim_state$is_finished
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
  output$position_plot <- renderPlotly({
    plot_df <- bind_rows(sim_state$plot_data)
    
    # --- Data Duplication to Fix Gaps ---
    # For each car, find where status changes. Duplicate the point *before* the change,
    # but give it the *new* status. This creates an overlapping point that allows
    # ggplot to draw a continuous, color-changing line.
    plot_data_fixed <- plot_df %>%
      group_by(id) %>%
      arrange(id, time) %>%
      do({
        df <- .
        if (nrow(df) < 2) {
          df
        } else {
          transition_points <- list()
          for (i in 2:nrow(df)) {
            if (df$status[i] != df$status[i-1]) {
              # Duplicate the CURRENT point, but give it the PREVIOUS status
              new_point <- df[i, ]
              new_point$status <- df[i-1, ]$status
              transition_points[[length(transition_points) + 1]] <- new_point
            }
          }
          bind_rows(df, bind_rows(transition_points))
        }
      }) %>%
      ungroup() %>%
      arrange(id, time)
    # --- End of Data Duplication ---
    
    # Add hover text to the fixed data
    plot_data_fixed <- plot_data_fixed %>%
      mutate(
        passed_status = case_when(
          position >= input$intersection_width ~ "Passed",
          position >= 0 ~ "Passing",
          TRUE ~ "Not Passed"
        ),
        hover_text = paste(
          "Car ID:", id,
          "<br>Time:", time, "s",
          "<br>Position:", round(position, 2), "m",
          "<br>Velocity:", round(velocity, 2), "m/s",
          "<br>Status:", passed_status
        )
      )
    
    # Create clean data for the points, resolving duplicates at transition times.
    # At a status change, we have two points at the same time. We want the one
    # with the "newer" status for the point geometry.
    current_points_df <- plot_data_fixed %>%
      filter(time == max(time)) %>%
      mutate(status = factor(status, levels = c("resting", "reacting", "moving"))) %>%
      group_by(id) %>%
      arrange(status) %>%
      slice_tail(n = 1) %>%
      ungroup()
    
    y_limits <- if(nrow(plot_data_fixed) > 0) {
      max_y <- max(plot_data_fixed$position)
      c(-64, max(16, max_y + 4))
    } else {
      c(-64, 16)
    }
    
    line_color <- if (sim_state$timer < 0 || sim_state$is_finished) "red" else "green"
    
    p <- ggplot(plot_data_fixed, aes(x = time, y = position, group = id)) +
      geom_line(aes(color = status), linewidth = 0.5) +
      geom_point(
        data = current_points_df, 
        aes(color = status, text = hover_text), 
        size = 2
      ) +
      geom_rect(aes(xmin = -Inf, xmax = Inf, ymin = 0, ymax = input$intersection_width), fill = "grey80", alpha = 0.5, inherit.aes = FALSE) + # Using input
      geom_segment(
        aes(x = -1, y = 0, xend = 15, yend = 0, text = "Traffic Light<br>Position: 0 m"),
        color = line_color,
        linetype = "dashed",
        linewidth = 0.5,
        inherit.aes = FALSE
      ) +
      geom_segment(
        aes(x = -1, y = input$intersection_width, xend = 15, yend = input$intersection_width, text = paste("Intersection Exit<br>Position:", input$intersection_width, "m")), # Using input
        color = "black",
        linetype = "dashed",
        linewidth = 0.5,
        inherit.aes = FALSE
      ) +
      labs(
        title = "Car Position vs Time",
        x = "Time (seconds, t=0 is green light)",
        y = "Position (meters, relative to traffic light)",
        color = "Status"
      ) +
      coord_cartesian(xlim = c(-1, 15), ylim = y_limits) +
      scale_x_continuous(breaks = seq(-1, 15, by = 1)) +
      scale_color_manual(
        name = NULL,
        values = c("resting" = "#FFB6B6", "reacting" = "#ADD8E6", "moving" = "#9DC183"),
        labels = c("moving" = "Moving", "reacting" = "Reacting", "resting" = "Resting")
      ) +
      theme_minimal() +
      theme(
        axis.title = element_text(size = rel(0.9)),
        legend.text = element_text(size = rel(0.9))
      )
    
    gp <- ggplotly(p, tooltip = "text")
    
    gp %>% layout(legend = list(orientation = "h", x = 0, y = -0.2, xanchor = "left"))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)