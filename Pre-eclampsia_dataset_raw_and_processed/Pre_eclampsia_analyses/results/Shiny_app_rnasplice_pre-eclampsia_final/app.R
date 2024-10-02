# THIS IS THE IMPROVED AND FUNCTIONALITY-ENHANCED VERSION OF MY INITIAL APP

# In case needing to set the working directory to the app directory:
# setwd("./results/Shiny_app_rnasplice_pre-eclampsia_final")
# To deploy:
# rsconnect::deployApp(appName = 'shiny_app_pre-eclampsia_results')

# ___________________________________________ -----------------------------------------------------

# Preparations -----------------------------------------------

## * loading libraries -------------------------------------------------------
pacman::p_load(shiny,
               shinydashboard,
               rsconnect,
               DT,
               plotly,
               readr,
               wrappedtools)

# ___________________________________________ -----------------------------------------------------

# UI -----------------------------------------------


ui <- fluidPage(

  # ___________________ -----------------------------------------------------
  ## * Set application title for page -----------------------------------------------
  titlePanel(
    title = div(
      h1("How Does Pre-eclampsia affect Alternative Splicing in the Developing Brain?",  style = "text-align: center;"),
      h4("Transcript levels and Alternative pre-mRNA Splicing Changes in the Cerebral Cortices of a Pre-eclampsia Mouse Model at Embryonic Day 17.5", style = "text-align: center;")
    )
  ),

  #div(class = "title", titlePanel("Gene Expression and Alternative pre-mRNA Splicing Changes")),

  # Insert some space after title
  br(),
  div(style = "height: 5px;"),


  # ___________________ -----------------------------------------------------
  ## * Style settings ---------------------------------------
  tags$head(

    #### * *  Title for the browser tab ----------------------------------
    #tags$title("Gene Expression and Alternative Splicing Changes in a Pre-eclampsia Mouse Model"), # this stopped working for some reason
    tags$script(HTML("
    document.title = 'Effect of Pre-eclampsia on Alternative Splicing in the Developing Brain';
  ")),

    ### * * Icon for the browser tab --------------------------------------------
    tags$link(rel = "icon", type = "image/png", href = "favicon_RNA.png"),

    ### * *  Link to custom Lux theme CSS (free theme from Bootswatch) ----------
    tags$link(rel = "stylesheet", type = "text/css", href = "bootstrap.min.css"),

    ### * * Fix title, top bar, and navigation pane in place   --------
    tags$style(HTML("
      /* Sticky tab row */
      .nav-tabs {
        position: sticky;
        top: 0px;  /* Sticky below the title */
        text-decoration: none;       /* Remove underline */
        background-color: white;
        z-index: 999;
      }

      /* Sticky sidebar (navigation) */
      .sidebar {
        position: sticky;
        background-color: white;
        border: none;  /* Remove the border */
        box-shadow: none;  /* Remove any shadow */
        top: 100px;  /* Below title and tab row */
        height: calc(100vh - 100px);
        overflow-y: auto;
        z-index: 998;
      }

      /* Scrollable main content */
      .main-panel {
        overflow-y: auto;
        max-height: calc(100vh - 100px);  /* Subtract fixed elements' height */
      }
    ")),

    ### * * "About me" tab color   --------
    tags$style(HTML("
  /* Target the sixth tab specifically and change its color */
  .nav-tabs li:nth-child(6) a {
    background-color: #007BFF;
    color: white;
  }

  /* Change the color on hover for the sixth tab */
  .nav-tabs li:nth-child(6) a:hover {
    background-color: white;
    color: black;
  }
")),

    ### * * Background sidebar list  --------
    tags$style(HTML("
      /* Remove gray background from the sidebar list */
      .sidebar ul {
        background-color: white;
        padding: 0;  /* Remove padding */
        margin: 0;  /* Remove margin */
      }
    ")),


    ### * * decrease space between main panel and sidebar panel   --------
    tags$style(HTML("
      .row {
        margin-left: 0px;
        margin-right: 0px;
      }
      .col-sm-10 {
        padding-right: -10px; /* Reduce space in main panel */
      }
      .col-sm-2 {
        padding-left: -10px;  /* Reduce space in sidebar panel */
      }
    ")),

    ### * * remove border from Plotly outputs  -----------
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

    ### * * remove padding within fluidRows to help the Plotly plots make most of the space   --------
    tags$style(HTML("
  /* Remove padding and margin from the fluidRow */
  .custom-row {
    margin-left: 0 !important;
    margin-right: 0 !important;
    padding-left: 50 !important;
    padding-right: 50 !important;
  }

  /* Decrease padding and margin from columns inside the fluidRow */
  .custom-row .col-sm-6 {
    padding-left: 50 !important;
    padding-right: 50 !important;
    margin-left: 50 !important;
    margin-right: 50 !important;
    flex: 0.8 0.8 45%;  /* Force each column to take up 50% width */
    /* max-width: 45% !important;  Ensure columns occupy half the row */
  }

    /* Ensure plotly outputs fill the full width */
    .shiny-plot-output {
      width: 100% !important;
")),

    ### * * remove border from iframe and container   --------
    tags$style(HTML("
    .iframe-container {
      border: none;
      box-shadow: none;
      max-width: 100%;
      margin: 0px;
      padding: 0px;
      background-color: white;
    }
    iframe {
      border: none;
      box-shadow: none;
      max-width: 100%;
      width: 100%;
      height: auto;
      overflow: hidden;
    }
  ")),

    ### * * improve scrolling behavior   --------
    tags$style(HTML("
    html {
      scroll-behavior: smooth;
    }
  ")),

    ### * * headings colors, spacing   --------
    tags$style(HTML("
  h1 {
    color: #007BFF;  /* blue for title */
  }
  h2 {
    color: #890025;  /* dark red for section headings */
    margin-top: 30px;  /* Add space above the h2 heading */
  }
  h3 {
    color: #6c757d;  /* gray for column/plot headings  */
    font-size: 12px;
    margin-top: 30px;  /* Add space above the h2 heading */
  }
    h4 {
    /* for page subtitle */
    color: #6c757d;  /* gray for column/plot headings  */
  }
")),

    ### * * set colors for body and everything else   --------
    tags$style(HTML("
  /* Change the font color globally, excluding headings and sidebar links */

  /* Global font color change */
  body, p, div, span, li {
    color: #000000;  /* Set a black font color for better readability */
  }
")),

    ### * * make fonts larger across the board (too small until now) and more bold  --------
    tags$style(HTML("
  /* Scale up all fonts universally and make them a bit more bold */
  * {
    font-size: 1.6rem;
    font-weight: 500;  /* Use 500 for medium boldness */

     /* Customize specific elements if needed (e.g., titles) */
  h1, h2, h3, h4, h5, h6 {
    font-weight: 700;  /* Use 700 for a slightly bolder effect on headings */
  }
  }
")),

    ### * * Line spacing, margins,justification --------
    tags$style(HTML("
  /* Reduce line spacing in main text */
  body, p {
    line-height: 1.2;  /* Adjust the line-height (1.2 is slightly tighter) */
  }

  /* Reduce margins around paragraphs */
  p {
    margin-top: 5px;
    margin-bottom: 5px;
  }

  /* Optionally reduce spacing in other text elements */
  li, ul {
    line-height: 1.2;  /* Adjust list item line spacing */
    margin-top: 5px;
    margin-bottom: 5px;
  }

    /* Justify all text except for h1 and h2 */
 p {
    text-align: justify;  /* Justify text */
    text-align-last: left;  /* Left-align the last line */
  }


")),

    ### * * remove underlining from tabs and navigation pane links to sections   --------
    tags$style(HTML("
  /* Remove underline and change color for links in tab titles (navbar) */
  .nav-tabs > li > a, .nav-tabs > li > a:focus, .nav-tabs > li > a:hover {
    text-decoration: none;  /* Remove underline */
    color: #007BFF;         /* Set a new color for tab title links */
  }

 /* Adjust font size of the tab names in the navbar */
  .nav-tabs > li > a {
    font-size: 14px;  /* Change this value to the desired size */
  }

  /* Remove underline and change color for links in the sidebar */
  .sidebar a {
    text-decoration: none !important;  /* Remove underline */
    color: #890025 !important;         /* Set a new color for sidebar links */
  }

  /* Ensure hover effect removes underline as well */
  .nav-tabs > li > a:hover, .sidebar a:hover {
    text-decoration: none !important;  /* Remove underline on hover */
    color: #FF5733 !important;         /* Change color on hover */
  }
")),

    ### * * image containers   --------
    tags$style(HTML("
    .image-container {
      display: flex;
      align-items: center; /* Vertical alignment */
      justify-content: center; /* Horizontal alignment */
      max-height: 250px; /* Ensure it takes the full height of the column */
    }
    .image-container img {
      max-width: 250px; /* Responsive image size */
      height: auto;
    }
  ")),

  ),


  # ___________________ -----------------------------------------------------
  ## * Tab Layout ----------------------------------------------------------
  tabsetPanel(
    id = "main_tabs",
    type = "tabs",

    ## ___________________ -----------------------------------------------------
    ### * * Tab 1: Overview --------------------------------------------

    tabPanel(
      "Overview",

      # Insert some space at the top
      br(),
      div(style = "height: 5px;"),


      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right


          #### * * * Section 1: Welcome ----
          h2(id = "section1", "Welcome!"),

          ##### * * * * Row: intro text ----
          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              status = "primary",
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("Welcome to my analysis of alternative splicing in developing brains under the stress of pre-eclampsia.
                This analysis is based on the RNA sequencing data published by Xueyuan Liu, Wenlong Zhao, and their colleagues from the lab of
                <a href='https://sites.rutgers.edu/shuo-xiao/'>Shuo Xiao at Rutgers University</a>.
                The data was deposited under the accession number
                <a href='https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE167193'>GSE167193</a>  on NCBI's GEO platform, and the lab already has a
              <a href='	https://www.life-science-alliance.org/content/6/8/e202301957'>publication</a> that analyzes gene expression based on this data.
       <br><br>If you are here for the first time, read on to find out more about the project, including what alternative splicing is and how it is tied to prenatal brain development.
       <br><br>If you prefer to jump right into the results, use the tabs above to explore specific analyses."
                ))
              )
            ),
            column(
              width = 4,
              status = "primary",
              div(class = "image-container",
                  img(src = "welcome_image.jpg", alt = "Welcome Image")
              )
            )
          ),

          # Insert some space at the top
          br(),
          div(style = "height: 5px;"),

          #### * * * Section 2: Rationale ----
          h2(id = "section2", "Why this analysis?"),
          p(HTML("As an internship project, I wanted to perform an analysis that would both expand my skills in NGS data analysis and visualization <b><i>and</i></b> provide something potentially useful for our understanding of how our bodies work.
                 I therefore searched for clinically relevant, cerebral cortex development-related RNA-seq datasets with attached publication.My research background is in prenatal brain development, so I kept an extra eye out for data related to this realm, because I knew that I'd be able to interpret the results better and check them for plausibility.
                 <br><br>
                 I selected only datasets uploaded last year and whose publications don't do highly in-depth analyses, as I believe that me working on this data will bring the biggest contribution to expanding our knowledge horizon. As to why I selected datasets that were associated with a publication: this was for me to be able to cross-check the results of my analyses and make sure I am performing my analysis properly.")),


          # Insert some space at the top
          br(),
          div(style = "height: 20px;"),


          #### * * * Section 3: Background --------------------------------------------
          h2(id = "section3", "Biological Background"),

          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("The study I chose analyzed a potential connection between a pregnancy disorder known as pre-eclampsia and autism spectrum disorders. Pre-eclampsia is a common and dangerous increase in maternal blood pressure that can occur after the 20th week of pregnancy. One in 20 pregnant people are affected by pre-eclampsia, which has a severe negative impact on both the pregnant person and the fetus. There is no treatment known to date, except for the delivery of the placenta, and very little is known about the long-term consequences on the development of the child's brain.
          <br><br>
          The authors used a pre-eclampsia mouse model in which the disorder was induced in pregnant mice by treating them with a compound called L-NAME. The mouse offspring from mothers that were exposed to L-NAME behaved in ways reminiscent of ASD and scored accordingly on several behavioral tests that are thought to assess metrics related to the condition.
          <br><br>
          For insights into what happens in the cerebral cortices of these mice before birth, the authors collected embryos from treated or control mother animals."
                ))
              )
            ),
            column(
              width = 4,
              #h3(HTML("Paired reads available for STAR alignment"), style = "text-align: center;"),
              status = "primary",
              img(src = "2024-09-29-experiment_setup.png", style = "max-width: 100%; max-height: 350px; height: auto; display: block; margin: 0 auto;")
            )
          ),

          # Insert some space at the top
          br(),
          div(style = "height: 20px;"),


          #### * * * Section 4: original experiment --------------------------------------------
          h2(id = "section4", "The experiment from the original publication"),
          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("To better understand the relationship between the two conditions, the authors sequenced RNAs extracted from the cortices of mouse embryos at day E 17.5, two days before birth, from mother animals that had or did not have elevated blood pressure, and similarly from the hippocampi of adult offspring. The authors generated cDNA libraries from the cortical RNAs of control and experimental condition embryonic cortices using a kit for stranded mRNA detection. This means that the kit enriches for poly-A-tailed mRNAs and also captures information regarding which genomic DNA strand the mRNAs were transcribed from."))
              )
            ),
            column(
              width = 4,
              #h3(HTML("Paired reads available for STAR alignment"), style = "text-align: center;"),
              status = "primary",
              img(src = "2024-09-29-embryo_processing.png", style = "max-width: 100%; max-height: 350px; height: auto; display: block; margin: 0 auto;")
            )
          ),

          # Insert some space at the top
          br(),
          div(style = "height: 20px;"),


          #### * * * Section 5: analyses I added --------------------------------------------
          h2(id = "section5", "Analyses I added"),

          ##### * * * * Row: AS biologically ----
          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("The original study focused on gene expression and identified around 250 genes that are differentially expressed under the prenatal stress of pre-eclampsia. I chose to re-analyze the data using a different suite of alignment, mapping, and expression analysis tools (STAR, Salmon, and DESeq).
                       <br><br>Additionally, I wanted to focus on better understanding alternative pre-mRNA splicing. Alternative splicing is a post-transcriptional regulatory mechanism that can lead to the production of different mRNA (transcript) variants from the singular pre-mRNA a gene will produce. This often happens because certain parts of the pre-mRNA, called exons, can be left out in the process of creating the final, mature mRNA.
                       <br><br>In the example on the right, by including or skipping a set of the two purple exons at the expense of the three green ones, one pre-mRNA can be turned into either a longer transcript variant (1) or a shorter one (2). In turn, this can, for instance, produce proteins with different intracellular signaling domains, which function differently."
                ))
              )
            ),
            column(
              width = 4,
              #h3(HTML("Paired reads available for STAR alignment"), style = "text-align: center;"),
              status = "primary",
              img(src = "2024-09-29-AS.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;")
            )
          ),

          # Insert some space at the top
          br(),
          div(style = "height: 20px;"),


          ##### * * * * Row: AS outcome ----
          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("The process of alternative splicing is highly responsive to changes in the organism's or cell's environment. Such external factors often result in a modified relative abundance of certain transcripts produced from the same gene, meaning that, from the total pool of transcripts a gene will produce, a larger or smaller percentage will be represented by one transcript or the other. On the right, you can see how this could look like for the example transcripts produced from the alternative splicing event we looked at above.
                       <br><br>
                       I reasoned that the high blood pressure and malformations of the placenta are external factors that could have an impact not just on gene expression, but also on alternative splicing. This is why I chose to start this analysis."
                ))
              )
            ),
            column(
              width = 4,
              #h3(HTML("Paired reads available for STAR alignment"), style = "text-align: center;"),
              status = "primary",
              img(src = "2024-09-29-AS_outcome.png", style = "max-width: 100%; max-height: 350px; height: auto; display: block; margin: 0 auto;")
            )
          ),


          # Insert some space at the top
          br(),
          div(style = "height: 20px;"),


          #### * * * Section 6: Tools I used --------------------------------------------
          h2(id = "section6", "Tools I used"),

          ##### * * * * Row: Tools text----
          fluidRow(
            div(
              style = "height: 100%; display: flex; align-items: center; justify-content: center;",
              p(HTML("I started processing the files of the experiment from NCBI as SRA archives using
                       <a href='https://github.com/ncbi/sra-tools/'>the sratoolkit suite</a> from NCBI.
                       <br><br>In a second step, I used the workflow management software Nextflow to deploy the <a href='https://nf-co.re/rnasplice/1.0.4/'>rnasplice</a> pipeline under Linux (I work on an Ubuntu 22.04 virtual machine, made with VMware Workstation Pro 17 on a Windows 10 host). The rnasplice pipeline encompasses the majority of the steps that are critical for performing an alternative splicing analysis, including using several tools for detecting alternative splicing events."
              ))
            )
          ),

          ##### * * * * Row: Nextflow pipeline----
          fluidRow(
            div(
              style = "height: 100%; display: flex; align-items: center; justify-content: center;",
              img(src = "https://raw.githubusercontent.com/nf-core/rnasplice/1.0.4/docs/rnasplice_map.png", style = "max-width: 100%; max-height: 350px; height: auto; display: block; margin: 0 auto;")
            )
          ),

          ##### * * * * Row: post-processing ----
          fluidRow(
            div(
              style = "height: 100%; display: flex; align-items: center; justify-content: center;",
              p(HTML("I processed the results of the pipeline using R in RStudio. For the gene expression analysis, I used the files output by the pipeline in DESeq2. After obtaining all of the results, I assembled them into this app using Shiny."
              ))
            )
          ),
        ),

        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section1", "Welcome!")),
            tags$li(tags$a(href = "#section2", "Why this analysis?")),
            tags$li(tags$a(href = "#section3", "Background")),
            tags$li(tags$a(href = "#section4", "The experiment from the original publication")),
            tags$li(tags$a(href = "#section5", "Analyses I added")),
            tags$li(tags$a(href = "#section6", "Tools I used"))
          )
        )
      )
    ),


    ## ___________________ -----------------------------------------------------
    ### * * Tab 2: Geneneral Stats for the dataset --------------------------------------------

    ## ___________________ -----------------------------------------------------
    ### * * Tab 2: General Stats for the dataset --------------------------------------------

    tabPanel(
      "General statistics and QC",

      # Insert some space at the top
      br(),
      div(style = "height: 5px;"),

      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right

          #### * * * Section 11: Initial read counts ----
          h2(id = "section11", "Initial read counts"),

          ##### * * * * Row: read counts after trimming -----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("I downloaded the datasets directly from the entry of this study on GEO in SRA/SRR format and extracted the FastQ files from them using the sratoolkit from NCBI.
                       <br><br>
                       The SRR archives I downloaded from NCBI GEO all contained around 20 million reads for each of the samples. After trimming the reads where needed using Cutadapt in the rnasplice pipeline, only the biological replicate 4 from the control/untreated cortices had 19.3 million reads available for pairing. Every other sample retained over 20 million reads that were available for alignment with STAR."
                ))
              )
            ),
            column(
              width = 6,
              h3(HTML("Paired reads available for STAR alignment"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "paired_read_counts_plot.html", style = "height: 400px; width: 90%;")
            )
          ),

          #### * * * Section 12: Read usage in pipeline --------------------------------------------
          h2(id = "section12", "Read usage in pipeline"),
          p("The read pairs that were available after the trimming were then subsequently aligned by STAR, and the aligned reads were then mapped by Salmon to known transcripts. In the following plots, you can see how the reads of each sample were used in the pipeline. Overall, around 75% of each sample's reads were identified by Salmon as belonging to a particular transcript."),

          ##### * * * * Row: read usage in Controls ----
          fluidRow(
            column(
              width = 3,
              h3(HTML("Control cortices, replicate 1"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "CONTROL_REP1_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Control cortices, replicate 2"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "CONTROL_REP2_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Control cortices, replicate 3"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "CONTROL_REP3_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Control cortices, replicate 4"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "CONTROL_REP4_alluvial.html", style = "height: 400px; width: 100%;")
            )
          ),

          # Insert some space between rows
          br(),
          div(style = "height: 5px;"),

          ##### * * * * Row: read usage in Pre-eclampsia samples ----
          fluidRow(
            column(
              width = 3,
              h3(HTML("Pre-eclampsia cortices, replicate 1"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "PREECLAMPSIA_REP1_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Pre-eclampsia cortices, replicate 2"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "PREECLAMPSIA_REP2_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Pre-eclampsia cortices, replicate 3"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "PREECLAMPSIA_REP3_alluvial.html", style = "height: 400px; width: 100%;")
            ),

            column(
              width = 3,
              h3(HTML("Pre-eclampsia cortices, replicate 4"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "PREECLAMPSIA_REP4_alluvial.html", style = "height: 400px; width: 100%;")
            )
          ),

          #### * * * Section 13: Coverage --------------------------------------------
          h2(id = "section13", "Coverage"),
          p("I wanted to understand whether the numbers of reads that Salmon mapped are sufficient to have a coverage of the transcriptome that suffices for alternative splicing analysis. The coverage is calculated as:"),

          ##### * * * * Row: coverage ----
          fluidRow(

           # MathJax equation for coverage
            withMathJax(
              p("$$\\text{Coverage} = \\frac{\\text{Total Bases Sequenced}}{\\text{Transcriptome Size}}$$")
            ),

            # Dynamic calculation output in MathJax
            withMathJax(
              p("For 14.1 to 15.8 million reads mapped to the mouse transcriptome by Salmon (read length = 150 bp, paired-end reads):"),
              uiOutput("coverage_formula")
            )
          ),

          p("This confirmed that I had a high enough coverage to perform an alternative splicing analysis.")
        ),

        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section11", "Initial read counts")),
            tags$li(tags$a(href = "#section12", "Read usage in pipeline")),
            tags$li(tags$a(href = "#section13", "Coverage"))
          )
        )
      )
    ),


    ## ___________________ -----------------------------------------------------
    ### * * Tab 3: Gene- and Transcript-Level Analysis --------------------------------------------
    tabPanel(
      "Gene- and Transcript-Level Analysis", # name of the tab (must be same in server logic below)

      # Insert some space after title bar
      br(),
      div(style = "height: 5px;"),

      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right


          #### * * * Section 21: explanations --------------------------------------------
          ##### * * * * Row: explanation box ----
          h2(id = "section21", "How I performed the analysis"),
          p(HTML("To find genes that were up- or downregulated in the pre-eclampsia cortices, I performed an analysis of the quant.sf files output by Salmon using DESeq2. For the more granular transcript expression analysis, I used the data output by the pipeline for differential transcript usage analysis with DEXSeq2 (DEXSeq2 DTU).
          <br><br>
          I chose to investigate transcript expression in addition to gene expression, because, even if the overall expression level of a gene does not change when considering it as a sum of the levels of all transcripts it generates, one thing can still change: the relative abundance of its transcripts to one another. This can be a first indication of post-transcriptional regulatory mechanisms, such as alternative splicing or alternative promoter usage. I therefore analyzed gene expression differences with DESeq2 and transcript abundance differences with DEXSeq DTU.
                 ")),


          #### * * * Section 22: QC --------------------------------------------
          h2(id = "section22", "Data quality checks"),
          p(HTML("The first checks for the dataset are very basic: I ensured that the samples had comparable numbers of reads that were mapped to genes, and I checked how the distribution of read counts look like across all of the genes detected in each sample.
                 <br><br>")),

          ##### * * * * Row: mapped read counts and distr per gene ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Total read counts in DESeq2 object"), style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_DESeq2_total_counts"),
              #tags$iframe(src = "DESeq2_total_raw_counts.html"), #, style = "height: 1000px; width: 90%;"
              p("These are the reads that the DESeq2 object used for generating the analyses. They correspond to the total number of reads mapped by Salmon (see the General stats and QC tab")
            ),
            column(
              width = 6,
              h3(HTML("DESeq2 read count per gene"), style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_DESeq2_countsgene"),
              p("Here, you can see how many reads DESeq2 found per gene. As expected, most genes have a fairly low read count, even zero. Some very few genes are extremely highly expressed, and the ones in this category are biologically relevant. For example, Tubb and MAP genes are typically neuronal microtubule proteins, and well-known to be highly abundant.")
            )
          ),


          # Insert some space between rows
          br(),
          div(style = "height: 50px;"),

          ##### * * * * Row: valid FDR and FDR distribution plot ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Valid and invalid FDRs in DESeq2 result"), style = "text-align: center;"),
              status = "primary",
              img(src = "valid_padjGene_afterDESeq2_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"),
              p("The data from DESeq contained a number of cases in which DESeq could not calculate a FDR for particular genes. This can have a variety of causes, mainly low expression, but the number of affected genes was fairly low. These genes are simply not displayed in the DESeq2 gene-level volcano plot in the next section.")
            ),
            column(
              width = 6,
              h3(HTML("Distribution of FDR values (DESeq2)"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"),
              tags$iframe(src = "DESeq2_padj_plot.html", style = "height: 400px; width: 90%;"),
              p("The distribution of adjusted p-values/FDRs in the DESeq2 data. Interestingly, many genes had a very low FDR, with around one in five being significant. However, not all of these genes also had a strong enough up- or downregulation in the pre-eclampsia cortices to be considered biologically relevant.")
            )
          ),

          # Insert some space between rows
          br(),
          div(style = "height: 50px;"),

          ##### * * * * Row: DEXSeq DTU QC ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("<br><br><br><br><br><br><br><br><br>
                The data from DEXSeq DTU did, surprisingly, not contain any undefined (NA) nominal p values, FDR values, or log2 fold change values. You can inspect the distribution of the FDR values in the plot to the right. "))
              )
            ),
            column(
              width = 6,
              h3(HTML("Distribution of FDR values (DEXSeq DTU)"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"),
              tags$iframe(src = "DEXSeq_DTU_padj_plot.html", style = "height: 400px; width: 90%;"),
              p("The distribution of adjusted p-values/FDRs in the DEXSeq2 data is multi-modal and seems to not follow a clear distribution like that of the DESeq2 data. However, in this case, most of the detected transcripts do not have a significant FDR.")
            )
          ),


          #### * * * Section 23: gene and transcript analysis results --------------------------------------------
          h2(id = "section23", "Gene and transcript expression changes"),
          p(HTML("Results of the analyses. Data points are color-coded for significance and direction of the expression change. Only points with a significant FDR are colored as dark red (decreased expression) or light blue (increased expression).
        <br><br>

        Hover above data points to see what gene or transcript they represent. Double click on the legend components to show expression+significance categories in isolation. Click and drag to zoom to particular points. Double click to exit zoom.")),

          # Insert some space before columns
          br(),
          div(style = "height: 5px;"),

          ##### * * * * Row: DESeq2 and DEXSeq volcano plots ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Gene expression levels (DESeq2)"), style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_DESeq2", height = "600px", width = "100%"),
              #tags$iframe(src = "Gene_raw_volcano_overlap_labels2.html", style = "height: 400px; width: 90%;"),
              p("The data points with dark centers are part of the ~250 genes indicated by the authors of the original study to be significantly deregulated in the pre-eclampsia cortices. Genes that are specifically labeled with the persistent name and arrow are those whose deregulation they validated experimentally. Interestingly, two of the most interesting candidates from the publication, the GABA receptor units Grin2a and Grin2b were not detected as significantly changed by DESeq2 on the basis of the STAR alignment and Salmon mapping that I performed with the rnasplice pipeline. The authors of the study had used a different alignment and mapping toolkit and a tool called EBSeq for differential gene expression analysis, not DESeq2.")
            ),
            column(
              width = 6,
              h3(HTML("Transcript expression levels (DEXSeq DTU)"),  style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_DEXSeq_DTU", height = "600px", width = "100%"),
              p("XYZ")

            )
          )
        ),

        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section21", "How I performed the analysis")),
            tags$li(tags$a(href = "#section22", "Data quality checks")),
            tags$li(tags$a(href = "#section23", "Gene and transcript expression changes"))
          )
        )
      )
    ),



    ## ___________________ -----------------------------------------------------
    ### * * Tab 4: Exon-Level Analysis --------------------------------------------

    tabPanel(
      "Exon-Level Analysis",
      #
      # Insert some space after title
      br(),
      div(style = "height: 5px;"),
      #

      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right


          #### * * * Section 31: explanations --------------------------------------------
          ##### * * * * Row: explanation box ----
          h2(id = "section31", "How I performed the analysis"),
          p(HTML("For the differential splicing analysis, I focused on the splicing of exons, as all four of the bioinformatic tools employed in the pipeline analyzed this type of splicing event. The tools the pipeline used were SUPPA, edgeR, rMATS, and DEXSeq DEU (differential exon usage, a different mode of the tool I also used for differential transcript usage analysis).")),

          #### * * * Section 32: QC --------------------------------------------
          ##### * * * * Row: explanation box ----
          h2(id = "section32", "Data quality checks"),
          p(HTML("XYZ")),

          ##### * * * * Row: DEXSeq DEU QC ----
          fluidRow(
            class = "custom-row",
            column(
              width = 4,
              h3(HTML("Valid log2FC values DEXSEQ DEU"), style = "text-align: center;"),
              status = "primary",
              img(src = "valid_log2fold_afterDEXSeqDEU_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"), #, style = "height: 1000px; width: 90%;"
              p("XYZ")
            ),
            column(
              width = 4,
              h3(HTML("Valid FDR values DEXSeq DEU"), style = "text-align: center;"),
              status = "primary",
              img(src = "valid_padjExon_afterDEXSeqDEU_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"), #, style = "height: 1000px; width: 90%;"
              p("XYZ")
            ),
            column(
              width = 4,
              h3(HTML("Distribution of FDR values (DEXSeq DEU)"), style = "text-align: center;"),
              status = "primary",
              tags$iframe(src = "DEXSeq_DEU_padj_plot.html", style = "height: 400px; width: 90%;"),
              p("XYZ")
            )
          ),


          # Insert some space between rows
          br(),
          div(style = "height: 50px;"),

          ##### * * * * Row: SUPPA QC ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("<br><br><br><br><br><br><br><br><br>
                The data from SUPPA did not contain any undefined (NA) nominal p values, FDR values, or log2 fold change values. You can inspect the distribution of the FDR values in the plot to the right. The distribution of adjusted p-values/FDRs in the SUPPA data seems to have a cutoff at 0.46, with 278 exons being under the significance threshold."))
              )
            ),
            column(
              width = 6,
              h3(HTML("Distribution of FDR values (SUPPA)"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"),
              tags$iframe(src = "SUPPA_SE_padj_plot.html", style = "height: 400px; width: 90%;")
            )
          ),

          # Insert some space between rows
          br(),
          div(style = "height: 50px;"),

          ##### * * * * Row: rMATS QC ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Valid FDR values rMATS"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"), "valid_padjExon_rMATS_plot.png"
              #tags$iframe(src = "DEXSeq_DTU_padj_plot.html", style = "height: 400px; width: 90%;"),
              img(src = "valid_padjExon_rMATS_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"),
              p("XYZ.")
            ),

            column(
              width = 6,
              h3(HTML("Distribution of FDR values (rMATS)"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"), "valid_padjExon_rMATS_plot.png"
              tags$iframe(src = "rMATS_SE_FDR_plot_density.html", style = "height: 400px; width: 90%;"),
              #img(src = "valid_padjExon_rMATS_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"),
              p("XYZ.")
            )
          ),

          # Insert some space between rows
          br(),
          div(style = "height: 50px;"),

          ##### * * * * Row: edgeR QC ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("<br><br><br><br><br><br><br><br><br>
                The data from edgeR did not contain any undefined (NA) nominal p values, FDR values, or log2 fold change values. You can inspect the distribution of the FDR values in the plot to the right. In comparison to the other tools, the edgeR data contained many exons that were significantly changed. However, as visible in the volcano plot below, the changes for the vast majority of them were of a magnitude that is likely not biologically relevant."))
              )
            ),
            column(
              width = 6,
              h3(HTML("Distribution of FDR values (edgeR)"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"),
              tags$iframe(src = "edgeR_SE_FDR_plot_density.html", style = "height: 400px; width: 90%;")
            )
          ),

          #### * * * Section 33: individual tool results --------------------------------------------
          ##### * * * * Row: explanation box ----
          h2(id = "section33", "Differentially spliced exons from individual tools"),
          p(HTML("XYZ")),

          ##### * * * * Row: DEXSeq and SUPPA plots ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Exons from DEXSeq DEU analysis"), style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_DEXSeq_DEU", height = "600px", width = "100%"),
              p("XYZ")
            ),
            column(
              width = 6,
              h3(HTML("Exons from SUPPA analysis"),  style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_SUPPA", height = "600px", width = "100%"),
              p("XYZ")

            )
          ),

          ##### * * * * Row: rMATS and edgeR plots ----
          fluidRow(
            class = "custom-row",
            column(
              width = 6,
              h3(HTML("Exons from rMATS analysis"), style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_rMATS", height = "600px", width = "100%"),
              p("XYZ")
            ),
            column(
              width = 6,
              h3(HTML("Exons from edgeR analysis"),  style = "text-align: center;"),
              status = "primary",
              plotlyOutput("plot_edgeR", height = "600px", width = "100%"),
              p("XYZ")

            )
          ),

          ##### * * * * Row: interpretations box ----
          p(HTML("XYZ")),

          #### * * * Section 34: Overlap of exon results --------------------------------------------
          ##### * * * * Row: explanation box ----
          h2(id = "section34", "Overlap of exon results"),
          p(HTML("XYZ")),

          ##### * * * * Row: UpSet plot and gene name table ----
          fluidRow(
            class = "custom-row",
            column(
              width = 5,
              h3(HTML("Overlap between significantly changed exons from the four tools"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"), "valid_padjExon_rMATS_plot.png"
              #tags$iframe(src = "DEXSeq_DTU_padj_plot.html", style = "height: 400px; width: 90%;"),
              img(src = "2023-09-26_UpSet_plot_genes_w_sig_exons.png", style = "max-width: 100%; max-height: 600px; height: auto; display: block; margin: 0 auto;"),
              p("XYZ.")
            ),

            column(
              width = 7,
              h3(HTML("Genes found to have significantly changed exons by more than one tool"), style = "text-align: center;"),
              status = "primary",
              #plotlyOutput("plot_DESeq2_countsgene"), "valid_padjExon_rMATS_plot.png"
              tags$iframe(src = "overlap_flextable.html", style = "height: 600px; width: 90%;"),
              #img(src = "valid_padjExon_rMATS_plot.png", style = "max-width: 100%; max-height: 400px; height: auto; display: block; margin: 0 auto;"),
              p("XYZ.")
            )
          ),


          ##### * * * * Row: interpretations box ----
          p(HTML("XYZ")),
        ),


        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section31", "How I performed the analysis")),
            tags$li(tags$a(href = "#section32", "Data quality checks")),
            tags$li(tags$a(href = "#section33", "Differentially spliced exons from individual tools")),
            tags$li(tags$a(href = "#section34", "Overlap of exon results"))
          )
        )
      )
    ),



    ## ___________________ -----------------------------------------------------
    ### * * Tab 5: Sources --------------------------------------------

    tabPanel(
      "Sources",

      # Insert some space at the top
      br(),
      div(style = "height: 5px;"),


      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right


          #### * * * Section 51: Publications ----
          h2(id = "section51", "Publications"),
          p(HTML("XYZ")),

          #### * * * Section 52: Software --------------------------------------------
          h2(id = "section52", "Software"),
          p("XYZ"),

          #### * * * Section 52: Other --------------------------------------------
          h2(id = "section52", "Other"),
          p("XYZ")
        ),

        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section51", "Publications")),
            tags$li(tags$a(href = "#section52", "Software")),
            tags$li(tags$a(href = "#section52", "Other"))
          )
        )
      )

    ),

    ## ___________________ -----------------------------------------------------
    ### * * Tab 6: About me --------------------------------------------

    tabPanel(
      "About me",

      # Insert some space at the top
      br(),
      div(style = "height: 5px;"),


      sidebarLayout( # split the tab contents into a main panel and a side panel with the navigation
        mainPanel(
          class = "main-panel",
          width = 10, # Leave space for the navigation panel on the right


          #### * * * Section 61: Who am I? ----
          h2(id = "section61", "Who am I?"),
          ##### * * * * Row: intro text ----
          fluidRow(
            class = "custom-row",
            column(
              width = 8,
              status = "primary",
              div(
                style = "height: 100%; display: flex; align-items: center; justify-content: center;",
                p(HTML("I am Ioana Weber, and I am just now branching into bioinformatics after having done research in brain development and alternative pre-mRNA splicing. This is my first project."
                ))
              )
            ),
            column(
              width = 4,
              status = "primary",
              div(class = "image-container",
                  img(src = "me_square_small.jpg", alt = "Ioana Weber")
              )
            )
          ),

          #### * * * Section 62: Where to find me --------------------------------------------
          h2(id = "section62", "Where to find me"),
          p(HTML("<a href='https://www.linkedin.com/in/ioanaweber'>LinkedIn</a>
                  <br>
                 <a href='https://ioana-weber.info'>Website</a>"))
        ),

        sidebarPanel(
          class = "sidebar",
          width = 2, # Adjust width of the sidebar for navigation
          h4("Navigation"),
          tags$ul(
            tags$li(tags$a(href = "#section51", "Who am I")),
            tags$li(tags$a(href = "#section52", "Where to find me"))
          )
        )
      )
    )
  )
)



