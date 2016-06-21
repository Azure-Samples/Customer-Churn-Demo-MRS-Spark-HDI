name         := "com.adf.spark.customerchurn.scoredatafeatureengineering"
version      := "1.0"
organization := "inqiu"

scalaVersion := "2.10.5"

//libraryDependencies += "org.apache.spark" %% "spark-core" % "1.6.0"
//libraryDependencies += "org.apache.spark" %% "spark-sql" % "1.0.0"

//seq(webSettings :_*)

libraryDependencies ++= Seq(
   "org.apache.spark" %% "spark-core" % "1.6.1",
   "org.apache.spark" %% "spark-sql" % "1.6.1",
   "org.apache.spark" %% "spark-hive" % "1.6.1"
)

resolvers += Resolver.sonatypeRepo("releases")
