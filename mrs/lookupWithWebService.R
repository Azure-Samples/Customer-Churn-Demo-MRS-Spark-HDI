#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly = TRUE)
print(args)

# test if there is at least one argument: if not, return an error
if (length(args)<3) {
  stop("We need three arguments: arg1: path to storage container arg2: AML workspace id arg3: auth for AML workspace", call.=FALSE)
} 

myNameNode <- args[1]
wsID <- args[2]
wsAuth <- args[3]
thisTime <- args[4]

publishWS <- 1
library("AzureML")

print(paste("myNameNode=",myNameNode))
message("Sourcing setup.R...")
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
other.name <- paste(sep="/", script.basename, "setup.R")
print(paste("Sourcing",other.name,"from",script.name))
source(other.name)

# Specify the input file in HDFS to analyze.
inputFile2 <- file.path(bigDataDirRoot, predictionDataFileName)

# Define the data source.
inputDS2 <- RxTextData(file = inputFile2,
                      missingValueString = "M",
                      firstRowIsColNames = TRUE,
                      delimiter = ",",
                      fileSystem = hdfsFS)

# Import the prediction results.
prediction <- rxImport(inData = inputDS2, fileSystem = hdfsFS)

# Define a function to return different message for non-churner and churner.
lookUpFn <- function(x) {
  index <- match(x, prediction$UserId)
  pred <- prediction$Pred[index]
  if (is.na(index)) {
    return("Please enter a valid user ID.")
  } else if (pred == "1"){
    return("Welcome back to Joseph Mart!")
  } else {
    return("Thank you for being our loyal customer!")
  }
}

# Test the scoring function locally.
lookUpFn(prediction$UserId[1])

# Publish the service.
webServiceName2 <- paste("userid-look-up-churn_", thisTime)
publishWebService(ws = ws,
                  fun = lookUpFn,
                  name = webServiceName2,
                  inputSchema = list(id = "numeric"),
                  outputSchema = list(pred = "character"))
