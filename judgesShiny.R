# Shiny app for judges

library(shiny)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput(inputId = "duration",
                  label = "Duration:",
                  choices = c("durationNomToReferral", "durationReferralToHearing","durationHearingToCmteAction",
                              "durationCmteActionToSenateVote","durationTotal"),
                  selected = "durationTotal")
    ),
    mainPanel(
      plotOutput(outputId = "plot")
    )
  )
)

server <- function(input, output) {
  output$plot <- renderPlot({
    ggplot(data = modernJudges, aes_string(x=modernJudges$Nomination.Date, y=input$duration)) +
      geom_point() +
      geom_vline(xintercept = prezChanges)
  })
}

shinyApp(ui = ui, server = server)
