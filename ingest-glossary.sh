#!/bin/bash

####################################################################################################
########## Author: Basanta Aryal  ############################## Created Date: 07/31/2023 ##########
####################################################################################################
########## Last Modified by: Basanta Aryal      ########## Last Modified Date: 07/31/2023 ##########
####################################################################################################
##  This is a bash script that calls python to convert excel to yaml and execute glossary ingest  ##
####################################################################################################
##              use chmod u+x <name of the file> to make the bash file executable                 ##
####################################################################################################
##       The python script that converts the given spreadsheet (xlsx) file to Yaml format.        ##
## The desired columns are hardcoded, if the changes are needed code can be modified respectively ##
####################################################################################################
##Pre-Req1: Pandas for python3.5+:'pip3 install pandas' on Linux, 'pip install pandas' on Windows ##
##Pre-Req2: Openpyxl for python3.5+:'pip3 install openpyxl' Lin, 'pip install openpyxl' on Windows##
####################################################################################################
## command use 'bash ingest-glossary.sh "Excel file path/name" "y or n"' y=ingest,n=dry-run       ##
## Preferred use 'bash ingest-glossary.sh "Excel file path/name"' provide ingest flag at runtime  ##
## command use 'bash ingest-glossary.sh' provide Excel file and ingest flag both at runtime       ##
####################################################################################################

this_file=$(readlink -f $0)
current_dir=`dirname $this_file`"/"
python_file="$current_dir""excelToYaml.py"

#current_dir="/home/""$USER""/python/"
mkdir -p "/home/""$USER""/python/"
history_files_dir="/home/""$USER""/python/"

recipe_file="$history_files_dir""glossary_recipe.yaml"

cd "$current_dir"

dated_folder="$history_files_dir""IngestHistory/""$(date +"%Y")""/""$(date +"%m")""/"
mkdir -p "$dated_folder"

#read the command line parameters for file path and ingest flag if any, if not ask during runtime
if [ $# -eq 0 ]
  then
    echo "Please enter a excel file name (with extension)."
    read file
else 
    file="$1"
    if [ -z "$2" ]
    then
        echo "Running with only one input argument"
        ask_for_ingestion="Y"
    else
        ask_for_ingestion="N"
        character="$2"
    fi
fi


#check for required python libraries, install if it does not exist
python3 -c "import pandas"
library_status="$?"
if [ "$library_status" -ne 0 ]
then 
    pip3 install pandas
fi

python3 -c "import openpyxl"
library_status="$?"
if [ "$library_status" -ne 0 ]
then 
    pip3 install openpyxl
fi

python3 -c "import uuid"
library_status="$?"
if [ "$library_status" -ne 0 ]
then 
    pip3 install uuid
fi

python3 -c "import yaml"
library_status="$?"
if [ "$library_status" -ne 0 ]
then 
    pip3 install pyyaml
fi

#consolidate the exact file name from full path/file name
filename="$(b=${file##*/}; echo ${b%.*})"
echo "$filename"

file_postfix="_"$(date +"%Y%m%d%H%M")

#copy the original excel file and create also make similar name for output yaml file in same directory.
excel_file="$dated_folder""$filename""$file_postfix"".xlsx"
cp "$file" "$excel_file" 

yaml_file="$dated_folder""$filename""$file_postfix"".yaml"


find . -name "$excel_file"  # | egrep '.*'
if [ "$?" -ne 0 ] 
then
    echo "file does not exist"
fi

echo "Now using the excel file: '""$excel_file""' to create a yaml file: '""$yaml_file""'"

#calling python script to convert the excel file to yaml file
python3 "$python_file" "$excel_file" "$yaml_file"

echo "Now using the glossary yaml file '""$yaml_file""' with in the recipe file: '""$recipe_file""'"

#create a recipe file with the yaml files just created
echo -e "
#Datahub Ingestion Recipe File
source:
  type: datahub-business-glossary
  config:
     #Coordinates
     enable_auto_id: true
     file: ""$yaml_file""
     " > "$recipe_file"

echo "
################################################################################################################################
#Now executing : 'datahub ingest -c ""$recipe_file"" --dry-run' command
################################################################################################################################
"

#execute a datahub ingest dry run
datahub ingest -c "$recipe_file" --dry-run
dry_run_status="$?"
echo "
################################################################################################################################
#Previous command status (0 if success, 1 if failed): ""$dry_run_status""
################################################################################################################################
"

#check whether the ingest dry run command failed or succeded, halt further process if failed, 
#if not take the ingest flag from user (if not already provided on the command line)
if [ "$dry_run_status" -ne 0 ]
then 
    character="N"
else 
    if [ "$ask_for_ingestion" = "Y" ]
    then 
        echo "Do you want to run the actual ingestion now (Y/N)?"
        read character
    fi
fi

#perform the ingestion or abort it based on the ingest flag(either provided by user at run time or passed via command line )
#Please refer to the command use and preferred use notes on the header of the file
if [ "${character:0:1}" = "Y" ] || [ "${character:0:1}" = "y" ] 
then
    echo "Ingesting the file in 30 seconds, if you want to exit out, ctrl+c before it starts"
    sleep 5s
    echo "Ingesting now 25s"
    sleep 5s
    echo "Ingesting now 20s"
    sleep 5s
    echo "Ingesting now 15s"
    sleep 5s
    echo "Ingesting now 10s"
    sleep 5s
    echo "Ingesting now 5s"
    sleep 5s    
    echo "Ingesting now"
    echo "running 'datahub ingest -c ""$recipe_file""' command"
    sleep 5s    
    datahub ingest -c "$recipe_file"
    ingest_status="$?"
    echo "
################################################################################################################################
#Ingestion status (0 if success, 1 if failed): ""$ingest_status""
################################################################################################################################
"
else
    echo "Now aborting ingestion"
fi

##End of the Script
#############################################################################################
## disregard anything below, just for testing purpose
## echo "$filename" | cut -f 2 -d '.' 
