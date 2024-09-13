# THIS IS A TEST APP TO IMPROVE AND ENHANCE THE FUNCTIONALITY OF MY INITIAL APP


# ___________________________________________ -----------------------------------------------------

# Preparations -----------------------------------------------

# * loading libraries -------------------------------------------------------
pacman::p_load(shiny,
               shinydashboard,
               rsconnect,
               DT,
               plotly,
               readr)

# ___________________________________________ -----------------------------------------------------

# Define UI for application -----------------------------------------------


ui <- fluidPage(

# ___________________ -----------------------------------------------------
## * Tab title, icon, and style settings ---------------------------------------
 tags$head(

#### * *  Set the title for the browser tab ----------------------------------
    tags$title("Gene Expression and Alternative Splicing Changes in a Pre-eclampsia Mouse Model"),


### * * Set the icon for the tab --------------------------------------------
    tags$link(rel = "icon", type = "image/png", href = "./results/Shiny_app_rnasplice_results-test/www/favicon_RNA.png"),

### * *  Link to custom Lux theme CSS (free theme from Bootswatch) ----------
  tags$link(rel = "stylesheet", type = "text/css", href = "./results/Shiny_app_rnasplice_results-test/www/bootstrap.min.css"),



### * * remove border from Plotly outputs with custom CSS styling -----------

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



### * * remove border from iframe and container with custom CSS styling  --------
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

# ___________________ -----------------------------------------------------
## * Set application title for page -----------------------------------------------
  titlePanel(title = div("Gene Expression and Alternative pre-mRNA Splicing Changes in the Embryonic Cerebral Cortices of a Pre-eclampsia Mouse Model vs Controls at Embryonic Day 17.5",
                         style = "text-align: center;"
                         )
             ),

  # Insert some space after title
  br(),
  div(style = "height: 5px;"),

# ___________________ -----------------------------------------------------
## * Tab Layout ----------------------------------------------------------
  tabsetPanel(
    id = "main_tabs",


### * * Overview Dashboard Tab --------------------------------------------

    tabPanel(
      "Overview",
      fluidRow(
        column(12,
               h3("Overview"),
               p("Welcome to the gene and transcript expression analysis. Use the tabs above to explore specific analyses, or click the buttons below"),

               # Insert some space after title
               br(),
               div(style = "height: 5px;"),

               p("General statistics and quality control of the dataset:"),
               actionButton("general_tab", "General statistics and quality control"),

               # Insert some space after overview tab button
               br(),
               div(style = "height: 20px;"),

               p("Below are links to the specific analyses:"),
               actionButton("gene_tab", "Gene- and Transcript-Level Analysis"),
               actionButton("exon_tab", "Exon-Level Analysis")
        )
      )
    ),

### * * Geneneral Stats of RNA-Seq dataset GSE167193 --------------------------------------------

 tabPanel(
      "General statistics and quality control",

      # Insert some space after title bar
      br(),
      div(style = "height: 5px;"),

      fluidRow(
        column(
          width = 6,
          box(
            title = "Counts",
            status = "primary",
            plotlyOutput(""),
            p("Add explanations or details here")
            ),

          ),
        column(
          width = 6,
          box(
            title = "NAs",
            status = "primary",
            plotlyOutput(""),
            p("Add explanations or details here")
          )
        )
        )
      ),

### * * Gene- and Transcript-Level Analysis Tab --------------------------------------------
    tabPanel(

      "Gene- and Transcript-Level Analysis", # name of the tab (must be same in server logic below)

     # Insert some space after title bar
      br(),
      div(style = "height: 5px;"),

      ### * * * Row with search box and data download button ----
      fluidRow(
        column(
          width = 6,
          textInput("geneSearch", "Search for a gene and its associated transcripts:", ""),
        ),
        column(
          width = 6,
          downloadButton("downloadGeneData", "Click here to download data of selected points"),
        ),
      ),


     ### * * * Row with volcano plots ----
      fluidRow(
        column(
          width = 6,
          box(
            title = "Gene expression levels (DESeq2)",
            status = "primary",
            plotlyOutput("plot_DESeq2"),
            p("Add explanations or details here")
            ),

          ),
        column(
          width = 6,
          box(
            title = "Transcript expression levels (DEXSeq DTU)",
            status = "primary",
            plotlyOutput("plot_DEXSeq_DTU"),
            p("Add explanations or details here")
          )
        )
        )
      ),

### * * Exon-Level Analysis Tab --------------------------------------------



    tabPanel(
      "Exon-Level Analysis",

      # Insert some space after title
      br(),
      div(style = "height: 5px;"),

      ### * * * Row with volcano plots ----
      fluidRow(
        column(
          width = 12,
          textInput("geneSearch2", "Search for an Exon:", ""),
          plotlyOutput("DEXSeq_DEU_exon_plot", height = "auto", width = "auto"),
          DTOutput("exonDataTable"),
          downloadButton("downloadExonData", "Download Selected Exon Data")
        )
      )



    ),

### * * Sources Tab --------------------------------------------

tabPanel(
  "Sources",


  fluidRow(
    column(
      width = 12,
      textInput("geneSearch2", "Search for an Exon:", ""),
      plotlyOutput("DEXSeq_DEU_exon_plot", height = "auto", width = "auto"),
      DTOutput("exonDataTable"),
      downloadButton("downloadExonData", "Download Selected Exon Data")
    )
  )

  ### * * * Row with volcano plots ----

)

  )

)


# ___________________________________________ -----------------------------------------------------

# Define server logic -----------------------------------------------------
server <- function(input, output, session) {

# ___________________________________________ -----------------------------------------------------

# ___________________________________________
# Import CSV files as tibbles ----
  DESeq2_data <- read_csv("www/DESeq2_non-NA_res.csv")
  DEXSeq_DTU_data <- read_csv("www/DEXSeq_DTU_all.csv")
  DEXSeq_DEU_data <- read_csv("www/DEXSeq_DEU_res.csv")
  rMATS_SE_data <- read_csv("www/rMATS_SE_jcec.csv")
  SUPPA_SE_data <- read_csv("www/SUPPA_SE_res.csv")
  edgeR_SE_data <- read_csv("www/edgeR_exon_res.csv")

  # Extract a mini tibble with the data for the differentially expressed genes the authors have validated in the paper
  points_to_label <- DESeq2_data[DESeq2_data$gene %in% c("Grin2a","Grin2b","Ube2c","Celsr1","Kif18","Creb5", "Gli2", "Plk1"), ] # Kif18 not found in my data

  # ___________________ -----------------------------------------------------
# Overview tab -----------------------------------------------------

### Navigate between tabs using action buttons ----
  observeEvent(input$general_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "General statistics and quality control")
  })

  observeEvent(input$gene_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "Gene- and Transcript-Level Analysis")
  })

  observeEvent(input$exon_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "Exon-Level Analysis")
  })

  observeEvent(input$citation_tab, {
    updateTabsetPanel(session, "main_tabs", selected = "Sources")
  })
  # ___________________ -----------------------------------------------------
