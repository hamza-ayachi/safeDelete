#!/bin/bash



#First it stores the hashes of the files in the TrashCan directory to sum.md5 file using the md5sum command
#It trashCan directory is empty it creates empty file for efficency purpose
#Sleeps for 15sec as required
#Stores hashes in a new file(sum1.md5) 
#It reads the first md5 file containing the old hashes and compares them to the new md5 file to track changes
#For every changes: Deletion, Modification, Recovery of a file, the script tracks and notifies the user every 15sec(as required)
Listen_Trash(){
echo "*******************************"
echo "* Name: Hamza Ayachi          *"
echo "* Student ID: S1719020        *"
echo "* Assignment: Monitor Script  *"
echo "*******************************"
echo -e "You are watching your TrashCan directory ......."
local size1
local size2
while true
do
if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
find $HOME/.TrashCan -type f -print0 | xargs -0 md5sum > sum.md5
else
touch sum.md5
fi 
sleep 15
if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
find $HOME/.TrashCan -type f -print0 | xargs -0 md5sum > sum1.md5
else 
touch sum1.md5
fi
size1=$(wc -c <"sum.md5")
size2=$(wc -c <"sum1.md5")
if [[ $size1 -ne 0 ]] || [[ $size2 -ne 0 ]]; then
while IFS=" " read -r oldhash name; do
  if [[ ! -e "$name" ]]; then
     echo "$(date +"%F %R") The file $name has been deleted or recovered from the TrashCan"
  else
  while IFS=" " read -r oldhash1 name1; do
  if [[ "$name" == "$name1" ]]; then
   if [[ "$oldhash" != "$oldhash1" ]]; then
     echo "$(date +"%F %R") The file $name has been modified"
   fi  
  fi
  done <sum1.md5
  fi
done <sum.md5
while IFS=" " read -r oldhash2 name2; do
 if ! grep -q "$name2" sum.md5; then
   echo "$(date +"%F %R") The file $name2 has been added recently to TrashCan"
 fi 
done <sum1.md5
fi   
rm sum.md5
rm sum1.md5
done
}

trap trapCtrlC SIGINT
trap trapEndMonitor KILL


#It gets the signal(SIGINT) trap from the user
#Informs the user
#Exits the program
trapCtrlC(){
    echo -e "\r\nYou hit Ctrl-C. You are no longer watching your TrashCan!"
    exit 130
}

#gets the process id and kill the monitor
trapEndMonitor(){
    kill -9 $1
    echo -e "\r\nGoodbye watching is over for today"
}



