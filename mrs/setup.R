#load R package
message("Loading CRAN R packages...")
library("AzureML")
library("rpart") 

#### Set Compute Context to rxSpark and HDFS path

# if the data is stored in a different Blob container than the default one, 
# the connection can be set up thru the "wasb" string.
#myNameNode <- args[1]
myPort <- 0

# Define the path to the data.
bigDataDirRoot <- "/customerchurn/data" # this location can be adjusted to your defined directory accordingly.
print(paste("namenode is ",myNameNode))
print(paste("bigDataDirRoot is ",bigDataDirRoot))
# Define Spark compute context.
mySparkCluster <- RxSpark(hdfsShareDir = bigDataDirRoot,
                          nameNode = myNameNode,
                          port = myPort,
                          executorMem = "10g",
                          driverMem = "10g",
                          executorOverheadMem = "10g",
                          idleTimeout = 86400000,
                          autoCleanup = TRUE,
                          consoleOutput = TRUE)

# Tell RevoScaleR to use MapReduce compute context.
message("Setting compute context to Spark...")
rxSetComputeContext(mySparkCluster)

# Define HDFS file system.
hdfsFS <- RxHdfsFileSystem(hostName = myNameNode, port = myPort)

#### Set Up Configuration for Web Service via AzureML

## This diverts outputs and messages to a sink file on the R-server node (where R-studio server is installed)
if(publishWS == 1)
{
    sinkFilePath <- paste0(getwd(), "/logs/checkWS.txt")
    system(paste0("rm -f ", sinkFilePath))
    sinkFile <- file(sinkFilePath, open = "w+")
    sink(sinkFile)

    # Connect to an Azure Machine Learning work space.
    capture.output(tryCatch({
        if(Sys.getenv("R_ZIPCMD") == "")
        {
          Sys.setenv(R_ZIPCMD = "zip") # needed by AzureML::publishWebService
        }
        
        # Connect to an Azure Machine Learning work space.
        if(file.exists("~/.azureml/settings.json")){
          ws <- workspace()
        } else {
          ws <- workspace(
            id = wsID,  # this id can be adjusted to your own AML workspace id.
            auth = wsAuth  # this auth can be adjusted to your own workspace authorization.
          )
        }
    }, error = function(e) {
      return(e)
    }
    ), file = sinkFile)
}

#### Define Inputs and Outputs

# Inputs:
trainDataFileName <- "traindatauserfeatured/"
scoreDataFileName <- "scoredatauserfeatured/"
predictionDataFileName <- "predictions/"


# Outputs:
outChurnPath <- "mrs/temp/churn"
outChurn2Path <- "mrs/temp/churn2"
# outSplitPath <- "mrs/temp/split"
outTrainPath <- "mrs/temp/train"
outTestPath <- "mrs/temp/test"
outModelPath <- "mrs/trainModel"
outScorePath <- "mrs/temp/score"
outPredPath <- "predictions"
