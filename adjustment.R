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
p$Year <- chart1.data$Year %>% format("%Y")
avg.cpi <- apply.yearly(CPIAUCSL, mean)
cf <- avg.cpi/as.numeric(avg.cpi['2008']) #using 2008 as the base year
cf.df <- data.frame(cf %>% as.data.frame(stringsAsFactors = FALSE) %>% rownames %>% substr(1, 4),
                    cf %>% as.data.frame,
                    row.names = NULL, stringsAsFactors = FALSE)
colnames(cf.df) <- c("Year", "Adj")
p.df <- p %>% as.data.frame

adjustUSD <- function(year, dollars) {
  adj.rate <- cf.df[cf.df$Year == year,'Adj']
  dollars * adj.rate
}

adjusted.usd <- c()
for (row.num in 1:nrow(p.df)) {
  row.loan <- p.df$LoanOutstanding[row.num]
  row.year <- p.df$Year[row.num]
  adjusted.usd <- c(adjusted.usd, adjustUSD(row.year, row.loan))
}

p$Adj <- adjusted.usd

adjusted.df.total <- data.frame(p.df %>% row.names %>% substr(1, 10) %>% ymd,
                          adjusted.usd)
colnames(adjusted.df.total) <- c("Date", "AdjOutstanding")

# aaaand chart 2

q <- xts(chart2.data$LoanOutstanding, chart2.data$Year, by='years')
colnames(q) <- "LoanOutstanding"
q$Year <- chart2.data$Year %>% format("%Y")
q.df <- q %>% as.data.frame

adjusted.usd <- c()
for (row.num in 1:nrow(q.df)) {
  row.loan <- q.df$LoanOutstanding[row.num]
  row.year <- q.df$Year[row.num]
  adjusted.usd <- c(adjusted.usd, adjustUSD(row.year, row.loan))
}

q$Adj <- adjusted.usd

adjusted.df.per.grad <- data.frame(q.df %>% row.names %>% substr(1, 10) %>% ymd,
                          adjusted.usd)
colnames(adjusted.df.per.grad) <- c("Date", "AdjOutstanding")


# Save data

write.csv(adjusted.df.per.grad, "chart1_data_adjusted.csv")
write.csv(adjusted.df.total, "chart2_data_adjusted.csv")