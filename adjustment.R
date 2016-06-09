# Data obtained with the digitizeR package
# https://github.com/ankitrohatgi/digitizeR

library(ggplot2)
library(lubridate)
library(quantmod)
library(magrittr)

chart1.data <- read.csv("./chart1_data.csv", col.names=c("Year","LoanOutstanding"), stringsAsFactors = FALSE) # Total, billions
chart2.data <- read.csv("./chart2_data.csv", col.names=c("Year","LoanOutstanding"), stringsAsFactors = FALSE) # Per grad, thousands

chart1.data$Year <- chart1.data$Year %>% date_decimal # %>% format("%d-%m-%Y")
chart2.data$Year <- chart2.data$Year %>% date_decimal # %>% format("%d-%m-%Y")

# via http://stackoverflow.com/a/12591311/2668831
# Adjust for inflation:
getSymbols("CPIAUCSL", src='FRED') #Consumer Price Index for All Urban Consumers: All Items
set.seed(1)
p <- xts(chart1.data$LoanOutstanding, chart1.data$Year, by='years')
colnames(p) <- "LoanOutstanding"
avg.cpi <- apply.yearly(CPIAUCSL, mean)
cf <- avg.cpi/as.numeric(avg.cpi['2008']) #using 2008 as the base year
dat <- merge(p, cf, all=FALSE)
dat$adj <- dat[, 1] * dat[, 2]