#!/bin/bash

pauseflag="on"
while [ $# -gt 0 ]
do
    case "$1" in
        -d)  pauseflag="off";;
	*)  break;;	# terminate while loop
    esac
    shift
done

#different colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3` 
blue=`tput setaf 4` 
reset=`tput sgr0`
sp="/-\|"

now=$(date +"%Y%m%d-%H%M%S")
thisDir=$(pwd)
mkdir -p ${thisDir}/logs
rm -rf ${thisDir}/tmp/
mkdir -p ${thisDir}/tmp/predictions

logFile="${thisDir}/logs/run_demo_${now}.log"
echo "${green}You can find the log file at $logFile${reset}" 
echo "${green}Start setting Demo for Customer Churn using Spark/MRS${reset}" | tee -a $logFile
echo "${green}Setting Demo started at: ${now}${reset}" | tee -a $logFile

storagePass=0
#dataContainerPass=0
#resultContainerPass=0
HDIContainerPass=0
wsIDPass=0
wsAuthPass=0
allPass=0

datacontainer="customerchurnintern"
resultcontainer="customerchurnresult"
while [ $allPass -ne 1 ];
do
	if [ $storagePass -ne 1 ] 
	then
		while true; do
			read -p "Enter storage name: "  storagename
			if [ ! -z "$storagename" -a "$storagename" != " " ]; then
				echo "${green}storage name is ${storagename}${reset}"  | tee -a $logFile
				break
			fi
		done
	fi

	if [ $HDIContainerPass -ne 1 ] 
	then
		while true; do
			read -p "Enter container name for HDI: "  HDIcontainer
			if [ ! -z "$HDIcontainer" -a "$HDIcontainer" != " " ]; then
				echo "${green}container name for HDI is ${HDIcontainer}${reset}"  | tee -a $logFile
				break
			fi
		done
	fi
	
	hdfsHDIContainerPath="wasb://${HDIcontainer}@${storagename}.blob.core.windows.net"	
	hdfsHDIPath="${hdfsHDIContainerPath}/HdiNotebooks/Scala"	
	#check if the storage and HDIcontainer are correct
	if [ $storagePass -ne 1 ] || [ $HDIContainerPass -ne 1 ]
	then	
		rtn1=$(hadoop fs -ls ${hdfsHDIContainerPath}/ 2>&1)
		if [[ "$rtn1" == *"No such file or directory"* ]] 
		then
			HDIContainerPass=0
			echo "${red}container ${HDIcontainer} doesn't exists${reset}"  | tee -a $logFile
		elif  [[ "$rtn1" == *"Unable to access container"* ]] 
		then
			#storagePass=1
			echo "${red}storage account ${storagename} doesn't exists${reset}"  | tee -a $logFile
		else
			storagePass=1
			HDIContainerPass=1
			#break
		fi
	fi
	
	hdfsDataContainerPath="wasb://${datacontainer}@${storagename}.blob.core.windows.net"

	#check if workspace info is correct
	#wsID="aa7d2c32261a4897a435815c2c052f28",  # this id can be adjusted to your own workspace id.
	#wsAuth="19a1f8c2b8b743809c20151629a659ca"
	if [[ $wsIDPass -ne 1  ||  $wsAuthPass -ne 1 ]] && [ $storagePass -eq 1 ] && [ $HDIContainerPass -eq 1 ]
	then		

  	    if [ $wsIDPass -ne 1 ] 
		then
			while true; do
				read -p "Enter Azure Machine Learning workspace id: "  wsID
				if [ ! -z "$wsID" -a "$wsID" != " " ]; then
					echo "${green}Azure Machine Learning workspace id is ${wsID}${reset}"  | tee -a $logFile
					break
				fi
			done
		fi
		
		if [ $wsAuthPass -ne 1 ] 
		then		
			while true; do
				read -p "Enter Azure Machine Learning workspace auth key: "  wsAuth
				if [ ! -z "$wsAuth" -a "$wsAuth" != " " ]; then
					echo "${green}Azure Machine Learning workspace auth key is ${wsAuth}${reset}"  | tee -a $logFile
					break
				fi
			done
		fi
		
		#install R packages in case they are not installed by set_demo.sh
		installRFile="${thisDir}/mrs/installrpackages.R"
		sudo Rscript --default-packages=methods,utils,datasets $installRFile >> $logFile 2>&1 

		lookupFile="${thisDir}/mrs/checkWS.R"
		Rscript --default-packages=methods,utils,datasets $lookupFile  ${hdfsDataContainerPath} ${wsID} ${wsAuth} >> $logFile 2>&1 
		rtn2=$(cat "${thisDir}/logs/checkWS.txt")
		if [[ "$rtn2" == *"Bad request"* ]] || [[ "$rtn2" == *"Unauthorised"* ]] 
		then
			if [[ "$rtn2" == *"Bad request"* ]]
			then
				echo "${red}The workspace ID for Azure Machine Learning is incorrect${reset}"  | tee -a $logFile
				wsIDPass=0
			fi
			if [[ "$rtn2" == *"Unauthorised"* ]]
			then
				echo "${red}The workspace auth key for Azure Machine Learning is incorrect${reset}"  | tee -a $logFile
				wsAuthPass=0
				wsIDPass=1
			fi	
		fi
		if [ "$rtn2" == "" ] 
		then
			wsIDPass=1
			wsAuthPass=1			
			allPass=1
			break
		fi
	fi
