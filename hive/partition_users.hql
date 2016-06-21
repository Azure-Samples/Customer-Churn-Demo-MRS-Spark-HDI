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
 
--if hive jobs previously ran much faster than in the current released version, look into potentially setting property 
--hive.optimize.sort.dynamic.partition = false .
 
use customerchurn;

INSERT OVERWRITE TABLE users PARTITION (year, month, day)
select 
        a.UserId,
        age,
        address,
        gender,
        usertype,
        year(date_add(registerTime, -1)),
        month(date_add(registerTime, -1)),
        day(date_add(registerTime, -1))
from userssample a, 
(select userid, min(from_unixtime(unix_timestamp(TransactionTime, 'MM/dd/yyyy HH:mm'))) as registerTime 
from activitiesSample group by userid) b
where a.userid=b.userid;
 
 
