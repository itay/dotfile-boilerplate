#!/bin/bash
 
# Number of seconds we wait after a file is received before we consider the
# batch to be completed.
TIMEOUT=2
# Title of the tab in Kaleidoscope
LABEL="P4V ksdiff-batch"
 
# FIFO we communicate with the "batch master" for.
fifo="/tmp/ksdiff-batch-$USER"
# PID of the batch master, to see if it's still running.
pidfile="$fifo.pid"
 
# This function forks a process that just reads the FIFO for a new pair of files
# to read. If $TIMEOUT seconds pass without a new pair of files, it closes the
# Kaleidoscope "changeset" and deletes the FIFO and pidfile.
function fork_batchmaster()
{
  rm -f "$fifo" "$pidfile"
  mkfifo "$fifo"
 
  ( session="batch-$$"
    exec 3<> "$fifo"
 
    function cleanup() {
      if [ ! -z "$(pidof Kaleidoscope)" ]; then
        ksdiff --mark-changeset-as-closed "$session"
      fi
      exec 3>&-
      rm -f "$fifo" "$pidfile"
    }
    trap "cleanup" "EXIT"
 
    while read -r -t $TIMEOUT -u 3 line1; do
      if read -r -t $TIMEOUT -u 3 line2; then
        ksdiff --partial-changeset --label "$LABEL" --UUID "$session" "$line1" "$line2"
      else
        break
      fi
    done ) &
 
  echo "$?" > "$pidfile"
}
 
export PATH=$PATH:/usr/local/bin
 
# We use a lockfile to prevent interleaving of lines in the FIFO, and to ensure
# that two different processes aren't trying to become the batchmaster at the
# same time.
lock=/tmp/ksdiff-batch-$USER.lock
function delete_lock() { rm -f "$lock"; }
 
# Retry interval is 1 second so that the batchmaster won't time out waiting for
# new files while we're waiting for the lock.
if ! lockfile -1 -l 10 "$lock"; then exit 1; fi
# Ensure we delete the lock at exit, no matter what.
trap "delete_lock" "EXIT"
 
# If there's no pidfile, or the pid is dead, we assume the responsibility of
# creating a new batchmaster.
if [ ! -f "$pidfile" ] || ! kill -0 $(cat "$pidfile") >/dev/null 2>&1; then
  fork_batchmaster
fi
 
# Assuming everything went OK, there should be a FIFO available, and we can
# write to it.
if [ -p "$fifo" ]; then
  echo "$1" > "$fifo"
  echo "$2" > "$fifo"
fi
