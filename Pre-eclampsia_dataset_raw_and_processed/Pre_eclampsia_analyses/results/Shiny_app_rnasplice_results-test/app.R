# THIS IS A TEST APP TO IMPROVE AND ENHANCE THE FUNCTIONALITY OF MY INITIAL APP

# Load the interactive plots saved as RDS files
DESeq_gene_plot <- readRDS("www/Gene_raw_volcano_overlap_labels2.rds")

DEXSeq_DTU_tx_plot <- readRDS("www/DEXSeq_DTU_volcano_plot2.rds")

DEXSeq_DEU_exon_plot <- readRDS("www/DEXSeq_DEU_res_volcano_plot.rds")

# DEXSeq_DEU_exon_plot <- readRDS("./results/Shiny_app_rnasplice_results-test/www/DEXSeq_DTU_volcano_plot2.rds")

# load libraries
pacman::p_load(shiny,
               rsconnect,
               DT,
               plotly)

# Define UI for application
ui <- fluidPage(

  tags$head(
    tags$title("Expression and Alternative Splicing Changes in a Pre-eclampsia Mouse Model"),  # Set the title for the browser tab
    tags$link(rel = "icon", type = "image/png", href = "./results/Shiny_app_rnasplice_results-test/www/favicon_RNA.png"),  # Set the icon for the tab

  tags$link(rel = "stylesheet", type = "text/css", href = "./results/Shiny_app_rnasplice_results-test/www/bootstrap.min.css"),  # Link to custom Lux theme CSS (free theme from Bootswatch)


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


  # Custom CSS for iframe and container styling to remove borders and scroll bars
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
  ),

  # Application title
  titlePanel(title = div("Gene and Transcript Expression Differences in Pre-eclampsia E 17.5 Mouse Cortices vs Controls",
                         style = "text-align: center;"
                         )
             ),

  # Insert some space after title
  br(),
  div(style = "height: 5px;"),

  # Tab Layout
  tabsetPanel(
    id = "main_tabs",

    # Overview Dashboard Tab
    tabPanel(
      "Overview",
      fluidRow(
        column(12,
               h3("Overview Dashboard"),
               p("Welcome to the gene and transcript expression analysis dashboard. Use the tabs above to explore specific analyses."),
               p("Below are links to the specific analyses:"),
               actionButton("gene_tab", "Gene-Level Volcano Plot"),
               actionButton("exon_tab", "Exon-Level Volcano Plot")
        )
      )
    ),

    # Gene-Level Analysis Tab
    tabPanel(
      "Gene-Level Volcano Plot",
      fluidRow(
        column(
          width = 12,
          textInput("geneSearch1", "Search for a Gene:", ""),
          plotlyOutput("DESeq_gene_plot", height = "auto", width = "auto"),
          DTOutput("geneDataTable"),
          downloadButton("downloadGeneData", "Download Selected Gene Data")
        )
      )
    ),

    # Exon-Level Analysis Tab
    tabPanel(
      "Exon-Level Volcano Plot",
      fluidRow(
        column(
          width = 12,
          textInput("geneSearch2", "Search for an Exon:", ""),
          plotlyOutput("DEXSeq_DEU_exon_plot", height = "auto", width = "auto"),
          DTOutput("exonDataTable"),
          downloadButton("downloadExonData", "Download Selected Exon Data")
        )
      )
    )
  )
)
#
#   fluidRow(
#     column(width = 6,
#            style = "margin-bottom: 0px;",
#            tags$iframe(src = "Gene_raw_volcano_overlap_labels2.html", style = "height: 1000px;") #, height = "1000px", width = "100%"
#            ),
#
#
#     column(width = 6,
#            #style = "padding-left: 100px; padding-right: 100px;"
#     ),
#
#     column(width = 6,
#            style = "margin-bottom: 0px;",
#            tags$iframe(src = "DEXSeq_DTU_volcano_plot2.html", style = "height: 1000px;")
#            ),
#   )
# )