# ___________________________________________ -----------------------------------------------------

# Server logic -----------------------------------------------------
server <- function(input, output, session) {


  # ___________________________________________ -----------------------------------------------------

  # ___________________________________________
  # Set server options ----
  options(shiny.timeout = 10000)
  # session$setTimeout(5000 * 60)  # 5 minutes timeout



  # ___________________________________________ -----------------------------------------------------
  # ___________________________________________
  # Import CSV files as tibbles ----
  DESeq2_data <- read_csv("www/DESeq2_non-NA_res.csv")
  DESeq2_total_RC <- read_csv("www/DESeq_total_raw_counts_long.csv")
  DESeq2_raw_nonnorm_counts <- read_csv("www/DESeq_raw_nonnorm_counts_long.csv")
  DEXSeq_DTU_data <- read_csv("www/DEXSeq_DTU_all.csv")
  DEXSeq_DEU_data <- read_csv("www/DEXSeq_DEU_res.csv")
  rMATS_SE_data <- read_csv("www/rMATS_SE_jcec.csv")
  SUPPA_SE_data <- read_csv("www/SUPPA_SE_res.csv")
  edgeR_SE_data <- read_csv("www/edgeR_exon_res.csv")

  # Extract a mini tibble with the data for the differentially expressed genes the authors have validated in the paper
  points_to_label <- DESeq2_data[DESeq2_data$gene %in% c("Grin2a","Grin2b","Ube2c","Celsr1","Kif18","Creb5", "Gli2", "Plk1"), ] # Kif18 not found in my data


  # ___________________ -----------------------------------------------------
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
  # Tab: Overview -----------------------------------------------------

  # ___________________ -----------------------------------------------------
  # Tab: General stats, QC -----------------------------------------------------
  #
  ## * * Coverage calculation formula ----

  # Transcriptome size for mouse (in bases)
  transcriptome_size <- 50 * 10^6 # 50 million bases

  # Define output for coverage formula
  output$coverage_formula <- renderUI({

    # Number of read pairs (in millions) converted to bases sequenced (multiply by 150 bp and by 2 for paired-end)
    min_reads <- 14.1 * 10^6 * 150 * 2
    max_reads <- 15.8 * 10^6 * 150 * 2

    # Calculate coverage for the range
    min_coverage <- min_reads / transcriptome_size
    max_coverage <- max_reads / transcriptome_size

    # Display the formula with the calculated values
    paste0(
      "$$\\text{Coverage} = \\frac{", formatC(min_reads, format = "e", digits = 2), "}{50 \\times 10^6} \\text{ to } \\frac{",
      formatC(max_reads, format = "e", digits = 2), "}{50 \\times 10^6}$$",
      " which results in a coverage range of approximately $$", round(min_coverage, 2), " \\times \\text{ to } ", round(max_coverage, 2), " \\times$$."
    )
  })

  # ___________________ -----------------------------------------------------
  # Tab: Gene and transcript expression ----
  #
  ## * * Plots ----

  ### * * * plot_DESeq2_total_counts ----
  output$plot_DESeq2_total_counts <- renderPlotly(
    {
      plot_ly(
        data = DESeq2_total_RC,
        x = ~Sample,
        y = ~TotalCounts,
        type = 'bar',
        hoverinfo = 'y', # show y value on hover
        textposition = 'none', # make sure no text within bars
        marker = list(color = 'rgba(50, 171, 96, 0.6)', width = 1)
      ) |>
        layout(
          #title = "Total Raw Counts per Sample",
          xaxis = list(title = "Sample"),
          yaxis = list(title = "Total Counts")
        )
    })

  ### * * * plot_DESeq2_countsgene ----
  output$plot_DESeq2_countsgene <- renderPlotly(
    {
      plot_ly(
        data = DESeq2_raw_nonnorm_counts,
        x = ~Sample,
        y = ~Counts,
        type = 'violin',
        color = ~Sample,
        box = list(visible = TRUE),  # optional boxplot inside the violin plot
        meanline = list(visible = TRUE),  # optional line for the mean
        #points = "all",  # Show all data points
        #jitter = 0.3,  # if showing all data points, add some jitter to points for better visibility
        bandwidth = 125, #...or else KDE is calculated in a way that makes values around 300 counts plot on 0 on the y axis instead of at their real value (it oversmoothes the curves)
        hoverinfo = 'text',  # Display y-value and additional text on hover
        text = ~paste(Gene, "<br>Count:", Counts),
        showlegend = FALSE
      ) |>
        layout(
          #title = "Distribution of Read Counts per Gene and Sample",
          yaxis = list(title = "Raw Counts",
                       range = c(0, NA))

        )
    })


  ### * * * Gene-level DESeq2 volcano plot ----
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
          color = I("black"), # I = collapse the mapping of all points onto one single color, which also ensure there's only one legend entry for this property, not 3 (there doesn't seem to be any easy way to prevent this second trace from inheriting the mapping to upregulated, downregulated, not significant from the first trace)
          hoveron = "fills", # useful so that the annotations are taken from the trace underneath and the labels then have the color of the large points (red, gray, or blue)
          showlegend = TRUE,
          name = "DEG identified in published data"
        ) |>
        layout(
          title = list(text = paste(nrow(DESeq2_data), " points plotted", sep = ""), x = 0.5),
          xaxis = list(title = "Log2(Fold Change Preeclampsia vs Control)"),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of gene)"),
          legend = list(title = list(text = "Regulation and Dataset"),
                        orientation = 'v',
                        y = -0.5, x = 0.5,
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

  ### * * * Transcript-level DEXSeq DTU plot ----
  output$plot_DEXSeq_DTU <- renderPlotly(
    {
      plot_ly(data = DEXSeq_DTU_data,
              x = ~log2fold_CONTROL_PREECLAMPSIA,
              y = ~minuslog10padj,
              type = 'scatter',
              mode = 'markers',
              marker = list(size = 6,
                            opacity = 0.4),
              color = ~regulation,
              colors = c( "lightgray","darkred","skyblue3"),
              hoverinfo = 'text',
              text = ~paste("Transcript:", featureID,
                            "<br>FDR:", formatC(padj, format = "e", digits = 3),
                            "<br>Source gene:", groupID,
                            "<br>Source gene Q val:", formatC(Q_value, format = "e", digits = 3)
              ),
              showlegend = TRUE
      ) |>
        add_trace(
          data = DEXSeq_DTU_data |> filter(significance_perGeneQValue == "significant Q value"),
          x = ~log2fold_CONTROL_PREECLAMPSIA,
          y = ~minuslog10padj,
          type = 'scatter',
          mode = 'markers',
          marker = list(size = 2, opacity = 0.5),
          color = I("black"), # I = collapse the mapping of all points onto one single color, which also ensures there's only one legend entry for this property, not 3 (there doesn't seem to be any easy way to prevent this second trace from inheriting the mapping to upregulated, downregulated, not significant from the first trace)
          hoveron = "fills", # useful so that the annotations are taken from the trace underneath and the labels then have the color of the large points (red, gray, or blue)
          showlegend = TRUE,
          name = "from gene with significant Q value"
        ) |>
        layout(
          title = list(text = paste(nrow(DEXSeq_DTU_data), " points plotted", sep = ""), x = 0.5),
          # annotations = list(
          #   font = list(size = 14),  # Title font size
          #   x = 0.5,
          #   y = 1.08, # Position of the title (above the plot)
          #   xref = "paper",  # Position relative to the entire plot
          #   yref = "paper",
          #   showarrow = FALSE
          # ),
          xaxis = list(title = list(text = "Log2(Fold Change Preeclampsia vs Control)"),
                       standoff = 1),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of transcript)"),
          legend = list(title = list(text = "Regulation and Significance"),
                        orientation = 'v',
                        y = -0.5, x = 0.5,
                        xanchor = 'center')
        )
    }
  )



  # ___________________ -----------------------------------------------------
  # # Tab: Exon-Level ----
  #
  ## * * Plots ----
  ### * * * DEXSeq DEU plot ----
  output$plot_DEXSeq_DEU <- renderPlotly(
    {plot_ly(data = DEXSeq_DEU_data,
             x = ~log2fold_CONTROL_PREECLAMPSIA,
             y = ~`-log10padj`,
             type = 'scatter',
             mode = 'markers',
             marker = list(size = 6,
                           opacity = 0.4),
             color = ~regulation,
             colors = c( "darkred","lightgray","skyblue3"),
             hoverinfo = 'text',
             text = ~paste("Source gene:", groupID,
                           "<br>Exon:", featureID,
                           "<br>FDR:", formatC(padj, format = "e", digits = 3),
                           "<br>Source gene Q val:", formatC(Q_value, format = "e", digits = 3)
             ),
             showlegend = TRUE
    ) |>
        layout(
          annotations = list(
            text = paste(nrow(DEXSeq_DEU_data), " points plotted", sep = ""),
            font = list(size = 14),  # Title font size
            x = 0.5,
            y = 1.05, # Position of the title (above the plot)
            xref = "paper",  # Position relative to the entire plot
            yref = "paper",
            showarrow = FALSE
          ),
          xaxis = list(title = list(text = "Log2(Fold Change Preeclampsia vs Control)",
                                    standoff = 1)
          ),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of exon)"),
          legend = list(title = list(text = "Regulation and Significance"),
                        orientation = 'h',
                        y = -0.15, x = 0.5,
                        xanchor = 'center')
        )
    }
  )


  ### * * * SUPPA plot ----
  output$plot_SUPPA <- renderPlotly(
    {
      plot_ly(data = SUPPA_SE_data,
              x = ~`dPSI_PE-Ctrl`*100,  #*100 to really be able to talk about percentages
              y = ~`-log10(p-adj PE-Ctrl)`,
              type = 'scatter',
              mode = 'markers',
              marker = list(size = 6,
                            opacity = 0.4),
              color = ~regulation,
              colors = c( "darkred","lightgray","skyblue3"),
              hoverinfo = 'text',
              text = ~paste("Source gene:", Gene,
                            "<br>Chromosome:", Chromosome,
                            "<br>Strand:", Strand,
                            "<br>Exon coordinates:", Coordinates,
                            "<br>dPSI:", round(`dPSI_PE-Ctrl`*100, digits =2), "%",
                            "<br>Adj. p-val:", formatP(`p-val_PE-Ctrl`, ndigits = 3)
              ),
              showlegend = TRUE
      ) |>
        layout(
          annotations = list(
            text = paste(nrow(SUPPA_SE_data), " points plotted", sep = ""),
            font = list(size = 14),  # Title font size
            x = 0.5,
            y = 1.05, # Position of the title (above the plot)
            xref = "paper",  # Position relative to the entire plot
            yref = "paper",
            showarrow = FALSE
          ),
          xaxis = list(title = list(text = "\u0394PSI (PSI in Preeclampsia - PSI in Control)",
                                    standoff = 1)
          ),
          yaxis = list(title = "-Log10(Adjusted P-Value of event)"),
          legend = list(title = list(text = "Regulation and Significance"),
                        orientation = 'h',
                        y = -0.15, x = 0.5,
                        xanchor = 'center')
        )
    }
  )

  ### * * * rMATS plot ----
  output$plot_rMATS <- renderPlotly(
    {
      plot_ly(data = rMATS_SE_data,
              x = ~IncLevelDifference*100,  #*100 to really be able to talk about percentages
              y = ~minuslog10FDR,
              type = 'scatter',
              mode = 'markers',
              marker = list(size = 6,
                            opacity = 0.4),
              color = ~regulation,
              colors = c( "darkred","lightgray","skyblue3"),
              hoverinfo = 'text',
              text = ~paste("Source gene:", geneSymbol,
                            "<br>Chromosome:", chr,
                            "<br>Strand:", strand,
                            "<br>Exon start:", exonStart_0base,
                            "<br>Exon end:", exonEnd,
                            "<br>dPSI:", IncLevelDifference,
                            "<br>FDR:", formatC(FDR, format = "e", digits = 3)
              ),
              showlegend = TRUE
      ) |>
        layout(
          annotations = list(
            text = paste(nrow(rMATS_SE_data), " points plotted", sep = ""),
            font = list(size = 14),  # Title font size
            x = 0.5,
            y = 1.05, # Position of the title (above the plot)
            xref = "paper",  # Position relative to the entire plot
            yref = "paper",
            showarrow = FALSE
          ),
          xaxis = list(title = list(text = "\u0394PSI (PSI in Preeclampsia - PSI in Control)",
                                    standoff = 1)
          ),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of event)"),
          legend = list(title = list(text = "Regulation and Significance"),
                        orientation = 'h',
                        y = -0.15, x = 0.5,
                        xanchor = 'center')
        )
    }
  )

  ### * * * edgeR plot ----
  output$plot_edgeR <- renderPlotly(
    {
      plot_ly(data = edgeR_SE_data,
              x = ~logFC,
              y = ~`-log10FDR`,
              type = 'scatter',
              mode = 'markers',
              marker = list(size = 6,
                            opacity = 0.5),
              color = ~regulation,
              colors = c( "darkred","lightgray","skyblue3"),
              hoverinfo = 'text',
              text = ~paste("Source gene:", Geneid,
                            "<br>Chromosome:", Chr,
                            "<br>Strand:", Strand,
                            "<br>Exon start:", Start,
                            "<br>Exon end:", End,
                            "<br>Exon length:", End-Start+1,
                            "<br>log2(fold change):", round(logFC, digits = 3),
                            "<br>FDR:", formatC(FDR, format = "e", digits = 3),
                            "<br>Exon F statistic:", round(exon.F, digits = 3)
              ),
              showlegend = TRUE
      ) |>
        layout(
          annotations = list(
            text = paste(nrow(edgeR_SE_data), " points plotted", sep = ""),
            font = list(size = 14),  # Title font size
            x = 0.5,
            y = 1.05, # Position of the title (above the plot)
            xref = "paper",  # Position relative to the entire plot
            yref = "paper",
            showarrow = FALSE
          ),
          xaxis = list(title = list(text = "log2(Fold Change in Preeclampsia vs Control)",
                                    standoff = 1)
          ),
          yaxis = list(title = "-Log10(Adjusted P-Value (FDR) of event)"),
          legend = list(title = list(text = "Regulation and Significance"),
                        orientation = 'h',
                        y = -0.15, x = 0.5,
                        xanchor = 'center')
        )
    }
  )




}

# Run the application
shinyApp(ui = ui, server = server)
