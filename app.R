# Shiny app for judges

library(shiny)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput(inputId = "duration",
                  label = "Duration:",
                  choices = c("durationNomToReferral", "durationReferralToHearing","durationHearingToCmteAction",
                              "durationCmteActionToSenateVote","durationTotal"),
                  selected = "durationTotal"),
      selectInput(inputId = "tableby",
                  label = "Table by:",
                  choices = c("judgesByPrez", "judgesByCourt"),
                  selected = "judgesByPrez")
    ),
    mainPanel(
      plotOutput(outputId = "plot"),
      #dataTableOutput(outputId = "table")
      tableOutput(outputId = "table")
    )
  )
)

server <- function(input, output) {
  output$plot <- renderPlot({
    ggplot(data = modernJudges, aes_string(x=modernJudges$Nomination.Date, y=input$duration)) +
      geom_point() +
      geom_vline(xintercept = prezChanges)
  })
  #output$table <- renderDataTable(ifelse(input$tableby == "judgesByPrez", judgesByPrez, judgesByCourt))
  output$table <- renderTable(ifelse(input$tableby == "judgesByPrez", judgesByPrez, judgesByCourt))
}

shinyApp(ui = ui, server = server)
