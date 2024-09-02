# load libraries
pacman::p_load(shiny,
               rsconnect)

# Define UI for application
ui <- fluidPage(

  tags$head(
    tags$title("Expression and alternative splicing changes in a pre-eclampsia mouse model"),  # Set the title for the browser tab
    tags$link(rel = "icon", type = "image/png", href = "./results/Shiny_app_rnasplice_results/www/favicon_RNA.png")  # Set the favicon
  ),

  # Custom CSS to remove borders and scroll bars
  tags$style(HTML("
    .shiny-plot-output, .plotly-output {
      border: none;             /* Remove borders */
      box-shadow: none;         /* Remove any box shadows */
      overflow: hidden;         /* Hide scroll bars */
      margin: 0px;              /* Remove margin */
      padding: 0px;             /* Remove padding */
      background-color: white;  /* Set background color to white */
    }
  ")),


  # Custom CSS for iframe and container styling
  tags$style(HTML("
    .iframe-container {
      border: none;
      box-shadow: none;
      margin: 0px;
      padding: 0px;
      background-color: white;
    }
    iframe {
      border: none;
      box-shadow: none;
      width: 100%;
      height: auto;
      overflow: hidden;
    }
  ")),

  # Application title
  titlePanel(
    title = div("Gene and transcript expression differences in pre-eclampsia E 17.5 mouse cortices vs controls",
                style = "text-align: center;")),

  # Insert some space after title
  br(),
  div(style = "height: 5px;"),


  fluidRow(
    column(width = 6,
           style = "margin-bottom: 0px;",
           tags$iframe(src = "Gene_raw_volcano_overlap_labels2.html", style = "height: 1000px;") #, height = "1000px", width = "100%"
           ),


    column(width = 6,
           #style = "padding-left: 100px; padding-right: 100px;"
    ),

    column(width = 6,
           style = "margin-bottom: 0px;",
           tags$iframe(src = "DEXSeq_DTU_volcano_plot2.html", style = "height: 1000px;")
           ),
  )
)

# Define server logic
server <- function(input, output) {
  # No server-side logic is required to display static HTML files
}

# Run the application
shinyApp(ui = ui, server = server)