# Gene and transcript expression tab ----
#
## * * Plots ----
### * * * Gene-level plot ----
  output$plot_DESeq2 <- renderPlotly(
    {
    plot_ly(DESeq2_data,
            x = ~log2FoldChange,
            y = ~minuslog10padj,
            type = 'scatter',
            mode = 'markers',
            marker = list(size = 6,
                          opacity = 0.4),
            color = ~regulation,
            colors = c("firebrick3", "cadetblue3", "lightgray"),#factor lelvels are downregulated, upregulated, not significant
            hoverinfo = 'text',
            text = ~paste("Gene:", gene,
                          "<br>log2 FC:", log2FoldChange,
                          "<br>FDR:", formatC(padj, format = "e", digits = 3)
            ),
            showlegend = TRUE
    ) |>
        add_trace(
          data = DESeq2_data |> filter(inPublication == TRUE),
          x = ~log2FoldChange,
          y = ~minuslog10padj,
          type = 'scatter',
          mode = 'markers',
          marker = list(size = 3),
          color=I("black"), # I = collapse the mapping of all points onto one single color, which also ensure there's only one legend entry for this property, not 3 (there doesn't seem to be any easy way to prevent this second trace from inheriting the mapping to upregulated, downregulated, not significant from the first trace)
          hoveron = "fills", # useful so that the annotations are taken from the trace underneath and the labels then have the color of the large points (red, gray, or blue)
          showlegend = TRUE,
          name = "DEG identified in published data"
        ) |>
        layout(
          title = list(text = paste(nrow(DESeq2_data), " points plotted", sep = ""), x = 0.5),
          xaxis = list(title = "Log2(Fold Change Preeclampsia vs Control)"),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of gene)"),
          legend = list(title = list(text = "Regulation and Dataset"),
                        orientation = 'h',
                        y = -0.25, x = 0.5,
                        xanchor = 'center')
        ) |>
        add_annotations(
          x = points_to_label$log2FoldChange,
          y = points_to_label$minuslog10padj,
          text = points_to_label$gene,
          showarrow = TRUE,
          arrowhead = 1,
          ax = 20,
          ay = -40
        )
      }
    )

## * * Reactive expression to highlight a gene in gene-level plot ----
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

  # ___________________ -----------------------------------------------------
  # Exon-Level tab ----
  #
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
