<img src=doc/image/ChurnLogo.png alt="ChurnLogo" width=200 height=125>

Author:

Min Qiu, Katherine Zhao

Date: June 2016

INTRODUCTION
============

This demo demonstrates how to use [Microsoft R
Server](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-hadoop-r-server-install-r-studio/), [Azure
HDInsight with R on
Linux](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-hadoop-r-server-get-started/),
[Azure Machine
Learning](https://azure.microsoft.com/en-us/services/machine-learning/),
Spark, Scala, Hive, etc. to build an end-to-end, cloud solution for
Retail Customer Churn. The demo attempts to simulate the real-world use
case of data placement/storage, feature engineering, model retraining,
prediction, and visualization.

Architecture
------------

<img src=doc/image/Architecture.png alt="Architecture" width=750 height=400>

Prerequisites
-------------

### **Subscription requirements.** 

An Azure subscription: Before you begin, you must have an Azure
subscription that have access to Azure HDInsight, Azure Blob Storage,
etc. See Get [Azure free trial](https://azure.microsoft.com/en-us/documentation/videos/get-azure-free-trial-for-testing-hadoop-in-hdinsight/) for
more information.

### **PowerBI.** 

You need an account for PowerBI. An account could be gotten
from [here](https://powerbi.microsoft.com/en-us/landing/signin/).

-   **Online:** access PowerBI online here

-   **Desktop:** download and install PowerBI Desktop
    [here](https://powerbi.microsoft.com/en-us/desktop/)

### **Windows side requirements.**

-   A Secure Shell (SSH) client: An SSH client is used to remotely
    connect to the HDInsight cluster and run commands directly on
    the cluster. Linux, Unix, and OS X systems provide an SSH client
    through the SSH command. For Windows systems, we
    recommend [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html).

-   (OPTIONAL) A SCP client: For Windows, we
    recommend [WinSCP](https://winscp.net/eng/download.php).

-   Visual Studio with Azure SDK. Please install Visual Studio,
    Azure SDK by following the step 1 in this instruction
    [here](https://blogs.msdn.microsoft.com/xiaoyong/2015/05/04/how-to-write-and-submit-hive-queries-using-visual-studio/)

### **HDInsight Cluster on Linux with R Server**.

First, you need a HDInsight Cluster on Linux with R Server to deploy in
order to run this demo.

you can deploy a HDInsight with Spark and R server through

<a href="https://azuredeploy.net/" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

You can also go to the azure portal deploy one like followings
-   Deploy an HDInsight cluster running Linux with R Server (with
    Azure Storage) with an SSH password. You can find the instruction
    [here](https://azure.microsoft.com/en-us/documentation/articles/hdinsight-hadoop-r-server-get-started/#create-the-cluster).

-   Follow the steps 1-9 in the “Create the Cluster” section. In Step 8,
    it’s better to put “Number of Worker nodes” to 8 and choose all
    D4 nodes.

-   We recommend you create a new resource group for the demo.

The deployment of the Cluster takes about 20-40 minutes.

### **Azure Machine Learning Workspace**.

You need a AML workspace pre-created.

-   Go to portal.azure.com. Choose the Machine Learning Workspace like
    below which will open the old azure portal

    <img src=doc/image/CreateAML.png alt="CreateAML" width=400 height=325>

-   Following the instruction
    [here](https://azure.microsoft.com/en-us/documentation/articles/machine-learning-create-workspace/)
    to create a new workspace if you don’t have one

-   Find out the Workspace ID and Authorization token as followings

    -   Open **Azure Machine Learning** through Portal. It will open the
        Azure Machine Learning portal.

    -   Select the workspace you want to use. And **Sign-in to
        ML Studio. **

        <img src=doc/image/MLStudioSignIn.png alt="SigninAML" width=350 height=225>

-   Go to SETTINGS in the AML Studio. Find the **WORKSPACE ID** under
    the NAME tab. And find **PRIMARY AUTHORIZATION TOKEN** under the
    **AUTHORIZATION TOKENS** tab

    <img src=doc/image/MLStudioID.png alt="AMLID" width=350 height=225>
    <img src=doc/image/MLStudioToken.png alt="AMLKey" width=350 height=225>

DEMO INSTRUCTIONS
========================

Please refer the **Demo Instructions Customer Churn.Docx** file for the detail of demo instruction.
