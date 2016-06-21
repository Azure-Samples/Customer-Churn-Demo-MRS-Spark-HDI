package com.adf.spark.customerchurn

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._

import scala.sys.process._
import org.apache.spark._
import org.apache.spark.sql._
import org.apache.spark.sql.functions
import org.apache.spark.sql.functions._
import org.apache.spark.sql.hive._
import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.hive.HiveContext
import org.apache.spark.sql.expressions.Window

object TrainDataFeatureEngineeringSparkApp {
  def main(args: Array[String]) {
    val namedArgs = getNamedArgs(args)
    val churnPeriodVal = namedArgs("ChurnPeriodPara") 
    val churnThresholdVal = namedArgs("ChurnThresholdPara")
    val dataDir = namedArgs("DataDirPara") 

    //create a spark application
    val conf = new SparkConf().setAppName("TrainDataFeatureEngineeringSparkApp")
    val sc = new SparkContext(conf)
    val sqlContext = new org.apache.spark.sql.hive.HiveContext(sc)
    import sqlContext.implicits._

    //create the dataframe for user transaction activities using HIVE partitioned table
    val activityTableDF = sqlContext.sql("select * from customerchurn.activities")

    //create a dataframe for the two parameters of Churn in order to use in the joins
    val ChurnVarsDF = sqlContext.createDataFrame(Seq((churnPeriodVal, churnThresholdVal)))
    
    //get the max Datetime for user transaction activities and assign it to a variable
    val maxTimeDF = activityTableDF.select(max($"TransactionTime").alias("maxAllTransDate"))
    val maxAllTransDateVal = (maxTimeDF.rdd.first())(0).toString()

    //create the dataframe for users using HIVE partitioned table    
    val userTableDF = sqlContext.sql("select * from customerchurn.users").join(ChurnVarsDF.withColumnRenamed("_1", "ChurnPeriod").withColumnRenamed("_2", "ChurnThreshold")).join(maxTimeDF)

    //using Analytic Functions to get lag of the TransactionTime for each user
    val w = Window.partitionBy("UserId").orderBy("TransactionTime")
    val activityLagTableDF = activityTableDF.select($"*", datediff($"TransactionTime", lag($"TransactionTime", 1).over(w)).alias("TransactionInterval"))

    //produce a Pre-Churn flag
    val exprStr = "case when datediff(TransactionTime, date_add('" + maxAllTransDateVal + "', -1*" + churnPeriodVal + ")) <= 0 then 1 else 0 end"
    val activityFlagTableDF = activityLagTableDF.withColumn("preChurnPeriodTransFlag", expr(exprStr))

    //produce all the features
    // Tag as Churn or Non-Churn for train data. For score data, we also tag it for comparison purpose with Prediction
    val featuredDF = (
         activityFlagTableDF
         .groupBy($"UserId")
         .agg(  sum(expr("case when preChurnPeriodTransFlag = 1 then 1 else 0 end")).alias("PrechurnProductsPurchased"), 
                count($"TransactionId").alias("OverallProductsPurchased"),
                sum(expr("case when preChurnPeriodTransFlag = 1 then Quantity else 0 end")).alias("TotalQuantity"), 
                sum(expr("case when preChurnPeriodTransFlag = 1 then Value else 0 end")).alias("TotalValue"),
                stddev_samp(expr("case when preChurnPeriodTransFlag = 1 then Quantity else null end")).alias("StDevQuantity"), 
                stddev_samp(expr("case when preChurnPeriodTransFlag = 1 then Value else null end")).alias("StDevValue"),             
                avg(expr("case when preChurnPeriodTransFlag = 1 then TransactionInterval else null end")).alias("AvgTimeDelta"),
                (max(expr("case when preChurnPeriodTransFlag = 1 then TransactionTime else null end"))).alias("RecencyDate"),
                (countDistinct(expr("case when preChurnPeriodTransFlag = 1 then TransactionId else '-1' end")) 
                 - sumDistinct(expr("case when (case when preChurnPeriodTransFlag = 1 then TransactionId else null end) is null then 1 else 0 end"))).alias("UniqueTransactionId"),
                (countDistinct(expr("case when preChurnPeriodTransFlag = 1 then ItemId else '-1' end")) 
                 - sumDistinct(expr("case when (case when preChurnPeriodTransFlag = 1 then ItemId else null end) is null then 1 else 0 end"))).alias("UniqueItemId"),
                (countDistinct(expr("case when preChurnPeriodTransFlag = 1 then Location else '-1' end")) 
                 - sumDistinct(expr("case when (case when preChurnPeriodTransFlag = 1 then Location else null end) is null then 1 else 0 end"))).alias("UniqueLocation"),
                (countDistinct(expr("case when preChurnPeriodTransFlag = 1 then ProductCategory else '-1' end")) 
                 - sumDistinct(expr("case when (case when preChurnPeriodTransFlag = 1 then ProductCategory else null end) is null then 1 else 0 end"))).alias("UniqueProductCategory")
          )
          .join(userTableDF.withColumnRenamed("UserID", "UId"), $"UId"===activityFlagTableDF("UserId"))
          .select($"UserId", 
          $"TotalQuantity", 
          $"TotalValue", 
          $"StDevQuantity", 
          $"StDevValue", 
          $"AvgTimeDelta", 
                   (datediff($"maxAllTransDate", $"RecencyDate") - $"ChurnPeriod").alias("Recency"), 
                   $"UniqueTransactionId", $"UniqueItemId", $"UniqueLocation", $"UniqueProductCategory", 
                   ($"TotalQuantity" /($"UniqueTransactionId"+1)).alias("TotalQuantityperUniqueTransactionId"), 
                   ($"TotalQuantity" /($"UniqueItemId"+1)).alias("TotalQuantityperUniqueItemId"), 
                   ($"TotalQuantity" /($"UniqueLocation"+1)).alias("TotalQuantityperUniqueLocation"), 
                   ($"TotalQuantity" /($"UniqueProductCategory"+1)).alias("TotalQuantityperUniqueProductCategory"), 
                   ($"TotalValue" /($"UniqueTransactionId"+1)).alias("TotalValueperUniqueTransactionId"), 
                   ($"TotalValue" /($"UniqueItemId"+1)).alias("TotalValueperUniqueItemId"), 
                   ($"TotalValue" /($"UniqueLocation"+1)).alias("TotalValueperUniqueLocation"), 
                   ($"TotalValue" /($"UniqueProductCategory"+1)).alias("TotalValueperUniqueProductCategory"),
                   $"Age",
                   $"Address",
                   $"Gender",
                   $"UserType",
                    expr("case when PrechurnProductsPurchased = 0 then 0 when PrechurnProductsPurchased >=0 and (( OverallProductsPurchased- PrechurnProductsPurchased)<= ChurnThreshold)  then 1 else 0 end").alias("churn"),
                    $"PrechurnProductsPurchased",
                    $"OverallProductsPurchased"                   
                  )
    )

    //save the featured/tagged data back to storage
    //first prepare the blob. Because for Hive External table, Scala write.mode(SaveMode.Overwrite) could not produce the data properly, 
    //because we have to use write.mode(SaveMode.Overwrite), we have to remove the old data may pre-existing there.
    val filePath= dataDir + "/customerchurn/data/traindatauserfeatured/"
    Seq("hadoop","fs","-mkdir", "-p",filePath).!!    
    Seq("hadoop","fs","-rm", "-r",filePath).!!

    sqlContext.sql("use customerchurn")

    sqlContext.sql("drop table traindata_user_Featured")

    val sqlStr = """
    CREATE EXTERNAL TABLE traindata_user_Featured(
        UserId varchar(50) ,
        TotalQuantity bigint ,
        TotalValue float ,
        StDevQuantity float ,
        StDevValue float ,
        AvgTimeDelta float ,
        Recency int ,
        UniqueTransactionId bigint ,
        UniqueItemId bigint ,
        UniqueLocation bigint ,
        UniqueProductCategory bigint ,
        TotalQuantityperUniqueTransactionId float ,
        TotalQuantityperUniqueItemId float ,
        TotalQuantityperUniqueLocation float ,
        TotalQuantityperUniqueProductCategory float ,
        TotalValueperUniqueTransactionId float ,
        TotalValueperUniqueItemId float ,
        TotalValueperUniqueLocation float ,
        TotalValueperUniqueProductCategory float ,
        Age varchar(50) ,
        Address varchar(50) ,
        Gender varchar(50),
        UserType varchar(50),
        tag   varchar(10),
        PrechurnProductsPurchased bigint ,
        OverallProductsPurchased bigint 
    )
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
    LINES TERMINATED BY '10' 
    STORED AS TEXTFILE LOCATION 
    """ + "'" + dataDir + "/customerchurn/data/traindatauserfeatured/'"

    sqlContext.sql(sqlStr)

    //we choose 70% data as train data, and then save as hive table to blob
    featuredDF.sample(false, 0.7, 123).coalesce(1).write.mode(SaveMode.Append).saveAsTable("traindata_user_Featured");

    //delete the log files produced by Hive, because MRS could not recongized them
    val lsFilePath= (Seq("hadoop","fs","-ls",filePath).!!).replace("\n", " ")
    val tempFileList= lsFilePath.split(" ").filter(x => (x.contains(".hive-staging_hive")))

    for(tempFilePath<- tempFileList)
    {
       Seq("hadoop","fs","-rm", "-r",tempFilePath).!!
    }
  }

  def getNamedArgs(args:Array[String]):Map[String,String]={
    args.filter(line=>line.contains("="))//take only named arguments
      .map(x=>(x.substring(0,x.indexOf("=")),x.substring(x.indexOf("=")+1)))//split into key values
      .toMap//convert to a map
  }  
}

 