# Define server logic
server <- function(input, output, session) {



  # Navigate between tabs using action buttons
  observeEvent(input$gene_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "Gene-Level Volcano Plot")
  })

  observeEvent(input$exon_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "Exon-Level Volcano Plot")
  })

  # Reactive expression to highlight a gene in gene-level plot
  highlighted_gene1 <- reactive({
    req(input$geneSearch1)
    df_gene <- DESeq_gene_plot$x$data[[1]]$customdata  # Assuming you stored custom data
    match <- df_gene[df_gene$Gene == input$geneSearch1, ]
    if (nrow(match) == 0) {
      return(NULL)
    } else {
      return(match)
    }
  })

  # Render gene-level plot with highlighting
  output$DESeq_gene_plot <- renderPlotly({
    # Register the plotly_selected event for DESeq_gene_plot
    plot <- event_register(DESeq_gene_plot, "plotly_selected")

    # Add highlighted points if applicable
    if (!is.null(highlighted_gene1())) {
      plot <- plot %>% add_markers(
        x = highlighted_gene1()$log2FoldChange,
        y = -log10(highlighted_gene1()$pvalue),
        text = highlighted_gene1()$Gene,
        marker = list(size = 10, color = "red"),
        name = "Highlighted Gene"
      )
    }

    plot
  })

  # Reactive expression to capture selected data points from gene plot
  selected_gene_data <- reactive({
    event_data("plotly_selected", source = "DESeq_gene_plot")
  })

  # Display selected gene data in a table
  output$geneDataTable <- renderDT({
    req(selected_gene_data())
    df_gene <- DESeq_gene_plot$x$data[[1]]$customdata  # Assuming you stored custom data
    selected_points <- selected_gene_data()
    df_gene[selected_points$pointNumber + 1, ]
  })

  # Download handler for selected gene data
  output$downloadGeneData <- downloadHandler(
    filename = function() {
      paste("selected_gene_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(selected_gene_data())
      df_gene <- DESeq_gene_plot$x$data[[1]]$customdata
      selected_points <- selected_gene_data()
      write.csv(df_gene[selected_points$pointNumber + 1, ], file, row.names = FALSE)
    }
  )

  # Reactive expression to highlight a gene in exon-level plot
  highlighted_gene2 <- reactive({
    req(input$geneSearch2)
    df_exon <- DEXSeq_DEU_exon_plot$x$data[[1]]$customdata  # Assuming you stored custom data
    match <- df_exon[df_exon$Exon == input$geneSearch2, ]
    if (nrow(match) == 0) {
      return(NULL)
    } else {
      return(match)
    }
  })

  # Render exon-level plot with highlighting
  output$DEXSeq_DEU_exon_plot <- renderPlotly({
    plot <- DEXSeq_DEU_exon_plot %>% event_register("plotly_selected")
    if (!is.null(highlighted_gene2())) {
      plot <- plot %>% add_markers(
        x = highlighted_gene2()$log2FoldChange,
        y = -log10(highlighted_gene2()$pvalue),
        text = highlighted_gene2()$Exon,
        marker = list(size = 10, color = "red"),
        name = "Highlighted Gene"
      )
    }
    plot
  })

  # Reactive expression to capture selected data points from exon plot
  selected_exon_data <- reactive({
    event_data("plotly_selected", source = "DEXSeq_DEU_exon_plot")
  })

  # Display selected exon data in a table
  output$exonDataTable <- renderDT({
    req(selected_exon_data())
    df_exon <- DEXSeq_DEU_exon_plot$x$data[[1]]$customdata
    selected_points <- selected_exon_data()
    df_exon[selected_points$pointNumber + 1, ]
  })

  # Download handler for selected exon data
  output$downloadExonData <- downloadHandler(
    filename = function() {
      paste("selected_exon_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(selected_exon_data())
      df_exon <- DEXSeq_DEU_exon_plot$x$data[[1]]$customdata
      selected_points <- selected_exon_data()
      write.csv(df_exon[selected_points$pointNumber + 1, ], file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
