####### Author: Zer0 ########
## Project Getting and Cleaning Data Coursera

## Loading Packages and Files
packages <- c("data.table", "reshape2")
sapply(packages, require, character.only=TRUE, quietly=TRUE)
path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")


# Setup Activities and Features
activityLabels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt"),
                        col.names = c("classLabels", "activityName"))
features       <- fread(file.path(path, "UCI HAR Dataset/features.txt"),
                        col.names = c("index", "featureNames"))

featuresMeanSTD <- grep("(mean|std)\\(\\)", features[, featureNames])
measurements    <- features[featuresMeanSTD, featureNames]
measurements    <- gsub('[()]', '', measurements)

# Loading Trainset
train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, featuresMeanSTD, with = FALSE]
data.table::setnames(train, colnames(train), measurements)
trainActivities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                         , col.names = c("Activity"))
trainSubjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                       , col.names = c("SubjectNum"))
train <- cbind(trainSubjects, trainActivities, train)


# Loading Testset
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, featuresMeanSTD, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
testActivities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                        , col.names = c("Activity"))
testSubjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                      , col.names = c("SubjectNum"))
test <- cbind(testSubjects, testActivities, test)

# Merging Train and Test
merged <- rbind(train, test)

# More descriptive Labels and Subject as Factor
merged[["Activity"]] <- factor(merged[, Activity]
                               , levels = activityLabels[["classLabels"]]
                               , labels = activityLabels[["activityName"]])
merged[["SubjectNum"]] <- as.factor(merged[, SubjectNum])

# Longformat for calc -> wideformat means for measurements per Subject and Activity
merged <- reshape2::melt(data = merged, id = c("SubjectNum", "Activity"))
merged <- reshape2::dcast(data = merged, SubjectNum + Activity ~ variable, fun.aggregate = mean)

# Export clean Dataset as .txt
data.table::fwrite(x = merged, file = "tidyData.txt", quote = FALSE)