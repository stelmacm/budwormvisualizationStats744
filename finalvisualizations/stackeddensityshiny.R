library(shiny)
library(ggplot2)
library(plotly)
library(tidyverse)
library(lubridate)
library(RColorBrewer)
library(imputeTS)

#palette
cbPalette <- rev(sequential_hcl(7, 'BurgYl'))
#Name all the stages, provinces, labels and such
stages <- c('L2o', 'L2', 'L3', 'L4', 'L5', 'L6')
prov.names <- c('in', 'qc', 'nb', 'on', 'ip')
prov.labs <- c('N.W.T', 'QC', 
               'N.B', 'ON', 'Lab-Reared')
names(prov.labs) <- c(prov.names)

sims.all.df <-readr::read_csv('https://raw.githubusercontent.com/stelmacm/budwormvisualizationStats744/master/datasets/sd_data.csv')
#Bringing it all together and seperate the data as needed
sadf.tt.lst <- lapply(1:nrow(sims.all.df), function(x) {
  row <- sims.all.df[x,]
  d <- as.character(row$date)
  p <- as.character(row$prov)
  ss <- subset(sims.all.df, date == d & prov == p)
  props <- ss$proportion
  nms <- as.character(ss$stage)
  names(props) <- nms
  row <- c(row, props)
  row <- as.data.frame(row)
  return(row)
})
sadf.tt <- do.call('rbind', sadf.tt.lst)
sadf.tt[,c(stages, 'Pupa')] <- round(sadf.tt[,c(stages, 'Pupa')], 2)
#Factor everything 
names(sadf.tt)[1] <- 'Date'
sadf.tt$Province <- toupper(sadf.tt$prov)
sadf.tt$prov <- factor(sadf.tt$prov, c('nb', 'on', 'qc', 'in'))
sadf.tt$stage <- factor(sadf.tt$stage, levels = c(stages, 'Pupa'))
sadf.tt$Date <- as.Date(sadf.tt$Date)
#Create a user interface where user selects year
ui <- fluidPage(
  titlePanel("Simulated Spruce Budworm Development by Location"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Year:",
                  c("2013","2014","2015","2016","2017","2018")),
      
    ),               
    mainPanel(
      plotlyOutput("stacked")
    ),
  )
)

server <- function(input, output){
  
  #Created the graph
  output$stacked <- renderPlotly({
    g <- ggplot(data=subset(sadf.tt, year == input$year), 
                aes(x=Date, y = proportion, group=stage, fill=stage,
                    lab1 = L2o, lab2 = L2, lab3 = L3, lab4 = L4,
                    lab5 = L5, lab6 = L6, lab7 = Pupa, lab8 = Province)) +
      scale_fill_manual(values = cbPalette) +
      geom_density(position="fill", stat = 'identity', lwd = 0.05) +
      theme_minimal() +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0))) +
      #facet_wrap(~prov, scales = 'free_x', ncol = 1, 
      #           labeller = labeller(prov = prov.labs)) +
      facet_grid(prov~., scales = 'free_x',  
                 labeller = labeller(prov = prov.labs)) +
      labs(y = 'Proportion of Population in Stage', 
           fill = 'Stage', x = 'Date', 
           title = 'Spruce Budworm Development by Location') +
      guides(alpha = FALSE)
    
    ggplotly(g, tooltip = c("Date", "Province", stages, "Pupa")) %>%
      layout(xaxis = list(showspikes = TRUE, spikedash = 'solid', 
                          spikemode = 'across', spikesnap = 'cursor',
                          spikethickness = 1, spikecolor = 'black'),
             hoverlabel = list(font = list(size = 10)))
  })
}

shinyApp(ui, server)
