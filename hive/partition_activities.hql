set hive.support.sql11.reserved.keywords=false;
 
set hive.execution.engine=tez;
set hive.cbo.enable=true;
set hive.compute.query.using.stats=true;
set hive.stats.fetch.column.stats=true;
set hive.stats.fetch.partition.stats=true;
set hive.vectorized.execution.enabled=true;
set hive.vectorized.execution.reduce.enabled = true;
set hive.vectorized.execution.reduce.groupby.enabled = true;

set hive.exec.dynamic.partition.mode=nonstrict;
 
--There is a danger with many partition columns to generate many broken files in ORC.  To prevent that
set hive.optimize.sort.dynamic.partition=true;
 
use customerchurn;

INSERT OVERWRITE TABLE Activities PARTITION (year, month,day)
        select TransactionId,
        from_unixtime(unix_timestamp(TransactionTime, 'MM/dd/yyyy HH:mm')),
        UserId,
        ItemId,
        Quantity,
        Value,
        Location,
        ProductCategory,
        year(from_unixtime(unix_timestamp(TransactionTime, 'MM/dd/yyyy HH:mm'))),
        month(from_unixtime(unix_timestamp(TransactionTime, 'MM/dd/yyyy HH:mm'))),
        day(from_unixtime(unix_timestamp(TransactionTime, 'MM/dd/yyyy HH:mm')))
        from activitiessample;

