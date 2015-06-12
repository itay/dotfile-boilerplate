#!/bin/bash

if [ -z "$1" ]
then
    echo "Must supply a changelist"
    exit 1
fi

TEMPOLD="$(mktemp /tmp/gendiff.old.XXXXXXXXXX)"
TEMPNEW="$(mktemp /tmp/gendiff.new.XXXXXXXXXX)"
TEMPOUT="$(mktemp /tmp/gendiff.output.XXXXXXXXXX)"

for CHANGED_FILE in $(p4 opened -c $1 | sed -e 's/#.*//')
do  
  OLDCONTENT=$(p4 print $CHANGED_FILE 2>&1)
  OLD_FIRST_LINE=$(echo "$OLDCONTENT" | head -n 1)
  OLDCONTENT=$(echo "$OLDCONTENT" | tail -n +2)
  
  NO_SUCH_FILE=$(echo "$CHANGED_FILE - no such file(s).")
  
  TEMPDATE=$(date "+2013-02-27 13:56:19.000000000")
  TEMPDATE2=$(date "+2013-02-27 13:56:19.000000000")
  
  if [ "$OLD_FIRST_LINE" == "$NO_SUCH_FILE" ] 
  then
    cat /dev/null > $TEMPOLD
    # For "added" files, we need to use the enoch beginning, and also
    # put a space after the perforce path
    TEMPDATE="1969-12-31 16:00:00.000000000"
    CHANGED_FILE="$CHANGED_FILE "
  else
    echo "$OLDCONTENT" > $TEMPOLD
  fi
  
  LOCAL_FILE=$(p4 where $CHANGED_FILE | awk '/^\// {print $3}')
  
  COMMON_FILE=$(python -c "import os.path as path; print path.commonprefix([\"$LOCAL_FILE\"[::-1], \"$CHANGED_FILE\"[::-1]])[::-1].lstrip(\"/\")")
  
  NEWCONTENT=$(cat $LOCAL_FILE 2> /dev/null)
  WAS_ERROR=$?
  
  if [ $WAS_ERROR == "1" ]
  then
    cat /dev/null > $TEMPNEW
  else
    echo "$NEWCONTENT" > $TEMPNEW
  fi
  
  CURRENT_DIR=`pwd`
  RELATIVE_PATH=$(python -c "import os.path; print os.path.relpath('$LOCAL_FILE', '$CURRENT_DIR')")
  
  echo -e "--- a/$RELATIVE_PATH" >> $TEMPOUT
  echo -e "+++ b/$RELATIVE_PATH" >> $TEMPOUT
  $(diff -U 10000 $TEMPOLD $TEMPNEW | tail -n +3 >> $TEMPOUT)
done

cat $TEMPOUT