done

defaultChrunPeriod=21
while true; do
	read -p "Enter Churn Period[$defaultChrunPeriod]: "  churnPeriod
	
	if [ ! -z "$churnPeriod" -a "$churnPeriod" != " " ]; then
		if ! [ "$churnPeriod" -eq "$churnPeriod" ] 2> /dev/null
		then
			echo "please input an integer"
		else
			break
		fi
	else
	  break
	fi
done
churnPeriod=${churnPeriod:-$defaultChrunPeriod}
echo "${green}Churn Period is ${churnPeriod}${reset}"  | tee -a $logFile

defaultChurnThreshold=0
while true; do
	read -p "Enter Churn Threshold[$defaultChurnThreshold]: "  churnThreshold
	
	if [ ! -z "$churnThreshold" -a "$churnThreshold" != " " ]; then
		if ! [ "$churnThreshold" -eq "$churnThreshold" ] 2> /dev/null
		then
			echo "please input an integer"
		else
			break
		fi
	else
	  break
	fi
done
churnThreshold=${churnThreshold:-$defaultChurnThreshold}
echo "${green}Churn Threshold is ${churnThreshold}${reset}"  | tee -a $logFile

echo | tee -a $logFile

hdfsDataPath="${hdfsDataContainerPath}/customerchurn/data"
hdfsLibPath="${hdfsDataContainerPath}/customerchurn/libs/"

hdfsResultContainerPath="wasb://${resultcontainer}@${storagename}.blob.core.windows.net"	
hdfsResultPath="${hdfsResultContainerPath}/customerchurn/data"	

hiveFile="${thisDir}/hive/preparedata.hql"
hiveFile2="${thisDir}/hive/partition_activities.hql"
hiveFile3="${thisDir}/hive/partition_users.hql"
localTrainingLibPath="${thisDir}/sparkapp/training/target/scala-2.10/com-adf-spark-customerchurn-traindatafeatureengineering_2.10-1.0.jar"
localScoringLibPath="${thisDir}/sparkapp/scoring/target/scala-2.10/com-adf-spark-customerchurn-scoredatafeatureengineering_2.10-1.0.jar"

