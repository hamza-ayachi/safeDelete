#!/bin/bash
#helps the user
USAGE="usage: safeDel.sh[OPTION]... [FILE]..." 

#Stops the proccess when the user hits ctrl-c
trap trapCtrlC SIGINT
#Ends the script
trap trapEndScript EXIT

#It gets the signal(SIGINT) trap from the user
#Informs the user
# It counts the number of files in the TrashCan Directory and Display to the user
trapCtrlC(){
    local counter
    echo -e "\r\nYou hit Ctrl-C. You are going to leave the application!"
    if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
      for var in $HOME/.TrashCan/*; do
       counter=$(($counter+1))
      done 
     echo "The TrashCan contains $counter files."
    else 
     echo "The TrashCan is empty"
    fi
    exit 130
}


#It echos a message to the user when the user exits the application
trapEndScript(){
    echo -e "\r\n*********** &&& Goodbye! &&& ***********"
}


#Displays the menu to the user when no arguments are provided
#Handles the safeDel commands
#It calls all the functions in the script
main() {
  Check_TrashCan
  Check_Total_Usage
  while getopts :lr:dtmk args #options
   do
   case $args in
     l) List_Trash;;
     r) File_Recover $OPTARG;;
     d) Delete_Trash;; 
     t) Total_Usage;; 
     m) Execute;; 
     k) End;;     
     :) echo "data missing, option -$OPTARG";;
    \?) echo "$USAGE";;
   esac
  done

 ((pos = OPTIND - 1))
 shift $pos

 PS3='option> '

 if (( $# == 0 ))
  then if (( $OPTIND == 1 )) 
    then select menu_list in list recover delete total monitor kill exit
      do case $menu_list in
         "list") List_Trash;;
         "recover") 
                 echo "Enter the file name to recover: "
                 read ans
                 if [[ -z "$ans" ]]; then
                   echo "Please enter a file name"
                 else  
                   File_Recover $ans
                 fi;;
         "delete") Delete_Trash;;
         "total") Total_Usage;;
         "monitor") Execute;;
         "kill") End;;
         "exit") exit 0;;
           *) echo "unknown option";;
         esac 
      done
 fi
 else
 Delete_files "$@"
 fi
 }

#Checks if the TrashCan directory exists in the home directory
#If not it creates a hidden TrashCan in the home directory
Check_TrashCan() {
  if [ ! -d $HOME/.TrashCan ]; then
    echo "************ &&& Hello &&& *************"
    mkdir -p $HOME/.TrashCan
  else
    echo "********** Welcome to safeDel **********"
  fi
}

#Checks if the TrashCan is empty
#If not it loops through the files and takes the size of each file in bytes
#If the total size of the TrashCan exceeds 1kb (1024 bytes) it displays a warning message using ***zenity*** 
Check_Total_Usage() {
 local disk_usage=0
 local size
  if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  for var in $HOME/.TrashCan/*; do
   size=$(wc -c <"$var")
   disk_usage=$(($disk_usage+$size))
  done 
  if [[ $disk_usage -gt 1024 ]]; then
   zenity --warning --text=" The total disk usage of the TrashCan is $disk_usage bytes has exceeded 1 kilobyte of memory" 
  fi
 fi
}


#It handles the files for safely deleted when passed the files as arguments-ex: safeDel.sh [file.sh]...
#Runs multiples checks: 
#***********#Checks if the file exits: if it exists it moves to the TrashCan Directory 
#***********#Checks if the the TrashCan contains a file with the same name:  if yes it prompts the user to rename
Delete_files(){
for name in "$@"; do
    if [[ -e $name ]]; then
      echo "Do you want to delete $name (Y/n): "
      read ans  
      case $ans in
         n | N)
          echo "$name not deleted"
         ;;
          Y | *)
          if [[ -e $HOME/.TrashCan/$name ]]; then
             renam=$name
             while [[ -e $HOME/.TrashCan/$renam ]]; do
             	echo "file with the same name $name already exists,please rename the file: "
                read renam
             done   
	     mv $name $renam
        
             mv $renam $HOME/.TrashCan 
          echo "The file $name has been renamed to $renam and deleted"  
          else
          mv $name $HOME/.TrashCan
          echo "The file $name has been deleted"
          fi
        ;;
      esac
     else
       echo "No such file exist in this directory."
       echo $USAGE	

     fi
   done
}


#it checks if the TrashCan directory is empty it simple echos 
#If it is not empty it loops through the TrashCan for every file it gets the file name, size and type
List_Trash() {
  local name
  local size
  local typ
 if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  for var in $HOME/.TrashCan/*; do
   name="$var"
   size=$(wc -c <"$var")
   typ=$(file $var)
   echo "FileName: $name Size: $size bytes Type: $typ"
  done
 else
   echo "TrashCan is Empty"
 fi
}

#It checks if the given file exits in the TrashCan directory
#*****if it does not exist it flags to the user
#*****if it exists, it checks if a file with the same name exists in the current directory
#*****if it does it informs the user 
#*****if not it recovers the file to the current directory
File_Recover() {
  if [[ -e $HOME/.TrashCan/$1 ]]; then
     if [[ -e $1 ]]; then
       echo "there is a file with the same name $1 exists in this directory"
     else
       chmod 755 $HOME/.TrashCan/$1
       mv $HOME/.TrashCan/$1 .
       echo "$1 file have been recovered"
     fi
  else
     echo "The file $1 does not exist in the TrashCan"
  fi  
}

#Checks if the TrashCan is empty
#******if yes if flags to user
#******if not it loops through the TrashCan and pronpts the user for every file wether to delete or not  
Delete_Trash() {
  
  if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
   for var in $HOME/.TrashCan/*; do
     echo "Do you want to delete this file $var (y/N):"
     read ans
     case $ans in
     y | Y) rm $var
        echo "file $var deleted";;
     N | *) echo "file $var is not deleted";;  
     esac 
   done
   else
   echo "TrashCan is empty"
   fi
}

#Checks if the TrashCan is empty
#If not it loops through the files and takes the size of each file in bytes
#Displays the total usage to the user in bytes
Total_Usage() {
 local kb
 local disk_usage=0
 local size
  if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  for var in $HOME/.TrashCan/*; do
   name="$var"
   size=$(wc -c <"$var")
   disk_usage=$(($disk_usage+$size))
  done 
   echo "The total disk usage of the TrashCan is $disk_usage bytes."
 else
   echo "The total disk usage of the TrashCan is 0 bytes."
 fi
}

#using the source method it exectutes the Listen_Trash function from the monitor.sh script
Execute(){
 #chmod 755 ./monitor.sh
 source ./monitor.sh
 Listen_Trash 
}

#using the source method it exectutes the trap to kill the monitor script using the process ID
End(){
source ./monitor.sh
trapEndMonitor $(pgrep safeDel-comments.sh)
}

main "$@"
