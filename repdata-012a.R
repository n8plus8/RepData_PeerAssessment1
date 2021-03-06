# Loading and preprocessing the data
 
# Show any code that is needed to
# Load the data (i.e. read.csv())
# Process/transform the data (if necessary) into a format suitable for your analysis

# setwd("D:/Coursera/repdata-012")
# setwd("C:/Users/n8plus8/Desktop/Coursera/repdata-012")
url <- "https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2Factivity.zip"
destfile <- "./repdata-data-activity.zip"
download.file(url, destfile)
unzip(destfile)

library(dplyr)
library(ggplot2)
library(scales)

rawData <- paste(getwd(),dir(pattern="csv"), sep="/")
amData <- read.csv(rawData, head = TRUE, stringsAsFactors = FALSE)
amData[,2] <- as.Date(amData[,2])
amData$interval <- sprintf("%04d", amData$interval)
amData$interval <- sub("([[:digit:]]{2,2})$", ":\\1",
                       amData$interval)
amData <- tbl_df(amData)


# What is mean total number of steps taken per day?
# For this part of the assignment,
# you can ignore the missing values in the dataset.
# Calculate the total number of steps taken per day

#dplyr chain
daySteps <- na.omit(amData) %>%
        group_by(date) %>%
        summarize(total = sum(steps))
daySteps$date <- as.POSIXct(daySteps$date)

ggplot(daySteps, aes(date,total)) +
        geom_bar(stat="identity", color = "black", fill = "light blue") +
        scale_x_datetime(breaks = date_breaks("1 day"),
                         labels = date_format("%m-%d")) +
        theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
# If you do not understand the difference between a histogram and a barplot,
# research the difference between them. Make a histogram of the total number of
# steps taken each day

# Copy data to clipboard for
# "Histogram Bin-width Optimization"
# http://toyoizumilab.brain.riken.jp/hideaki/res/histogram.html
writeClipboard(as.character(daySteps[,2]))

# Optimal Bin Size: 3021.86
# Optimal Number of Bins: 7

ggplot(daySteps, aes(total)) + geom_histogram(binwidth = 3021.86,
        color = "black", fill = "orange") + xlab("") +
        ggtitle("number of steps taken each day\n(NAs removed)")
        
# Calculate and report the mean and median of the total number of steps taken
# per day

paste("Mean:", round(mean(daySteps$total),2))
paste("Median:", median(daySteps$total))

# What is the average daily activity pattern?
# Make a time series plot (i.e. type = "l") of the 5-minute interval (x-axis)
# and the average number of steps taken, averaged across all days (y-axis)
# 
# Which 5-minute interval, on average across all the days in the dataset,
# contains the maximum number of steps?

timeSeries <- na.omit(amData) %>%
  group_by(interval) %>%
  summarize(average = mean(steps))

timeSeries$dateTime <- strptime(timeSeries$interval, "%H:%M")

ggplot(timeSeries, aes(dateTime, average)) + geom_line(color = "red") +
  scale_x_datetime(breaks = date_breaks("3 hours"),
                   labels = date_format("%H:%M")) +
  ggtitle("average number of steps taken per interval") +
  theme(axis.title.x = element_blank(), axis.title.y = element_blank())

timeSeries[which.max(timeSeries$average),1]

# Imputing missing values
# 
# Note that there are a number of days/intervals where there are missing
# values (coded as NA). The presence of missing days may introduce bias
# into some calculations or summaries of the data.
# 
# Calculate and report the total number of missing values in the dataset
# (i.e. the total number of rows with NAs)
# 
# Devise a strategy for filling in all of the missing values in the
# dataset. The strategy does not need to be sophisticated. For example,
# you could use the mean/median for that day, or the mean for that
# 5-minute interval, etc.
# 
# Create a new dataset that is equal to the original dataset but with
# the missing data filled in.
# 
# Make a histogram of the total number of steps taken each day and
# Calculate and report the mean and median total number of steps taken
# per day. Do these values differ from the estimates from the first part
# of the assignment? What is the impact of imputing missing data on the
# estimates of the total daily number of steps?

sum(is.na(amData[,1]))

noMissing <- amData %>% 
  group_by(interval) %>% 
  mutate(steps = ifelse(is.na(steps), mean(steps, na.rm=TRUE), steps))

daySteps2 <- noMissing %>%
        group_by(date) %>%
        summarize(total = sum(steps))

ggplot(daySteps2, aes(total)) + geom_histogram(binwidth = 3021.86,
        color = "black", fill = "green") + xlab("") +
  ggtitle("number of steps taken each day\n(NAs replaced with means for 5-minute intervals)")

NA_removed <- c(round(mean(daySteps$total),2), median(daySteps$total))
NA_replaced <- c(round(mean(daySteps2$total),2), median(daySteps2$total))
statCompare <- cbind(NA_removed,NA_replaced)
rownames(statCompare) <- (c("Mean", "Median"))
statCompare

# Are there differences in activity patterns between weekdays and
# weekends?
# 
# For this part the weekdays() function may be of some help here.
# Use the dataset with the filled-in missing values for this part.
# 
# Create a new factor variable in the dataset with two levels -
# "weekday" and "weekend" indicating whether a given date is a
# weekday or weekend day.
# 
# Make a panel plot containing a time series plot (i.e. type = "l")
# of the 5-minute interval (x-axis) and the average number of steps
# taken, averaged across all weekday days or weekend days (y-axis).
# See the README file in the GitHub repository to see an example of
# what this plot should look like using simulated data.

dayType <- noMissing

dayType$week <- as.factor(ifelse(weekdays(dayType$date) %in%
        c("Saturday","Sunday"), "Weekend", "Weekday"))

dayType <- dayType %>%
        group_by(week, interval) %>%
        summarize(average = mean(steps))
dayType$dateTime <- as.POSIXct(strptime(dayType$interval, "%H:%M"))

ggplot(dayType, aes(dateTime, average, color = week)) + 
        geom_line() +
        scale_x_datetime(breaks = date_breaks("3 hours"),
        labels = date_format("%H:%M")) +
        facet_wrap(~week, nrow=2) +
        theme(legend.position="none") +
        theme(axis.title.x = element_blank())

