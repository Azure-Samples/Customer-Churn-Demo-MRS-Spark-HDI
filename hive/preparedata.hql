drop database if exists customerchurn CASCADE;

create database if not exists customerchurn;

use customerchurn;

DROP TABLE IF EXISTS agelut;
create table agelut
(
Age string,
AgeRange string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:RESULTDIR}/customerchurn/data/referencedata/age/'
tblproperties("skip.header.line.count"="1");


DROP TABLE IF EXISTS regionlut;
create table regionlut
(
address string,
Region string,
Latitude double,
Longitude double
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:RESULTDIR}/customerchurn/data/referencedata/region/'
tblproperties("skip.header.line.count"="1");

DROP TABLE IF EXISTS UsersSample; 
create EXTERNAL TABLE UsersSample
(
       UserId string,
       Age string,
       Address string,
       Gender string,
       UserType string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:RESULTDIR}/customerchurn/data/sampledata/user/'
tblproperties("skip.header.line.count"="1");

DROP TABLE IF EXISTS ActivitiesSample; 
CREATE EXTERNAL TABLE ActivitiesSample
(
rownum  bigint,
TransactionId bigint,
TransactionTime string,
UserId string,
ItemId bigint,
Quantity bigint,
Value double,
Location string ,
ProductCategory  string 
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:RESULTDIR}/customerchurn/data/sampledata/activity/'
tblproperties("skip.header.line.count"="1");


DROP TABLE IF EXISTS ChurnPredictR;

create table ChurnPredictR
(
Pred string,
Churn string,
TotalQuantity int,
TotalValue int,
StDevQuantity double,
StDevValue double,
AvgTimeDelta double,
Recency smallint,
UniqueTransactionId smallint,
UniqueItemId smallint,
UniqueLocation  smallint,
UniqueProductCategory smallint,
TotalQuantityperUniqueTransactionId double,
TotalQuantityperUniqueItemId double,
TotalQuantityperUniqueLocation double,
TotalQuantityperUniqueProductCategory double,
TotalValueperUniqueTransactionId double,
TotalValueperUniqueItemId double,
TotalValueperUniqueLocation double,
TotalValueperUniqueProductCategory double,
Age string,
Address string,
PrechurnProductsPurchased smallint,
OverallProductsPurchased smallint,
UserId string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:RESULTDIR}/customerchurn/data/predictions/'
tblproperties("skip.header.line.count"="1");


DROP TABLE IF EXISTS Users; 
create EXTERNAL TABLE Users
(
   UserId string,
   Age string,
   Address string,
   Gender string,
   UserType string
)
partitioned by (year string, month string, day string) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:DATADIR}/customerchurn/data/partitioned/user/';

DROP TABLE IF EXISTS Activities; 
CREATE EXTERNAL TABLE Activities
(
TransactionId bigint,
TransactionTime timestamp,
UserId string,
ItemId bigint,
Quantity bigint,
Value double,
Location string ,
ProductCategory  string 
) 
partitioned by (year string, month string, day string) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '10' 
STORED AS TEXTFILE LOCATION '${hiveconf:DATADIR}/customerchurn/data/partitioned/activity/';