#upload notebook to HDI
localNotebookPath="${thisDir}/notebook/scala"
hdfsNotebookScalaPath="${hdfsHDIPath}/HdiNotebooks/Scala/"
hadoop fs -put -f ${localNotebookPath}/* ${hdfsNotebookScalaPath} >> $logFile 2>&1 &

#cleanup hdfs data directory
echo "${green}Begin cleaning up hdfs data directory${reset}"  | tee -a $logFile
hadoop fs -rm -r ${hdfsDataPath} >> $logFile 2>&1 &
hadoop fs -rm -r ${hdfsLibPath} >> $logFile 2>&1 &
hadoop fs -rm -r ${hdfsResultPath} >> $logFile 2>&1 &
echo "${green}End cleaning up hdfs data directory at $(date +"%Y%m%d-%H%M%S") ${reset}"  | tee -a $logFile
wait

echo | tee -a $logFile

#create directory in blob container
echo "${green}Begin creating blob directories${reset}"  | tee -a $logFile
hdfsSampleDataPath1="${hdfsResultPath}/sampledata/activity/"
hdfsSampleDataPath2="${hdfsResultPath}/sampledata/user/"
hdfsSampleDataPath3="${hdfsResultPath}/referencedata/age/"
hdfsSampleDataPath4="${hdfsResultPath}/referencedata/region/"
hdfsSampleDataPath5="${hdfsResultPath}/predictions/"

hadoop fs -mkdir -p ${hdfsDataPath} >> $logFile 2>&1 

hadoop fs -mkdir -p "${hdfsDataContainerPath}/customerchurn/libs/"  >> $logFile 2>&1 
hadoop fs -mkdir -p ${hdfsSampleDataPath1} >> $logFile 2>&1 
hadoop fs -mkdir -p ${hdfsSampleDataPath2} >> $logFile 2>&1 
hadoop fs -mkdir -p ${hdfsSampleDataPath3} >> $logFile 2>&1 
hadoop fs -mkdir -p ${hdfsSampleDataPath4} >> $logFile 2>&1 
hadoop fs -mkdir -p ${hdfsSampleDataPath5} >> $logFile 2>&1 
echo "${green}End creating blob directories at $(date +"%Y%m%d-%H%M%S") ${reset}"  | tee -a $logFile

echo | tee -a $logFile

#upload the sparkApp for training to blob
#hadoop fs -put -f localLibPath hdfsLibPath

#upload the lib for sparklauncher to blob
#localLibPath = "${thisDir}/libs/com.adf.sparklauncher.jar"
#hadoop fs -put -f localLibPath hdfsLibPath

#step 1: upload the sample data for activities and users
echo "${green}Step 1: Begin uploading the sample data for activities and users to blob${reset}" | tee -a $logFile
localDataPath1="${thisDir}/data/Activities.csv"
localDataPath2="${thisDir}/data/Users.csv"
localDataPath3="${thisDir}/data/age.csv"
localDataPath4="${thisDir}/data/region.csv"

hadoop fs -put -f ${localDataPath1} ${hdfsSampleDataPath1} >> $logFile 2>&1 &
hadoop fs -put -f ${localDataPath2} ${hdfsSampleDataPath2} >> $logFile 2>&1 &
hadoop fs -put -f ${localDataPath3} ${hdfsSampleDataPath3} >> $logFile 2>&1 &
hadoop fs -put -f ${localDataPath4} ${hdfsSampleDataPath4} >> $logFile 2>&1 &
echo "${green}End uploading the sample data for activities and users to blob at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile
wait

echo "${yellow}Step 1: Upload sample data and reference data completed. Now you can go to the blob storage ${hdfsResultPath} to check the data"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo | tee -a $logFile

#Step 2: call hive to create hive database 
echo "${green}Step 2: Begin preparing the hive database${reset}" | tee -a $logFile
echo | tee -a $logFile

hive -hiveconf RESULTDIR=${hdfsResultContainerPath} -hiveconf DATADIR=${hdfsDataContainerPath} -f $hiveFile >> $logFile 2>&1 & pid1=$! 

i1=1
echo -n "${green}Preparing the hive database${reset}" | tee -a $logFile
while [ -d /proc/$pid1 ]
do
  printf "\b${sp:i1++%${#sp}:1}"
done
wait
echo | tee -a $logFile
echo "${green}End creating hive tables at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile

echo "${yellow}Step 2: Create hive tables completed. Now you can go to hive database to check the tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

echo | tee -a $logFile

#Step 3: call hive to create hive database repare data(partition the sample data to different partitions)
#echo "${green}Begin partitioning the sample data using hive${reset}" | tee -a $logFile
hive -hiveconf DATADIR=${hdfsDataContainerPath} -f $hiveFile2 >> $logFile 2>&1 & pid1=$! 
hive -hiveconf DATADIR=${hdfsDataContainerPath} -f $hiveFile3 >> $logFile 2>&1 & pid2=$! 

i1=1
#echo -n ' '
echo -n "${green}Step 3: Begin Partitioning the sample activities data using hive${reset}" | tee -a $logFile
while [ -d /proc/$pid1 ]
do
  printf "\b${sp:i1++%${#sp}:1}"
done
echo -e "\n"
echo -n "${green}Partitioning the sample users data using hive${reset}" | tee -a $logFile
while [ -d /proc/$pid2 ]
do
  printf "\b${sp:i2++%${#sp}:1}"
done
wait

echo | tee -a $logFile
echo "${green}End partitioning the sample data using hive at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile

echo "${yellow}Step 3: Partition sample data using Hive completed. Now you can go to blob storage ${hdfsDataContainerPath} and hive database to check the data and tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#Step 4: call spark to do feature engineering for training data set

#first package the spark app for traindata feature engineering
echo "${green}Begin packaging the spark app for traindata feature engineering${reset}"  | tee -a $logFile
(cd ${thisDir}/sparkapp/training && sbt package && chmod 755 ${localTrainingLibPath}) >> $logFile 2>&1 &
echo "${green}End packaging the spark app for traindata feature engineering at $(date +"%Y%m%d-%H%M%S") ${reset}"  | tee -a $logFile

#package the spark app for scoredata feature engineering
echo "${green}Begin packaging the spark app for scoredata feature engineering${reset}"  | tee -a $logFile
(cd ${thisDir}/sparkapp/scoring && sbt package && chmod 755 ${localScoringLibPath})   >> $logFile 2>&1 &
echo "${green}End packaging the spark app for scoredata feature engineering at $(date +"%Y%m%d-%H%M%S") ${reset}"  | tee -a $logFile

wait
hive_site="/usr/hdp/current/spark-client/conf/hive-site.xml"
lib_hadoop_azure=`find /usr/hdp/current/hadoop-client/ -name hadoop-azure-*.jar -print`
lib_azure_storage=`find /usr/hdp/current/hadoop-client/lib/ -name azure-storage*.jar -print`
lib_data_jdo=`find /usr/hdp/2.*/spark/lib/ -name datanucleus-api-jdo-*.jar -print -quit`
lib_data_rdbms=`find /usr/hdp/2.*/spark/lib/ -name datanucleus-rdbms-*.jar -print -quit`
lib_data_core=`find /usr/hdp/2.*/spark/lib/ -name datanucleus-core-*.jar -print -quit`

echo "${green}Step 4: Begin feature engineering using spark${reset}" | tee -a $logFile
echo "${green}Feature engineering for train data using spark${reset}" | tee -a $logFile
echo "${green}Feature engineering for real data using spark${reset}" | tee -a $logFile
echo | tee -a $logFile

#             --driver-memory 2g --executor-cores 1 --executor-memory 4g --num-executors 18 \
spark-submit --master yarn --deploy-mode cluster --files ${hive_site} \
             --jars ${lib_hadoop_azure},${lib_azure_storage},${lib_data_jdo},${lib_data_rdbms},${lib_data_core} \
             ${localTrainingLibPath} \
              ChurnPeriodPara=$churnPeriod ChurnThresholdPara=${churnThreshold} DataDirPara=${hdfsDataContainerPath} >> $logFile 2>&1 & pid3=$! 

#call spark to do feature engineering for real data set
#             --driver-memory 2g --executor-cores 1 --executor-memory 4g --num-executors 18 \
spark-submit --master yarn --deploy-mode cluster --files ${hive_site} \
             --jars ${lib_hadoop_azure},${lib_azure_storage},${lib_data_jdo},${lib_data_rdbms},${lib_data_core} \
             ${localScoringLibPath} \
              ChurnPeriodPara=$churnPeriod ChurnThresholdPara=${churnThreshold} DataDirPara=${hdfsDataContainerPath} >> $logFile 2>&1 & pid4=$! 
i1=1
i2=1
echo -n "${green}Feature engineering for train data using spark${reset}" | tee -a $logFile
while [ -d /proc/$pid3 ]
do
  printf "\b${sp:i1++%${#sp}:1}"
done
echo -e "\n"
echo -n "${green}Feature engineering for score data using spark${reset}" | tee -a $logFile
while [ -d /proc/$pid4 ]
do
  printf "\b${sp:i2++%${#sp}:1}"
done
wait
echo -e "\n"
echo | tee -a $logFile
echo "${green}End feature engineering for train data using spark at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile
echo "${green}End feature engineering for real data using spark at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile

echo "${yellow}Step 4: Feature engineering for train data set using Spark completed. Now you can go to blob storage ${hdfsResultPath} and hive database to check the data and tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#Step 5: Call R script to do training
echo "${green}Step5: Begin training using MRS${reset}" | tee -a $logFile
trainingFile="${thisDir}/mrs/training.R"
echo | tee -a $logFile
Rscript --default-packages=methods,utils,datasets $trainingFile  ${hdfsDataContainerPath}  >> $logFile 2>&1 & pid5=$! 

i2=1
echo -n "${green}Training using MRS${reset}" | tee -a $logFile
while [ -d /proc/$pid5 ]
do
  printf "\b${sp:i2++%${#sp}:1}"
done
wait
echo -e "\n"
echo | tee -a $logFile
echo "${green}End training using MRS at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile

echo "${yellow}Step 5: Train model using MRS completed. Now you can go to blob storage ${hdfsDataContainerPath} and hive database to check the data and tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#step 6: this step is actually parallel progressed with feature engineering for train data togather for speed consideration for this demo.  
#for real-world case, this should be a seperate progress and need to repeat periodically
echo "${green}Step 6: Begin feature engineering for all data using spark${reset}" | tee -a $logFile
echo -e "\n"
echo | tee -a $logFile
echo "${yellow}Step 6: Feature engineering for train data set using Spark completed. Now you can go to blob storage ${hdfsResultPath} and hive database to check the data and tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#Step 7: Call R script to do prediction
echo "${green}Step 7: Begin scoring using MRS${reset}" | tee -a $logFile
echo | tee -a $logFile
scoringFile="${thisDir}/mrs/scoring.R"
Rscript --default-packages=methods,utils,datasets $scoringFile  ${hdfsDataContainerPath} >> $logFile 2>&1 & pid6=$!

i2=1
echo -n "${green}Scoring using MRS${reset}" | tee -a $logFile
while [ -d /proc/$pid6 ]
do
  printf "\b${sp:i2++%${#sp}:1}"
done
wait
echo -e "\n"
echo | tee -a $logFile
echo "${green}End scoring using MRS at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile

echo "${yellow}Step 7: Scoring using MRS completed. Now you can go to blob storage ${hdfsDataContainerPath} and hive database to check the data and tables"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#Step 8: Call R script to create a lookup webservice
echo "${green}Step 8: Begin creating a lookup webservice using MRS${reset}" | tee -a $logFile
echo | tee -a $logFile
lookupFile="${thisDir}/mrs/lookupWithWebService.R"
Rscript --default-packages=methods,utils,datasets $lookupFile  ${hdfsDataContainerPath} ${wsID} ${wsAuth} ${now} >> $logFile 2>&1  & pid7=$! 

i2=1
echo -n "${green}Creating a lookup webservice using MRS${reset}" | tee -a $logFile
while [ -d /proc/$pid7 ]
do
  printf "\b${sp:i2++%${#sp}:1}"
done
wait
echo -e "\n"
echo | tee -a $logFile
echo "${green}End creating a lookup webservice using MRS at $(date +"%Y%m%d-%H%M%S") ${reset}" | tee -a $logFile
echo "${yellow}Step 8: Create webservice using MRS completed. Now you can go to Joshph mart to run some user login"
if [[ "$pauseflag" == "on"* ]]
then
	read -s -n 1 -p "Press any key to continue......{reset}"
fi
echo

#Step 9: Copy the prediction result to the result container for visualization purposes
echo "${green}Step 9: Begin Copying prediction result to the result container ${reset}" | tee -a $logFile
echo | tee -a $logFile
hdfsResultDataPath="${hdfsDataPath}/predictions/"
hdfsResultDataPath2="${hdfsResultPath}/predictions/"
localResultDataPath="${thisDir}/tmp/predictions"
echo $hdfsResultDataPath
echo $hdfsResultDataPath2
echo $localResultDataPath
hadoop fs -get ${hdfsResultDataPath}/* ${localResultDataPath} >> $logFile 2>&1 
hadoop fs -put ${localResultDataPath}/* ${hdfsResultDataPath2} >> $logFile 2>&1 
echo | tee -a $logFile
echo "${yellow}Step 9: Copy prediction result completed. Now you can go to PowerBI to do visualization"

now=$(date +"%Y%m%d-%H%M%S")
echo "Demo ended at: ${now}" | tee -a $logFile