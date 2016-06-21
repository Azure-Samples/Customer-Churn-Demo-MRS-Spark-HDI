#!/usr/bin/Rscript 

args <- commandArgs(trailingOnly = TRUE)
print(args)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("We need one argument: arg1: path to storage container; ", call.=FALSE)
} 

myNameNode <- args[1]

publishWS <- 0

message("Sourcing setup.R...")
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
other.name <- paste(sep="/", script.basename, "setup.R")
print(paste("Sourcing",other.name,"from",script.name))
source(other.name)

#### Unserialize Model to a MRS Object
message("Retrieving a trained model from a Blob container...")
modelLocal <- file.path(getwd(), "tmp/trainModel")
modelFile <- file.path(myNameNode, bigDataDirRoot, outModelPath)
rxHadoopCopyToLocal(source = modelFile, dest = modelLocal)
dTree <- readRDS(modelLocal)

#### Prepare and Explore Data in HDFS
# Specify the input file in HDFS to analyze.
inputFilePath <- file.path(bigDataDirRoot, scoreDataFileName)
print(paste("inputFilePath=",inputFilePath))

# Define the output XDF files.
createOutXdf <- function(myNameNode, bigDataDirRoot, filePath) {
  # Create a new path in HDFS.
  rxHadoopMakeDir(file.path(myNameNode, bigDataDirRoot, filePath))
  # Generate XDF object.
  RxXdfData(file = file.path(bigDataDirRoot, filePath), 
            fileSystem = hdfsFS)
}

# Define the data source.
inputDS <- RxTextData(file = inputFilePath,
                      missingValueString = "M",
                      firstRowIsColNames = FALSE,
                      delimiter = ",",
                      fileSystem = hdfsFS)

# Define variable information.
colInfo <- list(V1 = list(type = "character", newName = "UserId"),
                V2 = list(type = "numeric", newName = "TotalQuantity"),
                V3 = list(type = "numeric", newName = "TotalValue"),
                V4 = list(type = "numeric", newName = "StDevQuantity"),
                V5 = list(type = "numeric", newName = "StDevValue"),
                V6 = list(type = "numeric", newName = "AvgTimeDelta"),
                V7 = list(type = "numeric", newName = "Recency"),
                V8 = list(type = "numeric", newName = "UniqueTransactionId"),
                V9 = list(type = "numeric", newName = "UniqueItemId"),
                V10 = list(type = "numeric", newName = "UniqueLocation"),
                V11 = list(type = "numeric", newName = "UniqueProductCategory"),
                V12 = list(type = "numeric", newName = "TotalQuantityperUniqueTransactionId"),
                V13 = list(type = "numeric", newName = "TotalQuantityperUniqueItemId"),
                V14 = list(type = "numeric", newName = "TotalQuantityperUniqueLocation"),
                V15 = list(type = "numeric", newName = "TotalQuantityperUniqueProductCategory"),
                V16 = list(type = "numeric", newName = "TotalValueperUniqueTransactionId"),
                V17 = list(type = "numeric", newName = "TotalValueperUniqueItemId"),
                V18 = list(type = "numeric", newName = "TotalValueperUniqueLocation"),
                V19 = list(type = "numeric", newName = "TotalValueperUniqueProductCategory"),
                V20 = list(type = "factor", newName = "Age"),
                V21 = list(type = "factor", newName = "Address"),
                V22 = list(type = "factor", newName = "Gender"),
                V23 = list(type = "factor", newName = "UserType"),
                V24 = list(type = "factor", newName = "Churn"),
                V25 = list(type = "numeric", newName = "PrechurnProductsPurchased"),
                V26 = list(type = "numeric", newName = "OverallProductsPurchased"))

# Import the score data.
message("Importing score data...")
outFileChurn2 <- createOutXdf(myNameNode, bigDataDirRoot, outChurn2Path)
rxImport(inData = inputDS,
         outFile = outFileChurn2,
         colInfo = colInfo,
         fileSystem = hdfsFS,
         createCompositeSet = TRUE,
         overwrite = TRUE)

# Uncomment the below line to get the data/feature information at a live demo. 
# rxGetInfo(outFileChurn2, getVarInfo = TRUE, numRows = 10)

# If a factor feature has zero variable, then eliminate that feature.
varsToDrop <- c()
varInfo <- rxGetVarInfo(outFileChurn2)  # get variable information
varNames <- names(varInfo)  # get variable names
for (n in varNames) {
  factorLevels <- varInfo[[n]]$levels
  if (!is.null(factorLevels) & length(factorLevels) == 1) {  # if it is a factor with level = 1, then record the variable name
    varsToDrop <- c(varsToDrop, n)
  }
}

#### Prepare the Score Data
message("Preparing the scoring dataset...")
outFileTest <- createOutXdf(myNameNode, bigDataDirRoot, outTestPath)
rxDataStep(inData = outFileChurn2, 
           outFile = outFileTest,
           varsToDrop = varsToDrop,
           overwrite = TRUE)

#### Predict Churn/Non-Churn on a New Dataset
# Predict with Class.
message("Predicting churn/non-churn...")
outFileScore <- createOutXdf(myNameNode, bigDataDirRoot, outScorePath)
rxPredict(modelObject = dTree, 
          data = outFileTest,
          outData = outFileScore,
          type = "class",
          extraVarsToWrite = as.vector(c("UserId", 
                                         "TotalQuantity",
                                         "TotalValue",
                                         "StDevQuantity",
                                         "StDevValue",
                                         "AvgTimeDelta",
                                         "Recency",
                                         "UniqueTransactionId",
                                         "UniqueItemId",
                                         "UniqueLocation",
                                         "UniqueProductCategory",
                                         "TotalQuantityperUniqueTransactionId",
                                         "TotalQuantityperUniqueItemId",
                                         "TotalQuantityperUniqueLocation",
                                         "TotalQuantityperUniqueProductCategory",
                                         "TotalValueperUniqueTransactionId",
                                         "TotalValueperUniqueItemId",
                                         "TotalValueperUniqueLocation",
                                         "TotalValueperUniqueProductCategory",
                                         "Age",
                                         "Address",
                                         "Churn",
                                         "PrechurnProductsPurchased",
                                         "OverallProductsPurchased")),
          predVarNames = "Pred",
          overwrite = TRUE)


#### Store Prediction Results in Blob
message("Storing prediction results in a Blob container...")
rxSetComputeContext("local")
predFile <- file.path(myNameNode, bigDataDirRoot, outPredPath)
rxHadoopMakeDir(predFile)
predDS <- RxTextData(predFile,
                     fileSystem = hdfsFS, 
                     createFileSet = TRUE,
					  rowsPerOutFile = 20000)

# Output the data to a .csv file.
rxDataStep(inData = outFileScore, 
           outFile = predDS,
           overwrite = TRUE) 
