#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly = TRUE)
print(args)

# test if there is at least one argument: if not, return an error
if (length(args)<3) {
  stop("We need three arguments: arg1: path to storage container arg2: AML workspace id arg3: auth for AML workspace", call.=FALSE)
} 

myNameNode <- args[1]
wsID <- args[2]
wsAuth <- args[3]

publishWS <- 1

print(paste("myNameNode=",myNameNode))
message("Sourcing setup.R...")
initial.options <- commandArgs(trailingOnly = FALSE)
file.arg.name <- "--file="
script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
script.basename <- dirname(script.name)
other.name <- paste(sep="/", script.basename, "setup.R")
print(paste("Sourcing",other.name,"from",script.name))
source(other.name)

