#!/bin/bash

aptGetInstall() {
    packageName=$1
	echo "Checking for $packageName installed or not"
	if [ $(dpkg-query -W -f='${Status}' $packageName 2>/dev/null | grep -c "ok installed") -eq 0 ];
	then
	  echo "No $packageName installed. Setting up $packageName....."
	  sudo apt-get --force-yes --yes install $packageName
	  echo "$packageName installed."
	else
	  echo "$packageName was installed."	  
	fi	
}

command_exists () {
    type "$1" &> /dev/null ;
}

$ date +"FORMAT"
now=$(date +"%Y%m%d-%H%M%S")
thisDir=$(pwd)

echo "start check and install required packages, libraries and tools"

# insall npm wget first
#sudo apt-get -y install rpm
aptGetInstall rpm

#rpm -qa wget
#yum -y install wget
#command -v wget >/dev/null 2>&1 || { echo "wget is not installed.  installing..." >&2; rpm -qa wget; yum -y install wget}

echo "Checking for wget installed or not"
if  command_exists wget ; then
	echo "wget was installed."
else
	echo "wget is not installed.  installing..."
    rpm -qa wget
	yum -y install wget
	echo "wget installed."
fi

downloadDir="${thisDir}/downloads"
sudo su - <<HERE
echo "Checking for RStudio-Server installed or not"
if ! type "rstudio-server" > /dev/null; then
	echo "RStudio-Server is not installed"
	# Download the custom script to install RStudio
	mkdir -p $downloadDir
	wget -P $downloadDir http://mrsactionscripts.blob.core.windows.net/rstudio-server-community-v01/InstallRStudio.sh	
	chmod 755 ${downloadDir}/InstallRStudio.sh
	${downloadDir}/InstallRStudio.sh
	(cd ${downloadDir} && ./InstallRStudio.sh)
else
	echo "RStudio-Server was installed"
	#sudo rstudio-server verify-installation
fi
HERE

sudo rm -rf ${downloadDir}

# Install libcurl and libxml
#sudo apt-get -y install libcurl4-openssl-dev
aptGetInstall libcurl4-openssl-dev

#sudo apt-get -y install libxml2-dev
aptGetInstall libxml2-dev

# Install node.js
#sudo apt-get -y install nodejs-legacy
aptGetInstall nodejs-legacy

websiteDir="${thisDir}/Website"
sudo rm -rf ${websiteDir}/node_modules
(cd ${websiteDir} && sudo npm install)

#sudo apt-get -y install npm
aptGetInstall npm

# Install sbt
if ! type "sbt" > /dev/null; then
	echo "sbt is not installed.  installing..."
	echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
	sudo apt-get update
	sudo apt-get install sbt
	echo "sbt installed."
else
	echo "sbt was installed."
fi

#sudo npm install -g azure-cli
if ! type "azure" > /dev/null; then
	echo "azure CLI is not installed.  installing..."
    sudo npm install -g azure-cli
	echo "azure CLI installed."
else
	echo "azure CLI was installed."
fi

installRFile="${thisDir}/mrs/installrpackages.R"
sudo Rscript --default-packages=methods,utils,datasets $installRFile

#sudo apt-get install dos2unix
aptGetInstall dos2unix
dos2unix run_demo.sh
#change file permission
chmod 755 run_demo.sh

echo "complete prerequisites installation!"

