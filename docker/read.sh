#!/bin/bash 

cat participants.txt
fileItemString=$(cat  participants.txt |tr "\n" " ")

fileItemArray=($fileItemString)

echo ${fileItemArray[0]}
echo ${fileItemArray[1]}
echo ${fileItemArray[2]}
Length=${#fileItemArray[@]}

echo $Length
