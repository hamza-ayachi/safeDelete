#! /bin/bash
USAGE="usage: safeDel.sh[OPTION]... [FILE]..."
trap trapCtrlC SIGINT
trap trapEndScript EXIT

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


trapEndScript(){
    echo -e "\r\n*********** &&& Goodbye! &&& ***********"
}


#Displays the menu to the user when no arguments are provided
#Handles the safeDel commands
#It calls all the functions in the script
#It handles the files for safely deleted when passed the files as arguments-ex: safeDel.sh [file.sh]...
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

     fi
   done
}

Execute(){
 source ./monitor.sh
 Listen_Trash 
}

End(){
source ./monitor.sh
trapEndMonitor $(pgrep safeDel.sh)
}

Check_TrashCan() {
  if [ ! -d $HOME/.TrashCan ]; then
    echo "************ &&& Hello &&& *************"
    mkdir -p $HOME/.TrashCan
  else
    echo "********** Welcome to safeDel **********"
  fi
}

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

Check_Total_Usage() {
 local kb
 local disk_usage=0
 local size
  if find $HOME/.TrashCan -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  for var in $HOME/.TrashCan/*; do
   name="$var"
   size=$(wc -c <"$var")
   disk_usage=$(($disk_usage+$size))
  done 
  if [[ $disk_usage -gt 1024 ]]; then
   zenity --warning --text=" The total disk usage of the TrashCan is $disk_usage bytes has exceeded 1 kilobyte of memory" 
  fi
 fi
}

main "$@"
