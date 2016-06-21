#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly = TRUE)
print(args)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("We need one argument: arg1: path to storage container; ", call.=FALSE)
} 

myNameNode <- args[1]

publishWS <- 0

print(paste("myNameNode=",myNameNode))
message("Sourcing setup.R...")
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
other.name <- paste(sep="/", script.basename, "setup.R")
print(paste("Sourcing",other.name,"from",script.name))
source(other.name)

#### Prepare and Explore Data in HDFS

# Specify the input file in HDFS to analyze.
inputFilePath <- file.path(bigDataDirRoot, trainDataFileName)
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

# Import the training data.
message("Importing training data...")
outFileChurn <- createOutXdf(myNameNode, bigDataDirRoot, outChurnPath)
rxImport(inData = inputDS,
         outFile = outFileChurn,
         colInfo = colInfo,
         fileSystem = hdfsFS,
         createCompositeSet = TRUE,
         overwrite = TRUE)

# Uncomment the below line to get the data/feature information at a live demo. 
# rxGetInfo(outFileChurn, getVarInfo = TRUE, numRows = 10)

# If a factor feature has zero variable, then eliminate that feature.
varsToDrop <- c()
varInfo <- rxGetVarInfo(outFileChurn)  # get variable information
varNames <- names(varInfo)  # get variable names
for (n in varNames) {
  factorLevels <- varInfo[[n]]$levels
  if (!is.null(factorLevels) & length(factorLevels) == 1) {  # if it is a factor with level = 1, then record the variable name
    varsToDrop <- c(varsToDrop, n)
  }
}

#### Prepare Training Data
message("Preparing training dataset...")
outFileTrain <- createOutXdf(myNameNode, bigDataDirRoot, outTrainPath)
rxDataStep(inData = outFileChurn, 
           outFile = outFileTrain,
           varsToDrop = varsToDrop,
           overwrite = TRUE)

#### Training a Decision Tree Model for a Classification Problem
message("Training and pruning a Decision Tree model...")
# Train DTree model.
modelFormula <- formula(outFileTrain, 
                        depVars = "Churn",
                        varsToDrop = c("UserId"))
dTree1 <- rxDTree(modelFormula, data = outFileTrain)

# Find the best value of cp for pruning rxDTree object.
treeCp <- rxDTreeBestCp(dTree1)

# Prune the tree.
dTree2 <- prune.rxDTree(dTree1, cp = treeCp)

#### Store Trained Model in Blob Storage.
message("Storing a trained model in a Blob container...")
# Serialize the model into a binary file to store in HDFS.
modelLocal <- file.path(getwd(), "tmp/trainModel")
modelFile <- file.path(myNameNode, bigDataDirRoot, outModelPath)
saveRDS(dTree2, modelLocal)
rxHadoopCopyFromLocal(source = modelLocal, dest = modelFile)

if (file.exists(modelLocal)) file.remove(modelLocal)


